@isTest
private class EV_PaymentBatchTest{
    static testMethod void createStaging() {

        EI_EEGA__c testeega = PM_EI_TestDataUtility.createEEGA('eega123');
        insert testeega;
        system.assertNotEquals(testeega.Id,null);
        
        EI_Portfolio__c testPortfolio = PM_EI_TestDataUtility.createPortfolio('Test Master Portfolio','Master Portfolio',null,'PG&E Sales');
        testPortfolio.EEGA_EI__c = testeega.id;
        insert testPortfolio;
        system.assertNotEquals(testPortfolio.Id,null); 
        
        system.debug ('@@@@record type of portfolio '+ testPortfolio.RecordType);
        system.debug ('@@@@record type of portfolio ID '+ testPortfolio.RecordTypeID);

        EI_Order_Number__c testOrder = PM_EI_TestDataUtility.createOrderNumber();
        testOrder.EEGA_EI__c = testeega.id;
        insert testOrder;
        system.assertNotEquals(testOrder.Id,null); 
        
        EI_Program__c programRec = PM_EI_TestDataUtility.createProgram(testPortfolio);
        programRec.Pgm_Code_EI__c = 'EVLCFS';
        programRec.Order_Number_EI__c = testOrder.id;
        insert programRec;
        system.assertNotEquals(testPortfolio.Id,null);

        // Creating Account
        Account partAcc = PM_EI_TestDataUtility.createAccount();
        insert partAcc;

        EI_Site__c testSite  =  PM_EI_TestDataUtility.createSiteRecord('TestSITE', partAcc.Id);
        testSite.Svc_Status_Code_EI__c = '20';
        testSite.Svc_Type_Code_EI__c = 'E';
        testSite.Cust_Type_EI__c = 'RES';
        testSite.Imported_Site_Name_EI__c = 'my test payable to name must be greater thanthirty five charcatrers 8888 ';
        testSite.Mailing_Street_Ln_1_EI__c = 'my address.aaaaaaaaaaaaaaaaaaa';
        testSite.Mailing_Street_Ln_2_EI__c = 'my address.aaaaaaaaaaaaaaaaaaaa';
        testSite.Mailing_City_EI__c = 'my city my addreaaaaaa';
        testSite.Mailing_State_EI__c = 'CA';
        testSite.Mailing_Zip_EI__c = '12345';
        insert testSite;

        User user = PM_EI_TestDataUtility.createUser();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' ];
        user.LAN_ID_EI__c = 'axnd';
        user.ProfileId = p.Id;
        insert user;

        EI_EV_Rebate__c rebateRec = new EI_EV_Rebate__c(Start_Date_EI__c=system.today()-10,End_Date_EI__c=system.today()+10,Rebate_Amount_EI__c=100);
        insert rebateRec;
        system.assertNotEquals(rebateRec.Id,null);

        //   EI_EV_Application__c application = new EI_EV_Application__c (Name='test',Applicant_Last_Name_EI__c='test', Email_Address_EI__c = 'abc@email.com', Approval_Status_EI__c = 'Approved', Payment_Approved_User_EI__c = user.Id, PG_E_Account_Site_EI__c = testSite.Id,  Application_Status_EI__c='New',Approved_for_Payment_EI__c=true,Date_Approved_for_Payment_EI__c=system.today(),Vehicle_Identification_Number_EI__c='12345678901234567',Registration_End_Date_EI__c=system.today()+370,Registration_Start_Date_EI__c=system.today()-370,Vehicle_Owner_First_Name_EI__c='test',Vehicle_Owner_Last_Name_EI__c='test',Program_EI__c=programRec.Id);
        EI_EV_Application__c application = new EI_EV_Application__c (Name='test',Applicant_Last_Name_EI__c='test', Rebate_Amount_EI__c= 100.00, Email_Address_EI__c = 'abc@email.com', Approval_Status_EI__c = 'New', Payment_Approved_User_EI__c = user.Id, PG_E_Account_Site_EI__c = testSite.Id,  Application_Status_EI__c='New',Approved_for_Payment_EI__c=false,Vehicle_Identification_Number_EI__c='12345678901234567',Registration_End_Date_EI__c=system.today()+370,Registration_Start_Date_EI__c=system.today()-370,Vehicle_Owner_First_Name_EI__c='test',Vehicle_Owner_Last_Name_EI__c='test',Program_EI__c=programRec.Id);

        //   EI_EV_Application__c application = new EI_EV_Application__c(Name='test',Applicant_Last_Name_EI__c='test',Application_Status_EI__c='New',Approved_for_Payment_EI__c=true,Date_Approved_for_Payment_EI__c=system.today(),Vehicle_Identification_Number_EI__c='12345678901234567',Registration_End_Date_EI__c=system.today()+370,Registration_Start_Date_EI__c=system.today()-370,Vehicle_Owner_First_Name_EI__c='test',Vehicle_Owner_Last_Name_EI__c='test');
        insert application;
        system.assertNotEquals(application.Id,null);
        application = [select id from EI_EV_Application__c where id = :application.id];
        application.Approval_Status_EI__c = 'Approved';
        application.Approved_for_Payment_EI__c=true;
        application.Date_Approved_for_Payment_EI__c=system.today();
        update application;

        // EI_Payment__c paymentRecord = new EI_Payment__c(EV_Application_EI__c=application.Id,Invoice_Date_EI__c=system.today(),Check_Address_1_EI__c='test',Check_City_EI__c='test',Check_State_EI__c='AL',Check_Zip_EI__c='123456',Check_Amount_EI__c=500,Check_Payable_To_EI__c='testwsefrsdfdgdfefewsfdddddddddddddferfwesfsdfsdfsfsfsfsdferfew', Check_Status_EI__c='Paid');
        //  insert paymentRecord;
        //  system.assertNotEquals(paymentRecord.Id,null);

        Test.startTest();
        EV_PaymentBatch testController = new EV_PaymentBatch();
        Database.executeBatch(testController);
        EV_PaymentSchedule paymentSchedule = new EV_PaymentSchedule();
        String sch = '0 0 23 * * ?';
        system.schedule('Payment Schedule', sch, paymentSchedule);
        EV_PaymentUtility paymentUtility = new EV_PaymentUtility();
        paymentUtility.sendEmail('abc@abc.com', 'tessubject', 'test');

        Test.StopTest();
    }
}