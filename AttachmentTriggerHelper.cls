/**************************************************************************************************   
Apex class Name      :  AttachmentTriggerHelper
Version              :  1.0                                                                          
Created Date         :  7/7/2016                                                         
Function             :  Do not allow Attachments to be deleted by TradePro & SalesRep profiles, 
                     :  for all Projects that are in Post Install stage.
Case                 :  Investigate and Correct: TradePro and BES Ability to Delete an Uploaded Document                      
Story                :  STY-00268                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer            Date                   Description                                     
* -------------------------------------------------------------------------------------------------  
* Balaram Nair        3/30/2017               Created.
*-------------------------------------------------------------------------------------------------*/
public class AttachmentTriggerHelper{
    // Constant Declaration
    // Processing stages to be accounted for!
    public static final String POST_INSTALL_REVIEW_STAGE= '8D - Post-Install Review - D&C';
    public static final String CIP_STAGE= '12 - CIP - D&C';
    public static final String POST_CIP_STAGE= '13 - Post CIP Review D';
    public static final String PENDING_APPROVAL_STAGE= '14 - Pending Approval';
    public static final String PAYMENT_APPROVAL_STAGE= '10 - Approved for Payment - D&C';
    public static final String PAID_STAGE= '11A - Paid - D&C';
    
    // Profiles to be accounted for!
    public static final set<string> setProfileStr = new set<string>{'Trade Pro', 'Trade Pro Admin','Sales Rep' };
    
    //Error Message
    public static final String errMsg= 'Attachments cannot be deleted when Projects are in or past Post Install Review stage.';
    
    public static string preventDeletion(list<attachment>lstAttachment){
        //creating Set to ensure attachments are for Oppurtunity only!
        set<Id>setOppId = new set<Id>();
        //This set holds only attachments related to the criteria of profile and stages!
        set<Id>setPreventDeletion = new set<Id>();
        system.debug ('@@@BXNE ' + 'START');
        for(attachment attach : lstAttachment){

            //All ID's for Opportunity starts with 006
            //Another way is using : Schema.getGlobalDescribe().get('Attachment').getDescribe().getKeyPrefix()
            if(attach.ParentId != null && string.valueOf(attach.ParentId).startsWithIgnoreCase('006') ){
                setOppId.add(attach.ParentId);
                
            }            
        }
        system.debug ('@@@BXNE setoppid    ' + SetOppId);
        if(setOppId != null && !setOppId.isEmpty()){
            list<profile>lstProfile = [select id from profile where Name IN :setProfileStr limit 10];
            set<id>setprofileId = new set<id>();
            
            //Get ID of the three profiles!
            if(!lstProfile.isEmpty()){
               for(profile pro : lstProfile){
                   setprofileId.add(pro.Id);
                }
            }
            system.debug ('@@@BXNE setprofileId    ' + setprofileId + '___' + userinfo.getProfileId() );
            
            //If Profile of logged in user matches then check if Project is in Post Install stage!
            if(!lstProfile.isEmpty() && setprofileId.contains (userinfo.getProfileId())){
                list<opportunity>lstOpp = [select id from opportunity where id IN :setOppId AND (stageName = :POST_INSTALL_REVIEW_STAGE OR stageName = :CIP_STAGE OR stageName = :POST_CIP_STAGE OR stageName = :PENDING_APPROVAL_STAGE OR stageName = :PAYMENT_APPROVAL_STAGE OR stageName = :PAID_STAGE)];
                if(!lstOpp.isEmpty()){
                   
                    //If Project is in Post Install stage then add the Opportunity ID in PreventDeletion set!
                    for(opportunity opp : lstOpp){
                        setPreventDeletion.add(opp.Id);
                    }
                }
            }
            system.debug ('@@@BXNE setPreventDeletion    ' + setPreventDeletion);

            //If setPreventDeletion is not empty then throw error message!
            if(!setPreventDeletion.isEmpty()){
                for(attachment att : lstAttachment){
                    if(setPreventDeletion.contains(att.ParentId)){
                        //att.addError(errMsg);
                        return errMsg;
                    }
                }
            }
        }
        return '';
    }
}