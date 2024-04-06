-------------------1------------------------
exec dbo.context_info_set 'mass_update_spb'
SELECT  dbo.fn_context_info_get()
--��������� ��������, ��������� 1 ���

begin tran
SELECT DISTINCT --22625
       cc.code AS [������� ��� (num)]
      ,cc.client_id
      ,cc.client_base_id
  INTO #tmp2
  FROM opendb.dbo.client c
  JOIN opendb.dbo.client cc ON c.client_base_id = cc.client_base_id
  WHERE c.code IN (
'322111',
'322111',
'350327',
'322518',
'322518',
'445000',
'401436',
'435607',
'484657',
'458678',
'394790',
'339596',
'335241',
'300157',
'245753',
'383171',
'261308',
'428889',
'238454',
'251888',
'432862',
'344426',
'76176',
'429456',
'259232',
'177603',
'104729',
'316476',
'290072',
'184860',
'280963',
'277427',
'212482',
'415617',
'250315',
'432184',
'324801',
'330935',
'11157',
'59954',
'449684',
'449684',
'451052',
'162363',
'394313',
'413990',
'331219',
'490898',
'331683',
'164326',
'334929',
'458611',
'127915',
'195331',
'174983',
'445439',
'480944',
'74426',
'314369',
'254553',
'120658',
'412466',
'417585',
'286245',
'144595',
'292085',
'95258',
'490262',
'243366',
'425793',
'339323',
'422099',
'434538',
'43905',
'441538',
'210619',
'465015',
'497308',
'442661i',
'395819',
'280126',
'280126',
'299623',
'470115',
'471577',
'451366',
'319428',
'483686',
'446904',
'411854',
'332772',
'37916',
'37916',
'433975',
'117359',
'326288',
'250852',
'308699',
'312041',
'295853',
'492588',
'534365',
'258112',
'455085',
'379713',
'220984',
'339307',
'328234',
'334547',
'474571',
'210144',
'323988',
'241948',
'295989',
'472176',
'321257',
'477439',
'291154',
'347194',
'199950',
'162091',
'288175',
'454447',
'333870',
'333870',
'351603',
'397877',
'428299',
'218874',
'395013',
'438389',
'244175',
'434006',
'341262',
'429305',
'143950',
'189483',
'345995',
'370437',
'352143',
'150762',
'419520',
'465178',
'244877',
'443377',
'228393',
'335330',
'324278',
'341442',
'194494',
'367791',
'174054',
'279342',
'311385',
'399674',
'186987',
'26771',
'36465',
'207602',
'317685',
'330342',
'408718',
'456563',
'310407',
'310407',
'328390',
'421415',
'363250',
'454308',
'402638',
'483794',
'237810',
'377038',
'322493',
'425831',
'180211',
'336969',
'473354',
'296120',
'180787',
'278016',
'455071',
'289996',
'348133',
'366885',
'203021',
'444449',
'429952',
'327478',
'439164',
'305959',
'243384',
'317048',
'118084',
'360068',
'395913',
'138325',
'369610',
'292910',
'451610',
'444096',
'469851',
'334749',
'137395',
'407020',
'407020',
'114657',
'360022',
'405963',
'466885',
'455537',
'321842',
'460002',
'103310',
'441390',
'271018',
'164154',
'467119',
'392153',
'293061',
'56358',
'424849',
'415798',
'183743',
'460358',
'279968',
'413085',
'413085',
'222573',
'471679',
'489981',
'228240',
'139027',
'365191',
'78958',
'415810',
'420117',
'183011',
'423799',
'110474',
'168173',
'458927',
'437528',
'451435',
'56847',
'432647',
'393901',
'435596',
'314829',
'336445',
'336445',
'361024',
'358839',
'264479',
'501287',
'212227',
'287354',
'494622',
'266962',
'353585',
'364584',
'447380',
'428302',
'266426',
'406366',
'150914',
'379353',
'355542',
'213492',
'280807',
'322280',
'310702',
'352127',
'460263',
'484895',
'484895',
'387787',
'457213',
'341274',
'328636',
'465810',
'416015',
'325828',
'313777',
'293733',
'426392',
'497203',
'141634',
'485486',
'307622',
'435085',
'309140',
'506721',
'433648',
'455703',
'214945',
'133054',
'321515',
'438705',
'322200',
'406497',
'346327',
'425451',
'312572',
'351117',
'445079',
'321880',
'34311',
'205382',
'103678',
'312058',
'131406',
'462590',
'172028',
'291540',
'431289',
'183821',
'235978',
'421894',
'336759',
'436145',
'308247',
'340022',
'268459',
'421633',
'342457',
'497816',
'197946',
'48788',
'345758',
'325303',
'165783',
'193701',
'319674',
'430605',
'470860',
'324945',
'260238',
'229972',
'298298',
'442984',
'206775',
'164328',
'395194',
'406961',
'235624',
'486678',
'470408',
'275224',
'444303',
'448420',
'230198',
'194566',
'448827',
'501242',
'330466',
'472740',
'113785',
'443398',
'427055',
'207918',
'324362',
'418069',
'301883',
'396061',
'310808',
'432910',
'332841',
'418169',
'495733',
'497883',
'237469',
'281957',
'331022',
'291969',
'310011',
'326114',
'422927',
'321054',
'429069',
'428773',
'334593',
'176582',
'336440',
'387451',
'367981',
'425317',
'423910',
'498135',
'330994',
'396697',
'473498',
'161712',
'161712',
'161597',
'248579',
'465445',
'334477',
'309092',
'381382',
'261965',
'395078',
'484869',
'444718',
'431683',
'308297',
'451284',
'387762',
'326778',
'403575',
'351838',
'472052',
'256961',
'418532',
'257343',
'444092',
'210639',
'331092',
'308951',
'257728',
'411283',
'430514',
'120374',
'335618',
'320972',
'375394',
'161529',
'476343',
'250722',
'454538',
'313257',
'459991',
'438954',
'281073',
'319675',
'503687',
'381549',
'413853',
'378502',
'190051',
'438904',
'354495',
'322688',
'274857',
'456865',
'305374',
'352987',
'216160',
'431588',
'296224',
'338090',
'488346',
'470389',
'167195',
'416865',
'217711',
'211910',
'332600',
'434156',
'369116',
'492349',
'100846'
)


SELECT * FROM #tmp2

SELECT 
       c.code
      ,c.client_base_id
      ,so.enddate
      ,so.comments
  FROM #tmp2 t
  JOIN opendb.dbo.client c ON c.client_base_id = t.client_base_id
  JOIN opendb.dbo.servicesopen so ON so.clientid = c.client_id
                                  AND so.serviceid = 787
                                  AND so.enddate IS NULL


INSERT INTO dbo.servicesopen (clientid, serviceid, startdate,  comments)
SELECT DISTINCT
       c.client_id
      ,787
      ,'2024.04.01'
      ,'SUP-209246'
  FROM #tmp2 t
  JOIN opendb.dbo.client c ON c.client_base_id = t.client_base_id
  commit