@isTest
private class CancelTripScheduleTest {

    private static final String CRON_EXPR = '0 0 2 * * ?';

    // ─────────────────────────────────────────────
    // Le scheduler s'enregistre avec la bonne expression CRON
    // ─────────────────────────────────────────────
    @isTest
    static void testSchedule_JobIsRegistered() {
        Test.startTest();
        String jobId = System.schedule(
            'CancelTripSchedule_Test',
            CRON_EXPR,
            new CancelTripSchedule()
        );
        Test.stopTest();

        CronTrigger ct = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertNotEquals(null, ct, 'Le job planifié doit exister.');
        System.assertEquals(CRON_EXPR, ct.CronExpression, 'L\'expression CRON doit correspondre.');
    }

    // ─────────────────────────────────────────────
    // État du job : WAITING ou COMPLETE après stopTest
    // ─────────────────────────────────────────────
    @isTest
    static void testSchedule_JobStateIsValid() {
        Test.startTest();
        String jobId = System.schedule(
            'CancelTripSchedule_StateTest',
            CRON_EXPR,
            new CancelTripSchedule()
        );
        Test.stopTest();

        CronTrigger ct = [SELECT State FROM CronTrigger WHERE Id = :jobId];
        System.assert(
            ct.State == 'WAITING' || ct.State == 'COMPLETE',
            'Le job doit être en état WAITING ou COMPLETE, état actuel : ' + ct.State
        );
    }
}