public with sharing class TripTriggerHandler {
    public static void handleTrigger(Map<Id, Trip__c> oldMap, List<Trip__c> newTrips) {
        checkDate(newTrips);
    }

    public static void checkDate(List<Trip__c> newTrips) {
        for (Trip__c trip : newTrips) {
            if (trip.Start_Date__c != null && trip.End_Date__c != null && trip.Start_Date__c >= trip.End_Date__c) {
                trip.addError('The Start Date cannot be after the End Date. Please correct the dates.');
            }
        }
    }
}