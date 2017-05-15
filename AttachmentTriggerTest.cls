@isTest
private class AttachmentTriggerTest{
    static testmethod void preventDeletion(){
        
       Account accountRecord = new Account(name='test');
      //  system.runas(userRecord){
            insert accountRecord;
            system.assertNotequals(accountRecord.Id,null);
       //}

        Contact contactRecord = PM_EI_TestDataUtility.createContact(accountRecord );
        contactRecord.LastName = 'Contact Last Name1';
        insert contactRecord;
        system.assertNotequals(contactRecord.Id,null);

        User user = PM_EI_TestDataUtility.createUser();
        user.ProfileID = [Select Id From Profile Where Name =: 'Trade Pro' ].id;
        user.Username = 'test@test9845876.com12';
        user.CommunityNickname = 'testUser1234';
        user.ContactId = contactRecord.Id;
        user.Approved_New_User_EI__c = true;
        insert user;
        system.assertNotequals(user.Id,null);
                        
        opportunity opp = new opportunity(name='test',closeDate=system.today(),stageName ='8D - Post-Install Review - D&C',accountId =accountRecord.Id);
        system.runas(user){
            insert opp;
            system.assertNotequals(opp.Id,null);
        }
        
        attachment att = new attachment(parentId=opp.Id,body=blob.valueOf('123'),name='test');
        system.runas(user){
            insert att;
            system.assertNotequals(att.Id,null);
        }
             
        Test.startTest();
            system.runas(user){
                try{
                    delete att;
                }
                catch(exception e){
                    string expectedExceptionThrown =  e.getMessage();
                    System.AssertNotEquals(expectedExceptionThrown, '');
                }
            }
        Test.stopTest();
    }
}