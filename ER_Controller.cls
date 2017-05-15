/**************************************************************************************************   
Apex Controller Name :  ER_Controller
Version              :  1.0                                                                          
Created Date         :  Oct 28, 2016                                                               
Function             :  Controller class for E-Rebates
Description          :  This is the controller class for E-Rebates wizard
Story                :                                                                               
Work Task            :                                                                               
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  
* Nikhil Kapoor               10/28/2016             First Iteration            
***************************************************************************************************/
 

public without sharing class ER_Controller {

    // Visualforce variables
    public String ServiceAgreementID {get;set;}
    public String manu {get;set;}
    public String model {get;set;}
    public String Quantity {get;set;}
    public String purchaseprice {get;set;}
    public String purchaseDate {get;set;}
    public String instaldate {get;set;}
    public String retailer {get;set;}
    public String unitmeasure {get;set;}
    public String comment {get;set;}
    public String contmake {get;set;}
    public String contmodel {get;set;}
    public String serinumber {get;set;}
    public String projectType {get;set;}
    
    //Customer variables
    public String sitestreetaddress {get;set;}
    public String siteinstalladdress {get;set;}
    public String sitecity {get;set;}
    public String sitestate {get;set;}
    public String sitezip {get;set;}
    public string payeename {get;set;}
    public String sitemailaddress {get;set;}
    public String sitemailaddress2 {get;set;}
    public String sitemailcity {get;set;}
    public String sitemailstate {get;set;}
    public String sitemailzip {get;set;}
    public string contactname {get;set;}
    public string contactLname {get;set;}
    public string email {get;set;}
    public string phone {get;set;}
    public String mailingRadio {get;set;}
    public string extension {get;set;}
    public string propertyoccpi {get;set;}
    public string Estimateyear {get;set;}
    public string Properttype {get;set;}
    public string taxstatus {get;set;}
    public string taxid {get;set;}
    public string specialflag {get;set;}
    public string permitnumber {get;set;}
    public string agency {get;set;}
    public String appSigned {get;set;}
    public List<EI_Site__c> SiteList {get;set;}
    public String editToken {get;set;}
    public Boolean showThankUPopup {get;set;}
    
    // Common Variables
    public string id{get;set;}
    public List<OpportunityLineItem> projectMeasureList {get;set;}
    public List<PM_MeasureListWrapper> measureWrapperList{get;set;}
    public Map<Id, Product2> measureMap {get;set;}
    public List<Product2> RemoveselectedMeasure{get;set;}
    public List<ER_Program_Control_Logic__c> projCreatePrograms {get;set;}
    public String resOrNonRes {get;set;}
    public Product2 latestMeasureSelected {get;set;}
    public static EI_Site__c validSite {get;set;}
    public OpportunityLineItem projectMeasure {get;set;}
    public Set<Id> measIdSet {get;set;}
    public Map<Id, OpportunityLineItem> measurePMMap {get;set;}
    public Map<Id, String> measurePMMakeMap {get;set;}
    public Map<Id, String> measurePMModelMap {get;set;}
    public Map<Id, Integer> measurePMQuantMap {get;set;}
    public Map<Id, Integer> measurePMUnitMeasMap {get;set;}
    public String projectId {get;set;}
    Public Opportunity projectAppnum {get;set;}
    public string ApplicationId {get;set;}
    public List<Attachment> newAttachments {get;set;}
    
    // Local Variables
    private Id selectedProgId, selectedProgMeasureId;
    private String delMeasId, selectMeasId, SearchText, siteNo, resProgramCode;
    private transient String attachName, attachType, attachBodyStr;
    private Set<Id> programIdSet;
    private Set<Id> measureIdSet;
    private Map<Id, Id> measureProgMeasureMap;
    private Map<String, Id> programMap;
    private Map<String, String> nonResProgtypeMap;
    private List<EI_Program__c> resProg;
    private List<Product2> measureList;
    private Map<String, Id> measureCodeMap;
    public Map<Id, PriceBookEntry> pbeMeasureMap;
    private List<PriceBook2> priceBookList;
    private List<Integer> captureIndexList;
    private List<Integer> captureIndexDescList;
    private boolean comingfromRebateReview;
    private RecordType deemedRT;
    private Id selProgramId;
    private String delAttachIndex;
    private Map<String, String> projBuildingTypeDependencyMap;
    private List<ER_Measures_Excl_On_CFSite__c> measuresExcludedOnSite;
    private Set<string> measuresExcludedSet;
    
    // Constants
    private static final String SITE_RT_RESIDENTIAL = 'Residential';
    private static final String SITE_RT_NON_RESIDENTIAL = 'Non_Residential'; 
    private static final String SITE_STATUS_ACTIVE = 'Active';
    private static final String SITE_STATUS_PS = 'Pending Start';
    private static final String PROJECT_APP_SOURCE = 'ERebate';
    private static final String PROJECT_STAGE = '8D - Post-Install Review - D&C';
    private static final Integer MAX_ATTACHMENTS = 4;
    private static final String PROJECT_API_NAME = 'Opportunity';
    private static final String DEEMED_RT = 'EI_Deemed_Application_Processing_Opportunity';
    private static final String PAYEE_RECEP_TYPE = 'Transaction';
    private static final Integer mailAddrLen = 40; //PS: Added due to pForce defect# 1441
    private static final Integer mailCityLen = 20; //PS: Added due to pForce defect# 1441
    
    
    /**
    * @Description: StandardSetController variable
    * @Parameter:
    * @Return: None
    * @USage:
    **/                         
    public ApexPages.StandardSetController ProjectMeasures {
        get {    
            if(ProjectMeasures == null) {
                ProjectMeasures = new ApexPages.StandardSetController(measureList);             
                ProjectMeasures.setPageSize(10);                
             }
            return ProjectMeasures;           
        }
        set;
    }  
    
    
    /**
    * @Description: Project variable
    * @Parameter:
    * @Return: None
    * @USage: Represents the single Rebate Application record
    **/ 
    public Opportunity project {
        get {
            if(project == Null) {
                project = new Opportunity();
            }
            return project;
        }
        set;
    }
    
    
    /**
    * @Description: Constructor method
    * @Parameter:
    * @Return: None
    * @USage:
    **/
    public ER_Controller() {}
    
    
    /**
    * @Description: Initialize Custom Setting method
    * @Parameter:
    * @Return: None
    * @Usage: 
    **/
    public void initCustomSetting() {
        
        try {
            // Variable initialization
            nonResProgtypeMap = new Map<String, String>();
            projCreatePrograms = new List<ER_Program_Control_Logic__c>();
            programMap = new Map<String, Id>();
            programIdSet = new Set<Id>();
            measuresExcludedOnSite  = new List<ER_Measures_Excl_On_CFSite__c>();
            measuresExcludedSet = new Set<String>();
        
        
            if(measurePMMap == Null) {
                measurePMMap = new Map<Id, OpportunityLineItem>();
            }
            
            // Fetching Programs from Custom Setting
            projCreatePrograms = ER_Program_Control_Logic__c.getall().values();
            for(ER_Program_Control_Logic__c projCreateProg : projCreatePrograms) {
                if(!projCreateProg.IsResidential__c) {
                    nonResProgtypeMap.put(projCreateProg.Program_Type__c, projCreateProg.Name);
                }
                else {
                    resProgramCode = projCreateProg.Name;
                }
            } 
            
            for(EI_Program__c prog : [select id, Pgm_Code_EI__c from EI_Program__c where Pgm_Code_EI__c IN: nonResProgtypeMap.Values()]) {
                programMap.put(prog.Pgm_Code_EI__c, prog.id);
                programIdSet.add(prog.id);
            }
            
            //S5SJ - Case 14654 - Exclude Measures on the Customer Facing SITE using the custom setting below
             measuresExcludedOnSite  = ER_Measures_Excl_On_CFSite__c.getall().values();
             for(ER_Measures_Excl_On_CFSite__c  exclMeasures: measuresExcludedOnSite ){
                //Grab all the measures to be excluded from the custom setting
                measuresExcludedSet.add(exclMeasures.Measure_Code__c);
                system.debug('IN Custom setting:'+exclMeasures.Measure_Code__c);
             }   
        }
        catch(Exception e) {
             EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
    }
    
    
    /***********************************************************************************************
    * @Description: Remote Action Method, designed to query the Site object for value SAIDs
    * @Parameter:
    * @Return: None
    * @USage:
    ***************************************************************************************************/
    @RemoteAction
    public static EI_Site__c getValidateSAID(String said) {
        validSite = [SELECT id FROM EI_Site__c WHERE SAID_EI__c =: said AND (F_Svc_Status_EI__c =: SITE_STATUS_ACTIVE OR F_Svc_Status_EI__c =: SITE_STATUS_PS) AND (Recordtype.DeveloperName =: SITE_RT_RESIDENTIAL OR Recordtype.DeveloperName =: SITE_RT_NON_RESIDENTIAL) LIMIT 1 ];
        return validSite;       
    }
    
    
    /******************************************************************************************************
    * @Description: Reset or Initialize method
    * @Parameter:
    * @Return: None
    * @Usage: 
    *******************************************************************************************************/
    public void fetchMeasureList() {
   // resOrNonRes 
    system.debug('resOrNonRes ???'+resOrNonRes);
        
        try {
            // Call Program Control Logic Custom Setting of ERebates
            initCustomSetting();
            
            // Variable initialization
            measureList = new List<Product2>();
            measureCodeMap = new Map<String, Id>();
            measureMap = new Map<Id, Product2>();
            priceBookList = new List<PriceBook2>();
            captureIndexList = new List<Integer>();
            captureIndexDescList = new List<Integer>();
            measureIdSet = new Set<Id>();
            measureProgMeasureMap = new Map<Id, Id>();
            resProg = new List<EI_Program__c>();
            pbeMeasureMap = new Map<Id, PriceBookEntry>();
            priceBookList = PM_EI_MeasureTriggerHelper.getPriceBook(new Set<String>{'Energy Efficiency'});
            
            system.debug('Measure Excluded set:'+measuresExcludedSet);
            for(string measure: measuresExcludedSet ){
                system.debug('EXCL Measures:'+measure);
            }
            
            // Fetching mreasures list based on whether Site is Residential or Non-Residential
            if(resOrNonRes == 'NR') {
                // Fetching Program details
                if(projectType != Null && nonResProgtypeMap.containsKey(projectType)) {
                    if(programMap.containsKey(nonResProgtypeMap.get(projectType))) {
                        selectedProgId = programMap.get(nonResProgtypeMap.get(projectType));
                        selProgramId = selectedProgId;
                    }
                    if(selectedProgId != Null) {
                        for(EI_Program_Measure__c progM : [select id, Component_EI__c from EI_Program_Measure__c where Pgm_EI__c =: selectedProgId AND Component_EI__r.name not in :measuresExcludedSet AND Pgm_Meas_Eff_To_EI__c >=: SYSTEM.TODAY()]) {
                           measureIdSet.add(progM.Component_EI__c);
                           measureProgMeasureMap.put(progM.Component_EI__c, progM.id);
                           system.debug('1111');
                        }
                        
                        measureList = [select id, Name, Unit_of_Measure_EI__c, Friendly_Name_EI__c, Inct_Rate_EI__c, Fuel_Type_EI__c, Incentive_Per_Unit_ER__c from Product2 where Id IN: measureIdSet];    
                    }
                }
                else {
                    // Fetching Program Measures from Programs
                    for(EI_Program_Measure__c progM : [select id, Component_EI__c from EI_Program_Measure__c where Pgm_EI__c IN: programIdSet AND Component_EI__r.name not in :measuresExcludedSet AND Pgm_Meas_Eff_To_EI__c >=: SYSTEM.TODAY()]) {
                        measureIdSet.add(progM.Component_EI__c);
                        measureProgMeasureMap.put(progM.Component_EI__c, progM.id);
                        system.debug('2222');
                    }
                    // Fetching Measure list to be displayed on Rebate Selection page
                    measureList = [select id, Name, Unit_of_Measure_EI__c, Friendly_Name_EI__c, Inct_Rate_EI__c, Fuel_Type_EI__c, Incentive_Per_Unit_ER__c from Product2 where Id IN: measureIdSet];
                }
                
                ProjectMeasures = Null;
            }
            else if(resOrNonRes == 'R') {
                resProg = [select id from EI_Program__c where Pgm_Code_EI__c =: resProgramCode];
                if(resProg.size() > 0) {
                    selProgramId = resProg[0].id;
                    // Fetching Program Measures from Programs
                    for(EI_Program_Measure__c progM : [select id, Component_EI__c from EI_Program_Measure__c where Pgm_EI__c =: resProg[0].id AND Component_EI__r.name not in :measuresExcludedSet AND Pgm_Meas_Eff_To_EI__c >=: SYSTEM.TODAY()]) {
                        measureIdSet.add(progM.Component_EI__c);
                        measureProgMeasureMap.put(progM.Component_EI__c, progM.id);
                        system.debug('3333');
                    }
                    
                    // Fetching Measure list to be displayed on Rebate Selection page
                    measureList = [select id, Name, Unit_of_Measure_EI__c, Friendly_Name_EI__c, Inct_Rate_EI__c, Fuel_Type_EI__c, Incentive_Per_Unit_ER__c from Product2 where Id IN: measureIdSet];
                    ProjectMeasures = Null;
                } 
            }
            // Creating Measure Map
            for(Product2 meas : measureList) {
                measureMap.put(meas.id, meas);
            }
            
            // Removing Measures already added from total Measure list
            removeSelectedMeasures();
            
            // Populating MeasureCode Map
            if(measureList.size() > 0) {
                for(Product2 measure : measureList) {
                    measureCodeMap.put(measure.Name, measure.id);
                }
            }
            // Populate PriceBookEntry Map
            if(measureCodeMap.size() > 0) {
                for(PriceBookEntry pbe : [select id, Product2Id from PriceBookEntry where PriceBook2Id =: priceBookList[0].id AND Product2Id IN: measureCodeMap.Values()]) {
                    pbeMeasureMap.put(pbe.Product2Id, pbe);
                }
            }
        }
        catch(Exception e) {
            EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        } 
    }
    
    
    public void removeSelectedMeasures() {
        
        try {
            if(measureList.size() > 0 && measurePMMap.size() > 0) {
                for(Integer i=0;i<measureList.size();i++) {
                    for(Id measId : measurePMMap.keySet()) {
                        if((String.ValueOf(measureList[i].id)).containsIgnoreCase(String.ValueOf(measId))) {
                            captureIndexList.add(i);
                        }
                    }
                }
            }
            captureIndexList.sort();
            if(captureIndexList.size() > 0) {
                for(Integer i=captureIndexList.size()-1;i>=0;i--) {
                    captureIndexDescList.add(captureIndexList[i]);
                }
            }
            if(captureIndexDescList.size() > 0) {
                for(Integer index : captureIndexDescList) {
                    measureList.remove(index);
                }
            }
        }
        catch(Exception e) {
            EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        } 
    }
    
      
    /*************************************************************************************************
    * @Description: Variable checks if Next records exist
    * @Parameter:
    * @Return: None
    * @Usage: 
    *************************************************************************************************/
    public Boolean hasNext {
        get {
            return ProjectMeasures.getHasNext();
        }
        set;
    }
    
    
    /*************************************************************************************************
    * @Description: Show Next records
    * @Parameter:
    * @Return: None
    * @Usage: 
    *************************************************************************************************/ 
    public void showNext() {
    
        ProjectMeasures.next();
    }
    
    
    /*************************************************************************************************
    * @Description: Variable checks if Previous records exist
    * @Parameter:
    * @Return: None
    * @Usage: 
    *************************************************************************************************/
    public Boolean hasPrevious {
        get {
            return ProjectMeasures.getHasPrevious();
        }
        set;
    }
    
    
    /*************************************************************************************************
    * @Description: Show Previous records
    * @Parameter:
    * @Return: None
    * @Usage: 
    *************************************************************************************************/ 
    public void showPrevious() {
    
        ProjectMeasures.previous();
    }
    
    
    /*************************************************************************************************
    * @Description: Searching for Site method method
    * @Parameter:
    * @Return: None
    * @Usage: 
    *************************************************************************************************/  
    public PageReference validateInputsDup() {
        
        try {
            // Declaring records
            project = new Opportunity();
            siteList = new List<EI_Site__c>();
            
            // Fetching Site values on Opportunity creation
            if(String.isNotEmpty(ServiceAgreementID)){
                siteList = [SELECT id, Name,SAID_EI__c, Street_Adr_Line_1_EI__c, Street_Adr_Line_2_EI__c, City_EI__c, State_EI__c, Zip_Code_EI__c,Recordtype.DeveloperName, Account_EI__r.Primary_Account_Id_EI__c, Account_EI__r.Local_Account_Id_EI__c FROM EI_Site__c WHERE SAID_EI__c =: ServiceAgreementID AND (F_Svc_Status_EI__c =: SITE_STATUS_ACTIVE OR F_Svc_Status_EI__c =: SITE_STATUS_PS) AND (Recordtype.DeveloperName =: SITE_RT_RESIDENTIAL OR Recordtype.DeveloperName =: SITE_RT_NON_RESIDENTIAL) LIMIT 1]; 
            }
            
            if(siteList.size() == 1) {
                // Providing Res/Non-Res indicator based on Site Type and Associating the Account
                if(siteList[0].Recordtype.DeveloperName == SITE_RT_RESIDENTIAL) {
                    resOrNonRes = 'R';
                    if(siteList[0].Account_EI__r.Local_Account_Id_EI__c != Null) {
                        project.AccountId = siteList[0].Account_EI__r.Local_Account_Id_EI__c;
                    }
                }
                else if(siteList[0].Recordtype.DeveloperName == SITE_RT_NON_RESIDENTIAL) {
                    resOrNonRes = 'NR';
                    if(siteList[0].Account_EI__r.Primary_Account_Id_EI__c != Null) {
                        project.AccountId = siteList[0].Account_EI__r.Primary_Account_Id_EI__c;
                    }
                }
            }
            
            // Populating Project fields
            project.Application_Source_EI__c = PROJECT_APP_SOURCE;
            project.Estimated_Completion_Date_EI__c = System.TODAY() + 15;
            project.Application_Received_Date_EI__c = System.TODAY();
            project.Payee_Recipient_Type_EI__c = PAYEE_RECEP_TYPE;
            
            // Passing to Rebate Selection Page
           PageReference productPage = new PageReference('/apex/ER_RebateSelectionPage');
           
            productPage.setRedirect(false);
            return productPage;
        }
        catch(Exception e) {
           EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
        
        return null;
    }
    
    
    
    /*************************************************************************************************
    * @Description: Method called on change of Project Type on Rebate Selection page
    * @Parameter:
    * @Return: None
    * @Usage: 
    *************************************************************************************************/
    public PageReference OnchangeProjectType(){
        
        measureIdSet = new Set<Id>();
        measureProgMeasureMap = new Map<Id, Id>();
        measureList = new List<Product2>();
        pbeMeasureMap = new Map<Id, PriceBookEntry>();
        measureCodeMap = new Map<String, Id>();
        priceBookList = new List<PriceBook2>();
        projectType = ApexPages.currentPage().getParameters().get('progType');
        
        try{
        
            priceBookList = PM_EI_MeasureTriggerHelper.getPriceBook(new Set<String>{'Energy Efficiency'});
            if(projectType != Null && nonResProgtypeMap.containsKey(projectType)){
                if(programMap.containsKey(nonResProgtypeMap.get(projectType))) {
                    selectedProgId = programMap.get(nonResProgtypeMap.get(projectType));
                    selProgramId = selectedProgId;
                }
                if(selectedProgId != Null) {
                    for(EI_Program_Measure__c progM : [select id, Component_EI__c from EI_Program_Measure__c where Pgm_EI__c =: selectedProgId AND Component_EI__r.name not in :measuresExcludedSet AND Pgm_Meas_Eff_To_EI__c >=: SYSTEM.TODAY()]) {
                       measureIdSet.add(progM.Component_EI__c);
                       measureProgMeasureMap.put(progM.Component_EI__c, progM.id);
                       system.debug('4444');
                    }
                    measureList = [select id, Name, Unit_of_Measure_EI__c, Friendly_Name_EI__c, Inct_Rate_EI__c, Fuel_Type_EI__c, Incentive_Per_Unit_ER__c from Product2 where Id IN: measureIdSet];    
                    for(Product2 measure : measureList) {
                        measureCodeMap.put(measure.Name, measure.id);
                    } 
                    
                    // Populate PriceBookEntry Map
                    if(measureCodeMap.size() > 0) {
                        for(PriceBookEntry pbe : [select id, Product2Id from PriceBookEntry where PriceBook2Id =: priceBookList[0].id AND Product2Id IN: measureCodeMap.Values()]) {
                            pbeMeasureMap.put(pbe.Product2Id, pbe);
                        }
                    }              
                }
            }
            
            ProjectMeasures = null;
        }
        catch(Exception e) {
            EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
        
        return null;
    }
    
    
    /*************************************************************************************************
    * @Description: Method which handles the Search functionality on page
    * @Parameter:
    * @Return: None
    * @Usage: 
    *************************************************************************************************/
    public void searchMeasure() {
        
        String query;
        measureList = new List<Product2>();
        pbeMeasureMap = new Map<Id, PriceBookEntry>();
        measureCodeMap = new Map<String, Id>();
        priceBookList = new List<PriceBook2>();
        SearchText  = ApexPages.currentPage().getParameters().get('serach');
        priceBookList = PM_EI_MeasureTriggerHelper.getPriceBook(new Set<String>{'Energy Efficiency'});
        captureIndexList = new List<Integer>();
        captureIndexDescList = new List<Integer>();
        
        try{
            // If search Text present
            if(String.isNotEmpty(searchText)) {
                query = 'SELECT id, Name, Unit_of_Measure_EI__c, Friendly_Name_EI__c, Inct_Rate_EI__c, Incentive_Per_Unit_ER__c from Product2 where Id IN: measureIdSet AND (Name LIKE \'%' + searchText + '%\' OR Unit_of_Measure_EI__c LIKE \'%' + searchText + '%\' OR Friendly_Name_EI__c LIKE \'%' + searchText + '%\' OR Incentive_Per_Unit_ER__c LIKE \'%' + searchText + '%\')';
                measureList = Database.query(query);
                // Removing Measures already added from total Measure list
                removeSelectedMeasures();
                
                ProjectMeasures = null;
                for(Product2 measure : measureList) {
                    measureCodeMap.put(measure.Name, measure.id);
                }
                // Populate PriceBookEntry Map
                if(measureCodeMap.size() > 0) {
                    for(PriceBookEntry pbe : [select id, Product2Id from PriceBookEntry where PriceBook2Id =: priceBookList[0].id AND Product2Id IN: measureCodeMap.Values()]) {
                        pbeMeasureMap.put(pbe.Product2Id, pbe);
                    }
                }
            }
            // If search text not present, Call the Inititalize method
            else {
                fetchMeasureList();
            }
        }
        catch(Exception e) {
           EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
        
    }     


    
    
    /*************************************************************************************************
    * @Description: Method collects all Measure records to display on Measure Search page
    * @Parameter: 
    * @Return: List of measure wrapper class
    * @Usage: Method collects all Measure records to display on Measure Search page after populating 
    the MeasureWrapper List
    *************************************************************************************************/
    public List<PM_MeasureListWrapper> getMeasureRecords() {
        
        
        measureWrapperList = new List<PM_MeasureListWrapper>();
        for(Product2 measure : (List<Product2>)ProjectMeasures.getRecords()) {
            
            measureWrapperList.add(new PM_MeasureListWrapper(measure));
        }
        
        return measureWrapperList;
    }
     
       
    /*************************************************************************************************
    * @Description: Wrapper class
    * @USage: Generates list of Measure records
    *************************************************************************************************/
    public class PM_MeasureListWrapper {
        
        // Variables declaration
        public Product2 measure {get;set;}
        public boolean isSelected {get;set;}

        // Wrapper Constructor declaration
        public PM_MeasureListWrapper(Product2 measure) {
            this.measure = measure;
            isSelected = false;
        }
    }
    
    
    /*************************************************************************************************
    * @Description: Method executed once the Measure is selected on Rebate Select screen
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    //public PageReference measureSelected() {
    public void measureSelected() {
        
        try {
            
            selectMeasId = ApexPages.currentPage().getParameters().get('selectedMeasId');
            
            // If Measure is selected, fetch the Measure record selected
            if(selectMeasId != Null && measureMap.containsKey(selectMeasId)) {
                latestMeasureSelected = measureMap.get(selectMeasId);
            }
            
            // If Measure is selected, fetch corresponding Program Measure
            if(selectMeasId != Null && measureProgMeasureMap.containsKey(selectMeasId)) {
                selectedProgMeasureId = measureProgMeasureMap.get(selectMeasId);
            }
        }
        catch(Exception e) {
           EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
    } 
    
    
    /*************************************************************************************************
    * @Description: Method takes user to Product Information page
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    
    public PageReference goToProductInfoPage() {
    
        PageReference productPage = new PageReference('/apex/ER_ProductInfoPage');
        productPage.setRedirect(false);
        return productPage;
    }
    
    
    /*************************************************************************************************
    * @Description: Method executed once the Product Information page is called
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    
    public void fetchProductInfo() {  
       
        projectMeasure = new OpportunityLineItem();
    }
    
    
    /*************************************************************************************************
    * @Description: Method executed once the 'Next' button on Product Information page is clicked
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    
    public void addProductInfo() {
        
        try {
            // Assiging Site on Project Measure entered on first screen
            if(!siteList.isEmpty()) {
                if(siteList.size() > 0) {
                    projectMeasure.Site_Service_Agreement_EI__c = siteList[0].Id;
                    projectMeasure.Site_Name_txt_EI__c = siteList[0].SAID_EI__c;
                    
                    // Assigning Project Measure Site address details
                    projectMeasure.Site_Address_EI__c = (siteList[0].Street_Adr_Line_1_EI__c != null ? siteList[0].Street_Adr_Line_1_EI__c : '');
                    if(!String.isBlank(projectMeasure.Site_Address_EI__c)) {
                        projectMeasure.Site_Address_EI__c += ' '+ (siteList[0].Street_Adr_Line_2_EI__c != null ? siteList[0].Street_Adr_Line_2_EI__c : '');
                    }
                    else {
                        projectMeasure.Site_Address_EI__c = (siteList[0].Street_Adr_Line_2_EI__c != null ? siteList[0].Street_Adr_Line_2_EI__c:'');
                    }
                    
                    projectMeasure.Site_City_EI__c = (siteList[0].City_EI__c != null ? siteList[0].City_EI__c : '');
                    projectMeasure.Site_State_EI__c = (siteList[0].State_EI__c != null ? siteList[0].State_EI__c : '');
                    
                    if(!String.isBlank(siteList[0].Zip_Code_EI__c)) {
                        if(siteList[0].Zip_Code_EI__c.length() > 5) {
                            projectMeasure.Site_Zip_EI__c = siteList[0].Zip_Code_EI__c.subString(0,5);
                        }
                        else {
                            projectMeasure.Site_Zip_EI__c = siteList[0].Zip_Code_EI__c;
                        }
                    }
                }
            }
            
            
            projectMeasure.Equip_Manufacturer_EI__c = manu;
            projectMeasure.Equipment_Model_EI__c = model;
            projectMeasure.Quantity= Decimal.ValueOf(Quantity);
            projectMeasure.Materials_Cost_EI__c = Decimal.ValueOf(purchaseprice);
            projectMeasure.Invoice_Date_EI__c = Date.parse(purchaseDate);
            projectMeasure.Install_Date_EI__c = Date.parse(instaldate);
            projectMeasure.Retailer_EI__c = retailer;
            projectMeasure.Req_Qty_of_UOM_EI__c = Integer.ValueOf(unitmeasure);
            projectMeasure.Measure_Comments_EI__c = comment;
            projectMeasure.Controller_Make_EI__c = contmake;
            projectMeasure.Controller_Model_EI__c = contmodel;
           
            // Assiging the correct Measure with Project Measure
            if(selectMeasId != Null) {
                if(pbeMeasureMap.containsKey(selectMeasId)) {
                    projectMeasure.PriceBookEntryId = pbeMeasureMap.get(selectMeasId).id;
                }
              
                if(selectedProgMeasureId != Null) {
                    projectMeasure.Program_Measure_EI__c = selectedProgMeasureId;
                     
                }
                
                measurePMMap.put(selectMeasId, projectMeasure);
                if(measureMap.containsKey(selectMeasId)) {
                    if(measureMap.get(selectMeasId).Inct_Rate_EI__c != null){   
                        projectMeasure.UnitPrice = measureMap.get(selectMeasId).Inct_Rate_EI__c;  
                    }    
                    else {
                        projectMeasure.UnitPrice = 0.0; 
                    }
                }
            }
        }
        catch(Exception e) {
          EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
    }
    
    
    /*************************************************************************************************
    * @Description: Method takes user to Customer and Contact Information Page
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public PageReference continueToCustInfoPage() {
            
        if(comingfromRebateReview) {
            PageReference rebateReviewPage = new PageReference('/apex/ER_RebateReview');
            rebateReviewPage.setRedirect(false);
            return rebateReviewPage;
        }
        else {
            PageReference productPage = new PageReference('/apex/ER_CustomerContactInfoPage');
            productPage.setRedirect(false);
            return productPage;
        }
    }
    
    
    /*************************************************************************************************
    * @Description: Method takes user back to Rebate Selection page
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public PageReference backToRebateSelectionPage() {
        
        PageReference productPage = new PageReference('/apex/ER_RebateSelectionPage');
        productPage.setRedirect(false);
        return productPage;
    }
    
    
    /*************************************************************************************************
    * @Description: Method executes once the Customer Information page is called
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public void fetchCustomerInfoPage() {
        
        sitestreetaddress = siteList[0].Street_Adr_Line_1_EI__c;
        siteinstalladdress = siteList[0].Street_Adr_Line_2_EI__c;
        sitecity = siteList[0].City_EI__c; 
        sitestate = siteList[0].State_EI__c;
        sitezip = siteList[0].Zip_Code_EI__c;
  
    }

    
    /*************************************************************************************************
    * @Description: Method executes once the Next button on Customer Information page is called
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public PageReference addCustomerInfo() {
        
        try {
            // Decoding variables in case they are encoded or special characters escaped
            payeename = EncodingUtil.urlDecode(payeename, 'UTF-8');
            sitemailaddress = EncodingUtil.urlDecode(sitemailaddress, 'UTF-8');
            sitemailaddress2 = EncodingUtil.urlDecode(sitemailaddress2, 'UTF-8');
            sitemailcity = EncodingUtil.urlDecode(sitemailcity, 'UTF-8');
            sitemailstate = EncodingUtil.urlDecode(sitemailstate, 'UTF-8');
            sitemailzip = EncodingUtil.urlDecode(sitemailzip, 'UTF-8');
            contactname = EncodingUtil.urlDecode(contactname, 'UTF-8');
            contactLname = EncodingUtil.urlDecode(contactLname, 'UTF-8');
            permitnumber = EncodingUtil.urlDecode(permitnumber, 'UTF-8');
            agency = EncodingUtil.urlDecode(agency, 'UTF-8');
            
            // Details from Front-end
            project.Site_Address_EI__c = sitestreetaddress;
            if(siteinstalladdress != Null && siteinstalladdress != '') {
                project.Site_Address_EI__c += ' '+siteinstalladdress;
            }
            project.Site_City__c = sitecity;
            project.Site_State_EI__c = sitestate;
            if(sitezip.length() > 5) {
                project.Site_Zip_EI__c = sitezip.subString(0, 5);
            }
            else {
                project.Site_Zip_EI__c = sitezip;
            }
            project.Payee_Attention_To_EI__c = payeename;
            project.Payee_EI__c = payeename;
            project.Site_Name_EI__c = siteList[0].id;
            project.Site_Name_txt_EI__c = siteList[0].SAID_EI__c;
            
            project.Payee_Mailing_Address_EI__c = sitemailaddress;
            if(sitemailaddress2 != Null && sitemailaddress2 != '') {
                project.Payee_Mailing_Address_EI__c += ' '+sitemailaddress2;
            }
            project.Payee_Mailing_City_EI__c = sitemailcity;
            project.Payee_Mailing_State_EI__c = sitemailstate;
            if(sitemailzip.length() > 5) {
                project.Payee_Mailing_Zip__c = sitemailzip.subString(0, 5);
            }
            else {
                project.Payee_Mailing_Zip__c = sitemailzip;
            }
            project.Site_Con_F_Name_EI__c = contactname;
            project.Site_Con_L_Name_EI__c = contactLname;
            project.Payee_Phone_EI__c = phone;
            project.Payee_Email_EI__c = email;
            project.Site_Contact_Phone_EI__c = phone;
            project.Site_Contact_Email_EI__c = email;
            
           /*  if(propertyoccpi != null && propertyoccpi != '' && propertyoccpi != ' ') //PS 1701013: Per QC defect# 2456, 
                    ensuring this value is not set if it is not presented on the page
                project.Property_Occupied_by_EI__c = propertyoccpi;*/
              
              
              
            if(resOrNonRes == 'R'){
            project.Property_Occupied_by_EI__c = propertyoccpi;
            }
              
            
            project.Site_Vintage_Year_EI__c = Estimateyear;
            project.Building_Type_Description_EI__c = Properttype;
            if(projBuildingTypeDependencyMap.size() > 0 && projBuildingTypeDependencyMap.containsKey(Properttype)) {
                project.Site_Building_Type_EI__c = projBuildingTypeDependencyMap.get(Properttype);
            }
            project.Payee_Tax_ID_Status_EI__c = taxstatus;
            project.Fed_Tax_Id_EI__c = taxid;
            project.Payee_Tax_ID_EI__c = taxid;
            if(specialflag != Null && specialflag != '' && specialflag != 'undefined') {
                project.Special_Project_Flag_EI__c = specialflag;
            }
            project.Contractor_Permit_Number_EI__c = permitnumber;
            project.Contractor_Company_Name_EI__c = agency;
            project.E_IM_Data_Entry_Complete_EI__c = true;
            project.Are_Man_Fields_Validated_EI__c = true;
            
            // Constant Details on Project
            project.Name = siteList[0].Name;
            project.StageName = PROJECT_STAGE;
            project.CloseDate = SYSTEM.TODAY().addDays(15);
            project.RecordTypeId = deemedRT.id;
            if(selProgramId != Null) {
                project.Program_EI__c = selProgramId;
            }
            
            PageReference rebateReviewPage = new PageReference('/apex/ER_RebateReview');
            rebateReviewPage.setRedirect(false);
            return rebateReviewPage;
        }
        catch(Exception e) {
         EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
        
        return Null;
    }
    
    
    /*************************************************************************************************
    * @Description: Method called when Rebate Review screen loads
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public void fetchRebateReviewPage() {
        
        try {
            measurePMMakeMap = new Map<Id, String>();
            measIdSet = new Set<Id>();
            measurePMModelMap = new Map<Id, String>();
            measurePMQuantMap = new Map<Id, Integer>();
            measurePMQuantMap = new Map<Id, Integer>();
            measurePMUnitMeasMap = new Map<Id, Integer>();
            
            newAttachments = new List<Attachment>();
            
            // Adding 4 Attachment variables
            for(Integer i=0;i<MAX_ATTACHMENTS;i++) {
                newAttachments.add(new Attachment());
            }
            
            if(!measurePMMap.isEmpty()) {
                if(measurePMMap.size() > 0) {
                    measIdSet = measurePMMap.keySet();
                    
                    for(Id measId : measIdSet) {
                        measurePMMakeMap.put(measId, measurePMMap.get(measId).Equip_Manufacturer_EI__c);
                        measurePMModelMap.put(measId, measurePMMap.get(measId).Equipment_Model_EI__c);
                        measurePMQuantMap.put(measId, Integer.ValueOf(measurePMMap.get(measId).Quantity));
                        measurePMUnitMeasMap.put(measId, Integer.ValueOf(measurePMMap.get(measId).Req_Qty_of_UOM_EI__c));
                    }
                }
            }
        }
        catch(Exception e) {
           EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
    }
    
    
    /*************************************************************************************************
    * @Description: Method called when PM is deleted on Rebate Review screen
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public void deleteProjectMeasure() {
        
       try {
            delMeasId = ApexPages.currentPage().getParameters().get('deleteMeasId');
            if(measurePMMap.containsKey(delMeasId)) {
                measurePMMap.remove(delMeasId);
            }
            
            fetchRebateReviewPage();
        }
        catch(Exception e) {
            EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
    }
    
    
    /*************************************************************************************************
    * @Description: Method called when user wants to add another rebate on Rebate Review screen
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public void addRebate() {
    
        comingfromRebateReview = true;
    }
    
    
    /*************************************************************************************************
    * @Description: Method called when user wants to add another rebate on Rebate Review screen
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public PageReference goToAddRebatePage() {
    
        PageReference productPage = new PageReference('/apex/ER_RebateSelectionPage');
        productPage.setRedirect(false);
        return productPage;
    }
    
    
    /*************************************************************************************************
    * @Description: Method called when Landing page is initially called
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public void initLandingPage() {
        
        try {
            comingfromRebateReview = false;
            showThankUPopup = false;
            deemedRT = [Select id From RecordType WHERE DeveloperName =: DEEMED_RT and SobjectType =: PROJECT_API_NAME AND IsActive = true];
            projBuildingTypeDependencyMap = new Map<String, String>();
            
            for(ER_Building_Type_Dependency__c bldgDepend : ER_Building_Type_Dependency__c.getall().values()) {
                if(bldgDepend.Object_API_Name__c == PROJECT_API_NAME) {
                    projBuildingTypeDependencyMap.put(bldgDepend.Name, bldgDepend.Child_Options_EI__c);
                }
            }
            
        }
        catch(Exception e) {
           EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
    }
    
    
    /*************************************************************************************************
    * @Description: Method called when Payee Name is edited on Rebate Review screen
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public void editCustInfoFromRR() {
    
       editToken = ApexPages.currentPage().getParameters().get('editToken');
    }
    
 
    
    /*************************************************************************************************
    * @Description: Method called when Payee Name is edited on Rebate Review screen
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public PageReference gotoCustInfoFromRR() {

        PageReference productPage = new PageReference('/apex/ER_CustomerContactInfoPage');
        productPage.setRedirect(false);
        return productPage;
    }
    
    

    
    /*************************************************************************************************
    * @Description: Method to create Project, Project Measures and attachments
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public PageReference createProjPM() {
        
        try {
            // Finding the smallest Install date from all Line Items to populate on Project
            Date projInstallDate = measurePMMap.Values()[0].Install_Date_EI__c;
            for(Integer i=1;i<measurePMMap.Values().size();i++) {
                if(measurePMMap.Values()[i].Install_Date_EI__c < projInstallDate) {
                    projInstallDate = measurePMMap.Values()[i].Install_Date_EI__c;
                }
            }
            
            showThankUPopup = true;
            List<Attachment> attToInsert = new List<Attachment>();
            for(Attachment newAtt : newAttachments) {
            }
            
            if(projInstallDate != Null) {
                project.Project_Install_Date_EI__c = projInstallDate;
            }
            
            project.Application_Signature_EI__c = appSigned;
            project.OwnerId = Label.ER_ProjectAndAttachmentOwnerId;
            insert project;
            projectAppnum = [SELECT id,Application_Number_EI__c FROM Opportunity WHERE id=: project.id];
            system.debug('projectAppnum '+projectAppnum);
            system.debug('Autonumber'+project.Application_Number_EI__c);
            if(project.id != Null) {
                projectId = project.id;
                system.debug('Autonumber'+project.Main_Project_ID_EI__c);
                system.debug('Autonumber'+project.Application_Number_EI__c);
               // ApplicationId = String.valueOf(project.id).substring(0, 15);
                ApplicationId = projectAppnum.Application_Number_EI__c;
                system.debug('ApplicationId '+ApplicationId);
                for(OpportunityLineItem projM : measurePMMap.Values()) {
                
                    projM.OpportunityId = project.id;
                    projM.Site_Con_F_Name_EI__c = project.Site_Con_F_Name_EI__c;
                    projM.Site_Con_L_Name_EI__c = project.Site_Con_L_Name_EI__c;
                    projM.Site_Contact_Phone_EI__c = project.Site_Contact_Phone_EI__c;
                    projM.Site_Contact_Email_EI__c = project.Site_Contact_Email_EI__c;
                    projM.Site_Vintage_Year_EI__c = project.Site_Vintage_Year_EI__c;
                    projM.Building_Type_Description__c = project.Building_Type_Description_EI__c;
                    projM.Site_Bldg_Type_EI__c = project.Site_Building_Type_EI__c;
                    projM.Payee_Recipient_Type_EI__c = project.Payee_Recipient_Type_EI__c;
                    projM.Are_Man_Fields_Validated_EI__c = true;
                    
                    projM.Payee_EI__c = project.Payee_EI__c;
                    projM.Payee_Attention_To_EI__c = project.Payee_Attention_To_EI__c;
                    
                    String payMailAddr = project.Payee_Mailing_Address_EI__c; //PS: Added due to pForce defect# 1441
                    if(payMailAddr.length() <= mailAddrLen)
                        projM.Payee_Mailing_Add_EI__c = payMailAddr;
                    else{
                        projM.Payee_Mailing_Add_EI__c = payMailAddr.left(mailAddrLen);
                    }
                    
                    String payCityAddr = project.Payee_Mailing_City_EI__c;//PS: Added due to pForce defect# 1441
                    if(payCityAddr.length() <= mailCityLen)
                        projM.Payee_Mailing_City_EI__c = payCityAddr;
                    else{
                        projM.Payee_Mailing_City_EI__c = payCityAddr.left(mailCityLen);
                    }
                    
                    projM.Payee_Mailing_Zip_EI__c = project.Payee_Mailing_Zip__c;
                    projM.Payee_Mailing_State__c = project.Payee_Mailing_State_EI__c;
                    projM.Payee_Tax_ID_EI__c = project.Payee_Tax_ID_EI__c;
                    projM.Payee_Tax_Status_EI__c = project.Payee_Tax_ID_Status_EI__c;
                    projM.Payee_Phone_EI__c = project.Payee_Phone_EI__c;
                    projM.Payee_Email_EI__c = project.Payee_Email_EI__c;
                }
                insert measurePMMap.Values();
                for(Attachment newAtt : newAttachments) {
                    if(newAtt.Name != Null) {
                        newAtt.ParentId = project.id;
                        attToInsert.add(newAtt);
                    }
                }
                insert attToInsert;
                newAttachments.clear();
                newAttachments.add(new Attachment());
                
                
                PageReference pg = new PageReference('/apex/ER_RebateReview');
                pg.setRedirect(false);
                return pg;
            }
        }
        
        catch(Exception e) {
           EI_CreateErrorLog.upsertException(EI_CreateErrorLog.logException('ER_Controller', e));
        }
        
        return null;
    }
    
    
    
    
    /*************************************************************************************************
    * @Description: Method to call Rebate Review page on click of 'Go To Review and Submit' button on 
        any screen
    * @Parameter: 
    * @Return: 
    * @Usage: 
    *************************************************************************************************/
    public PageReference gotoReviewSubmit() {
    
        PageReference rebateReviewPage = new PageReference('/apex/ER_RebateReview');
        rebateReviewPage.setRedirect(false);
        return rebateReviewPage;
    }
        
    
}