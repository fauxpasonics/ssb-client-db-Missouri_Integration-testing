SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [MERGEPROCESS_New].[vw_Cust_Contact_ColumnLogic]
AS

SELECT mrg.Winning_ID AS ID 
	  ,mrg.Losing_ID AS Losing_ID 																		
	 ,/*AccountId												- Standard							*/	COALESCE(winner.AccountId,loser.AccountId)																												  AS [AccountId]
	 ,/*CreatedById												- Standard							*/	COALESCE(winner.CreatedById,loser.CreatedById)																											  AS [CreatedById]
	 ,/*hed__AlternateEmail__c									- Standard							*/	COALESCE(winner.hed__AlternateEmail__c,loser.hed__AlternateEmail__c)																					  AS [hed__AlternateEmail__c]
	 ,/*hed__Current_Address__c									- Standard							*/	COALESCE(winner.hed__Current_Address__c,loser.hed__Current_Address__c)																					  AS [hed__Current_Address__c]
	 ,/*hed__Deceased__c										- Standard							*/	COALESCE(winner.hed__Deceased__c,loser.hed__Deceased__c)																								  AS [hed__Deceased__c]
	 ,/*hed__Preferred_Email__c									- Standard							*/	COALESCE(winner.hed__Preferred_Email__c,loser.hed__Preferred_Email__c)																					  AS [hed__Preferred_Email__c]
	 ,/*Last_Modified_Raw_Date_Time__c							- Standard							*/	COALESCE(winner.Last_Modified_Raw_Date_Time__c,loser.Last_Modified_Raw_Date_Time__c)																	  AS [Last_Modified_Raw_Date_Time__c]
	 ,/*LastModifiedById										- Standard							*/	COALESCE(winner.LastModifiedById,loser.LastModifiedById)																								  AS [LastModifiedById]
	 ,/*MailingAddress											- Standard							*/	COALESCE(winner.MailingAddress,loser.MailingAddress)																									  AS [MailingAddress]
	 ,/*Name													- Standard							*/	COALESCE(winner.Name,loser.Name)																														  AS [Name]
	 ,/*OwnerId													- Standard							*/	COALESCE(winner.OwnerId,loser.OwnerId)																													  AS [OwnerId]
	 ,/*PhotoUrl												- Standard							*/	COALESCE(winner.PhotoUrl,loser.PhotoUrl)																												  AS [PhotoUrl]
	 ,/*DoNotCall												- Check yes if Either Record is Yes	*/	CASE WHEN winner.DoNotCall = 1 OR loser.DoNotCall = 1 THEN 1 ELSE 0 END																					  AS [DoNotCall]
	 ,/*HasOptedOutOfEmail										- Check yes if Either Record is Yes	*/	CASE WHEN winner.HasOptedOutOfEmail = 1 OR loser.HasOptedOutOfEmail = 1 THEN 1 ELSE 0 END																  AS [HasOptedOutOfEmail]
	 ,/*hed__Do_Not_Contact__c									- Check yes if Either Record is Yes	*/	CASE WHEN winner.hed__Do_Not_Contact__c = 1 OR loser.hed__Do_Not_Contact__c = 1 THEN 1 ELSE 0 END														  AS [hed__Do_Not_Contact__c]
	 ,/*hed__Exclude_from_Household_Formal_Greeting__c			- Check yes if Either Record is Yes	*/	CASE WHEN winner.hed__Exclude_from_Household_Formal_Greeting__c = 1 OR loser.hed__Exclude_from_Household_Formal_Greeting__c = 1 THEN 1 ELSE 0 END		  AS [hed__Exclude_from_Household_Formal_Greeting__c]
	 ,/*hed__Exclude_from_Household_Informal_Greeting__c		- Check yes if Either Record is Yes	*/	CASE WHEN winner.hed__Exclude_from_Household_Informal_Greeting__c = 1 OR loser.hed__Exclude_from_Household_Informal_Greeting__c = 1 THEN 1 ELSE 0 END	  AS [hed__Exclude_from_Household_Informal_Greeting__c]
	 ,/*hed__Exclude_from_Household_Name__c						- Check yes if Either Record is Yes	*/	CASE WHEN winner.hed__Exclude_from_Household_Name__c = 1 OR loser.hed__Exclude_from_Household_Name__c = 1 THEN 1 ELSE 0 END								  AS [hed__Exclude_from_Household_Name__c]
	 ,/*hed__FERPA__c											- Check yes if Either Record is Yes	*/	CASE WHEN winner.hed__FERPA__c = 1 OR loser.hed__FERPA__c = 1 THEN 1 ELSE 0 END																			  AS [hed__FERPA__c]
	 ,/*hed__Financial_Aid_Applicant__c							- Check yes if Either Record is Yes	*/	CASE WHEN winner.hed__Financial_Aid_Applicant__c = 1 OR loser.hed__Financial_Aid_Applicant__c = 1 THEN 1 ELSE 0 END										  AS [hed__Financial_Aid_Applicant__c]
	 ,/*hed__HIPAA__c											- Check yes if Either Record is Yes	*/	CASE WHEN winner.hed__HIPAA__c = 1 OR loser.hed__HIPAA__c = 1 THEN 1 ELSE 0 END																			  AS [hed__HIPAA__c]
	 ,/*hed__is_Address_Override__c								- Check yes if Either Record is Yes	*/	CASE WHEN winner.hed__is_Address_Override__c = 1 OR loser.hed__is_Address_Override__c = 1 THEN 1 ELSE 0 END												  AS [hed__is_Address_Override__c]
	 ,/*hed__Military_Service__c								- Check yes if Either Record is Yes	*/	CASE WHEN winner.hed__Military_Service__c = 1 OR loser.hed__Military_Service__c = 1 THEN 1 ELSE 0 END													  AS [hed__Military_Service__c]
	 ,/*IsDeleted												- Check yes if Either Record is Yes	*/	CASE WHEN winner.IsDeleted = 1 OR loser.IsDeleted = 1 THEN 1 ELSE 0 END																					  AS [IsDeleted]
	 ,/*IsEmailBounced											- Check yes if Either Record is Yes	*/	CASE WHEN winner.IsEmailBounced = 1 OR loser.IsEmailBounced = 1 THEN 1 ELSE 0 END																		  AS [IsEmailBounced]
	 ,/*copyloaddate											- Most recent from both records		*/	CASE WHEN winner.copyloaddate < loser.copyloaddate THEN loser.copyloaddate ELSE winner.copyloaddate END													  AS [copyloaddate]
	 ,/*LastModifiedDate										- Most recent from both records		*/	CASE WHEN winner.LastModifiedDate < loser.LastModifiedDate THEN loser.LastModifiedDate ELSE winner.LastModifiedDate END									  AS [LastModifiedDate]
	 ,/*SystemModstamp											- Most recent from both records		*/	CASE WHEN winner.SystemModstamp < loser.SystemModstamp THEN loser.SystemModstamp ELSE winner.SystemModstamp END											  AS [SystemModstamp]
	 ,/*CreatedDate												- Earliest from both records			*/	CASE WHEN winner.CreatedDate > loser.CreatedDate THEN loser.CreatedDate ELSE winner.CreatedDate END													  AS [CreatedDate]
FROM [MERGEPROCESS_New].[Queue] mrg
	JOIN MERGEPROCESS_New.tmp_pccontact winner ON winner.id = mrg.Winning_ID
	JOIN MERGEPROCESS_New.tmp_pccontact loser ON loser.id = mrg.Losing_ID
 WHERE mrg.ObjectType = 'Contact'















































































































































































































































































































































 






 
 



   
    
      











  

  
       
     




    



 



       
        
          









  











    





    







   













 
 
 

       
       


  
  




     
     


     
     


       
       

   
   






     
           
         

 




    





















GO
