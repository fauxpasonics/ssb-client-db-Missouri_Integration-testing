SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vwCRMProcess_DeDupProdCopyContact_ByGUID] --updateme based on Account Model (may need contact)
AS

WITH ranking AS (SELECT SSB_CRMSYSTEM_CONTACT_ID__c, id, CreatedDate, CreatedById, ROW_NUMBER() OVER (PARTITION BY SSB_CRMSYSTEM_CONTACT_ID__c ORDER BY CreatedDate ASC) Rank
FROM prodcopy.vw_Contact
WHERE SSB_CRMSYSTEM_CONTACT_ID__c IS NOT NULL)

SELECT r.SSB_CRMSYSTEM_CONTACT_ID__c, r.id, r.CreatedDate, r.CreatedById, r.Rank
FROM ranking r 
WHERE r.SSB_CRMSYSTEM_CONTACT_ID__c IS NOT NULL
AND r.rank = 1;
GO
