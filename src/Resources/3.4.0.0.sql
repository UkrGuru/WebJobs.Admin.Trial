BEGIN /*** WJbActions ***/
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbActions_Del]
    @Data int
AS
DELETE FROM WJbActions
WHERE (ActionId = @Data)
';

EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbActions_Get]
    @Data int
AS
SELECT ActionId, ActionName, ActionType, ActionMore
FROM WJbActions 
WHERE ActionId = @Data
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
';

EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbActions_Grd]
AS
SELECT ActionId, ActionName, ActionType, ActionMore
FROM WJbActions
WHERE (Disabled = 0)
ORDER BY ActionName
FOR JSON PATH
';

EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbActions_Ins]
	@Data nvarchar(max) 
AS
INSERT INTO WJbActions (ActionName, ActionType, ActionMore)
SELECT ActionName, ActionType, ActionMore 
FROM OPENJSON(@Data) 
WITH (ActionName nvarchar(100), ActionType nvarchar(255), ActionMore nvarchar(max))
';

EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbActions_Upd]
	@Data nvarchar(max) 
AS
UPDATE R
SET ActionName = D.ActionName, ActionType = D.ActionType, ActionMore = D.ActionMore
FROM WJbActions R
CROSS JOIN (SELECT * FROM OPENJSON(@Data) 
    WITH (ActionName nvarchar(100), ActionType nvarchar(255), ActionMore nvarchar(max))) D
WHERE R.ActionId = JSON_VALUE(@Data,''$.ActionId'')
';
END

BEGIN /*** WJbRules ***/
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbRules_Del]
    @Data int
AS
DELETE FROM WJbRules
WHERE (RuleId = @Data)
';
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbRules_Get]
    @Data int
AS
SELECT R.*, A.ActionName, A.ActionMore
FROM WJbRules R
INNER JOIN WJbActions A ON R.ActionId = A.ActionId
WHERE (RuleId = @Data)
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
';
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbRules_Grd]
AS
SELECT R.*, A.ActionName
FROM WJbRules R
INNER JOIN WJbActions A ON R.ActionId = A.ActionId
FOR JSON PATH
';
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbRules_Ins]
	@Data nvarchar(max) 
AS
INSERT INTO WJbRules (RuleName, RulePriority, ActionId, RuleMore, Disabled)
SELECT RuleName, RulePriority, ActionId, RuleMore, ISNULL(Disabled, 0) Disabled
FROM OPENJSON(@Data) 
WITH (RuleName nvarchar(100), RulePriority tinyint, ActionId int, RuleMore nvarchar(max), Disabled bit)
';
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbRules_Upd]
	@Data nvarchar(max) 
AS
DECLARE @RuleId int = JSON_VALUE(@Data,''$.RuleId'');

UPDATE R
SET RuleName = D.RuleName
    ,RulePriority = D.RulePriority
    ,ActionId = D.ActionId
    ,RuleMore = D.RuleMore
    ,Disabled = D.Disabled
FROM WJbRules R
CROSS JOIN (SELECT * FROM OPENJSON(@Data) 
    WITH (RuleName nvarchar(100), RulePriority tinyint, ActionId int, RuleMore nvarchar(max), Disabled bit)) D
WHERE R.RuleId = @RuleId
';
END

BEGIN /*** WJbJobs ***/
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbJobs_Grd]
    @Data varchar(400)
AS
DECLARE @Today datetime, @PageIndex int, @PageSize int 
SET @Today = ISNULL(CAST(JSON_VALUE(@Data, ''$.Today'') AS date), CAST(GETDATE() AS date))
SET @PageIndex = ISNULL(CAST(JSON_VALUE(@Data, ''$.PageIndex'') AS int), 1) 
SET @PageSize = ISNULL(CAST(JSON_VALUE(@Data, ''$.PageSize'') AS int), 100)
--SELECT @Date, @PageIndex, @PageSize

DECLARE @Qry varchar(4000), @Exp varchar(1000) = '''', @Ord varchar(1000) = ''''
SET @Qry = ''SELECT H.JobId, H.JobPriority, H.Created, H.RuleId, H.Started, H.Finished, R.RuleMore + ISNULL(H.JobMore, ''''{}'''') JobMore, R.RuleName, A.ActionName, H.JobStatus 
FROM (
    SELECT JobId, JobPriority, Created, RuleId, Started, Finished, LEFT(JobMore, 200) JobMore, JobStatus
    FROM WJbHistory
    WHERE Created >= '''''' + CONVERT(varchar, @Today, 112) + '''''' AND Created < '''''' + CONVERT(varchar, DATEADD(DAY, 1, @Today), 112) + 
    '''''' UNION ALL 
    SELECT JobId, JobPriority, Created, RuleId, Started, Finished, LEFT(JobMore, 200) JobMore, JobStatus
    FROM WJbQueue
    ) AS H 
INNER JOIN WJbRules AS R ON H.RuleId = R.RuleId 
INNER JOIN WJbActions AS A ON R.ActionId = A.ActionId '';

SET @Ord = '' ORDER BY H.JobId DESC OFFSET '' + CAST((@PageIndex - 1) * @PageSize AS varchar) + 
    '' ROWS FETCH NEXT '' + CAST(@PageSize AS varchar) + '' ROWS ONLY 
    FOR JSON PATH''

EXEC (@Qry + @Exp + @Ord)
--PRINT (@Qry + @Exp + @Ord)
';
END

BEGIN /*** WJbHistory ***/
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbHistory_Retry]
    @Data int
