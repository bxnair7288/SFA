@RestResource(urlMapping='/EIPaymentService/postPayments/')
global class WS_TestRestA {  
    global class mainObj{
      
          global objL1 d;
      }
      
      global class objL1{      
          global string DocNumber;
          global string DocDate;
          global list<InvoiceItem> InvoiceToItems;
          global InvoiceVendor InvoiceToVendor;
      }
      
      global class InvoiceItem{      
          global string DocNumber;
          global string ItemNo;
      }  
      
      global class InvoiceVendor{      
          global string DocNumber;
          global string VendorNo;
      }
    
    
    @HttpPost
    global static void createTestIt(){
        String jsonStr = null;
        system.debug ('@@BXNE httppost');
        if (null != RestContext.request.requestBody) {
            jsonStr = RestContext.request.requestBody.toString();
            system.debug ('@@BXNE httppost: jsonStr - '+jsonStr);
        }
        JSONParser parser = JSON.createParser(jsonStr);
        
        mainObj inv = (mainObj)parser.readValueAs(mainObj.class);
        
        
    }
}