exec dbo.context_info_set 'mass_update_spb'
select  dbo.fn_context_info_get()
INSERT INTO dbo.servicesopen (clientid, serviceid, startdate,  comments)
SELECT c.client_id, 786, @dt,  'Ошибка по Дедушкиной оговорке'
 FROM tmpdatadb.dbo.[SUP-201540] p 
   LEFT JOIN  opendb.dbo.client c ON p.client_base_code=c.code