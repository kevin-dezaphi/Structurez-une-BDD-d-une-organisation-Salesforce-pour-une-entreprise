public with sharing class CancelTripBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id FROM Trip__c WHERE Start_Date__c < (:Date.today() + 7) AND Status__c != \'Cancelled\' AND Number_Participants != null AND Number_Participants__c < 10');
    }

    public void execute(Database.BatchableContext BC, List<Trip__c> scope) {
        List<Trip__c> tripsToUpdate = new List<Trip__c>();

        for (Trip__c trip : scope) {
            trip.Status__c = 'Cancelled';
            tripsToUpdate.add(trip);
        }

        if (!tripsToUpdate.isEmpty()) {
            update tripsToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: Add any post-processing logic here, such as sending notifications
    }
}