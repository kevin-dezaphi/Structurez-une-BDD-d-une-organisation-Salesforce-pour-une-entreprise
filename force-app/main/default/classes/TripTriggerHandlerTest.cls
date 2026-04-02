@isTest
private class TripTriggerHandlerTest {

    // ─────────────────────────────────────────────
    // Setup commun
    // ─────────────────────────────────────────────
    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Stage != 'Closed Won' pour éviter que le trigger Opportunity crée des Trips
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

    private static Trip__c buildTrip(Date startDate, Date endDate) {
        return new Trip__c(
            Opportunity__c = getOppId(),
            Start_Date__c  = startDate,
            End_Date__c    = endDate,
            Status__c      = 'A venir'
        );
    }

    // ─────────────────────────────────────────────
    // INSERT – dates valides
    // ─────────────────────────────────────────────
    @isTest
    static void testInsert_ValidDates_NoError() {
        Trip__c trip = buildTrip(Date.today().addDays(1), Date.today().addDays(10));

        Test.startTest();
        insert trip;
        Test.stopTest();

        System.assertNotEquals(null, trip.Id, 'Le Trip doit être inséré.');
    }

    // ─────────────────────────────────────────────
    // INSERT – Start_Date == End_Date → erreur
    // ─────────────────────────────────────────────
    @isTest
    static void testInsert_StartDateEqualsEndDate_ThrowsError() {
        Trip__c trip = buildTrip(Date.today(), Date.today());

        Test.startTest();
        try {
            insert trip;
            System.assert(false, 'Une DmlException était attendue.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Start Date cannot be after the End Date'),
                'Message d\'erreur inattendu : ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // INSERT – Start_Date > End_Date → erreur
    // ─────────────────────────────────────────────
    @isTest
    static void testInsert_StartDateAfterEndDate_ThrowsError() {
        Trip__c trip = buildTrip(Date.today().addDays(5), Date.today().addDays(1));

        Test.startTest();
        try {
            insert trip;
            System.assert(false, 'Une DmlException était attendue.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Start Date cannot be after the End Date'),
                'Message d\'erreur inattendu : ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // INSERT – dates nulles → pas d'erreur
    // ─────────────────────────────────────────────
    @isTest
    static void testInsert_NullDates_NoError() {
        Trip__c trip = buildTrip(null, null);

        Test.startTest();
        insert trip;
        Test.stopTest();

        System.assertNotEquals(null, trip.Id, 'Le Trip doit être inséré sans erreur quand les dates sont nulles.');
    }

    // ─────────────────────────────────────────────
    // INSERT – seule Start_Date est nulle → pas d'erreur
    // ─────────────────────────────────────────────
    @isTest
    static void testInsert_OnlyStartDateNull_NoError() {
        Trip__c trip = buildTrip(null, Date.today().addDays(5));

        Test.startTest();
        insert trip;
        Test.stopTest();

        System.assertNotEquals(null, trip.Id);
    }

    // ─────────────────────────────────────────────
    // UPDATE – dates deviennent invalides → erreur
    // ─────────────────────────────────────────────
    @isTest
    static void testUpdate_DatesBecomesInvalid_ThrowsError() {
        Trip__c trip = buildTrip(Date.today().addDays(1), Date.today().addDays(10));
        insert trip;

        trip.Start_Date__c = Date.today().addDays(15);

        Test.startTest();
        try {
            update trip;
            System.assert(false, 'Une DmlException était attendue.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Start Date cannot be after the End Date'),
                'Message d\'erreur inattendu : ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ─────────────────────────────────────────────
    // UPDATE – dates restent valides → pas d'erreur
    // ─────────────────────────────────────────────
    @isTest
    static void testUpdate_DatesStillValid_NoError() {
        Trip__c trip = buildTrip(Date.today().addDays(1), Date.today().addDays(10));
        insert trip;

        trip.Start_Date__c = Date.today().addDays(2);
        trip.End_Date__c   = Date.today().addDays(15);

        Test.startTest();
        update trip;
        Test.stopTest();

        Trip__c updated = [SELECT Start_Date__c, End_Date__c FROM Trip__c WHERE Id = :trip.Id];
        System.assertEquals(Date.today().addDays(2),  updated.Start_Date__c);
        System.assertEquals(Date.today().addDays(15), updated.End_Date__c);
    }

    // ─────────────────────────────────────────────
    // Bulk INSERT – 200 records valides
    // ─────────────────────────────────────────────
    @isTest
    static void testBulkInsert_ValidDates() {
        Id oppId = getOppId();
        List<Trip__c> trips = new List<Trip__c>();
        for (Integer i = 0; i < 200; i++) {
            trips.add(new Trip__c(
                Opportunity__c = oppId,
                Start_Date__c  = Date.today().addDays(1),
                End_Date__c    = Date.today().addDays(10),
                Status__c      = 'A venir'
            ));
        }

        Test.startTest();
        insert trips;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Trip__c WHERE Opportunity__c = :oppId];
        System.assertEquals(200, count, '200 trips valides doivent être insérés.');
    }

    // ─────────────────────────────────────────────
    // Test direct du handler (sans trigger)
    // ─────────────────────────────────────────────
    @isTest
    static void testHandlerDirect_InvalidDates_AddsError() {
        Trip__c trip = buildTrip(Date.today().addDays(5), Date.today().addDays(1));

        Test.startTest();
        TripTriggerHandler.checkDate(new List<Trip__c>{ trip });
        Test.stopTest();

        System.assert(trip.hasErrors(), 'Le record doit porter une erreur DML.');
    }
}