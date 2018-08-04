SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [wrk].[sp_Account_Custom]
AS 


MERGE INTO dbo.Account_Custom Target
USING dbo.Account source
ON source.[SSB_CRMSYSTEM_ACCT_ID] = target.[SSB_CRMSYSTEM_ACCT_ID]
WHEN NOT MATCHED BY TARGET THEN
INSERT ([SSB_CRMSYSTEM_ACCT_ID]) VALUES (source.[SSB_CRMSYSTEM_ACCT_ID])
WHEN NOT MATCHED BY SOURCE THEN
DELETE ;

/*=======================================================
					Dimcustomer Temp
=======================================================*/

SELECT SSB_CRMSYSTEM_ACCT_ID 
	  ,SSB_CRMSYSTEM_PRIMARY_FLAG
	  ,ssbid.SourceSystem
	  ,ssbid.SSID
	  ,dc.AccountId
	  ,dc.DimCustomerId
INTO #SSBID
FROM Missouri.dbo.dimcustomerssbid ssbid
	JOIN Missouri.dbo.dimcustomer dc ON dc.DimCustomerId = ssbid.DimCustomerId

CREATE INDEX IX_ACCT ON #SSBID (SSB_CRMSYSTEM_ACCT_ID)
CREATE INDEX IX_SOURCE	ON #SSBID (SourceSystem)
CREATE INDEX IX_SSID	ON #SSBID (SSID)
CREATE INDEX IX_AccountID	ON #SSBID (AccountID)
CREATE INDEX IX_DimCustomerID	ON #SSBID (DimCustomerID)


/*=======================================================
				dbo.sp_CRMProcess_ConcatIDs
=======================================================*/

EXEC dbo.sp_CRMProcess_ConcatIDs 'Account'

/*=======================================================
					SSID Winner
=======================================================*/

UPDATE a
SET SSID_Winner = ssbid.[SSID], a.SSB_CRMSystem_SSIDWinnerSourceSystem__c =  ssbid.SourceSystem	 
FROM [dbo].Account_Custom a
	JOIN #SSBID ssbid ON ssbid.[SSB_CRMSYSTEM_ACCT_ID] = [a].[SSB_CRMSYSTEM_ACCT_ID]
WHERE ssbid.SSB_CRMSYSTEM_PRIMARY_FLAG = 1

/*=========================================
 sp_CRMLoad_Account_ProcessLoad_Criteria
=========================================*/


/*=======================================================
					Football Seasons
=======================================================*/

CREATE TABLE #Seasons_FB(
dimseasonid INT
,IsCurrentSeason BIT)

INSERT INTO #Seasons_FB 

SELECT dimseasonid
	  ,CASE WHEN YearRank = 1 THEN 1 ELSE 0 END IsCurrentSeason
FROM (
		SELECT dimseasonid
			  ,RANK() OVER(ORDER BY seasonyear DESC) AS yearRank
		FROM missouri.dbo.dimseason ds
		where seasonname = concat(seasonyear,' Mizzou Football')
	 )x

/*=======================================================
					Sport TBD Seasons
=======================================================

CREATE TABLE #Seasons_FB(
dimseasonid INT
,IsCurrentSeason BIT)

SELECT dimseasonid
	  ,CASE WHEN YearRank = 1 THEN 1 ELSE 0 END IsCurrentSeason
FROM (
		SELECT dimseasonid
			  ,RANK() OVER(ORDER BY seasonyear DESC) AS yearRank
		FROM missouri.dbo.dimseason ds
		where seasonname = concat(seasonyear,' Mizzou Football')
	 )x

*/

/*=======================================================
					Ticketing Temp
=======================================================*/

SELECT SSB_CRMSYSTEM_ACCT_ID
	  ,CurrentSTH
	  ,PriorSTH
	  ,PartialPlan
INTO #Ticketing
FROM (  SELECT ssbid.SSB_CRMSYSTEM_ACCT_ID
			  ,MAX(CASE WHEN fb.IsCurrentSeason = 1 AND fts.DimTicketTypeId = 5 THEN 1 ELSE 0 END) CurrentSTH	-- 20180524 jbarberio OLD -> SUM(CASE WHEN fb.IsCurrentSeason = 1 AND fts.DimTicketTypeId = 5 THEN 1 ELSE 0 END) CurrentSTH
			  ,MAX(CASE WHEN fb.IsCurrentSeason = 0 AND fts.DimTicketTypeId = 5 THEN 1 ELSE 0 END) PriorSTH		-- 20180524 jbarberio OLD -> SUM(CASE WHEN fb.IsCurrentSeason = 0 AND fts.DimTicketTypeId = 5 THEN 1 ELSE 0 END) PriorSTH
			  ,MAX(CASE WHEN fb.IsCurrentSeason = 1 AND fts.DimTicketTypeId = 6 THEN 1 ELSE 0 END) PartialPlan	-- 20180524 jbarberio OLD -> SUM(CASE WHEN fb.IsCurrentSeason = 1 AND fts.DimTicketTypeId = 6 THEN 1 ELSE 0 END) PartialPlan
		FROM missouri.dbo.FactTicketSales fts
			JOIN #Seasons_FB fb ON fb.dimseasonid = fts.DimSeasonId
			JOIN #SSBID ssbid ON ssbid.DimCustomerId = fts.DimCustomerId
		GROUP BY ssbid.SSB_CRMSYSTEM_ACCT_ID
	 )x
