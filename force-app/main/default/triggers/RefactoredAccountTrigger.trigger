trigger RefactoredAccountTrigger on Account (before insert,before update,after insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            // Set default Type to 'Prospect' if not provided
            AccountHelper.setTypeProspect(Trigger.new);
        }
    }
    
          if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Update the Billing Address fields to match Shipping Address
            AccountHelper.addressCopy(Trigger.new);
        }
    }

    

    
     if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            // Set rating and create default contact
            AccountHelper.setRating(Trigger.new);
            
    }
     }
    if (Trigger.isAfter && Trigger.isInsert) {
        AccountHelper.defaultContact(Trigger.new);
    }
}