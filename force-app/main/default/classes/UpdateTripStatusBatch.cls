public with sharing class UpdateTripStatusBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Start_Date__c, End_Date__c, Status__c ';
        query += 'FROM Trip__c ';
        query += 'WHERE Status__c != \'Annulé\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Trip__c> scope) {
        List<Trip__c> tripsToUpdate = new List<Trip__c>();

        for (Trip__c trip : scope) {
            if (trip.Start_Date__c != null && trip.Start_Date__c > Date.today()
            && trip.Status__c != 'A venir') {
                trip.Status__c = 'A venir';
            } else if (trip.End_Date__c != null && trip.End_Date__c < Date.today()
            && trip.Status__c != 'Terminé') {
                trip.Status__c = 'Terminé';
            } else if (trip.Start_Date__c != null && trip.Start_Date__c <= Date.today()
            && trip.End_Date__c >= Date.today() && trip.Status__c != 'En cours') {
                trip.Status__c = 'En cours';
            }
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