--region DECLARE
DECLARE @max_date DATE = GETDATE()+9999;
DECLARE @cur_date DATE = GETDATE();
DECLARE @rep_date DATE = GETDATE()-1;
--endregion

IF OBJECT_ID('tempdb..#crm') IS NOT NULL
  BEGIN
    DROP TABLE #crm;
  END;

IF OBJECT_ID('tempdb..#depo_codes') IS NOT NULL
  BEGIN
    DROP TABLE #depo_codes;
  END;

CREATE TABLE #crm(cid VARCHAR (15)
                 ,base_code VARCHAR (20)
                 ,code VARCHAR (20)
                 ,vip_mso VARCHAR (2)
                 ,mso VARCHAR (2)
                 ,prem_mso VARCHAR (2)
                 ,vip VARCHAR (2)
                 ,up_code VARCHAR (300)
                 );

CREATE TABLE #depo_codes(code VARCHAR (50)
                        ,obOpen_Code VARCHAR (50)
                        );
  
INSERT INTO #depo_codes (code, obOpen_Code)
SELECT
    c.Code
  , c.obOpen_Code
FROM SATURN.IP_DEPO.dbo.Customers c

INSERT INTO #crm (cid, base_code, code, vip_mso, mso, prem_mso, vip, up_code)
SELECT DISTINCT
       sc.ROW_ID
      ,''
      ,sc.X_OPENDB_CLIENT_CODE
      ,case when MSO_CLIENTS = 'Y' then 'Да'
            else '' 
        end
      ,case when X_MSO_FLG = 'Y' then 'Да'
            else ''
        end
      ,case when cx.X_MSO_PREM = 'Y' then 'Да'
            else '' 
        END
      ,case when X_VIP_FLG = 'Y' then 'Да'
            else '' 
        END
      --,STRING_AGG(ISNULL(acc_up.PARTNER_CONTRACT_NUM_UP_N_DOG,''),';')
      --,ISNULL(acc_up.PARTNER_CONTRACT_NUM_UP_N_DOG,'')
      ,acc_up.PARTNER_CONTRACT_NUM_UP_N_DOG
  FROM [DCM-SIEBEL-DB].siebeldb.dbo.S_CONTACT sc WITH (NOLOCK)
  LEFT JOIN [DCM-SIEBEL-DB].siebeldb.dbo.S_PER_COMM_ADDR addr2 WITH (NOLOCK) ON addr2.ROW_ID= sc.PR_EMAIL_ADDR_ID 
  LEFT JOIN [DCM-SIEBEL-DB].siebeldb.dbo.CX_CON_VIP_X VIP WITH (NOLOCK) ON VIP.PAR_ROW_ID=sc.ROW_ID
  LEFT JOIN [DCM-SIEBEL-DB].siebeldb.dbo.S_CONTACT_X cx WITH (NOLOCK) ON cx.ROW_ID=sc.ROW_ID
  LEFT JOIN [DCM-SIEBEL-DB].siebeldb.dbo.CX_PARTY_REL rel WITH (NOLOCK) ON rel.PARTY_ID = sc.ROW_ID
                                                                        AND ISNULL(rel.END_DATE, @max_date) > @cur_date
  LEFT JOIN [DCM-SIEBEL-DB].siebeldb.dbo.S_ORG_EXT soe_up	WITH (NOLOCK) ON soe_up.ROW_ID = rel.REL_PARTY_ID
  LEFT JOIN [DCM-SIEBEL-DB].siebeldb.dbo.CX_ACCNT_INFO_X acc_up WITH (NOLOCK) ON acc_up.ROW_ID = soe_up.ROW_ID
                     AND acc_up.PARTNER_CONTRACT_NUM_UP_N_DOG ='10362'
--GROUP BY sc.ROW_ID      
--      ,sc.X_OPENDB_CLIENT_CODE
--      ,MSO_CLIENTS, X_MSO_FLG ,cx.X_MSO_PREM , X_VIP_FLG --,acc_up.PARTNER_CONTRACT_NUM_UP_N_DOG
  UPDATE c 
  SET c.base_code = cb.code
  FROM #crm c
  JOIN dbo.person p WITH(NOLOCK) ON p.crm_ext_id = c.cid
  JOIN dbo.client cc WITH(NOLOCK) ON cc.client_id = p.broker_client_id
  JOIN dbo.client cb  WITH(NOLOCK) ON cb.client_id = cc.client_base_id

