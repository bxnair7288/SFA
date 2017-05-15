global class EV_PaymentBatch implements Database.Batchable<sObject>, Database.Stateful{
    //------------------------------------------------------------------------------------
    // Author  - bxne 
    // Desc    - Class to read Payment records in Approved for Payment status
    //           and create staging object in the format of SAP input text file.
    // 7/11/16 - Initial version.
    // 1/13/17 - Header & Trailer control record change to handle multiple batches
    // 2/21/17 - Case 15773 Append Address line 2 to Checks Address line 1 when available
    //------------------------------------------------------------------------------------

    global Integer totalRecCount = 0, totalRec002Count = 0, totalValidAppCnt=0, totalInvalidAppCnt=0;
    global decimal totalAmount999 = 0.00;
    global final string headerForExcel = 'APPLICATION NUMBER\t PAYABLE TO\t AMOUNT\t APPROVER LANID\t ERROR \n';
    global string finalExcelStr = headerForExcel;
    global string recordString;
    global boolean insertFirstRecord = false;
    global string headerValue999 = '999';

    //Start Method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT EV_Application_EI__c,Invoice_Date_EI__c,Check_Address_1_EI__c,Check_Address_2_EI__c,Check_City_EI__c, Check_State_EI__c,Check_Zip_EI__c,EV_Application_EI__r.Application_Number_EI__c,Check_Amount_EI__c,Check_Payable_To_EI__c, Check_Status_EI__c,EV_Application_EI__r.Payment_Approved_User_EI__r.LAN_ID_EI__c, EV_Application_EI__r.Vehicle_Identification_Number_EI__c, EV_Application_EI__r.Program_EI__r.Pgm_Code_EI__c, F_GL_Account_Code_EI__c FROM EI_EV_Payment__c WHERE EI_To_SAP_Date_EI__c = null AND Check_Status_EI__c = null ORDER BY Name';
        return Database.getQueryLocator(query);
    }

    //Execute logic to read Payment records and create data in text file format and insert into
    //Payment staging object.
    global void execute(Database.BatchableContext BC, List<EI_EV_Payment__c>lstPayment) {

        string errorVal ='';
        string INVALID_APPROVER    = 'Invalid Payment Approver LAN ID - ';
        string INVALID_INVOICEDATE = 'Invalid Invoice Date';
        string INVALID_PAYABLETO   = 'Invalid Payable To';

        if (!lstPayment.isEmpty()) {
            //declare local variables
            system.debug('Record here 1');
            list<EI_EV_Payment_Staging__c>lstStaging = new list<EI_EV_Payment_Staging__c>();
            string dateValue = system.now().format('MMddyyyyHHmmss');
            string headerValue001 = '001INVOICE   ELECTRIC.VEHICLES.INVOICES                  EV LCFS '+ dateValue;
            //string headerValue999 = '999ZZZZZZZZ9ZZZZZZZZZZZZ9.99               0ZZZZZZZZ9';
            //string headerValue004 = '0044028605                   ';
            string lanIdVal = '', amountVal, payableVal, payableVal1, addressVal, cityVal, zipVal;
            integer lanIdlengthVal, lengthVal, lengthPayableVal, lengthPayableVal1;

            //-------------------------------
            //create Header record type = 001
            //-------------------------------
            //Do this only once - to address multiple batches
            if (!insertFirstRecord) {
               EI_EV_Payment_Staging__c paymentStaging001 = new EI_EV_Payment_Staging__c(Record_Detail_EI__c = headerValue001);
               lstStaging.add(paymentStaging001);
               system.debug('@@___'+dateValue);
               system.debug('Record type 001 length : '+headerValue001.length());
               insertFirstRecord = true;
               totalRecCount++;
            }
            
            //Prepare for loop to create 002, 003 and 004 record types
            for (EI_EV_Payment__c payment : lstpayment) {

                string headerValue002 = '002';
                string headerValue003 = '00331ZCEER     ';
                string headerValue004 = '00440';

                //------------------------------------
                // Process and Create Record Type 002
                // -----------------------------------

                //Validate Required fields
                if(payment.Invoice_Date_EI__c == null)
                    errorVal = INVALID_INVOICEDATE ;

                If (payment.EV_Application_EI__r.Payment_Approved_User_EI__r.LAN_ID_EI__c == null)
                    errorVal = (errorVal == '') ? INVALID_APPROVER : errorVal + ' / ' + INVALID_APPROVER;

                if(payment.Check_Payable_To_EI__c == null)
                    errorVal = (errorVal == '') ? INVALID_PAYABLETO : errorVal + ' / ' + INVALID_PAYABLETO;


                if (errorVal == '') {

                    totalValidAppCnt++;

                    //Append Invoice date to record type 002
                    if (payment.Invoice_Date_EI__c != null)
                        headerValue002 = headerValue002 + string.valueof(padZero(payment.Invoice_Date_EI__c.month()))+ string.valueof(padZero(payment.Invoice_Date_EI__c.day()))+ string.valueof(payment.Invoice_Date_EI__c.year());
                    else
                            headerValue002 = padSpaces(headerValue002, 8, 0);

                    //Append columns 12 to 36
                    headerValue002 = headerValue002 + 'LVPGE1'+payment.EV_Application_EI__r.Application_Number_EI__c+payment.EV_Application_EI__r.Program_EI__r.Pgm_Code_EI__c+'USD';

                    //Append LAN ID - Approver's corporate ID
                    if(payment.EV_Application_EI__r.Payment_Approved_User_EI__r.LAN_ID_EI__c != null){
                        lanIdVal = string.valueof(payment.EV_Application_EI__r.Payment_Approved_User_EI__r.LAN_ID_EI__c);
                        //lanIdlengthVal = 25 - lanIdVal.length();
                        headerValue002 = headerValue002 + lanIdVal;
                        headerValue002  = padSpaces(headerValue002, 25, lanIdVal.length());
                    }
                    else
                            headerValue002 = padSpaces(headerValue002, 25, 0);
                    //headerValue002  =headerValue002 + '                         ';

                    //Append blanks from 62 to 119. Maybe not be needed, just in case!
                    //headerValue002 = headerValue002 + '                                                          ';
                    headerValue002 = padSpaces(headerValue002, 58, 0);

                    //Add 002 record type to collection.
                    EI_EV_Payment_Staging__c paymentStaging002 = new EI_EV_Payment_Staging__c(Record_Detail_EI__c=headerValue002);
                    lstStaging.add(paymentStaging002);
                    totalRecCount++;
                    totalRec002Count++;

                    system.debug('Record type 002 length : '+headerValue002.length());

                    //------------------------------------
                    // Process and Create Record Type 003
                    // -----------------------------------
                    // Append Check Amount
                    if(payment.Check_Amount_EI__c != null){
                        totalAmount999 += payment.Check_Amount_EI__c;
                        amountVal = string.valueof(payment.Check_Amount_EI__c);
                        //lengthVal = 14 - amountVal.length();
                        headerValue003 = padSpaces(headerValue003, 14, amountVal.length());
                        headerValue003 = headerValue003 + amountVal;
                    }
                    else
                            headerValue003 = padSpaces(headerValue003, 14, 0);        //headerValue003 + '              ';

                    system.debug('Record type 002 chk amt  : '+headerValue003.length());

                    // Append columns 30 to 118
                    //headerValue003 = headerValue003+'                  PT10I82                          *Clean Fuel Rebate for VIN ';
                    headerValue003 = padSpaces(headerValue003, 28, 0) + 'PT10I82';
                    headerValue003 = padSpaces(headerValue003, 27, 0) + '*Clean Fuel Rebate for VIN ';
                    // Append VIN number to print on checks.
                    headerValue003 = headerValue003 + payment.EV_Application_EI__r.Vehicle_Identification_Number_EI__c;
                    headerValue003 = padSpaces(headerValue003, 6, 0);

                    system.debug('Record type 002 before payable : '+headerValue003.length());
                    system.debug('app# : '+payment.EV_Application_EI__r.Application_Number_EI__c);

                    // Append Payable to Name. If Payable to is greater than 35 characters then first 35 characters
                    // will be go into Name 1, remaining 35 to Name 2 and rest to Name 3. In EI max Name length = 80 characters.
                    if(payment.Check_Payable_To_EI__c != null){
                        payableVal = string.valueof(payment.Check_Payable_To_EI__c);
                        lengthVal  = payableVal.length();

                        system.debug('PayableVal to & length : '+payableVal+' / '+payableVal.length());
                        system.debug('Payable to 1st 35 characters : '+payableVal.substring(0,lengthVal  )+' / '+payableVal.substring(0,lengthVal).length());

                        if(payableVal.length() > 35) {

                            headerValue003 = headerValue003 + payableVal.substring(0,35);

                            if (payableVal.length() > 70) {
                                headerValue003 = headerValue003 + payableVal.substring(35,70);
                                //This is the 3rd bucket!
                                system.debug('This is the 3rd bucket!');
                                system.debug('Payable to 3rd 35 characters : '+payableVal.substring(35,70)+' / '+payableVal.substring(35,70).length());

                                headerValue003 = headerValue003 + payableVal.substring(70,lengthVal);
                                lengthPayableVal = payableVal.substring(70,lengthVal).length();
                                headerValue003 = padSpaces(headerValue003, 35, lengthPayableVal);
                                headerValue003 = padSpaces(headerValue003, 35, 0);
                            } else {
                                //This is the 2nd bucket
                                system.debug('This is the 2nd bucket!');
                                headerValue003 = headerValue003 + payableVal.substring(35,lengthVal);
                                lengthPayableVal = payableVal.substring(35,lengthVal).length();
                                headerValue003 = padSpaces(headerValue003, 35, lengthPayableVal);
                                headerValue003 = padSpaces(headerValue003, 70, 0);
                            }

                        } else {
                            //This is the 1st bucket!
                            system.debug('This is the 1st bucket!');
                            headerValue003 = headerValue003 + payableVal;
                            headerValue003 = padSpaces(headerValue003, 35, payableVal.length());
                            headerValue003 = padSpaces(headerValue003, 105, 0);
                        }
                    }
                    else
                            headerValue003 = padSpaces(headerValue003, 140, 0);

                    // Append Check Address1
                    if(string.isNotblank(payment.Check_Address_1_EI__c)){
                        addressVal = string.valueof(payment.Check_Address_1_EI__c).trim();
                        if(addressVal.length() > 35)
                            addressVal = addressVal.substring(0,35);
                        //---------------------------------------------------------------------------------
                        //02-21-2017: When address line 2 is not empty and it is not NA or N/A then append
                        //the Unit number of address to check address 1 column.
                        //---------------------------------------------------------------------------------
                        if (string.isNotblank(payment.Check_Address_2_EI__c) && payment.Check_Address_2_EI__c <> 'NA' && payment.Check_Address_2_EI__c <> 'N/A'){
                            addressVal = addressVal + ' ' + payment.Check_Address_2_EI__c.trim();
                            if(addressVal.length() > 35)
                               addressVal = addressVal.substring(0,35);
                        }
                        headerValue003 = headerValue003 + addressVal;
                        headerValue003 = padSpaces(headerValue003, 35, addressVal.length());
                    }
                    else
                            headerValue003 = padSpaces(headerValue003, 35, 0);
                    //headerValue003 = headerValue003+'                                                                      ';

                    // Append Check City
                    if(string.isNotblank(payment.Check_City_EI__c)){
                        cityVal = string.valueof(payment.Check_City_EI__c);
                        if(cityVal.length() > 35)
                            cityVal = cityVal.substring(0,35);
                        //lengthVal = 35 - cityVal.length();
                        headerValue003 = headerValue003 + cityVal;
                        headerValue003 = padSpaces(headerValue003, 35, cityVal.length());
                    }
                    else
                            headerValue003 = padSpaces(headerValue003, 35, 0);
                    //headerValue003 = headerValue003+'                                                                      ';

                    // Append Check State
                    if(string.isNotblank(payment.Check_State_EI__c)){
                        headerValue003 = headerValue003 + payment.Check_State_EI__c + ' ';
                    }
                    else
                            headerValue003 = headerValue003 + '   ';

                    // Append Check Zip
                    if(string.isNotblank(payment.Check_Zip_EI__c)){
                        zipVal = string.valueof(payment.Check_Zip_EI__c);
                        //lengthVal = 10 - zipVal.length();
                        headerValue003 = headerValue003 + zipVal.substring(0,5);
                        headerValue003 = padSpaces(headerValue003, 10, 5);
                    }
                    else
                            headerValue003 = padSpaces(headerValue003, 10, 0);
                    //headerValue003 = headerValue003+'          ';

                    // Append columns 365 to 407
                    //headerValue003 = headerValue003+'US                                         ';
                    headerValue003 = headerValue003 + 'US ';
                    headerValue003 = padSpaces(headerValue003, 40, 0);

                    // Create and add record type 003 record to collection
                    EI_EV_Payment_Staging__c paymentStaging003 = new EI_EV_Payment_Staging__c(Record_Detail_EI__c=headerValue003);
                    lstStaging.add(paymentStaging003);
                    totalRecCount++;
                    system.debug('Record type 003 length : '+headerValue003.length());

                    //------------------------------------
                    // Process and Create Record Type 004
                    // -----------------------------------
                    //headerValue004 = headerValue004 + payment.F_GL_Account_Code_EI__c + '                   ';
                    headerValue004 = headerValue004 + payment.F_GL_Account_Code_EI__c;
                    system.debug('Record type 004 length AFTER GL: '+headerValue004.length());
                    headerValue004 = padSpaces(headerValue004, 17, 0);

                    if(payment.Check_Amount_EI__c != null){

                        string amountVal1 = string.valueof(payment.Check_Amount_EI__c);
                        integer lengthAmountVal = 14 - amountVal1.length();
                        headerValue004 = padSpaces(headerValue004 , 14, amountVal1.length());
                        headerValue004 = headerValue004 + amountVal1;
                    }
                    else
                            headerValue004 = padSpaces(headerValue004, 14, 0);

                    headerValue004 = padSpaces(headerValue004, 109, 0);

                    EI_EV_Payment_Staging__c paymentStaging004 = new EI_EV_Payment_Staging__c(Record_Detail_EI__c=headerValue004);
                    lstStaging.add(paymentStaging004);
                    totalRecCount++;
                    system.debug('Record type 004 length : '+headerValue004.length());
                } else { //end of errorVal == ''

                    totalInValidAppCnt++;
                }
                //form string to print in CSV file
                recordString = payment.EV_Application_EI__r.Application_Number_EI__c+'\t'+payment.Check_Payable_To_EI__c+'\t'+payment.Check_Amount_EI__c +'\t'+payment.EV_Application_EI__r.Payment_Approved_User_EI__r.LAN_ID_EI__c+'\t'+errorVal+'\n';
                finalExcelStr = finalExcelStr + recordString;
                errorVal = '';

            } //End of For Loop
            if(!lstStaging.isEmpty()){
                insert lstStaging;
            }
        /*
            //---------------------------------------------------------
            // Process and Create Record Type 999 - File trailer record
            // --------------------------------------------------------
            totalRecCount++;
            //Append total record count
            amountVal = string.valueof(totalRecCount);
            headerValue999 = padSpaces(headerValue999, 9, amountVal.length());
            headerValue999 = headerValue999 + amountVal;

            //Append total amount
            amountVal = string.valueof(totalAmount999);
            headerValue999 = padSpaces(headerValue999, 16, amountVal.length());
            headerValue999 = headerValue999 + amountVal;
            system.debug('Record type 999 length 1 : '+headerValue999.length());

            //Append qty = 0
            //headerValue999 = amountVal.rightPad(15) + '0';
            headerValue999 = padSpaces(headerValue999, 15, 0) + '0';
            system.debug('Record type 999 length 2 : '+headerValue999.length());

            headerValue999 = padSpaces(headerValue999, 9, string.valueof(totalRec002Count).length()) + totalRec002Count;
            //headerValue999 = amountVal.rightPad(9 - string.valueof(totalRec002Count).length()) + totalRec002Count;
            system.debug('Record type 999 length 4 : '+headerValue999.length());

            EI_EV_Payment_Staging__c paymentStaging999 = new EI_EV_Payment_Staging__c(Record_Detail_EI__c=headerValue999);
            lstStaging.add(paymentStaging999);
            if(!lstStaging.isEmpty()){
                insert lstStaging;
            }
            system.debug('Record type 999 length : '+headerValue999.length());
        */
        }
        //Send email to email distribution list of Job status!
      /*
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      list<string>lstStr = new list<string>();
      string strEmail = system.label.EV_PaymentOutboundEmailList;

      if(string.isNotblank(strEmail)){
         for(string str : strEmail.split(';')){
             lstStr.add(str);
         }
      }

      string [] toaddress=lstStr;
      email.setSubject('Payment Batch Loaded - Successfully');
      email.setHtmlBody(' Total record count : '+ totalRecCount + ' <br/><br/>Total check amount : '+ totalAmount999 + '<br/><br>' + string.valueof(system.today()));
      email.setToAddresses(toaddress);
      Messaging.sendEmail(New Messaging.SingleEmailMessage[]{email});
      */

 /*     EV_PaymentUtility paymentUtility = new EV_PaymentUtility();
      string strEmailList = system.label.EV_PaymentOutboundEmailList;
      string strEmailSubject = 'EV Payment Batch Upload Processed';
      string strEmailBody;
      string fileName = 'EV_EITOSAP_' + Datetime.now().format('MM-dd-YYYY') + '.xls';
      //filename = fileName + Datetime.now().format('MM-dd-YYYY') + '.csv';
      //'Run Date/Time: '+ string.valueof(Datetime.now().format('MM-dd-YYYY\' \'HH:mm:ss'))
      strEmailBody = ('Attached file has the details of Applications processed in this batch on: '+ string.valueof(Datetime.now().format('MM-dd-YYYY\' \'HH:mm:ss'))+'<br/><br>'+
                      'Total valid Application count:   '+ totalValidAppCnt + '<br/><br>' +
                      'Total invalid Application count: '+ totalInValidAppCnt + '<br/><br>' +
                      'Total record count in SAP file:  '+ totalRecCount + '<br/><br>' +
                      'Total check amount in SAP file:  '+ totalAmount999 + '<br/><br><br>' +
                      'Please forward any questions to the Energy Insight Support team' + '<br/><br>' +
                      'or email EnergyInsightSupport@pge.com Thanks!' + '<br/><br>' +
                      '<Please do not reply to the sender address of this email.>'
                      );
      paymentUtility.sendEmailWithAttachment(strEmailList, strEmailSubject, strEmailBody, finalExcelStr, fileName );

                      'Please forward any questions to the Energy Insight Support team' + '<br/><br>' +
                      'or email EnergyInsightSupport@pge.com Thanks!' + '<br/><br>' +
                      '<Please do not reply to the sender address of this email.>'

      */

    }

    //pad single digit month, day etc with zeros
    private string padZero(Integer val) {
        if (val < 10) {
            return '0' + val;
        }
        return '' + val;
    }

    //pad with spaces using Max & Original Length
    private string padSpaces(String sValue, Integer maxLength, Integer originalLength) {
        maxLength = maxLength - originalLength;
        for(integer i = 1; i <= maxLength; i++){
            sValue = sValue + ' ';
        }
        return sValue;
    }

    //finish logic
    global void finish(Database.BatchableContext BC) {

       if (totalRecCount > 0) {
            //---------------------------------------------------------
            // Process and Create Record Type 999 - File trailer record
            // --------------------------------------------------------
            list<EI_EV_Payment_Staging__c >lstStaging = new list<EI_EV_Payment_Staging__c >();
            totalRecCount++;
            //Append total record count
            string amountVal = string.valueof(totalRecCount);
            headerValue999 = padSpaces(headerValue999, 9, amountVal.length());
            headerValue999 = headerValue999 + amountVal;

            //Append total amount
            amountVal = string.valueof(totalAmount999);
            headerValue999 = padSpaces(headerValue999, 16, amountVal.length());
            headerValue999 = headerValue999 + amountVal;
            system.debug('Record type 999 length 1 : '+headerValue999.length());

            //Append qty = 0
            //headerValue999 = amountVal.rightPad(15) + '0';
            headerValue999 = padSpaces(headerValue999, 15, 0) + '0';
            system.debug('Record type 999 length 2 : '+headerValue999.length());

            headerValue999 = padSpaces(headerValue999, 9, string.valueof(totalRec002Count).length()) + totalRec002Count;
            //headerValue999 = amountVal.rightPad(9 - string.valueof(totalRec002Count).length()) + totalRec002Count;
            system.debug('Record type 999 length 4 : '+headerValue999.length());

            EI_EV_Payment_Staging__c paymentStaging999 = new EI_EV_Payment_Staging__c(Record_Detail_EI__c=headerValue999);
            lstStaging.add(paymentStaging999);
            if(!lstStaging.isEmpty()){
              try {
                insert lstStaging;
              }catch (exception e) {
                system.debug('exception________' + e.getMessage() + '___' + e.getLineNumber());
              }  
            }
            system.debug('Record type 999 length : '+headerValue999.length());
        }

        EV_PaymentUtility paymentUtility = new EV_PaymentUtility();

        string strEmailList = system.label.EV_PaymentOutboundEmailList;
        string strEmailSubject = 'EV Payment Batch Upload Processed';
        string strEmailBody;
        string fileName = 'EV_EITOSAP_' + Datetime.now().format('MM-dd-YYYY') + '.xls';
        //filename = fileName + Datetime.now().format('MM-dd-YYYY') + '.csv';
        //'Run Date/Time: '+ string.valueof(Datetime.now().format('MM-dd-YYYY\' \'HH:mm:ss'))
        if (totalRecCount != 0) {
            strEmailBody = ('Attached file has the details of Applications processed in this batch on: '+ string.valueof(Datetime.now().format('MM-dd-YYYY\' \'HH:mm:ss'))+'<br/><br>'+
                    'Total valid Application count:   '+ totalValidAppCnt + '<br/><br>' +
                    'Total invalid Application count: '+ totalInValidAppCnt + '<br/><br>' +
                    'Total record count in SAP file:  '+ totalRecCount + '<br/><br>' +
                    'Total check amount in SAP file:  '+ totalAmount999 + '<br/><br><br>'
            );
        } else {
            strEmailBody = ('There are no applications to process in this batch on: ' + string.valueof(Datetime.now().format('MM-dd-YYYY\' \'HH:mm:ss'))+'<br/><br>');
        }

        paymentUtility.sendEmailWithAttachment(strEmailList, strEmailSubject, strEmailBody, finalExcelStr, fileName, true );

    }
}