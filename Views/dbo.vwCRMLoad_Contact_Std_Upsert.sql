SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vwCRMLoad_Contact_Std_Upsert] AS
SELECT a.SSB_CRMSYSTEM_ACCT_ID__c, a.SSB_CRMSYSTEM_CONTACT_ID__c, Prefix, a.FirstName, a.LastName, Suffix AS SSB_CRMSYSTEM_Suffix__c, 
--a.Suffix AS Suffix__c,
MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, a.Phone, a.AccountId, a.Email
, [LoadType]
FROM [dbo].[vwCRMLoad_Contact_Std_Prep] a
WHERE LoadType = 'Upsert'
--and ISNULL(uu.IsActive,1) = 1
AND ISNULL(a.FirstName,'') + ISNULL(a.Lastname,'') <> ''





GO
