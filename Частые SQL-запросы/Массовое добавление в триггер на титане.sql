DECLARE @login VARCHAR(40), @pc_name  VARCHAR(40)
DECLARE triggger CURSOR FOR SELECT * FROM [tmpdatadb].[dbo].[timtrig] --временная таблица, данные импортированы из xlsx, если у вас в ином виде - делайте как удобно
USE [logdb]
    OPEN triggger
        FETCH NEXT FROM triggger INTO  @login, @pc_name
            WHILE @@FETCH_STSTUS = 0
                BEGIN
                    EXEC SetAccessToUser
                    @usr = @login,
                    @hostname = @pc_name,
                    @appname = 'Microsoft SQL Server' -- Указывайте по необходимости из какого ПО коннект к серверу(Clients, OpenBrokerBO, ОС Windows и тд.) Можно засунуть инфу в курсор
                    FETCH NEXT FROM triggger INTO  @login, @pc_name
                END
    CLOSE triggger
DEALLOCATE triggger