SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE PROCEDURE [wrk].[sp_Contact_Custom]
AS 

--Custom Fields in SOW: Last Ticket Purchase Date
--Last Donation Date
--Donor Warning Flag
--Priority Points
--FB STH Flag
--FB ST Rookie Flag
--FB Parital Plan Holder Flag
--Sport TBD Ticket Holder Flag
--Sport TBD Ticket Rookie Flag
--Sport TBD Partial Plan Holder Flag
--Other Ticketmaster Ticketing (3x)
--Other Ticketmaster Donations (3x)

MERGE INTO dbo.Contact_Custom Target
USING dbo.Contact source
ON source.[SSB_CRMSYSTEM_CONTACT_ID] = target.[SSB_CRMSYSTEM_CONTACT_ID]
WHEN NOT MATCHED BY TARGET THEN
INSERT ([SSB_CRMSYSTEM_ACCT_ID], [SSB_CRMSYSTEM_CONTACT_ID]) VALUES (source.[SSB_CRMSYSTEM_ACCT_ID], Source.[SSB_CRMSYSTEM_CONTACT_ID])
WHEN NOT MATCHED BY SOURCE THEN
DELETE ;

/*=======================================================
					Dimcustomer Temp
=======================================================*/

SELECT SSB_CRMSYSTEM_CONTACT_ID 
	  ,SSB_CRMSYSTEM_PRIMARY_FLAG
	  ,ssbid.SourceSystem
	  ,ssbid.SSID
	  ,dc.AccountId
	  ,dc.DimCustomerId
INTO #SSBID
FROM Missouri.dbo.dimcustomerssbid ssbid (NOLOCK)
	JOIN Missouri.dbo.dimcustomer dc (NOLOCK)
		ON dc.DimCustomerId = ssbid.DimCustomerId

CREATE INDEX IX_CONTACT ON #SSBID (SSB_CRMSYSTEM_CONTACT_ID)
CREATE INDEX IX_SOURCE	ON #SSBID (SourceSystem)
CREATE INDEX IX_SSID	ON #SSBID (SSID)
CREATE INDEX IX_AccountID	ON #SSBID (AccountID)
CREATE INDEX IX_DimCustomerID	ON #SSBID (DimCustomerID)


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

SELECT SSB_CRMSYSTEM_CONTACT_ID
	  ,CurrentSTH
	  ,PriorSTH
	  ,PartialPlan
INTO #Ticketing
FROM (  SELECT ssbid.SSB_CRMSYSTEM_CONTACT_ID
			  ,MAX(CASE WHEN fb.IsCurrentSeason = 1 AND fts.DimTicketTypeId = 5 THEN 1 ELSE 0 END) CurrentSTH	-- 20180524 jbarberio OLD -> SUM(CASE WHEN fb.IsCurrentSeason = 1 AND fts.DimTicketTypeId = 5 THEN 1 ELSE 0 END) CurrentSTH
			  ,MAX(CASE WHEN fb.IsCurrentSeason = 0 AND fts.DimTicketTypeId = 5 THEN 1 ELSE 0 END) PriorSTH		-- 20180524 jbarberio OLD -> SUM(CASE WHEN fb.IsCurrentSeason = 0 AND fts.DimTicketTypeId = 5 THEN 1 ELSE 0 END) PriorSTH
			  ,MAX(CASE WHEN fb.IsCurrentSeason = 1 AND fts.DimTicketTypeId = 6 THEN 1 ELSE 0 END) PartialPlan	-- 20180524 jbarberio OLD -> SUM(CASE WHEN fb.IsCurrentSeason = 1 AND fts.DimTicketTypeId = 6 THEN 1 ELSE 0 END) PartialPlan
		FROM missouri.dbo.FactTicketSales fts
			JOIN #Seasons_FB fb ON fb.dimseasonid = fts.DimSeasonId
			JOIN #SSBID ssbid ON ssbid.DimCustomerId = fts.DimCustomerId
		GROUP BY ssbid.SSB_CRMSYSTEM_CONTACT_ID
	 )x
