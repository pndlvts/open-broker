--loginname вводим в формате OPEN.RU\доменное_имя, если авторизация средствами ОС. Если средствами СУБД, то без open.ru



--Создать нового пользователя на сервере
USE master
CREATE LOGIN [loginname] FROM windows



--Создаем пользователя на баз, даем роли (в большинстве случаев ролей хватает для ДИТ. Не сотрудникам ДИТ даем отдельно к объектам БД, если не акцептовано иное)
CREATE USER [loginname] FROM LOGIN [loginname]
ALTER ROLE [DIT_Analytics] ADD MEMBER [loginname]



-- Доступ/отзыв полномочий к объектам БД
GRANT SELECT ON dbo.client TO [loginname]
DENY SELECT ON dbo.client TO [loginname]



--Доступы юзера
USE master
EXEC sp_helplogins [loginname]



--При доступе на титане добавлять в триггер процей
EXEC SetAccessUser @usr = [loginname], @hostname = <имя_компа>, @appname = 'из какой проги'
--Посмотреть, какие доступы по триггеру уже имеются 
SELECT * FROM LoginHostApp WHERE PrincipalName LIKE 'имя пользователя'



--Если нет доступа на титан после предоставления прав, то через PowerShell на компе пользователя
[System.Net.Sockets.TcpClient]::new("BD-SRV-TITAN", 1433)



--Отключить/включить пользователя
ALTER LOGIN [loginname] disable
ALTER LOGIN [loginname] enable



--Доступ ко всей схеме
GRANT EXEC ON SCHEMA::INOUT TO [loginname]



--Права на коннект, если багануло
GRANT CONNECT TO [loginname]
GO
ALTER USER [loginname] WITH LOGIN = [loginname]



--Место на дисках 
EXEC xp_fixeddrives



--Права на булк лоад и xp_cmdshell
USE master
GRANT EXEC ON xp_cmdshell TO [loginname]
GRANT administer bulk OPERATIONS TO [loginname]