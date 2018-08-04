SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [MERGEPROCESS_New].[MergeDetect] -- 'missouri'
--exec [MERGEPROCESS_New].[MergeDetect]  'missouri'
	@Client VARCHAR(100) 
AS
--DECLARE @client VARCHAR(100) = 'missouri'
Declare @Date Date = (select cast(getdate() as date));
DECLARE @Account varchar(100) = 'Mizzou PC_SFDC Account';
DECLARE @Contact varchar(100) = 'MIzzou PC_SFDC Contact' ;


With MergeAccount as (
select a.SSB_CRMSYSTEM_ACCT_ID, count(1) CountAccounts, max(CASE WHEN b.SSB_CRMSYSTEM_ACCT_ID is not null then 1 else 0 END) Key_Related
	, CASE WHEN rt.DeveloperName = 'Administrative' AND rt.SobjectType = 'Account' THEN c.RecordTypeId ELSE 1 END AS RecordType
FROM dbo.vwDimCustomer_ModAcctID a WITH (NOLOCK)
LEFT JOIN (SELECT m.SSB_CRMSYSTEM_ACCT_ID
	FROM dbo.vw_KeyAccounts k
	JOIN dbo.vwDimCustomer_ModAcctId m ON m.DimCustomerId = k.dimcustomerid
	WHERE m.SSB_CRMSYSTEM_ACCT_ID IS NOT NULL	
) b ON a.SSB_CRMSYSTEM_ACCT_ID = b.SSB_CRMSYSTEM_ACCT_ID
JOIN prodcopy.vw_Account c WITH (NOLOCK) ON a.ssid = c.Id
LEFT JOIN prodcopy.recordtype rt ON c.RecordTypeId = rt.id
where SourceSystem =  @Account
and a.SSB_CRMSYSTEM_ACCT_ID is not null
group by a.SSB_CRMSYSTEM_ACCT_ID, (CASE WHEN rt.DeveloperName = 'Administrative' AND rt.SobjectType = 'Account' THEN c.RecordTypeId ELSE 1 END)
having count(1) > 1), 


 MergeContact as (
select SSB_CRMSYSTEM_CONTACT_ID, count(1) CountContacts, max(CASE WHEN k.SSBID is not null then 1 else 0 END) Key_Related
FROM dbo.vwDimCustomer_ModAcctID a  WITH (NOLOCK)
LEFT JOIN dbo.vw_KeyAccounts k
        ON k.SSBID = a.SSB_CRMSYSTEM_CONTACT_ID
where SourceSystem = @Contact
and a.SSB_CRMSYSTEM_CONTACT_ID is not null
group by SSB_CRMSYSTEM_CONTACT_ID
having count(1) > 1),



 MergeAdminAccount as (
select SSB_CRMSYSTEM_CONTACT_ID, count(1) CountContacts, max(CASE WHEN k.SSBID is not null then 1 else 0 END) Key_Related
FROM dbo.vwDimCustomer_ModAcctID a  WITH (NOLOCK)
left join dbo.vw_keyaccounts k WITH (NOLOCK) on a.SSB_CRMSYSTEM_CONTACT_ID = k.SSBID
INNER JOIN prodcopy.vw_Contact pcc WITH (NOLOCK) ON pcc.id = a.SSID
INNER JOIN prodcopy.vw_Account pca WITH (NOLOCK) ON pca.id = pcc.AccountId
INNER JOIN prodcopy.recordtype rt WITH (NOLOCK) ON rt.id = pca.RecordTypeId
where SourceSystem = @Contact
AND rt.DeveloperName = 'Administrative' AND rt.SobjectType = 'Account'
and a.SSB_CRMSYSTEM_CONTACT_ID is not null
group by SSB_CRMSYSTEM_CONTACT_ID
having count(1) > 1)


MERGE  MERGEPROCESS_New.DetectedMerges  as tar
using ( Select 'Account' MergeType, SSB_CRMSYSTEM_ACCT_ID SSBID, CASE WHEN Key_Related = 0 THEN 1 ELSE 0 END AutoMerge, @Date DetectedDate, CountAccounts NumRecords FROM MergeAccount
		UNION ALL
		Select 'Contact' MergeType, SSB_CRMSYSTEM_Contact_ID SSBID, CASE WHEN Key_Related = 0 THEN 1 ELSE 0 END AutoMerge, @Date DetectedDate, CountContacts NumRecords FROM MergeContact
		UNION ALL
		SELECT 'AdmnAct' MergeType,  SSB_CRMSYSTEM_Contact_ID SSBID, CASE WHEN Key_Related = 0 THEN 1 ELSE 0 END AutoMerge, @Date DetectedDate, CountContacts NumRecords FROM MergeAdminAccount
		) as sour
	ON tar.MergeType = sour.MergeType
	AND tar.SSBID = sour.SSBID
