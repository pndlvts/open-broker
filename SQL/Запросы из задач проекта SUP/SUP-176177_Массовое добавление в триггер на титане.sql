DECLARE @login VARCHAR(40), @vmname VARCHAR(20);
DECLARE triggggered CURSOR FOR SELECT * FROM [tmpdatadb].[dbo].[timtrig]
use [logdb];
       OPEN triggggered
             FETCH NEXT FROM triggggered INTO @login, @vmname
                    WHILE @@FETCH_STATUS = 0
                           BEGIN
                                  EXEC SetAccessToUser
                                  @usr = @login,
                                  @hostname = @vmname,
                                  @appname = 'Microsoft SQL Server' 
				       FETCH NEXT FROM triggggered INTO @login, @vmname
                           END
       CLOSE triggggered
DEALLOCATE triggggered