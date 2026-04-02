public with sharing class OpportunityTriggerHandler {
    public static void handleTrigger(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        createTrips(newMap.values(), oldMap);
    }

    public static void createTrips(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        List<Trip__c> tripsToInsert = new List<Trip__c>();

        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOpportunitiesMap != null ? oldOpportunitiesMap.get(opp.Id) : null;
            if ((oldOpp == null || oldOpp.StageName != 'Closed Won') && opp.StageName == 'Closed Won') {
                Trip__c newTrip = new Trip__c();
                newTrip.Destination__c = opp.Destination__c;
                newTrip.Start_Date__c = opp.Start_Date__c;
                newTrip.End_Date__c = opp.End_Date__c;
                newTrip.Number_Participants__c = opp.Number_Participants__c;
                newTrip.Account__c = opp.AccountId;
                newTrip.Opportunity__c = opp.Id;
                tripsToInsert.add(newTrip);
            }
        }

        if (!tripsToInsert.isEmpty()) {
            insert tripsToInsert;
        }
    }
}