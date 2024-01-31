-------------------1------------------------
exec dbo.context_info_set 'mass_update_spb'
SELECT  dbo.fn_context_info_get()
--отключаем триггеры, выполняем 1 раз

SELECT c.code, so.enddate
  FROM opendb.dbo.servicesopen so
  JOIN opendb.dbo.client c ON c.client_id = so.clientid
 WHERE so.serviceid = 2 --Указываем id сервиса
  AND c.code IN ('12345') --Указываем список счетов

UPDATE so
   SET so.enddate = '2023.12.01' --Указываем дату окончания
    --  ,so.comments = '' --Указываем коммент, если необходимо
  FROM opendb.dbo.servicesopen so
  JOIN opendb.dbo.client c ON c.client_id = so.clientid
 WHERE so.serviceid = 2 --Указываем id сервиса
  AND c.code IN ('12345') --Указываем список счетов