trigger RefactoredOpportunityTrigger on Opportunity (before insert,before delete,after undelete,after insert,after update,before update) {
     if (Trigger.isBefore && Trigger.isInsert) {
        OpportunityHelper.setTypeOnInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isDelete) {
        OpportunityHelper.preventClosedOpportunityDeletion(Trigger.old);
        OpportunityHelper.preventDeletionOfClosedWonInBanking(Trigger.old);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityHelper.createTasks(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        OpportunityHelper.updateDescriptionOnStageChange(Trigger.new, Trigger.oldMap);
        OpportunityHelper.validateOpportunityAmount(Trigger.new);
        OpportunityHelper.setPrimaryContactToCEO(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isDelete) {
        OpportunityHelper.notifyOwnersOpportunityDeleted(Trigger.old);
    }
     if (Trigger.isAfter && Trigger.isUndelete) {
        OpportunityHelper.assignPrimaryContact(Trigger.newMap);
    }
     
}