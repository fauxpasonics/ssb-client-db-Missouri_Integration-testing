SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [MERGEPROCESS_New].[QueueMerges] --missouri
--Exec  [MERGEPROCESS_New].[QueueMerges] 'missouri'
	@Client VARCHAR(100) 
AS
--Declare @Client VARCHAR(100) ='missouri'
DECLARE @Account VARCHAR(100) = (SELECT CASE WHEN @client = 'Missouri' THEN 'Mizzou PC_SFDC Account' ELSE CONCAT(@client,' PC_SFDC Account' ) END);
DECLARE @Contact VARCHAR(100) = (SELECT CASE WHEN @client = 'Missouri' THEN 'Mizzou PC_SFDC Contact' ELSE CONCAT(@client,' PC_SFDC Contact' ) END );

--WITH only2Acct as
TRUNCATE TABLE MERGEPROCESS_New.Queue 
INSERT INTO MERGEPROCESS_New.Queue

SELECT PK_MergeID, b.MergeType,  MAX(CASE WHEN xRank =1 THEN CAST(c.ID AS VARCHAR(100)) END) AS Winner, MAX(CASE WHEN xRank =2 THEN CAST(c.ID AS VARCHAR(100)) END) AS Loser 
FROM mergeprocess_new.tmp_dimcust a 
JOIN MERGEPROCESS_New.DetectedMerges b ON a.SSB_CRMSYSTEM_ACCT_ID = b.SSBID AND SourceSystem = @Account
JOIN MERGEPROCESS_New.vwMergeAccountRanks c ON a.SSID = CAST(c.ID AS VARCHAR(100))
WHERE  ((AutoMerge = 1 and NumRecords = 2) OR Approved = 1)	
AND b.MergeType = 'Account'
AND MergeComplete = 0 
GROUP BY PK_MergeID,b.MergeType
HAVING MAX(CASE WHEN xRank =1 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL AND  MAX(CASE WHEN xRank =2 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL

UNION ALL

SELECT PK_MergeID, b.MergeType,  MAX(CASE WHEN xRank =1 THEN CAST(c.ID AS VARCHAR(100)) END) AS Winner, MAX(CASE WHEN xRank =2 THEN CAST(c.ID AS VARCHAR(100)) END) AS Loser  
FROM mergeprocess_new.tmp_dimcust a 
JOIN MERGEPROCESS_New.DetectedMerges b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSBID AND SourceSystem = @Contact
JOIN MERGEPROCESS_New.vwMergeContactRanks c ON a.SSID = CAST(c.ID AS VARCHAR(100))
WHERE  ((AutoMerge = 1 and NumRecords = 2) OR Approved = 1)
	--AND NumRecords = 2	
	AND b.MergeType = 'Contact'
	AND MergeComplete = 0 
GROUP BY PK_MergeID,b.MergeType
HAVING MAX(CASE WHEN xRank =1 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL AND  MAX(CASE WHEN xRank =2 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL


UNION ALL

SELECT PK_MergeID, 'AdmnAct' AS MergeType,  MAX(CASE WHEN xRank =1 THEN CAST(pcc.AccountID AS VARCHAR(100)) END) AS Winner, MAX(CASE WHEN xRank =2 THEN CAST(pcc.AccountID AS VARCHAR(100)) END) AS Loser  
FROM mergeprocess_new.tmp_dimcust a 
JOIN MERGEPROCESS_New.DetectedMerges b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSBID AND SourceSystem = @Contact
JOIN MERGEPROCESS_New.vwMergeContactRanks c ON a.SSID = CAST(c.ID AS VARCHAR(100))
INNER JOIN mergeprocess_new.tmp_pccontact pcc ON c.id = pcc.Id
INNER JOIN prodcopy.vw_Account pca ON pcc.AccountId = pca.Id
INNER JOIN prodcopy.recordtype rt ON rt.id = pca.RecordTypeId
WHERE  ((AutoMerge = 1 and NumRecords = 2) OR Approved = 1)
	--AND NumRecords = 2	
	AND b.MergeType = 'AdmnAct'
	AND MergeComplete = 0 
	AND rt.DeveloperName = 'Administrative' AND SobjectType = 'Account'
GROUP BY PK_MergeID,b.MergeType
HAVING MAX(CASE WHEN xRank =1 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL AND  MAX(CASE WHEN xRank =2 THEN CAST(c.ID AS VARCHAR(100)) END) IS NOT NULL

GO
