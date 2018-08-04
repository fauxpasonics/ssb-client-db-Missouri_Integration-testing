SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vwCRMLoad_Contact_Custom_Update]
AS
SELECT  
	 z.[crm_id] Id
	,b.[SSB_CRMSYSTEM_ACCT_ID] ssb_crmsystem_acct_id__c											--,c.ssb_crmsystem_acct_id__c
	,b.[SSB_CRMSYSTEM_CONTACT_ID] ssb_crmsystem_contact_id__c									--,c.ssb_crmsystem_contact_id__c
	,b.[SSID_Winner] SSB_CRMSYSTEM_SSID_Winner__c												--,c.SSB_CRMSYSTEM_SSID_Winner__c
	,b.[TM_Ids] 	SSB_CRMSYSTEM_SSID_TIX__c													--,c.SSB_CRMSYSTEM_SSID_TIX__c
	,b.[DimCustIDs] SSB_CRMSYSTEM_DimCustomerID__c												--,c.SSB_CRMSYSTEM_DimCustomerID__c
	,b.[AccountID] 	SSB_CRMSYSTEM_TIX_Account_ID__c												--,c.SSB_CRMSYSTEM_TIX_Account_ID__c
	,b.[MDMProcess_UpdatedDate] 																--
	,b.SSB_CRMSystem_SSIDWinnerSourceSystem__c SSB_CRMSYSTEM_SSID_Winner_SourceSystem__c		--,c.SSB_CRMSYSTEM_SSID_Winner_SourceSystem__c
	,b.SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c												--,c.SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c
	,b.SSB_CRMSYSTEM_Last_Donation_Date__c														--,c.SSB_CRMSYSTEM_Last_Donation_Date__c
	,b.SSB_CRMSYSTEM_Donor_Warning__c															--,c.SSB_CRMSYSTEM_Donor_Warning__c			
	,b.SSB_CRMSYSTEM_Total_Priority_Points__c													--,c.SSB_CRMSYSTEM_Total_Priority_Points__c	
	,b.SSB_CRMSYSTEM_Football_STH__c															--,c.SSB_CRMSYSTEM_Football_STH__c			
	,b.SSB_CRMSYSTEM_Football_Rookie__c															--,c.SSB_CRMSYSTEM_Football_Rookie__c			
	,b.SSB_CRMSYSTEM_Football_Partial__c														--,c.SSB_CRMSYSTEM_Football_Partial__c		
	
--,case when  ISNULL(b.SSID_Winner,'') != ISNULL(c.SSB_CRMSYSTEM_SSID_Winner__c,'')																 then 1 else 0 end as SSB_CRMSYSTEM_SSID_Winner__c
--,case when  ISNULL(b.DimCustIDs,'') != ISNULL(c.SSB_CRMSYSTEM_DimCustomerID__c,'')																 then 1 else 0 end as SSB_CRMSYSTEMDimCustomerIDs__c
--,case when  ISNULL(b.TM_Ids,'') != ISNULL(c.SSB_CRMSYSTEM_SSID_TIX__c,'')																	 then 1 else 0 end as SSB_CRMSYSTEMFullArchticsIDs__c
--,case when  ISNULL(b.AccountID,'') != ISNULL(c.SSB_CRMSYSTEM_TIX_Account_ID__c,'')																	 then 1 else 0 end as SSB_CRMSystemArchticsIDs__c
--,case when  ISNULL(b.SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c,'') != ISNULL(c.SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c,'')					 then 1 else 0 end as SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c
--,case when  ISNULL(b.SSB_CRMSYSTEM_Last_Donation_Date__c,'') != ISNULL(c.SSB_CRMSYSTEM_Last_Donation_Date__c,'')								 then 1 else 0 end as SSB_CRMSYSTEM_Last_Donation_Date__c
--,case when  ISNULL(b.SSB_CRMSYSTEM_Donor_Warning__c,'') != ISNULL(c.SSB_CRMSYSTEM_Donor_Warning__c,'')											 then 1 else 0 end as SSB_CRMSYSTEM_Donor_Warning__c
--,case when  ISNULL(CAST(b.SSB_CRMSYSTEM_Total_Priority_Points__c AS NVARCHAR(100)),'') != ISNULL(c.SSB_CRMSYSTEM_Total_Priority_Points__c,'')	 then 1 else 0 end as SSB_CRMSYSTEM_Total_Priority_Points__c
--,case when  ISNULL(b.SSB_CRMSYSTEM_Football_STH__c,'') != ISNULL(c.SSB_CRMSYSTEM_Football_STH__c,'')											 then 1 else 0 end as SSB_CRMSYSTEM_Football_STH__c
--,case when  ISNULL(b.SSB_CRMSYSTEM_Football_Rookie__c,'') != ISNULL(c.SSB_CRMSYSTEM_Football_Rookie__c,'')										 then 1 else 0 end as SSB_CRMSYSTEM_Football_Rookie__c
--,case when  ISNULL(b.SSB_CRMSYSTEM_Football_Partial__c,'') != ISNULL(c.SSB_CRMSYSTEM_Football_Partial__c,'')									 then 1 else 0 end as SSB_CRMSYSTEM_Football_Partial__c
--,case when  ISNULL(b.SSB_CRMSystem_SSIDWinnerSourceSystem__c,'') != ISNULL(c.SSB_CRMSYSTEM_SSID_Winner_SourceSystem__c,'')						 then 1 else 0 end as SSB_CRMSYSTEM_SSID_Winner_SourceSystem__c
		