WHEN MATCHED  AND (sour.DetectedDate <> tar.DetectedDate 
				OR sour.NumRecords <> tar.NumRecords
				OR sour.AutoMerge != tar.AutoMerge
				OR MergeComplete =  1
				OR 0 <> tar.Mergecomplete) THEN UPDATE 
	Set DetectedDate = @Date
	,NumRecords = sour.NumRecords
	,AutoMerge = sour.AutoMerge
	,MergeComplete = 0 
	,tar.MergeComment = NULL
WHEN Not Matched THEN Insert
	(MergeType
	,SSBID
	,AutoMerge
	,DetectedDate
	,NumRecords)
Values(
	 sour.MergeType
	,sour.SSBID
	,sour.AutoMerge
	,sour.DetectedDate
	,sour.NumRecords)
WHEN NOT MATCHED BY SOURCE AND tar.MergeComment IS NULL THEN UPDATE
	SET MergeComment = CASE WHEN tar.Mergecomplete = 1 then 'Merge Detection - Merge Successfully completed'
							WHEN tar.mergeComplete = 0 THEN 'Merge Detection - Merge not completed, but no longer detected' END
		,MergeComplete = 1
	;


--NEW CODE for Force Merge Functionality --TCF 09112017
UPDATE MERGEPROCESS_New.DetectedMerges SET AutoMerge = 1
FROM MERGEPROCESS_New.DetectedMerges dm
INNER JOIN MERGEPROCESS_New.ForceMerge fm
ON dm.PK_MergeID = fm.FK_MergeID AND fm.complete = 0
WHERE AutoMerge != 1
--Create materialized tables for Prodcopy and DimCustomer?

IF OBJECT_ID('mergeprocess_new.tmp_pcaccount', 'U') IS NOT NULL 
DROP TABLE mergeprocess_new.tmp_pcaccount; 

IF OBJECT_ID('mergeprocess_new.tmp_pccontact', 'U') IS NOT NULL 
DROP TABLE mergeprocess_new.tmp_pccontact;

IF OBJECT_ID('mergeprocess_new.tmp_dimcust', 'U') IS NOT NULL 
DROP TABLE mergeprocess_new.tmp_dimcust;

select * into mergeprocess_new.tmp_dimcust from dbo.vwdimcustomer_modacctid  where ssb_crmsystem_contact_id in (
select ssb_crmsystem_contact_id from dbo.vwdimcustomer_modacctid where sourcesystem = @Contact group by ssb_crmsystem_contact_id having count(*) > 1 )
and sourcesystem = @Contact
UNION ALL
select * from dbo.vwdimcustomer_modacctid where ssb_crmsystem_acct_id in (
select ssb_crmsystem_acct_id from dbo.vwdimcustomer_modacctid where sourcesystem = @Account group by ssb_crmsystem_acct_id having count(*) > 1 )
and sourcesystem = @Account
--1:04

create nonclustered index ix_tmp_dimcust_acct on mergeprocess_new.tmp_dimcust (sourcesystem, ssb_crmsystem_acct_id)
create nonclustered index ix_tmp_dimcust_contact on mergeprocess_new.tmp_dimcust (sourcesystem, ssb_crmsystem_contact_id)
create nonclustered index ix_tmp_dimcust_ssid on mergeprocess_new.tmp_dimcust (sourcesystem, ssid)
--0:05

select pcc.* into mergeprocess_new.tmp_pccontact from mergeprocess_new.tmp_dimcust dc
inner join prodcopy.vw_contact pcc on dc.ssid = pcc.id
where dc.sourcesystem = @Contact
--0:07

select pca.* into mergeprocess_new.tmp_pcaccount from mergeprocess_new.tmp_dimcust dc
inner join prodcopy.vw_account pca on dc.ssid = pca.id
where dc.sourcesystem = @Account
--0:08

alter table mergeprocess_new.tmp_pcaccount
alter column id varchar(200)
--0:03


alter table mergeprocess_new.tmp_pccontact
alter column id varchar(200)
--0:02

create nonclustered index ix_tmp_pcaccount on mergeprocess_new.tmp_pcaccount (id)
--0:05

create nonclustered index ix_tmp_pccontact on mergeprocess_new.tmp_pccontact (id)
--0:01

 
 

GO
