public with sharing class CancelTripBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        Date oneWeekAfterToday = Date.today().addDays(7);
        String query = 'SELECT Id, Status__c ';
        query += 'FROM Trip__c ';
        query += 'WHERE Start_Date__c < :oneWeekAfterToday ';
        query += 'AND Status__c != \'Annulé\' ';
        query += 'AND Number_Participants__c != null ';
        query += 'AND Number_Participants__c < 10';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Trip__c> scope) {
        List<Trip__c> tripsToUpdate = new List<Trip__c>();

        for (Trip__c trip : scope) {
            trip.Status__c = 'Annulé';
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