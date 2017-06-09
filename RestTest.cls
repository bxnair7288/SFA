@RestResource(urlMapping='/testAccount/*')
global with sharing class RestTest {
  
    @HttpGet
    global static string doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        string str='';
        list<Account>result = [SELECT Id, Name, Phone, Website FROM Account limit 1];
        str = '{ name:'+result[0].name+', Id:'+string.valueOf(result[0].Id)+'}';
        return str;
    }
  
}