AS
INSERT INTO WJbQueue (RuleId, JobPriority, JobMore, JobStatus)
SELECT RuleId, 0 JobPriority, JSON_MODIFY(ISNULL(JobMore, ''{}''), ''$.lmsjobid'', null) JobMore, 0 JobStatus
FROM WJbHistory
WHERE (JobId = @Data)

DECLARE @JobId int = SCOPE_IDENTITY()
EXEC WJbQueue_Get @Data

DELETE FROM WJbHistory
WHERE (JobId = @Data)
';
END

BEGIN /*** WJbFiles ***/
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbFiles_Del]
    @Data uniqueidentifier
AS
DELETE FROM WJbFiles
WHERE (Id = @Data)
';

EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbFiles_Get]
    @Data uniqueidentifier
AS
SELECT Id, Created, FileName, FileContent
FROM WJbFiles 
WHERE Id = @Data
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
';

EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbFiles_Grd]
    @Data varchar(200)
AS
-- DECLARE @Search varchar(100) = JSON_VALUE(@Data, ''$.Search'') 
--SET @Id = TRY_CAST(@Search AS uniqueidentifier)
--SET @Today = TRY_CAST(@Search AS date)

DECLARE @Id uniqueidentifier = NULL, @Created datetime = NULL, @PageIndex int, @PageSize int 
SET @Id = TRY_CAST(JSON_VALUE(@Data, ''$.Id'') AS uniqueidentifier) 
SET @Created = TRY_CAST(JSON_VALUE(@Data, ''$.Created'') AS date)
SET @PageIndex = ISNULL(CAST(JSON_VALUE(@Data, ''$.PageIndex'') AS int), 1) 
SET @PageSize = ISNULL(CAST(JSON_VALUE(@Data, ''$.PageSize'') AS int), 100)
--SELECT @Id, @Created, @PageIndex, @PageSize

DECLARE @Qry varchar(4000), @Exp varchar(1000) = '''', @Ord varchar(1000) = ''''
SET @Qry = ''SELECT Id, Created, FileName FROM WJbFiles '';

IF NOT @Id IS NULL
    SET @Exp += '' WHERE Id = '''''' + CONVERT(varchar(50), @Id) + '''''' '';
ELSE IF NOT @Created IS NULL 
    SET @Exp += '' WHERE Created >= '''''' + CONVERT(varchar, @Created, 112) + '''''' AND Created < '''''' + CONVERT(varchar, DATEADD(DAY, 1, @Created), 112) + '''''' '';

SET @Ord = '' ORDER BY Created DESC OFFSET '' + CAST((@PageIndex - 1) * @PageSize AS varchar) + 
    '' ROWS FETCH NEXT '' + CAST(@PageSize AS varchar) + '' ROWS ONLY FOR JSON PATH''

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
EXEC (@Qry + @Exp + @Ord)
';
END

BEGIN /*** WJbLogs ***/
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbLogs_Grd]
    @Data varchar(400)
AS
DECLARE @Today datetime, @PageIndex int, @PageSize int 
SET @Today = ISNULL(CAST(JSON_VALUE(@Data, ''$.Today'') AS date), CAST(GETDATE() AS date))
SET @PageIndex = ISNULL(CAST(JSON_VALUE(@Data, ''$.PageIndex'') AS int), 1) 
SET @PageSize = ISNULL(CAST(JSON_VALUE(@Data, ''$.PageSize'') AS int), 100)
--SELECT @Date, @PageIndex, @PageSize

DECLARE @Qry varchar(4000), @Exp varchar(1000) = '''', @Ord varchar(1000) = ''''
SET @Qry = ''SELECT LogId, Logged, LogLevel, Title, LogMore FROM WJbLogs '';

SET @Exp = ''WHERE Logged >= '''''' + CONVERT(varchar, @Today, 112) + '''''' AND Logged < '''''' + CONVERT(varchar, DATEADD(DAY, 1, @Today), 112) + '''''''';

SET @Ord = '' ORDER BY LogId DESC OFFSET '' + CAST((@PageIndex - 1) * @PageSize AS varchar) + 
    '' ROWS FETCH NEXT '' + CAST(@PageSize AS varchar) + '' ROWS ONLY 
    FOR JSON PATH''

EXEC (@Qry + @Exp + @Ord)
--PRINT (@Qry + @Exp + @Ord)
';

EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbLogs_Grd_Job]
    @Data int
AS
DECLARE @Created datetime = (SELECT TOP 1 Created FROM WJbHistory WHERE JobId = @Data)

SELECT LogId, Logged, LogLevel, Title, LogMore
FROM WJbLogs
WHERE Logged >= @Created AND Logged < DATEADD(DAY, 1, @Created)
AND ISJSON(LogMore) = 1 AND JSON_VALUE(LogMore, ''$.jobId'') = @Data
ORDER BY LogId DESC
FOR JSON PATH
';
END

BEGIN /*** WJbSettings ***/
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbSettings_Del]
	@Data nvarchar(100)
AS
DELETE FROM WJbSettings
WHERE Name = @Data
';
EXEC dbo.sp_executesql @statement = N'
CREATE OR ALTER PROCEDURE [dbo].[WJa_WJbSettings_Grd]
AS
SELECT [Name], [Value] 
FROM WJbSettings
FOR JSON PATH
';
END