CREATE TABLE [dbo].[Account_Custom]
(
[SSB_CRMSYSTEM_ACCT_ID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SSID_Winner] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TM_Ids] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DimCustIDs] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AccountID] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SSB_CRMSYSTEM_Last_Ticket_Purchase_Date__c] [date] NULL,
[SSB_CRMSYSTEM_Last_Donation_Date__c] [date] NULL,
[SSB_CRMSYSTEM_Donor_Warning__c] [bit] NULL,
[SSB_CRMSYSTEM_Total_Priority_Points__c] [numeric] (18, 2) NULL,
[SSB_CRMSYSTEM_Football_STH__c] [bit] NULL,
[SSB_CRMSYSTEM_Football_Rookie__c] [bit] NULL,
[SSB_CRMSYSTEM_Football_Partial__c] [bit] NULL,
[SSB_CRMSystem_SSIDWinnerSourceSystem__c] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
ALTER TABLE [dbo].[Account_Custom] ADD CONSTRAINT [PK_Account_Custom] PRIMARY KEY CLUSTERED  ([SSB_CRMSYSTEM_ACCT_ID])
GO
