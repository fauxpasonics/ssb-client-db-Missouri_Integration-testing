SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[vwCRMLoad_Contact_Std_Update] AS
SELECT a.SSB_CRMSYSTEM_ACCT_ID__c
, a.SSB_CRMSYSTEM_CONTACT_ID__c
, a.Prefix
, a.FirstName
, a.LastName
--, a.Suffix AS Suffix__c --Deprecated
, a.Suffix AS SSB_CRMSYSTEM_Suffix__c
, a.MailingStreet
, a.MailingCity
, a.MailingState
, a.MailingPostalCode
, a.MailingCountry
, a.Phone
, a.Email
--, a.AccountId  --NEVER MAP, WILL BREAK HEDA
, [LoadType]
, a.Id
FROM [dbo].[vwCRMLoad_Contact_Std_Prep] a
LEFT JOIN  prodcopy.vw_contact c ON a.Id = c.Id
WHERE LoadType = 'Update'
AND  ( HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.FirstName AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.FirstName AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.LastName AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.LastName AS VARCHAR(MAX)))),'')) 
	--OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.Suffix AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.Suffix__c AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.MailingStreet AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.MailingStreet AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.MailingCity AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.MailingCity AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.MailingState AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.MailingState AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.MailingPostalCode AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.MailingPostalCode AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.MailingCountry AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.MailingCountry AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.Phone AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.Phone AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.Email AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.Email AS VARCHAR(MAX)))),'')) 
	OR HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( a.Suffix AS VARCHAR(MAX)))),'') )  <> HASHBYTES('SHA2_256',ISNULL(LTRIM(RTRIM(CAST( c.SSB_CRMSYSTEM_Suffix__c AS VARCHAR(MAX)))),'')) 	
	
	)
	


GO
