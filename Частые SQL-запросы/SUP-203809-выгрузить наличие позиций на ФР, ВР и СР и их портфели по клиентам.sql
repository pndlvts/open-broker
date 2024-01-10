   DECLARE @dt DATE = GETDATE()-1 --100776

   Create table #t(OLD_CLIENTCODE varchar(50))
Insert into #t(OLD_CLIENTCODE) values
('131428'),
('145851'),
('18089'),
('181779'),
('182444'),
('184585'),
('188558'),
('189418'),
('205986'),
('214129'),
('218411'),
('219787'),
('234016'),
('249018'),
('257365'),
('274620'),
('279274'),
('283708'),
('307704'),
('319595'),
('336069'),
('372444'),
('372622'),
('375699'),
('389451'),
('392465'),
('406630'),
('442192'),
('467056'),
('480821'),
('496356'),
('64831'),
('71330'),
('76117'),
('81631'),
('87569'),
('91446')


SELECT
   t.OLD_CLIENTCODE OLD_CLIENTCODE
   ,Count(CASE when ass.market_place_id IN (-106, 6) THEN name END) [позиции на фр мб] 
   ,Count(CASE when ass.market_place_id IN (-117, 17) THEN name END) [позиции на вр мб] 
   ,Count(CASE when ass.market_place_id IN (-102, 2) THEN name END) [позиции на СР FORTS] 
   ,SUM(CASE when ass.market_place_id IN (-106, 6) THEN ass.asset_plan END) [стоимость портфеля на фр мб] 
   ,SUM(CASE when ass.market_place_id IN (-117, 17) THEN ass.asset_plan END) [стоимость портфеля на вр мб] 
   ,SUM(CASE when ass.market_place_id IN (-102, 2) THEN ass.asset_plan END) [стоимость портфеля на СР FORTS] 
--   ,SUM(CASE when ass.market_place_id IN (-102, 2) THEN ass.asset_plan END) [стоимость всех активов] 
--,ass.market_place_id
--   ,ass.asset_plan 
--   ,ass.fin_instrument_id
   INTO #res
FROM #t t
   LEFT JOIN opendb.dbo.client c ON t.OLD_CLIENTCODE=c.code--bcode=c.code
   LEFT JOIN [bd-srv-dwh].[OpenDWH].[detail_stage].rem_client_asset_by_market_place ass 
      on c.client_id = ass.client_id and ass.[date] = @dt AND ass.market_place_id IN (2,6,17, -102, -106, -117) AND ass.fin_instrument_id<>810
   LEFT JOIN [bd-srv-dwh].[OpenDWH].[detail_stage].[dim_fin_instruments] dfi ON dfi.fin_instrument_id= ass.fin_instrument_id --AND dfi.name<>'Рубли РФ'
   where 1=1
   --AND t.OLD_CLIENTCODE='102263'  
  GROUP BY t.OLD_CLIENTCODE--,c.quik_forts_code

--SELECT * FROM #res

SELECT OLD_CLIENTCODE
      --,quik_forts_code
      ,CASE WHEN [позиции на фр мб]>0 THEN 'да' else '' END [позиции на фр мб]
,[стоимость портфеля на фр мб] 
      ,CASE WHEN [позиции на вр мб]>0 THEN 'да' else '' END [позиции на вр мб]
,[стоимость портфеля на вр мб] 
      ,CASE WHEN [позиции на СР FORTS] >0 THEN 'да' else '' END [позиции на СР FORTS] 
,[стоимость портфеля на СР FORTS] 
   FROM #res
--   select * FROM tmpdatadb.dbo.[SUP-203499] --1366
