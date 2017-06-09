/**************************************************************************************************   
Apex class Name      :  EIPaymentService
Version              :  1.0                                                                          
Created Date         :  5/10/2017                                                          
Function             :  REST web service to integrate with SAP
Story                :  STY-                                                                           
Work Task            :  TSK-                                                                          
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer            Date                   Description                                     
* -------------------------------------------------------------------------------------------------  
* Balaram            5/10/2017                  Created.
***************************************************************************************************/
@RestResource(urlMapping='/EIPaymentServiceTest/*')
global with sharing class EIPaymentService
{
    global String paymentQuery;
    global static final Set<String> paymentRecordTypeSet = new Set<String>{'EV_LCFS', 'EV_SITE', 'EI_CEER', 'EPO_ESA'};
    global Integer totalRecCount = 0, totalValidAppCnt=0, totalInvalidAppCnt=0;
    global Decimal totalAmount999 = 0.00;
    global final string headerForExcel = 'APPLICATION NUMBER\t PAYABLE TO\t AMOUNT\t APPROVER LANID\t ERROR \n';
    global String finalExcelStr = headerForExcel;
    global String recordString;
 
  //  global public static final String FAILED = System.Label.EI_File_Upload_Failed;
    
    global class PaymentController {
    
        date    runDate {get; set;}
        String  processType = 'Energy Insight';
        Integer rowCount=0;
        List<EI_Payment__c> lstEIPayments {get; set;}    
    }

  /**
    * @Description: This method will return the Payments records ready for check processing.
    * @Parameter: None
    * @Return: LIST<Payments>
    * @Usage: Return the Payment records to SAP for check processing
    **/
    @HttpGet
    global static PaymentController getEIPayments() {
             
        String paymentQuery;
        String errorVal = '';
        String INVALID_APPROVER = 'Invalid Payment Approver LAN ID - ';
        String INVALID_INVOICEDATE = 'Invalid Invoice Date';
        String INVALID_PAYABLETO = 'Invalid Payable To';
        String INVALID_ADDRESS = 'Invalid Address';
        String INVALID_CITY = 'Invalid City';
        String INVALID_STATE = 'Invalid State';
        String INVALID_ZIP = 'Invalid Zip code';
        String INVALID_AMOUNT = 'Invalid Amount';
        String INVALID_GLCODE = 'Invalid GL A/C';
        String INVALID_ORDERNUMBER = 'Invalid Order#';
        String recordString='';
        String headerForExcel = 'APPLICATION NUMBER\t PAYABLE TO\t AMOUNT\t APPROVER LANID\t ERROR \n';
        String finalExcelStr = headerForExcel;
        
        Integer totalValidAppCnt=0,  totalInValidAppCnt=0, totalRecCount = 0;
        List<EI_Payment__c> lstUpdatePayments;
            
        paymentQuery  = 'SELECT Id, name, Payee_Name_EI__c, Payee_Address_EI__c, Payee_Attention_To_EI__c,' +
                          'Payee_City_EI__c, Payee_State_EI__c, Payee_Zip_EI__c,' +                     
                          'Reference_Number__c, Total_Incentive_EI__c, Vendor_Number__c,' +
                          'Order_Number__c, GL_Account_Code__c, Check_Description__c, EI_To_SAP_Date__c' +
                          'FROM EI_Payment__c ' +
                          'WHERE (Check_Status__c  = \'Pending Payment\' OR Check_Status__c  = \'R - Reissue\')';
        
        PaymentController eiPayment = new PaymentController();
        eiPayment.runDate = date.today();

        try{
             lstUpdatePayments= DataBase.Query(paymentQuery);
             if (eiPayment.lstEIPayments.size() > 0) {
    
                for (EI_Payment__c payment : lstUpdatePayments) {
                   totalRecCount++;  
                   //Validate payee name, address, incentive amount etc
                   if (payment.Payee_Name_EI__c == null)
                        errorVal = (errorVal == '') ? INVALID_PAYABLETO : errorVal + ' / ' + INVALID_PAYABLETO;

                   if (payment.Payee_Address_EI__c == null)
                        errorVal = (errorVal == '') ? INVALID_ADDRESS : errorVal + ' / ' + INVALID_ADDRESS;

                   if (payment.Payee_City_EI__c == null)
                        errorVal = (errorVal == '') ? INVALID_CITY : errorVal + ' / ' + INVALID_CITY;

                   if (payment.Payee_State_EI__c == null)
                        errorVal = (errorVal == '') ? INVALID_STATE : errorVal + ' / ' + INVALID_STATE;

                   if (payment.Payee_Zip_EI__c == null)
                        errorVal = (errorVal == '') ? INVALID_ZIP : errorVal + ' / ' + INVALID_ZIP;

                   if (payment.Total_Incentive_EI__c == null || payment.Total_Incentive_EI__c == 0.00)
                        errorVal = (errorVal == '') ? INVALID_AMOUNT : errorVal + ' / ' + INVALID_AMOUNT;

                   if (payment.GL_Account_Code__c == null)
                        errorVal = (errorVal == '') ? INVALID_GLCODE : errorVal + ' / ' + INVALID_GLCODE;

                   if (payment.Order_Number__c == null)
                        errorVal = (errorVal == '') ? INVALID_ORDERNUMBER : errorVal + ' / ' + INVALID_ORDERNUMBER;

                   if (string.isBlank(errorVal)) {
                        system.debug('@@@ NO ERRORS! : ');
                        totalValidAppCnt++;                                    
            
                        recordString = payment.ID + '\t' + payment.Payee_Name_EI__c + '\t' + payment.Total_Incentive_EI__c + '\t' + payment.Approvers_Corp_ID__c + '\t' + errorVal + '\n';
                        finalExcelStr = finalExcelStr + recordString;
                        errorVal = '';             

                        //update List for SAP 
                        eiPayment.lstEIPayments.add(payment);
                        //set EI to SAP flag to today's date    
                        payment.EI_To_SAP_Date__c = eiPayment.runDate;
                        lstUpdatePayments.add(payment);
                                    
                   }else{
                        totalInValidAppCnt++;
                   }
                }
                update lstUpdatePayments;
                sendOutboundEmail(totalRecCount, finalExcelStr);
             }
           }
           catch (Exception exp) 
           {
             system.debug('HttpGet Error: '+exp.getMessage());     
             EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('EIPaymentService', new EI_BatchException(exp.getMessage())));  
           }
        return eiPayment;    
    }

  /**
    * @Description: This method will return the Payments records ready for check processing.
    * @Parameter: None
    * @Return: LIST<Payments>
    * @Usage: Return the Payment records to SAP for check processing
    **/
    @HttpPost
    global static void postEIOutboundPayments() {
    }
        
    public static void sendOutboundEmail(Integer totalRecCount, string finalExcelStr){
        string strEmailList = system.label.EIPaymentEITOSAPEmailList;
        string strEmailSubject = 'EI Payment Batch Upload Processed';
        string strEmailBody;
        string fileName = 'EI_EITOSAP_' + Datetime.now().format('MM-dd-YYYY') + '.xls';
        //filename = fileName + Datetime.now().format('MM-dd-YYYY') + '.csv';
        //'Run Date/Time: '+ string.valueof(Datetime.now().format('MM-dd-YYYY\' \'HH:mm:ss'))
        if (totalRecCount != 0) {
            strEmailBody = '';
//            strEmailBody = ('Attached file has the details of Applications processed in this batch on: ' + string.valueof(Datetime.now().format('MM-dd-YYYY\' \'HH:mm:ss')) + '<br/><br>' +
//                    'Total valid Application count:   ' + totalValidAppCnt + '<br/><br>' +
//                    'Total invalid Application count: ' + totalInValidAppCnt + '<br/><br>' +
//                    'Total record count in SAP file:  ' + totalRecCount + '<br/><br>' +
//                    'Total check amount in SAP file:  ' + totalAmount999 + '<br/><br><br>'
//            );
        } else {
            strEmailBody = ('There are no applications to process in this batch on: ' + string.valueof(Datetime.now().format('MM-dd-YYYY\' \'HH:mm:ss')) + '<br/><br>');
        }
        EV_PaymentUtility paymentUtility = new EV_PaymentUtility();
        paymentUtility.sendEmailWithAttachment(strEmailList, strEmailSubject, strEmailBody, finalExcelStr, fileName, true);
    }
    
}