WHERE CurrentSTH	= 1
	 OR PriorSTH	= 1
	 OR PartialPlan = 1





/*=======================================================
				dbo.sp_CRMProcess_ConcatIDs
=======================================================*/

EXEC dbo.sp_CRMProcess_ConcatIDs 'Contact'

/*=======================================================
						SSID WINNER
=======================================================*/

UPDATE a
SET SSID_Winner = ssbid.[SSID], a.SSB_CRMSystem_SSIDWinnerSourceSystem__c = ssbid.SourceSystem	 
FROM [dbo].Contact_Custom a
	JOIN #SSBID ssbid ON ssbid.[SSB_CRMSYSTEM_CONTACT_ID] = [a].[SSB_CRMSYSTEM_CONTACT_ID]
WHERE ssbid.SSB_CRMSYSTEM_PRIMARY_FLAG = 1


/*=======================================================
					LAST PURCHASE DATE
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c] = CAST(ssbid.transdate AS DATE) 
FROM 
dbo.contact_custom a
JOIN
		(SELECT  ssb.ssb_crmsystem_contact_id, MAX(dd.CalDate) transdate 
		 FROM #SSBID ssb 
			JOIN missouri.dbo.FactTicketSales fts ON ssb.DimCustomerId = fts.DimCustomerId
			JOIN missouri.dbo.dimdate dd ON dd.dimdateid = fts.DimDateId_OrigSale
		 GROUP BY ssb.SSB_CRMSYSTEM_CONTACT_ID
		 ) ssbid
ON ssbid.ssb_crmsystem_contact_id = a.ssb_crmsystem_contact_id

/*=======================================================
					Last Donation Date
=======================================================*/