FROM dbo.[vwCRMLoad_Contact_Std_Prep] a
INNER JOIN dbo.[Contact_Custom] b ON [a].[SSB_CRMSYSTEM_CONTACT_ID__c] = b.[SSB_CRMSYSTEM_CONTACT_ID]
INNER JOIN dbo.Contact z ON a.[SSB_CRMSYSTEM_CONTACT_ID__c] = z.[SSB_CRMSYSTEM_CONTACT_ID]
LEFT JOIN  prodcopy.vw_contact c ON z.[crm_id] = c.ID
WHERE z.[SSB_CRMSYSTEM_CONTACT_ID] <> z.[crm_id]
--AND  (HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  b.SSID_Winner AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.SSB_CRMSYSTEM_SSID_Winner__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.DimCustIDs AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_CRMSYSTEMDimCustomerIDs__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.[TM_Ids] AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_CRMSYSTEMFullArchticsIDs__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.[AccountID] AS VARCHAR(MAX)))),'') )  	<> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_CRMSystemArchticsIDs__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.SSB_LastPurchaseDate__c AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_LastPurchaseDate__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.SSB_LastDonationDate__c AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_LastDonationDate__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.SSB_IsDonor__c AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_IsDonor__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.SSB_PriorityPoints__c AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_PriorityPoints__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.SSB_FB_STH__c AS VARCHAR(MAX)))),'') )  	<> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_FB_STH__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.SSB_FB_STHRookie__c AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_FB_STHRookie__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.SSB_FB_PartialBuyer__c AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_FB_PartialBuyer__c AS VARCHAR(MAX)))),'')) 
--	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( b.SSB_CRMSystem_SSIDWinnerSourceSystem__c AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST(  c.SSB_CRMSystem_SSIDWinnerSourceSystem__c AS VARCHAR(MAX)))),'')) 

--	)
AND ( 1=2
OR ISNULL(b.SSID_Winner,'') != ISNULL(c.SSB_CRMSYSTEM_SSID_Winner__c,'')
OR ISNULL(b.DimCustIDs,'') != ISNULL(c.SSB_CRMSYSTEM_DimCustomerID__c,'')
OR ISNULL(b.TM_Ids,'') != ISNULL(c.SSB_CRMSYSTEM_SSID_TIX__c,'')
OR ISNULL(b.AccountID,'') != ISNULL(c.SSB_CRMSYSTEM_TIX_Account_ID__c,'')
OR ISNULL(b.SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c,'') != ISNULL(c.SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c,'')
OR ISNULL(b.SSB_CRMSYSTEM_Last_Donation_Date__c,'') != ISNULL(c.SSB_CRMSYSTEM_Last_Donation_Date__c,'')
OR ISNULL(b.SSB_CRMSYSTEM_Donor_Warning__c,'') != ISNULL(c.SSB_CRMSYSTEM_Donor_Warning__c,'')
OR ISNULL(CAST(b.SSB_CRMSYSTEM_Total_Priority_Points__c AS NVARCHAR(100)),'') != ISNULL(c.SSB_CRMSYSTEM_Total_Priority_Points__c,'')
OR ISNULL(b.SSB_CRMSYSTEM_Football_STH__c,'') != ISNULL(c.SSB_CRMSYSTEM_Football_STH__c,'')
OR ISNULL(b.SSB_CRMSYSTEM_Football_Rookie__c,'') != ISNULL(c.SSB_CRMSYSTEM_Football_Rookie__c,'')
OR ISNULL(b.SSB_CRMSYSTEM_Football_Partial__c,'') != ISNULL(c.SSB_CRMSYSTEM_Football_Partial__c,'')
OR ISNULL(b.SSB_CRMSystem_SSIDWinnerSourceSystem__c,'') != ISNULL(c.SSB_CRMSYSTEM_SSID_Winner_SourceSystem__c,'')

)






GO
