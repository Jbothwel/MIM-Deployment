  

USE FIMService

GO

----------------------------------------------------------------------------------------

DECLARE @currentTime DATETIME,

        @expirationTimeAttributeKey SMALLINT,

        @numberExpiredRequestObjects BIGINT,

        @requestObjectTypeKey SMALLINT

-----------------------------------------------------------------------------------------

SELECT  @currentTime = GETUTCDATE(),

@expirationTimeAttributeKey = [fim].[AttributeKeyFromName](N'ExpirationTime'),

@requestObjectTypeKey = [fim].[ObjectTypeKeyFromName](N'Request')



--------------------------------------------------------------------------------------------

SELECT @numberExpiredRequestObjects = COUNT(*)

FROM [fim].[ObjectValueDateTime]

WHERE   

        [ObjectTypeKey] = @requestObjectTypeKey

    AND [AttributeKey] = @expirationTimeAttributeKey

    AND [ValueDateTime] <= @currentTime;



------------------------------------------------------------------------------------------

while (@numberExpiredRequestObjects > 0)

begin

exec fim.DeleteExpiredSystemObjects;



SELECT @numberExpiredRequestObjects = COUNT(*)

FROM [fim].[ObjectValueDateTime]

WHERE   

[ObjectTypeKey] = @requestObjectTypeKey

AND [AttributeKey] = @expirationTimeAttributeKey

AND [ValueDateTime] <= @currentTime;



PRINT N'There are ' + CAST(@numberExpiredRequestObjects AS NVARCHAR(19)) + ' expired requests remaining to delete'

end

?[9/13 9:36 AM] Marcus Adams
    There is the SQL script but it runs in a loop and it does 20k at a time 
?[9/13 9:36 AM] Marcus Adams
    but give me a sec
?[9/13 9:37 AM] Marcus Adams
    getting more info
?[9/13 9:38 AM] Marcus Adams
    SO to do this it will put a big strain on the transaction log
?[9/13 9:38 AM] Marcus Adams
    so from the SQL side we'd need someone to watch that
?[9/13 9:41 AM] Marcus Adams
    
We can change the line

------------------------------------------------------------------------------------------

while (@numberExpiredRequestObjects > 0)


?[9/13 9:41 AM] Marcus Adams
    
to

------------------------------------------------------------------------------------------

while (@numberExpiredRequestObjects > 15000000)


