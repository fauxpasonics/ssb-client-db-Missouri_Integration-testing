SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [MERGEPROCESS_New].[sp_ReceiveResults]
  @PK_QueueID VARCHAR(50)
  , @ErrorCode varchar(8000)
  , @ErrorDescription varchar(8000)
  ,@Master_ID varchar(50)
  ,@Slave_ID varchar(50)
  ,@ObjectType NVARCHAR(50)
AS 
BEGIN
--MergeProcess.sp_ReceiveResults 42952, '',''

INSERT INTO MergeProcess_New.[ReceiveResults]
        ( [PK_MergeID] ,
          [ErrorCode] ,
          [ErrorDescription] ,
          [DateInserted],
		  Winning_ID
		  ,Losing_ID
		  ,ObjectType
        )
VALUES  ( @PK_QueueID , -- PK_QueueID - int
          @ErrorCode , -- ErrorCode - varchar(8000)
          @ErrorDescription , -- ErrorDescription - varchar(8000)
          GETDATE()  -- DateInserted - datetime
		  ,@Master_ID
		  ,@Slave_ID
		  ,@ObjectType
        )

UPDATE a
SET MergeComplete = 1
,MergeComment = 'Merge Completed by SSB ' + CAST(CAST(GETDATE() as DATE) as varchar)
FROM [MERGEProcess_New].[DetectedMerges] a
JOIN [MERGEProcess_New].[Queue] b on a.PK_MergeID =b.FK_MergeID
WHERE b.Winning_ID = @Master_ID
AND b.Losing_ID = @Slave_ID 
AND ISNULL(@ErrorCode,'') = ''



--NEW CODE for Force Merge Functionality --TCF 09112017
UPDATE MERGEPROCESS_New.ForceMerge
SET Complete = 1, CompletedDate = GETDATE(), CompletionNotes = 'Successfully Completed'
FROM  MERGEPROCESS_New.ForceMerge a
INNER JOIN MERGEPROCESS_New.[Queue] B
ON B.FK_MergeID = a.FK_MergeID
JOIN [MERGEPROCESS_New].[ReceiveResults] C
    ON C.Losing_ID = B.Losing_ID 
    AND c.Winning_ID = b.Winning_ID
    AND c.ObjectType = b.ObjectType --Needs to be added to SSIS
WHERE c.ErrorDescription =''
AND a.Complete = 0

UPDATE MERGEPROCESS_New.ForceMerge
SET Complete = 1, CompletedDate = GETDATE(), CompletionNotes = 'Force Expired without Merging'
FROM MERGEPROCESS_New.ForceMerge 
WHERE Complete = 0 AND CreatedDate < GETDATE() - 14

END


GO
