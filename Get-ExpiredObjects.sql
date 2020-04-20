-********************************************************
--*                                                      *
--*   Copyright (C) Microsoft. All rights reserved.      *
--*   Created on 4/30/2010  (deanpa)                     *
--*   Version: FIM 2010 RTM Update1                      *
--*   Compatibility:  Should work at least back to       *
--*     FIM 2010 RC1.  Forward compatibility is not      *
--*     guaranteed.                                      *
--********************************************************
USE FIMService
GO

/*-----------------------------------------------------------------------------
*      At this time, the only Object that FIM stamps an ExpirationTime on
*      is a Request object.   The Date stamped is a future date which defaults
*      to 30 days from the day the Request has completed all of its processing.
*      This date can be modified by the creation/update of this Out of box Object
*      SystemResourceRetentionConfiguration and its Attribute [RetentionPeriod]
*
*---------------------------------------------------------------------------*/    
 
DECLARE @currentTime DATETIME,
        @expirationTimeAttributeKey SMALLINT,
        @numberExpiredRequestObjects BIGINT,
        @requestObjectTypeKey SMALLINT,
        @retentionPeriodAttributeKey SMALLINT,
        @retentionPeriodInDays INTEGER,
        @systemResourceRetentionConfigurationObjectTypeKey SMALLINT;
       
SELECT  @currentTime = GETUTCDATE(),
        @expirationTimeAttributeKey = [fim].[AttributeKeyFromName](N'ExpirationTime'),
        @requestObjectTypeKey = [fim].[ObjectTypeKeyFromName](N'Request'),
        @retentionPeriodAttributeKey = [fim].[AttributeKeyFromName](N'RetentionPeriod'),
        @systemResourceRetentionConfigurationObjectTypeKey = [fim].[ObjectTypeKeyFromName](N'SystemResourceRetentionConfiguration');
       
       
/*-----------------------------------------------------------------------------
*      This give you the Request Object Retention Period in days
*---------------------------------------------------------------------------*/    
SELECT @retentionPeriodInDays = ValueInteger
FROM [fim].[ObjectValueInteger]
WHERE
        [ObjectTypeKey] = @systemResourceRetentionConfigurationObjectTypeKey
    AND [AttributeKey]  = @retentionPeriodAttributeKey
SELECT @retentionPeriodInDays AS [RequestObjectRetentionPeriodInDays]
       
/*-----------------------------------------------------------------------------
*      This give you the number of Requests that have been stamped with
*      the ExpirationTime attribute.
*---------------------------------------------------------------------------*/    
 
SELECT COUNT(*) AS [TotalRequestsThatAreFinalAndWillExpireInTheFuture]
FROM [fim].[ObjectValueDateTime]
WHERE  
        [ObjectTypeKey] = @requestObjectTypeKey
    AND [AttributeKey] = @expirationTimeAttributeKey
   
/*-----------------------------------------------------------------------------
*      This give you the number of Requests that have been stamped and the
*      Expiration time is in the past.  These Requests will be cleaned up by the
*      FIM_DeleteExpiredSystemObjectsJob.
*---------------------------------------------------------------------------*/    
 
SELECT @numberExpiredRequestObjects = COUNT(*)
FROM [fim].[ObjectValueDateTime]
WHERE  
        [ObjectTypeKey] = @requestObjectTypeKey
    AND [AttributeKey] = @expirationTimeAttributeKey
    AND [ValueDateTime] <= @currentTime;

IF(@numberExpiredRequestObjects > 0 OR 1 = 1)
BEGIN
    SELECT N'There are ' + CAST(@numberExpiredRequestObjects AS NVARCHAR(19)) + ' Expired Request Objects in your system that exceed the configured retention period.' +
            ' Make sure the SQL Server Agent Job [FIM_DeleteExpiredSystemObjectsJob] is enabled and' +
            ' running successfully.' AS [ExpiredRequestStatus]
END
ELSE
BEGIN
    SELECT N'There are no Expired Requests in your system at this time.' AS [ExpiredRequestStatus]
END
   