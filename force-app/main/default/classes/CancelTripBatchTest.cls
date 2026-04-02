@isTest
private class CancelTripBatchTest {

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

    private static Trip__c buildTrip(Date startDate, String status, Decimal participants) {
        return new Trip__c(
            Opportunity__c         = getOppId(),
            Start_Date__c          = startDate,
            End_Date__c            = startDate != null ? startDate.addDays(5) : Date.today().addDays(5),
            Status__c              = status,
            Number_Participants__c = participants
        );
    }

    // ─────────────────────────────────────────────
    // Trips éligibles → passent à 'Annulé'
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_EligibleTrips_GetCancelled() {
        List<Trip__c> trips = new List<Trip__c>{
            buildTrip(Date.today().addDays(3), 'A venir', 5),
            buildTrip(Date.today().addDays(1), 'En cours', 2),
            buildTrip(Date.today().addDays(6), 'A venir', 9)
        };
        insert trips;

        Test.startTest();
        Database.executeBatch(new CancelTripBatch(), 200);
        Test.stopTest();

        for (Trip__c t : [SELECT Status__c FROM Trip__c WHERE Id IN :trips]) {
            System.assertEquals('Annulé', t.Status__c,
                'Le trip éligible doit être annulé : ' + t.Id);
        }
    }

    // ─────────────────────────────────────────────
    // Trips déjà 'Annulé' → exclus par la requête, inchangés
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_AlreadyCancelled_NotReprocessed() {
        Trip__c trip = buildTrip(Date.today().addDays(2), 'Annulé', 5);
        insert trip;

        Test.startTest();
        Database.executeBatch(new CancelTripBatch(), 200);
        Test.stopTest();

        Trip__c result = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals('Annulé', result.Status__c,
            'Un trip déjà Annulé doit rester Annulé.');
    }

    // ─────────────────────────────────────────────
    // Start_Date > today + 7 → non annulé
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_StartDateTooFar_NotCancelled() {
        Trip__c trip = buildTrip(Date.today().addDays(10), 'A venir', 5);
        insert trip;

        Test.startTest();
        Database.executeBatch(new CancelTripBatch(), 200);
        Test.stopTest();

        Trip__c result = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals('A venir', result.Status__c,
            'Un trip dont la date est > today+7 ne doit pas être annulé.');
    }

    // ─────────────────────────────────────────────
    // Number_Participants__c >= 10 → non annulé
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_EnoughParticipants_NotCancelled() {
        Trip__c trip = buildTrip(Date.today().addDays(3), 'A venir', 10);
        insert trip;

        Test.startTest();
        Database.executeBatch(new CancelTripBatch(), 200);
        Test.stopTest();

        Trip__c result = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals('A venir', result.Status__c,
            'Un trip avec 10 participants ou plus ne doit pas être annulé.');
    }

    // ─────────────────────────────────────────────
    // Number_Participants__c null → exclu par la requête, non annulé
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_NullParticipants_NotCancelled() {
        Trip__c trip = buildTrip(Date.today().addDays(3), 'A venir', null);
        insert trip;

        Test.startTest();
        Database.executeBatch(new CancelTripBatch(), 200);
        Test.stopTest();

        Trip__c result = [SELECT Status__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals('A venir', result.Status__c,
            'Un trip sans participants ne doit pas être annulé.');
    }

    // ─────────────────────────────────────────────
    // Bulk – 200 trips éligibles
    // ─────────────────────────────────────────────
    @isTest
    static void testExecute_BulkEligibleTrips_AllCancelled() {
        Id oppId = getOppId();
        List<Trip__c> trips = new List<Trip__c>();
        for (Integer i = 0; i < 200; i++) {
            trips.add(new Trip__c(
                Opportunity__c         = oppId,
                Start_Date__c          = Date.today().addDays(3),
                End_Date__c            = Date.today().addDays(8),
                Status__c              = 'A venir',
                Number_Participants__c = 5
            ));
        }
        insert trips;

        Test.startTest();
        Database.executeBatch(new CancelTripBatch(), 200);
        Test.stopTest();

        Integer cancelled = [SELECT COUNT() FROM Trip__c WHERE Status__c = 'Annulé'];
        System.assertEquals(200, cancelled, '200 trips doivent être annulés en bulk.');
    }

    // ─────────────────────────────────────────────
    // Méthode finish – ne lève pas d'exception
    // ─────────────────────────────────────────────
    @isTest
    static void testFinish_NoException() {
        Test.startTest();
        Database.executeBatch(new CancelTripBatch(), 200);
        Test.stopTest();
        System.assert(true);
    }
}