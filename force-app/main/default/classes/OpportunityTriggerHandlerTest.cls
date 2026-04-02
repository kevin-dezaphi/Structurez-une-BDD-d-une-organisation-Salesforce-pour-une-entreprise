@isTest
private class OpportunityTriggerHandlerTest {

    // ─────────────────────────────────────────────
    // Setup commun
    // ─────────────────────────────────────────────
    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Opportunity buildOpp(Id accountId, String stage) {
        return new Opportunity(
            Name                   = 'Test Opp',
            AccountId              = accountId,
            StageName              = stage,
            CloseDate              = Date.today().addDays(30),
            Destination__c         = 'Paris',
            Start_Date__c          = Date.today().addDays(10),
            End_Date__c            = Date.today().addDays(20),
            Number_Participants__c = 15
        );
    }

    // ─────────────────────────────────────────────
    // INSERT – StageName = 'Closed Won' → Trip créé
    // ─────────────────────────────────────────────
    @isTest
    static void testInsert_ClosedWon_CreateTrip() {
        Account acc = getAccount();
        Opportunity opp = buildOpp(acc.Id, 'Closed Won');

        Test.startTest();
        insert opp;
        Test.stopTest();

        List<Trip__c> trips = [
            SELECT Id, Destination__c, Start_Date__c, End_Date__c,
                   Number_Participants__c, Account__c, Opportunity__c
            FROM Trip__c
            WHERE Opportunity__c = :opp.Id
        ];

        System.assertEquals(1, trips.size(), 'Un Trip doit être créé pour une Opp Closed Won.');
        System.assertEquals('Paris',                   trips[0].Destination__c);
        System.assertEquals(Date.today().addDays(10),  trips[0].Start_Date__c);
        System.assertEquals(Date.today().addDays(20),  trips[0].End_Date__c);
        System.assertEquals(15,                        trips[0].Number_Participants__c);
        System.assertEquals(acc.Id,                    trips[0].Account__c);
        System.assertEquals(opp.Id,                    trips[0].Opportunity__c);
    }

    // ─────────────────────────────────────────────
    // INSERT – StageName != 'Closed Won' → pas de Trip
    // ─────────────────────────────────────────────
    @isTest
    static void testInsert_NotClosedWon_NoTrip() {
        Account acc = getAccount();
        Opportunity opp = buildOpp(acc.Id, 'Prospecting');

        Test.startTest();
        insert opp;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Trip__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(0, count, 'Aucun Trip ne doit être créé pour un stage autre que Closed Won.');
    }

    // ─────────────────────────────────────────────
    // UPDATE – passage à 'Closed Won' → Trip créé
    // ─────────────────────────────────────────────
    @isTest
    static void testUpdate_TransitionToClosedWon_CreateTrip() {
        Account acc = getAccount();
        Opportunity opp = buildOpp(acc.Id, 'Negotiation/Review');
        insert opp;

        opp.StageName = 'Closed Won';

        Test.startTest();
        update opp;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Trip__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, count, 'Un Trip doit être créé lors du passage à Closed Won.');
    }

    // ─────────────────────────────────────────────
    // UPDATE – déjà 'Closed Won', mise à jour d'un autre champ → pas de Trip en double
    // ─────────────────────────────────────────────
    @isTest
    static void testUpdate_AlreadyClosedWon_NoDuplicateTrip() {
        Account acc = getAccount();
        Opportunity opp = buildOpp(acc.Id, 'Closed Won');
        insert opp;

        opp.Name = 'Updated Name';

        Test.startTest();
        update opp;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Trip__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, count, 'Aucun Trip supplémentaire ne doit être créé si la Opp était déjà Closed Won.');
    }

    // ─────────────────────────────────────────────
    // UPDATE – changement de stage mais pas vers Closed Won → pas de Trip
    // ─────────────────────────────────────────────
    @isTest
    static void testUpdate_StageChangeNotToClosedWon_NoTrip() {
        Account acc = getAccount();
        Opportunity opp = buildOpp(acc.Id, 'Prospecting');
        insert opp;

        opp.StageName = 'Needs Analysis';

        Test.startTest();
        update opp;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Trip__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(0, count, 'Aucun Trip ne doit être créé pour un stage autre que Closed Won.');
    }

    // ─────────────────────────────────────────────
    // Bulk INSERT – 200 Opps Closed Won → 200 Trips
    // ─────────────────────────────────────────────
    @isTest
    static void testBulkInsert_200ClosedWon_200TripsCreated() {
        Account acc = getAccount();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            Opportunity opp = buildOpp(acc.Id, 'Closed Won');
            opp.Name = 'Bulk Opp ' + i;
            opps.add(opp);
        }

        Test.startTest();
        insert opps;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Trip__c];
        System.assertEquals(200, count, '200 Trips doivent être créés en bulk.');
    }

    // ─────────────────────────────────────────────
    // Bulk UPDATE – 100 passages à Closed Won + 100 autres stages → 100 Trips
    // ─────────────────────────────────────────────
    @isTest
    static void testBulkUpdate_MixedStageTransitions() {
        Account acc = getAccount();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            Opportunity opp = buildOpp(acc.Id, 'Prospecting');
            opp.Name = 'Bulk Opp ' + i;
            opps.add(opp);
        }
        insert opps;

        for (Integer i = 0; i < 100; i++) {
            opps[i].StageName = 'Closed Won';
        }

        Test.startTest();
        update opps;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Trip__c];
        System.assertEquals(100, count, 'Seuls 100 Trips doivent être créés.');
    }
}