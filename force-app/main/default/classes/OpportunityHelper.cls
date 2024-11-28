public class OpportunityHelper {
    public static void setTypeOnInsert(List<Opportunity> newOpps) {
        for (Opportunity opp : newOpps) {
            if (opp.Type == null) {
                opp.Type = 'New Customer';
            }
        }
    }
    public static void preventClosedOpportunityDeletion(List<Opportunity> opps) {
          for (Opportunity opp : opps) {
            if (opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost') {
                // Throw a regular exception to stop the delete operation
                throw new TriggerException('Cannot delete closed opportunity: ' + opp.Name);
            }
        }
    }

    // Custom exception class
    public class TriggerException extends Exception {}


    
        public static void createTasks(List<Opportunity> opportunities) {
        // List to hold the tasks to be created
        List<Task> tasksToInsert = new List<Task>();

        for (Opportunity opp : opportunities) {
            // Create a task for each opportunity
            Task task = new Task(
                Subject = 'Follow up on Opportunity',
                WhatId = opp.Id, // Link the task to the Opportunity
                Status = 'Not Started',
                Priority = 'Normal'
            );
            tasksToInsert.add(task);
        }

        // Bulk insert all tasks
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
    public static void updateDescriptionOnStageChange(List<Opportunity> newOpps1, Map<Id, Opportunity> oldOppsMap) {
        for (Opportunity newOpp : newOpps1) {
            Opportunity oldOpp = oldOppsMap.get(newOpp.Id);

            // Check if the StageName has changed
            if (oldOpp.StageName != newOpp.StageName) {
                // Append or set the Description with the stage change information
                String stageChangeMessage = 'Stage Change:' + newOpp.StageName;
                if (String.isNotBlank(newOpp.Description)) {
                    newOpp.Description += ' | ' + stageChangeMessage;
                } else {
                    newOpp.Description = stageChangeMessage;
                }
            }
        }
    }
    public static void notifyOwnersOpportunityDeleted(List<Opportunity> deletedOpportunities) {
        // Collect user Ids from deleted opportunities
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : deletedOpportunities) {
            ownerIds.add(opp.OwnerId);
        }

        // Fetch the user records
        List<User> users = [SELECT Id, Email FROM User WHERE Id IN :ownerIds];

        // Prepare and send notifications (e.g., email)
        for (User user : users) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {user.Email});
            email.setSubject('Opportunity Deleted');
            email.setPlainTextBody('An opportunity you own has been deleted.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }
     
    public static void assignPrimaryContact(Map<Id, Opportunity> oppNewMap) {
        // Step 1: Collect Account IDs from Opportunities without a primary contact
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : oppNewMap.values()) {
            if (opp.Primary_Contact__c == null && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        // Step 2: Query VP Sales Contacts for the collected Account IDs
        Map<Id, Contact> accountToVPContactMap = new Map<Id, Contact>();
        if (!accountIds.isEmpty()) {
            List<Contact> vpContacts = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Title = 'VP Sales' AND AccountId IN :accountIds
            ];
            for (Contact contact : vpContacts) {
                // Map AccountId to the contact with title 'VP Sales'
                if (!accountToVPContactMap.containsKey(contact.AccountId)) {
                    accountToVPContactMap.put(contact.AccountId, contact);
                }
            }
        }

        // Step 3: Prepare Opportunities to update
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Opportunity opp : oppNewMap.values()) {
            if (opp.Primary_Contact__c == null && accountToVPContactMap.containsKey(opp.AccountId)) {
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = accountToVPContactMap.get(opp.AccountId).Id;
                opportunitiesToUpdate.add(oppToUpdate);
            }
        }

        // Step 4: Update Opportunities with fallback primary contact
        if (!opportunitiesToUpdate.isEmpty()) {
            try {
                update opportunitiesToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating Opportunities: ' + e.getMessage());
            }
        }
    }

 public static void validateOpportunityAmount(List<Opportunity> opportunities1) {
        for (Opportunity opp : opportunities1) {
            if (opp.Amount < 5000) {
                // Throw an exception to prevent DML operation
                throw new TriggerException('Opportunity amount must be greater than 5000');
            }
        }
    }
    public static void preventDeletionOfClosedWonInBanking(List<Opportunity> opportunities2) {
        // Collect Account IDs from opportunities being deleted
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities2) {
            if (opp.StageName == 'Closed Won' && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        // Query for relevant accounts with the industry 'Banking'
        Map<Id, Account> bankingAccounts = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            List<Account> accounts = [
                SELECT Id, Industry
                FROM Account
                WHERE Id IN :accountIds AND Industry = 'Banking'
            ];
            for (Account account : accounts) {
                bankingAccounts.put(account.Id, account);
            }
        }

        // Validate opportunities and throw an exception if the conditions are met
        for (Opportunity opp : opportunities2) {
            if (opp.StageName == 'Closed Won' && bankingAccounts.containsKey(opp.AccountId)) {
                throw new TriggerException('Cannot delete closed opportunity related to a Banking account.');
            }
        }
    }
    public static void setPrimaryContactToCEO(List<Opportunity> opportunities3) {
        // Collect Account IDs from the Opportunities
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities3) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        // Query Contacts with the title 'CEO' for the related Accounts
        Map<Id, Contact> accountToCEOContactMap = new Map<Id, Contact>();
        if (!accountIds.isEmpty()) {
            List<Contact> ceoContacts = [
                SELECT Id, AccountId, FirstName, Title
                FROM Contact
                WHERE Title = 'CEO' AND AccountId IN :accountIds
            ];
            for (Contact contact : ceoContacts) {
                accountToCEOContactMap.put(contact.AccountId, contact);
            }
        }

        // Update the Primary_Contact__c field for each Opportunity
        for (Opportunity opp : opportunities3) {
            if (accountToCEOContactMap.containsKey(opp.AccountId)) {
                opp.Primary_Contact__c = accountToCEOContactMap.get(opp.AccountId).Id;
            }
        }
}



}