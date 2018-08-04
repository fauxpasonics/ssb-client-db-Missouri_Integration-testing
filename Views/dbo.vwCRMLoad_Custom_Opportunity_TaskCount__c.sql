SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create VIEW [dbo].[vwCRMLoad_Custom_Opportunity_TaskCount__c]

AS

WITH CTE AS (
SELECT opp.id, COUNT(task.whatid) Task_Count__c
FROM Missouri_Reporting.prodcopy.Opportunity opp
LEFT JOIN Missouri_Reporting.prodcopy.Task task
ON task.WhatId = opp.Id
WHERE task.id IS NOT NULL AND task.IsClosed = 1 AND opp.IsDeleted = 0
GROUP BY opp.id)


SELECT cte.* FROM Missouri_Reporting.prodcopy.Opportunity opp
INNER JOIN CTE cte ON cte.Id = opp.Id
WHERE cte.Task_Count__c != ISNULL(opp.Task_Count__c,0)
                 ;
GO