UPDATE a
SET a.SSB_CRMSYSTEM_Last_Donation_Date__c = MaxDonationDate
FROM dbo.Contact_custom a
JOIN (
	SELECT dc.SSB_CRMSYSTEM_CONTACT_ID, CAST(MAX(don.donation_paid_datetime) AS DATE) MaxDonationDate
	FROM (SELECT * FROM Missouri.dbo.vwDimCustomer_ModAcctId 
		WHERE SourceSystem = 'TM') dc
	JOIN Missouri.ods.TM_Donation don ON dc.AccountId = don.apply_to_acct_id
	GROUP BY dc.SSB_CRMSYSTEM_CONTACT_ID
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID



/*=======================================================
						DONOR FLAG
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Donor_Warning__c] = ISNULL(b.IsDonor,0)
FROM dbo.Contact_custom a
LEFT JOIN (
	SELECT dc.SSB_CRMSYSTEM_CONTACT_ID, '1' AS IsDonor
	FROM (SELECT * FROM Missouri.dbo.vwDimCustomer_ModAcctId 
		WHERE SourceSystem = 'TM') dc
	JOIN Missouri.ods.TM_Donation don ON dc.AccountId = don.apply_to_acct_id
	WHERE drive_year > '2015' -- need to remove hard coded year
	GROUP BY dc.SSB_CRMSYSTEM_CONTACT_ID
	) b ON a.SSB_CRMSYSTEM_CONTACT_ID = b.SSB_CRMSYSTEM_CONTACT_ID

/*
UPDATE a 
SET [SSB_CRMSYSTEM_Donor_Warning__c] = CASE WHEN ssbid.SSB_CRMSYSTEM_CONTACT_ID IS NULL THEN 0 ELSE 1 END
FROM 
dbo.contact_custom a
LEFT JOIN (  SELECT  DISTINCT ssbid.ssb_crmsystem_contact_id
			 FROM #SSBID ssbid 
			 	JOIN missouri.ods.TM_Donation donation ON donation.acct_id = ssbid.AccountID
		  ) ssbid
ON ssbid.ssb_crmsystem_contact_id = a.ssb_crmsystem_contact_id


/*=======================================================
					  PRIORITY POINTS
=======================================================*/

UPDATE a 
SET SSB_CRMSYSTEM_Total_Priority_Points__c = points.SSB_PriorityPoints__c
FROM dbo.contact_custom a
	JOIN (  SELECT ssbid.SSB_CRMSYSTEM_CONTACT_ID, cust.points_itd SSB_PriorityPoints__c
			FROM missouri.ods.TM_Cust cust
				JOIN #SSBID ssbid ON ssbid.SSID = CONCAT(cust.acct_id,':',cust.cust_name_id)
			WHERE ssbid.SSB_CRMSYSTEM_PRIMARY_FLAG = 1
		 )points ON points.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID
*/

/*=======================================================
							STH
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Football_STH__c] = CASE WHEN tkt.SSB_CRMSYSTEM_CONTACT_ID IS NULL THEN 0 ELSE 1 END 
FROM dbo.contact_custom a
	LEFT JOIN #Ticketing tkt ON tkt.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID
								AND CurrentSTH = 1

/*=======================================================
						STH ROOKIE
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Football_Rookie__c] = CASE WHEN py.SSB_CRMSYSTEM_CONTACT_ID IS NULL AND cy.SSB_CRMSYSTEM_CONTACT_ID IS NOT NULL THEN 1 ELSE 0 END 
FROM dbo.contact_custom a
	LEFT JOIN #Ticketing cy ON cy.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID
								AND cy.CurrentSTH = 1
	LEFT JOIN #Ticketing py ON py.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID
								AND py.PriorSTH = 1

/*=======================================================
					PARTIAL BUYER
=======================================================*/

UPDATE a 
SET [SSB_CRMSYSTEM_Football_Partial__c] = CASE WHEN tkt.SSB_CRMSYSTEM_CONTACT_ID IS NULL THEN 0 ELSE 1 END 
FROM dbo.contact_custom a
	LEFT JOIN #Ticketing tkt ON tkt.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID
								AND PartialPlan = 1


EXEC  [dbo].[sp_CRMLoad_Contact_ProcessLoad_Criteria]






/*
ONE TIME UPDATE TO OWNERID

select dcCRM.SSID, pcu.id, MIN(pr.SS_ranking) SS_Rank
INTO #Temp
FROM [dbo].[vwDimCustomer_ModAcctId] dcTM --TM record
INNER JOIN missouri.ods.TM_CustRep c (NOLOCK) --Reps Associated
    ON dcTM.sourceSystem = 'TM' AND dcTM.AccountId = c.acct_id and dcTM.customerTYpe = 'Primary'
INNER JOIN [dbo].[vwDimCustomer_ModAcctId] dcCRM --SFDC Records
    ON dcTM.SSB_CRMSYSTEM_CONTACT_ID = dcCRM.SSB_CRMSYSTEM_CONTACT_ID 
    AND dcTM.SourceSystem = 'TM'
    AND dcCRM.SourceSystem = 'Mizzou PC_SFDC Contact'
INNER JOIN missouri.[mdm].[PrimaryFlagRanking_Contact] pr --MDM Ranking of TM Records to select winning rep where multiple TM records exist
    ON dcTM.DimcustomerId = pr.DimcustomerId 
INNER JOIN prodcopy.contact pcc ON dcCRM.ssid = pcc.id --To compare to what's currently in prodcopy for ownerid
INNER JOIN prodcopy.[User] pcu ON pcu.tm_user_id__c = c.rep_user_id --to join the TM Cust Rep to the SFDC User
WHERE pcc.ownerid = '0056A000000Mm7hQAC'--Only where ownerid = SSB
GROUP BY dcCRM.SSID, pcu.id
ORDER BY 1,3

--find where there is more than one owner based on TM
SELECT ssid, COUNT(*)
FROM #Temp t
GROUP BY ssid
HAVING COUNT(*) > 1

SELECT ssid AS Id, Id AS OwnerID FROM #Temp
WHERE ssid NOT IN (
'0036A00000AajBTQAZ',
'0036A00000AalqxQAB',
'0036A00000AaqJkQAJ',
'0036A00000AauiXQAR',
'0036A00000AawCwQAJ',
'0036A00000Ab06dQAB',
'0036A00000Ab7l7QAB'
)*/
GO
