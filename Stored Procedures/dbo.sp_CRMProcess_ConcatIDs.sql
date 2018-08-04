SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 -- Author name: Jeff Barberio

-- Created date: 7/1/2018

-- Purpose: Create Concatenated ID Fields for CRM

-- Copyright © 2018, SSB, All Rights Reserved

-------------------------------------------------------------------------------

-- Modification History --

-- 7/5/2018: Abbey Meitin

	-- Change notes: Added filter to exclude non-primary ids
	
	-- Peer reviewed by: Jeff Barberio
	
	-- Peer review notes: 
	
	-- Peer review date: 7/5/2018
	
	-- Deployed by:
	
	-- Deployment date:
	
	-- Deployment notes:

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
 
CREATE PROCEDURE [dbo].[sp_CRMProcess_ConcatIDs]
    @ObjectType VARCHAR(50)
AS --DECLARE @ObjectType varchar(50) SET @ObjectType = 'contact'
 
 
/*
EXEC [dbo].[sp_CRMProcess_ConcatIDs] 'Account'
Select * from wrk.customerWorkingList
EXEC [dbo].[sp_CRMProcess_ConcatIDs] 'Contact'
Select * from stg.Contact
*/
 
--DECLARE @ObjectType varchar(50) SET @ObjectType = 'contact'
--DROP TABLE #tmpDimCustIDs
 
    SELECT  CASE WHEN @ObjectType = 'Account' THEN a.SSB_CRMSYSTEM_ACCT_ID
                 ELSE a.[SSB_CRMSYSTEM_CONTACT_ID]
            END GUID 
           ,CAST(DimCustomerId AS VARCHAR(100)) AS DimCustomerID 
           ,CAST(SSID AS VARCHAR(50)) AS SSID 
           ,a.SourceSystem
           ,a.CustomerType
    INTO    #tmpDimCustIDs
    FROM    dbo.vwDimCustomer_ModAcctId AS a
        JOIN dbo.Contact contact ON contact.SSB_CRMSYSTEM_CONTACT_ID = a.SSB_CRMSYSTEM_CONTACT_ID
    WHERE   ( 1 = 1 )
            AND SourceSystem NOT LIKE '%SFDC%'
            AND SourceSystem NOT LIKE '%CRM%';
 
    TRUNCATE TABLE stg.tbl_CRMProcess_NonWinners;
 
    INSERT  INTO [stg].tbl_CRMProcess_NonWinners
            ( [GUID] ,
              [DimCustomerID] ,
              [SourceSystem] ,
              [SSID] ,
              CustomID1 ,
              Primary_Flag ,
              [CustomerType]
            )
            SELECT  GUID ,
                    a.DimCustomerID ,
                    a.[SourceSystem] ,
                    CAST(a.SSID AS VARCHAR(50)) AS SSID ,
                    b.AccountId CustomID1 ,
                    SSB_CRMSYSTEM_ACCT_PRIMARY_FLAG , 
                    a.CustomerType
            FROM    #tmpDimCustIDs a
                    INNER JOIN dbo.[vwDimCustomer_ModAcctId] b ON [b].[DimCustomerID] = [a].[DimCustomerID]
            WHERE   1 = 1;
 
    TRUNCATE TABLE stg.[tbl_CRMProcess_ConcatIDs];
 
    INSERT  INTO stg.tbl_CRMProcess_ConcatIDs
            ( GUID ,
              ConcatIDs1 ,
              ConcatIDs2 ,
              ConcatIDs3 ,
              ConcatIDs4 ,
              ConcatIDs5 ,
              DimCust_ConcatIDs
            )
            SELECT  [GUID] ,
                    ISNULL(LEFT(STUFF(( SELECT  ', ' + SSID AS [text()]
                                        FROM    stg.tbl_CRMProcess_NonWinners TM
                                        WHERE   TM.[GUID] = z.[GUID]
                                                AND TM.[SourceSystem] = 'TM'
                                                AND TM.CustomerType = 'Primary' --added 7/5/2018 by Ameitin
                                        ORDER BY CAST(Primary_Flag AS INT) DESC ,
                                                SSID
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, ''), 8000), '') AS ConcatIDs1 ,
                    ISNULL(LEFT(STUFF(( SELECT  ', ' + CustomID1 AS [text()]
                                        FROM    ( SELECT    CustomID1 ,
                                                            [GUID] ,
                                                            MAX(CAST(Primary_Flag AS INT)) Primary_Flag
                                                  FROM      stg.tbl_CRMProcess_NonWinners
                                                  WHERE     [SourceSystem] = 'TM'
                                                  AND CustomerType = 'Primary' --added 7/5/2018 by Ameitin
                                                  GROUP BY  CustomID1 ,
                                                            [GUID]
                                                ) acct
                                        WHERE   acct.[GUID] = z.[GUID]
                                        ORDER BY Primary_Flag DESC ,
                                                ', ' + CustomID1
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, ''), 8000), '') AS ConcatIDs2 ,
                    '' ConcatIDs3 ,
                    '' ConcatIDs4 ,
                    '' ConcatIDs5 ,
                    LEFT(STUFF(( SELECT ', ' + DimCustomerID AS [text()]
                                 FROM   #tmpDimCustIDs DimCust
                                 WHERE  DimCust.GUID = z.GUID
                                 ORDER BY [DimCustomerID]
                               FOR
                                 XML PATH('')
                               ), 1, 1, ''), 8000) AS DimCustID_LoserString
            FROM    ( SELECT DISTINCT
                                GUID
                      FROM      [stg].tbl_CRMProcess_NonWinners) z;
 
 
    IF @ObjectType = 'Account'
        UPDATE  a
        SET     TM_Ids = LEFT(ISNULL(LTRIM([b].[ConcatIDs1]), ''),255) ,
                [AccountId] = ISNULL(LTRIM([b].[ConcatIDs2]), '') ,
                DimCustIDs = ISNULL(LTRIM([b].[DimCust_ConcatIDs]), '')
        FROM    dbo.Account_Custom a
                INNER JOIN stg.[tbl_CRMProcess_ConcatIDs] b ON a.SSB_CRMSYSTEM_ACCT_ID = b.GUID;
 
    IF @ObjectType = 'Contact'
        UPDATE  a
        SET     TM_Ids = LEFT(ISNULL(LTRIM([b].[ConcatIDs1]), ''),255) ,
                [AccountId] = ISNULL(LTRIM([b].[ConcatIDs2]), '') ,
                DimCustIDs = ISNULL(LTRIM([b].[DimCust_ConcatIDs]), '')
        FROM    dbo.[Contact_Custom] a
                INNER JOIN stg.[tbl_CRMProcess_ConcatIDs] b ON a.[SSB_CRMSYSTEM_CONTACT_ID] = b.GUID;

GO
