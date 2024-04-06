begin tran
SELECT 
       c.code
      ,c.client_base_id
      ,so.enddate
      ,so.comments
  FROM #tmp2 t
  JOIN opendb.dbo.client c ON c.client_base_id = t.client_base_id
  JOIN opendb.dbo.servicesopen so ON so.clientid = c.client_id
                                  AND so.serviceid = 788
                                  AND so.enddate IS NULL
where c.client_base_id = 1864307
update so
set enddate = '20240401'
  FROM #tmp2 t
  JOIN opendb.dbo.client c ON c.client_base_id = t.client_base_id
  JOIN opendb.dbo.servicesopen so ON so.clientid = c.client_id
                                  AND so.serviceid = 788
                                  AND so.enddate IS NULL
where c.client_base_id = 1864307
SELECT 
       c.code
      ,c.client_base_id
      ,so.enddate
      ,so.comments
  FROM #tmp2 t
  JOIN opendb.dbo.client c ON c.client_base_id = t.client_base_id
  JOIN opendb.dbo.servicesopen so ON so.clientid = c.client_id
                                  AND so.serviceid = 788
                                  AND so.enddate IS NULL
where c.client_base_id = 1864307
rollback tran