WHERE CurrentSTH	= 1
	 OR PriorSTH	= 1
	 OR PartialPlan = 1


/*=======================================================
					LAST PURCHASE DATE
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c] = CAST(ssbid.transdate AS DATE)
FROM 
dbo.account_custom a
JOIN
		(SELECT  ssb.SSB_CRMSYSTEM_ACCT_ID, MAX(dd.CalDate) transdate 
		 FROM #SSBID ssb 
			JOIN missouri.dbo.FactTicketSales fts ON ssb.DimCustomerId = fts.DimCustomerId
			JOIN missouri.dbo.dimdate dd ON dd.dimdateid = fts.DimDateId_OrigSale
		 GROUP BY ssb.SSB_CRMSYSTEM_ACCT_ID
		 ) ssbid
ON ssbid.SSB_CRMSYSTEM_ACCT_ID = a.SSB_CRMSYSTEM_ACCT_ID

/*=======================================================
					Last Donation Date
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Last_Donation_Date__c] = ssbid.DonationDate
FROM 
dbo.account_custom a
JOIN (SELECT  ssbid.SSB_CRMSYSTEM_ACCT_ID, MAX(add_datetime) DonationDate 
	  FROM #SSBID ssbid
	 	 JOIN missouri.ods.TM_Donation donation ON donation.acct_id = ssbid.AccountID
	  GROUP BY ssbid.SSB_CRMSYSTEM_ACCT_ID
	  ) ssbid
ON ssbid.SSB_CRMSYSTEM_ACCT_ID = a.SSB_CRMSYSTEM_ACCT_ID


/*=======================================================
						DONOR FLAG
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Donor_Warning__c] = ISNULL(b.IsDonor,0)
FROM dbo.Account_custom a
LEFT JOIN (
	SELECT dc.SSB_CRMSYSTEM_ACCT_ID, '1' AS IsDonor
	FROM (SELECT * FROM Missouri.dbo.vwDimCustomer_ModAcctId 
		WHERE SourceSystem = 'TM') dc
	JOIN Missouri.ods.TM_Donation don (NOLOCK)
		ON dc.AccountId = don.apply_to_acct_id
	WHERE drive_year > '2015' -- need to remove hard coded year
	GROUP BY dc.SSB_CRMSYSTEM_ACCT_ID
	) b ON a.SSB_CRMSYSTEM_ACCT_ID = b.SSB_CRMSYSTEM_ACCT_ID


/*=======================================================
					  PRIORITY POINTS
=======================================================

UPDATE a 
SET SSB_CRMSYSTEM_Total_Priority_Points__c = points.SSB_PriorityPoints__c
FROM dbo.account_custom a
	JOIN (  SELECT ssbid.SSB_CRMSYSTEM_ACCT_ID, cust.points_itd SSB_PriorityPoints__c
			FROM missouri.ods.TM_Cust cust
				JOIN #SSBID ssbid ON ssbid.SSID = CONCAT(cust.acct_id,':',cust.cust_name_id)
			WHERE ssbid.SSB_CRMSYSTEM_PRIMARY_FLAG = 1
		 )points ON points.SSB_CRMSYSTEM_ACCT_ID = a.SSB_CRMSYSTEM_ACCT_ID
*/

/*=======================================================
							STH
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Football_STH__c] = CASE WHEN tkt.SSB_CRMSYSTEM_ACCT_ID IS NULL THEN 0 ELSE 1 END 
FROM dbo.account_custom a
	LEFT JOIN #Ticketing tkt ON tkt.SSB_CRMSYSTEM_ACCT_ID = a.SSB_CRMSYSTEM_ACCT_ID
								AND CurrentSTH = 1


/*=======================================================
						STH ROOKIE
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Football_Rookie__c] = CASE WHEN py.SSB_CRMSYSTEM_ACCT_ID IS NULL AND cy.SSB_CRMSYSTEM_ACCT_ID IS NOT NULL THEN 1 ELSE 0 END 
FROM dbo.account_custom a
	LEFT JOIN #Ticketing cy ON cy.SSB_CRMSYSTEM_ACCT_ID = a.SSB_CRMSYSTEM_ACCT_ID
								AND cy.CurrentSTH = 1
	LEFT JOIN #Ticketing py ON py.SSB_CRMSYSTEM_ACCT_ID = a.SSB_CRMSYSTEM_ACCT_ID
								AND py.PriorSTH = 1


/*=======================================================
					PARTIAL BUYER
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Football_Partial__c] = CASE WHEN tkt.SSB_CRMSYSTEM_ACCT_ID IS NULL THEN 0 ELSE 1 END 
FROM dbo.account_custom a
	LEFT JOIN #Ticketing tkt ON tkt.SSB_CRMSYSTEM_ACCT_ID = a.SSB_CRMSYSTEM_ACCT_ID
								AND PartialPlan = 1


EXEC  [dbo].[sp_CRMLoad_Account_ProcessLoad_Criteria]


GO
