public with sharing class UpdateTripStatusSchedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        UpdateTripStatusBatch batch = new UpdateTripStatusBatch();
        Database.executeBatch(batch, 200);
    }
}