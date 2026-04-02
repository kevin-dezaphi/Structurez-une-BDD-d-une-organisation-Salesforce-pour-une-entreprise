trigger OpportunityTrigger on Opportunity (after insert, after update) {
    OpportunityTriggerHandler.handleTrigger(Trigger.oldMap, Trigger.newMap);
}