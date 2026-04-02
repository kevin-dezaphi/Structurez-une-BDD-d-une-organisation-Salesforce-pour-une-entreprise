public with sharing class CancelTripSchedule  implements Schedulable {
    public void execute(SchedulableContext sc) {
        CancelTripBatch batch = new CancelTripBatch();
        Database.executeBatch(batch, 200);
    }
}