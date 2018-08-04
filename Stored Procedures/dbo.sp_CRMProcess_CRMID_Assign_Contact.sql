SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sp_CRMProcess_CRMID_Assign_Contact]
as
UPDATE a
SET crm_Id = a.SSB_CRMSYSTEM_CONTACT_ID
FROM dbo.contact a
LEFT JOIN prodcopy.vw_contact b
ON a.crm_id = b.id
where b.id IS NULL 

UPDATE a
SET a.crm_id = b.id
-- SELECT COUNT(*)
FROM dbo.contact a
INNER JOIN prodcopy.vw_contact b ON a.SSB_CRMSYSTEM_contact_ID = b.SSB_CRMSYSTEM_contact_ID__c
LEFT JOIN (SELECT [crm_id] FROM dbo.contact WHERE crm_id <> [SSB_CRMSYSTEM_CONTACT_ID]) c ON b.id = c.crm_id
WHERE isnull(a.[crm_id], '') != b.id 
AND c.crm_id IS NULL	
---and b.id = '0033800002JUEoUAAX'

UPDATE a
SET [crm_id] =  b.ssid 
-- SELECT COUNT(*) 
FROM dbo.contact a
INNER JOIN dbo.[vwDimCustomer_ModAcctId] b ON a.SSB_CRMSYSTEM_contact_ID = b.SSB_CRMSYSTEM_contact_ID
LEFT JOIN (SELECT crm_id FROM dbo.contact WHERE crm_id <> [SSB_CRMSYSTEM_CONTACT_ID]) c ON b.ssid = c.[crm_id]
WHERE b.SourceSystem = 'Missouri PC_SFDC Contact' AND a.[crm_id] != b.ssid
 AND c.[crm_id] IS NULL 

UPDATE c
SET crm_id = dc.ssid
--SELECT c.crm_id, dc.SSID
from dbo.contact c
INNER JOIN dbo.DimCustomerSSBID ssb
ON c.SSB_CRMSYSTEM_CONTACT_ID = ssb.SSB_CRMSYSTEM_CONTACT_ID
INNER JOIN dbo.DimCustomer dc ON ssb.DimCustomerId = dc.DimCustomerId AND dc.isdeleted = 0
WHERE dc.SourceSystem = 'Missouri PC_SFDC Contact'
AND c.crm_id = ssb.SSB_CRMSYSTEM_CONTACT_ID
GO