DELETE FROM #crm
WHERE base_code IN (
SELECT base_code FROM #crm WHERE up_code  IS NOT NULL
intersect
SELECT base_code FROM #crm WHERE up_code IS NULL) AND up_code IS null
--SELECT * FROM #crm c WHERE c.base_code IN ('447652','419627','453249')

--FROM dbo.client cc WITH (NOLOCK)
--   JOIN dbo.client c WITH (NOLOCK) ON c.client_base_id = cc.client_base_id
--   LEFT JOIN dbo.person p WITH (NOLOCK) ON p.broker_client_id = c.client_id

--   SELECT * FROM #crm c 
--      LEFT JOIN dbo.person p WITH(NOLOCK) ON p.crm_ext_id = c.cid
--      WHERE  c.code='100284'
--  JOIN dbo.client cc WITH(NOLOCK) ON cc.client_id = p.broker_client_id
--  JOIN dbo.client cb  WITH(NOLOCK) ON cb.client_id = cc.client_base_id
  --e-mail,филиал, менеджер, признак PB и МСО

--SELECT * from  opendb.dbo.dogovor_type dtt WHERE dtt.dogovor_type=643
--
--   dtt.dogovortype_txt LIKE '%ИФ%' 
--   WHERE dtt.type_id=7
--   SELECT COUNT(DISTINCT t.[Номер счета/субсчета]) FROM  tmpdatadb.dbo.[SUP-206317-1] t
SELECT cb.code  [Базовый код]
   
   ,[Номер счета/субсчета]
   ,Наименование
   ,[Договор БФ] = STRING_AGG(CASE WHEN dt.type_id=1 then d.dogovor_n END, ';')
   ,[Дата договора БФ]= STRING_AGG(CASE WHEN dt.type_id=1 then FORMAT(d.date_start, 'dd.MM.yyyy') end, ';')
   ,[Договор ДФ] = STRING_AGG(CASE WHEN dt.type_id=2 then d.dogovor_n end, ';')
   ,[Дата договора ДФ]= STRING_AGG(CASE WHEN dt.type_id=2 then  FORMAT(d.date_start, 'dd.MM.yyyy') end, ';')   
   ,[Договор ИФ] = STRING_AGG(CASE WHEN d.dogovor_type=643 then d.dogovor_n end, ';')
   ,[Дата договора ИФ]= STRING_AGG(CASE WHEN d.dogovor_type=643 then  FORMAT(d.date_start, 'dd.MM.yyyy') end, ';')  
   INTO #res2
FROM tmpdatadb.dbo.SUP_207502  t
LEFT JOIN opendb.dbo.client c ON t.[Номер счета/субсчета] = c.code
   LEFT JOIN opendb.dbo.client cb ON cb.client_id = c.client_base_id
   LEFT JOIN opendb.dbo.dogovor d ON d.client_id=c.client_id   
   LEFT JOIN opendb.dbo.dogovor_type dt ON d.dogovor_type=dt.dogovor_type
--LEFT JOIN #depo_codes dc ON dc.code =s.ИИС --cb.code--s.ИИС --?
  --LEFT JOIN dbo.client cc ON cc.code = dc.obOpen_Code
   LEFT JOIN dbo.client cc ON cc.code = cb.code
  LEFT JOIN dbo.sales ss WITH(NOLOCK) ON ss.sales_id = cc.client_sales
  LEFT JOIN dbo.offices o WITH(NOLOCK) ON o.id = cc.office
  LEFT JOIN dbo.client bc ON bc.client_id = cc.client_base_id
  LEFT JOIN #crm c1 ON c1.base_code = bc.code
   GROUP BY cb.code
   ,[Номер счета/субсчета]
   ,Наименование

CREATE TABLE #dwh(code VARCHAR(50) NOT NULL
                 ,activ DECIMAL(38,19)
                 ,ds DECIMAL(38,19)
                 );

CREATE INDEX IX_dwh_client_id ON #dwh(code);

--region #dwh
INSERT INTO #dwh (code, activ, ds)
SELECT 
       dc.code
      ,SUM(ISNULL(r.asset_plan, 0)) 
      ,SUM(ISNULL(r.money_fact, 0))
  FROM [BD-SRV-DWH].OpenDWH.detail_stage.rem_client_asset_total r WITH (NOLOCK)
  JOIN [BD-SRV-DWH].OpenDWH.detail_stage.dim_clients dc WITH (NOLOCK) ON dc.client_id = r.client_id
--  JOIN [BD-SRV-DWH].OpenDWH.detail_stage.dim_clients bc WITH (NOLOCK) ON bc.client_id = dc.client_base_id
 WHERE 1=1 
   AND CAST(r.date AS DATE) = @rep_date
 GROUP BY dc.code

   SELECT r.*
      ,[активы]=d.activ
      ,cc.e_mail_to AS [e-mail]    
   ,ISNULL(o.[name], '')  AS [филиал ОБ]
      ,ISNULL(ss.sales_name, '') AS [менеджер ОБ]
      ,IIF(c1.up_code = '10362','Да', '') AS [признак PB в ОБ]
      ,IIF(c1.mso <>'' OR c1.vip_mso <>'' OR c1.prem_mso <>'','Да', '') AS [признак МСО в ОБ]
   
   FROM #res2 r
   --LEFT JOIN #depo_codes dc ON dc.code =s.ИИС --cb.code--s.ИИС --?
  --LEFT JOIN dbo.client cc ON cc.code = dc.obOpen_Code
   LEFT JOIN dbo.client cc ON cc.code = r.[Базовый код]
  LEFT JOIN dbo.sales ss WITH(NOLOCK) ON ss.sales_id = cc.client_sales
  LEFT JOIN dbo.offices o WITH(NOLOCK) ON o.id = cc.office
  LEFT JOIN dbo.client bc ON bc.client_id = cc.client_base_id
  LEFT JOIN #crm c1 ON c1.base_code = bc.code
   LEFT JOIN #dwh d ON d.code = r.[Номер счета/субсчета]
--,o.[name], ss.sales_name, c1.up_code
--   ,c1.mso ,c1.vip_mso, c1.prem_mso
   --21494

--SELECT code, COUNT(code) FROM #r 
--   GROUP BY code
--   HAVING COUNT(code)>1
--  SELECT * FROM #crm  WHERE base_code IN ('352485','334812','419389')