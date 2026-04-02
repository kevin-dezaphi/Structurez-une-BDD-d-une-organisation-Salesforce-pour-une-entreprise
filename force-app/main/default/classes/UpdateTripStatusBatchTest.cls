@isTest
private class UpdateTripStatusBatchTest {

    // ─────────────────────────────────────────────
    // Setup commun
    // ─────────────────────────────────────────────
    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
    }

    private static Id getOppId() {
        return [SELECT Id FROM Opportunity LIMIT 1].Id;
    }

    private static Trip__c buildTrip(Date startDate, Date endDate, String status) {
        return new Trip__c(
            Opportunity__c = getOppId(),
            Start_Date__c  = startDate,
            End_Date__c    = endDate,
            Status__c      = status
        );
    }

    // ─────────────────────────────────────────────
    // Start_Date dans le futur → 'A venir'
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_FutureStartDate_StatusAVenir() {
        Trip__c trip = buildTrip(Date.today().addDays(5), Date.today().addDays(15), 'En cours');
        insert trip;

        Test.startTest();
        Database.executeBatch(new UpdateTripStatusBatch(), 200);
        Test.stopTest();

        Trip__c result = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals('A venir', result.Status__c,
            'Un trip dont le Start_Date est dans le futur doit passer à "A venir".');
    }

    // ─────────────────────────────────────────────
    // End_Date dans le passé → 'Terminé'
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_PastEndDate_StatusTermine() {
        Trip__c trip = buildTrip(Date.today().addDays(-10), Date.today().addDays(-1), 'En cours');
        insert trip;

        Test.startTest();
        Database.executeBatch(new UpdateTripStatusBatch(), 200);
        Test.stopTest();

        Trip__c result = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals('Terminé', result.Status__c,
            'Un trip dont la End_Date est passée doit passer à "Terminé".');
    }

    // ─────────────────────────────────────────────
    // Start_Date <= today ET End_Date >= today → 'En cours'
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_CurrentTrip_StatusEnCours() {
        Trip__c trip = buildTrip(Date.today().addDays(-2), Date.today().addDays(5), 'A venir');
        insert trip;

        Test.startTest();
        Database.executeBatch(new UpdateTripStatusBatch(), 200);
        Test.stopTest();

        Trip__c result = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals('En cours', result.Status__c,
            'Un trip en cours (start <= today <= end) doit avoir le statut "En cours".');
    }

    // ─────────────────────────────────────────────
    // Trip 'Annulé' → exclu de la requête, statut inchangé
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_CancelledTrip_NotProcessed() {
        Trip__c trip = buildTrip(Date.today().addDays(-10), Date.today().addDays(-1), 'Annulé');
        insert trip;

        Test.startTest();
        Database.executeBatch(new UpdateTripStatusBatch(), 200);
        Test.stopTest();

        Trip__c result = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals('Annulé', result.Status__c,
            'Un trip "Annulé" ne doit pas être modifié par le batch.');
    }

    // ─────────────────────────────────────────────
    // Trip déjà au bon statut → aucun changement parasite
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_StatusAlreadyCorrect_NoChange() {
        Trip__c trip = buildTrip(Date.today().addDays(5), Date.today().addDays(15), 'A venir');
        insert trip;

        Test.startTest();
        Database.executeBatch(new UpdateTripStatusBatch(), 200);
        Test.stopTest();

        Trip__c result = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals('A venir', result.Status__c,
            'Un trip déjà "A venir" avec Start_Date futur doit rester "A venir".');
    }

    // ─────────────────────────────────────────────
    // Bulk – mix de 3 cas (50 records chacun)
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_BulkMixedTrips() {
        Id oppId = getOppId();
        List<Trip__c> trips = new List<Trip__c>();

        for (Integer i = 0; i < 50; i++) { // futur → A venir
            trips.add(new Trip__c(Opportunity__c = oppId, Start_Date__c = Date.today().addDays(5),  End_Date__c = Date.today().addDays(15), Status__c = 'En cours'));
        }
        for (Integer i = 0; i < 50; i++) { // passé → Terminé
            trips.add(new Trip__c(Opportunity__c = oppId, Start_Date__c = Date.today().addDays(-10), End_Date__c = Date.today().addDays(-1), Status__c = 'A venir'));
        }
        for (Integer i = 0; i < 50; i++) { // en cours → En cours
            trips.add(new Trip__c(Opportunity__c = oppId, Start_Date__c = Date.today().addDays(-2), End_Date__c = Date.today().addDays(5),  Status__c = 'A venir'));
        }
        insert trips;

        Test.startTest();
        Database.executeBatch(new UpdateTripStatusBatch(), 200);
        Test.stopTest();

        System.assertEquals(50, [SELECT COUNT() FROM Trip__c WHERE Status__c = 'A venir'],  '50 trips doivent passer à "A venir".');
        System.assertEquals(50, [SELECT COUNT() FROM Trip__c WHERE Status__c = 'Terminé'],  '50 trips doivent passer à "Terminé".');
        System.assertEquals(50, [SELECT COUNT() FROM Trip__c WHERE Status__c = 'En cours'], '50 trips doivent passer à "En cours".');
    }

    // ─────────────────────────────────────────────
    // Méthode finish – ne lève pas d'exception
    // ─────────────────────────────────────────────
    @isTest
    static void testFinish_NoException() {
        Test.startTest();
        Database.executeBatch(new UpdateTripStatusBatch(), 200);
        Test.stopTest();
        System.assert(true);
    }
}