declare
 @date date = getdate()
,@end_date date = getdate() --'20181228'
,@p_client_ids xml = '<root><id value=""/></root>'

--клиенты для ei_totals и manager_assets
set @p_client_ids = (
select  CL.client_id as [@value]
from dbo.client CL
inner join  dogovor D on D.client_id = CL.manager and D.dogovor_type in (4,137,643) and date_sign is not null and date_end is null -- договор есть
for xml path('id'), root('root')
)


drop table if exists #totals_rub
drop table if exists #totals_68
drop table if exists #group
drop table if exists #totals
drop table if exists #bloc_service
drop table if exists #planned
drop table if exists #hell_all
drop table if exists #status

--оценка активов
drop table if exists #manager_states;
create table #manager_states (
                                            manager_id                      int                                    -- Cчет-менеджер
                                           ,base_commission                decimal(19,2)                          -- Размер минимальной комиссии
                                           ,commissions_charged            decimal(19,2)                          -- Начисленные за период с начала месяца комиссии
                                           ,commissions_charged_rts        decimal(19,2)                          -- Начисленные за период с начала месяца комиссии РТС
                                           ,tariff_plan                    int                                    -- Тарифный план
                                           ,exception_id                   int         -- Номер исключения - причины изменения мин. ком. отн. стандартной для данного т.п.
                                           ,assets                         decimal(19,2) default 0                -- Полные остатки
                                           ,assets_mmvb_fsfb               decimal(19,2) default 0                -- Остатки на ФССФБ ММВБ     
                                           ,assets_rts_sgk                 decimal(19,2) default 0                -- Остатки на БР РТС (ранее РТС СГК)
                                           ,assets_forts                   decimal(19,2) default 0                -- Остатки на ФОРТС
                                           ,assets_pie                     decimal(19,2) default 0                -- Остатки на паях
                                           ,assets_mmvb_gko                decimal(19,2) default 0                -- Остатки на ММВБ ГКО
                                           ,assets_mmvb_ss                 decimal(19,2) default 0                -- Остатки на СС ММВБ
                                           ,assets_rts_kr                  decimal(19,2) default 0                -- Остатки на КР РТС
                                           ,assets_spimex                  decimal(19,2) default 0                -- Остатки на СПбМТСБ
                                           ,assets_otc                     decimal(19,2) default 0                -- Остатки на Внебиржевые ПФИ
                                           ,assets_itp                     decimal(19,2) default 0 
                                           ,assets_spb                     decimal(19,2) default 0                -- Остатки на ФР СПБ
                                           ,assets_ets                     decimal(19,2) default 0                -- Остатки на ВР МБ
                                           ,commission_to_charge           decimal(19,2) default 0                -- Мин. ком. к списанию
                                           ,debt                           decimal(19,2) default 0                -- Задолженность клиента
                                           ,min_com_always                 int
                    )      

exec dbo.manager_assets --_test 
							 @p_date_beg = @date
							,@p_date_end = @date
							,@p_group_by = 1
							,@p_planed_rest = 1 
							,@p_client_xml = @p_client_ids
							,@p_stock_mask = 378465
							,@p_ets = 1
							,@p_spb = 2
							,@p_exclude_loan = 0
							,@p_debug = 0
							,@p_evaluation_type =1


--select count(*) from #manager_states where assets!=0


drop table if exists #dwh;
CREATE TABLE #dwh(client_id   INT NOT NULL
                 ,client_name NVARCHAR (255)
                 ,code        NVARCHAR (50)
                 ,manager     NVARCHAR (255)
                 ,office      NVARCHAR (255)
                 ,channel     NVARCHAR (100)
                 ,Privat      BIT
                 );
CREATE INDEX IX_dwh_client_id ON #dwh(client_id);

INSERT INTO #dwh (client_id, client_name, code, manager, office, channel, Privat)
  SELECT 
         c.client_id
        ,c.client_name
		,c.code
        ,ISNULL(m.name,'')
        ,ISNULL(o.name,'')
        ,ISNULL(cs.sale_channel,'')
        ,IIF(u.up_code = '10362', 1, 0)
    FROM [BD-SRV-DWH].OpenDWH.detail_stage.dim_clients c WITH (NOLOCK)
    LEFT JOIN [BD-SRV-DWH].OpenDWH.dwh.dim_clients u WITH (NOLOCK) ON u.client_id = c.client_id
    LEFT JOIN [BD-SRV-DWH].OpenDWH.olap.dim_clients cs WITH (NOLOCK) ON cs.client_id = c.client_id
    LEFT JOIN [BD-SRV-DWH].OpenDWH.detail_stage.dim_managers m WITH (NOLOCK) ON m.manager_id = c.sales_manager_id
    LEFT JOIN [BD-SRV-DWH].OpenDWH.detail_stage.dim_offices o WITH (NOLOCK) ON o.office_id = c.office_id
	where c.client_id = c.manager


--деньги 
drop table if exists #totals
create table #totals (
						date date
						,type_id int
						,client_id int
						,stock_id int
						,asset_type_id int
						,asset_id int
						,quantity decimal(28,8)
						)
exec ei_totals
 @p_date_from = @date
,@p_date_to = @end_date
,@p_types = '<root><id value="1"/><id value="2"/></root>'
,@p_clients = @p_client_ids
,@p_stocks = '<root><id value="21"/><id value="15"/><id value="6"/><id value="17"/></root>'
,@p_copy_xml = '
<table source="#_totals" destination="#totals">
<field source="date"/>
<field source="type_id"/>
<field source="client_id"/>
<field source="stock_id"/>
<field source="asset_type_id"/>
<field source="asset_id"/>
<field source="quantity"/>
</table>'

--select count(*) from  #totals where quantity!=0 and stock_id = 6

--declare @date date = '20231220'
--оценка денежной части активов 
select manager, client_base_id, sum(quantity_FRMB) as RUB_FRMB, sum(quantity_VRMB) as RUB_VRMB, sum(quantity_SPB) as RUB_SPB, sum(quantity_GL) as RUB_GL
into #totals_rub 
from(
select cl.manager, cl.client_base_id, round(quantity*C.course,2) as quantity_FRMB, 0 as quantity_VRMB, 0 as quantity_SPB, 0 as quantity_GL
from  #totals t
join client cl on t.client_id= cl.client_id and cl.registr in (3,8)  and t.stock_id = 6 
join vw_courses C on T.asset_id = C.currency_id  and C.date = @date
where asset_type_id = 1
union all
select cl.manager, cl.client_base_id, 0 as quantity_FRMB, round(quantity*C.course,2) as quantity_VRMB, 0 as quantity_SPB, 0 as quantity_GL
from  #totals t
join client cl on t.client_id= cl.client_id and cl.registr in (3,8)  and t.stock_id = 17
join vw_courses C on T.asset_id = C.currency_id  and C.date = @date
where asset_type_id = 1
union all
select cl.manager, cl.client_base_id, 0 as quantity_FRMB, 0 as quantity_VRMB, round(quantity*C.course,2) as quantity_SPB, 0 as quantity_GL
from  #totals t
join client cl on t.client_id= cl.client_id and cl.registr in (3,8)  and t.stock_id = 21 
join currency_type CT on asset_id = rts_currency_id
join vw_courses C on C.currency_id = CT.curr_numb  and C.date = @date
where asset_type_id = 1
union all
select cl.manager, cl.client_base_id, 0 as quantity_FRMB, 0 as quantity_VRMB, 0 as quantity_SPB, round(quantity*C.course,2) as quantity_GL
from  #totals t
join client cl on t.client_id= cl.client_id and cl.registr in (3,8)  and t.stock_id = 15
join currency_type CT on asset_id = rts_currency_id
join vw_courses C on C.currency_id = CT.curr_numb  and C.date = @date
where asset_type_id = 1
) a 
group by manager, client_base_id
having sum(quantity_SPB)!=0  or sum(quantity_GL) !=0 or  sum(quantity_FRMB) !=0 or sum(quantity_VRMB)!=0


--группы
select distinct CL.client_base_id, groupname into #group
from [PGLINK].[open].[directus].[vtbclientbygroups] GR
join person PR on GR.GUID = PR.person_guid
join client CL on PR.broker_client_id = CL.client_id

--статусы
select distinct CL.client_base_id
into #status
from [PGLINK].[open].[directus].[vtbclientreadyactive] ST
join person PR on ST.GUID = PR.person_guid
join client CL on PR.broker_client_id = CL.client_id

--несписанные отложенные
	Select 
		 PL.manager
		,PL.client_base_id
		,PL.account
		,sum(PL.minus_ROS)	as planned_ROS
		,sum(PL.minus_SPB)	as planned_SPB
		,sum(PL.minus_GL)	as planned_GL 
		,sum(PL.minus_ROS+PL.minus_SPB+PL.minus_GL)	as planned_ALL
	into #planned
		from
			(--рос отлож
			select CL.manager, CL.client_base_id, pt.account, round(pt.amount*c.course,2) as minus_ROS, 0 as minus_SPB, 0 as minus_GL
				from 
				dbo.planned_transactions PT inner join client_commissions CC on CC.id = PT.owner_id
				inner join client CL on PT.source_account_id = CL.client_id
				inner join dbo.vw_courses C on C.currency_id = PT.currency_id and C.date = @date		
				inner join dogovor D on D.client_id = CL.manager and D.dogovor_type in (4,643) and date_sign is not null and date_end is null --не ИТП
				where
				pt.account not in (70,73) 
				and PT.status_id in (3)			
				and isnull(cc.write_off_stock_id,0) not in (21)
				and cl.registr in (3,8) 
			union all
			--СПБ отлож
			select CL.manager, CL.client_base_id, pt.account, 0 as minus_ROS, round(pt.amount*c.course,2) as minus_SPB, 0 as minus_GL
				from 
				dbo.planned_transactions PT inner join client_commissions CC on CC.id = PT.owner_id
				inner join client CL on PT.source_account_id = CL.client_id
				inner join dbo.vw_courses C on C.currency_id = PT.currency_id and C.date = @date		
				inner join dogovor D on D.client_id = CL.manager and D.dogovor_type in (4,643) and date_sign is not null and date_end is null--не ИТП
				where
				pt.account not in (70,73) 
				and PT.status_id in (3)			
				and isnull(cc.write_off_stock_id,0) in (21)
				and cl.registr in (3,8) 
			union all
			--ИТП отлож
			select CL.manager, CL.client_base_id, pt.account, 0 as minus_ROS, 0 as minus_SPB, round(pt.amount*c.course,2) as minus_GL
				from 
				dbo.planned_transactions PT inner join client_commissions CC on CC.id = PT.owner_id
				inner join client CL on PT.source_account_id = CL.client_id 
				inner join dbo.vw_courses C on C.currency_id = PT.currency_id and C.date = @date		
				inner join dogovor D on D.client_id = CL.manager and D.dogovor_type in (137) and date_sign is not null and date_end is null --ИТП
				where
				pt.account not in (70,73) 
				and PT.status_id in (3)			
				and cl.registr in (3,8) 
			) PL
		group by PL.manager, PL.client_base_id, PL.account
		having sum(PL.minus_ROS)!=0 or sum(PL.minus_SPB)!=0 or sum(PL.minus_GL)!=0




select 
	 manager
	,client_base_id	
	,sum(planned_ALL)															as 	planned_ALL	
	,sum(quantity_ALL)															as 	quantity_ALL
	,sum(quantity_ALL-planned_ALL)												as 	quantity_ALL_WO_planned
	,sum(quantity_ALL-quantity_SPB-quantity_GL
		+case when RUB_SPB>=0 then RUB_SPB else 0 end  
		+case when RUB_GL>=0 then RUB_GL else 0 end)							as 	quantity_ALL_free
	,sum(quantity_ALL-quantity_SPB-quantity_GL
		+case when RUB_SPB>=0 then RUB_SPB else 0 end  
		+case when RUB_GL>=0 then RUB_GL else 0 end
		-planned_ALL)															as 	quantity_ALL_free_WO_planned
	,sum(planned_ROS)															as 	planned_ROS
	,sum(planned_SPB)															as 	planned_SPB
	,sum(planned_GL	)															as 	planned_GL	
	,sum(quantity_FORTS)														as 	quantity_FORTS			
	,sum(quantity_FRMB)															as 	quantity_FRMB			
	,sum(quantity_VRMB)															as 	quantity_VRMB			
	,sum(quantity_CLAS)															as 	quantity_CLAS			
	,sum(quantity_VPFI)															as 	quantity_VPFI			
	,sum(quantity_SPB )															as 	quantity_SPB 
	,sum(quantity_GL)															as 	quantity_GL
	,sum(RUB_FRMB)																as 	RUB_FRMB
	,sum(RUB_VRMB)																as 	RUB_VRMB
	,sum(RUB_SPB)																as 	RUB_SPB
	,sum(RUB_GL)																as 	RUB_GL
into #hell_all
	from(
select	 
	 manager
	,client_base_id
	,planned_ROS
	,planned_SPB
	,planned_GL
	,planned_ALL
	,0 as quantity_ALL
	,0 as quantity_FORTS				
	,0 as quantity_FRMB				
	,0 as quantity_VRMB				
	,0 as quantity_CLAS				
	,0 as quantity_VPFI				
	,0 as quantity_SPB 
	,0 as quantity_GL
	,0 as RUB_FRMB
	,0 as RUB_VRMB
	,0 as RUB_SPB
	,0 as RUB_GL
from #planned
union all
select
	 cl.manager
	,cl.client_base_id
	,0					as planned_ROS
	,0					as planned_SPB
	,0					as planned_GL
	,0					as planned_ALL
	,assets				as quantity_ALL
	,assets_forts		as quantity_FORTS	
	,assets_mmvb_fsfb	as quantity_FRMB		 
	,assets_ets			as quantity_VRMB		
	,assets_rts_kr		as quantity_CLAS		
	,assets_otc			as quantity_VPFI		
	,assets_spb			as quantity_SPB 
	,assets_itp			as quantity_GL
	,0 as RUB_FRMB
	,0 as RUB_VRMB
	,0 as RUB_SPB
	,0 as RUB_GL
from #manager_states MA
join client cl on MA.manager_id = cl.client_id  
union all
select 	 manager
		,client_base_id
		,0 as planned_ROS
		,0 as planned_SPB
		,0 as planned_GL
		,0 as planned_ALL
		,0 as quantity_ALL
		,0 as quantity_FORTS				
		,0 as quantity_FRMB				
		,0 as quantity_VRMB				
		,0 as quantity_CLAS				
		,0 as quantity_VPFI				
		,0 as quantity_SPB 
		,0 as quantity_GL
		,RUB_FRMB
		,RUB_VRMB
		,RUB_SPB
		,RUB_GL
from #totals_rub 
)hell_all
group by 	 
	 manager
	,client_base_id


select	 
	 Gr.groupname
	,case when ST.client_base_id is null then 'не едет'  else 'едет' end  as "статус"
	,case when TF.qty in (60,160, 46, 146,67,167,68,168,83,84,86) then 'ЛБ' else 'НЕ ЛБ' end as "ЛБ/не ЛБ"
	,CL.code  as code
	,CLB.code as code_base
	,CL.client_name 
	,TF.qty as "Тариф"
	,TF.name as "Название тарифа"
	,DW.manager, DW.office, DW.channel, DW.Privat
	,HA.manager
	,HA.client_base_id
	,case when P.quantity_ALL_WO_planned>=0 then 'активов больше долгов' else 'активов меньше долгов'  end as "активы-долги"
	,case when (HA.planned_ROS!=0 or HA.planned_SPB!=0 or HA.planned_GL!=0)  then 'есть'   else 'нет' end as "отложенные"
	,case when (HA.RUB_SPB<0 or HA.RUB_GL<0)  then 'есть'   else 'нет' end as "марж на СПБ/ИТП"
	,case when (HA.quantity_FORTS<0 or HA.quantity_FRMB<0 or HA.quantity_VRMB<0 or HA.quantity_CLAS<0 or HA.quantity_VPFI<0)  then 'есть'   else 'нет' end as "минус в Рос портфеле"
	,HA.planned_ALL						 as "Счет:Отлож"
	,HA.planned_ROS						 as "Счет:Отлож РОС"
	,HA.planned_SPB						 as "Счет:Отлож СПБ"
	,HA.planned_GL						 as "Счет:Отлож ИТП"
	,HA.quantity_FORTS					 as "Счет:Активы FORTS"
	,HA.quantity_FRMB					 as "Счет:Активы ФР МБ"
	,HA.RUB_FRMB						 as "из них Деньги ФР МБ"
	,HA.quantity_VRMB					 as "Счет:Активы ВР МБ"
	,HA.RUB_VRMB						 as "из них Деньги ВР МБ"
	,HA.quantity_CLAS					 as "Счет:Активы Классика"
	,HA.quantity_VPFI					 as "Счет:Активы ВПФИ"
	,HA.quantity_SPB 					 as "Счет:Активы СПБ"
	,HA.RUB_SPB							 as "из них Деньги СПБ"
	,HA.quantity_GL						 as "Счет:Активы ИТП"	
	,HA.RUB_GL							 as "из них Деньги ИТП"
	,P.quantity_ALL						 as "Персона:Активы"
	,P.quantity_ALL_free				 as "Персона:Незаблок.активы"
	,P.quantity_ALL_WO_planned			 as "Персона:Активы минус отлож"
	,P.quantity_ALL_free_WO_planned		 as "Персона:Незаблок.активы минус отлож"
	,P.quantity_FORTS					 as "Персона:Активы FORTS"
	,P.quantity_FRMB					 as "Персона:Активы ФР МБ"
	,P.quantity_VRMB					 as "Персона:Активы ВР МБ"
	,P.quantity_CLAS					 as "Персона:Активы Классика"
	,P.quantity_VPFI					 as "Персона:Активы ВПФИ"
	,P.quantity_SPB 					 as "Персона:Активы СПБ"
	,P.quantity_GL						 as "Персона:Активы ИТП"

--select count(*) 
from #hell_all HA
inner join client CL on  CL.client_id = HA.manager and registr in (3,8)
inner join client CLB on  CLB.client_id = HA.client_base_id
left join #status ST on HA.client_base_id = ST.client_base_id
left join 
	(select distinct C.manager, qty, TN.name
	from servicesopen S join client C on S.clientid = C.manager and serviceid = 29 and isnull(enddate,'99990101')>@date and isnull(startdate,'99990101')<=@date
	join tarifbasename TN on S.qty = TN.tarif
	) TF on HA.manager =TF.manager
left join #group GR on  HA.client_base_id = GR.client_base_id
left join #dwh DW on DW.client_id =HA.manager
inner join --берем только тех, у кого активов хватает на отложенные
	(select 
		 client_base_id
		,sum(quantity_ALL)					as quantity_ALL
		,sum(quantity_ALL_free)				as quantity_ALL_free 
		,sum(quantity_ALL_WO_planned)		as quantity_ALL_WO_planned
		,sum(quantity_ALL_free_WO_planned)	as quantity_ALL_free_WO_planned 
		,sum(quantity_FORTS)				as quantity_FORTS
		,sum(quantity_FRMB)					as quantity_FRMB
		,sum(quantity_VRMB)					as quantity_VRMB
		,sum(quantity_CLAS)					as quantity_CLAS
		,sum(quantity_VPFI)					as quantity_VPFI
		,sum(quantity_SPB)					as quantity_SPB
		,sum(quantity_GL)					as quantity_GL
	from #hell_all
	group by client_base_id
	)P 	on P.client_base_id = HA.client_base_id
where 
HA.planned_ROS!=0 or HA.planned_SPB!=0 or HA.planned_GL!=0 
or HA.RUB_SPB<0 or HA.RUB_GL<0
or HA.quantity_FORTS<0 or HA.quantity_FRMB<0 or HA.quantity_VRMB<0 or HA.quantity_CLAS<0 or HA.quantity_VPFI<0 
order by HA.planned_ALL	desc



			--select CL.manager, CL.client_base_id, pt.account, 0 as minus_ROS, 0 as minus_SPB, round(pt.amount*c.course,2) as minus_GL,  round(pt.charged_amount*c.course,2)  
			--	from 
			--	dbo.planned_transactions PT inner join client_commissions CC on CC.id = PT.owner_id
			--	inner join client CL on PT.source_account_id = CL.client_id 
			--	inner join dbo.vw_courses C on C.currency_id = PT.currency_id and C.date = '20231229'		
			--	inner join dogovor D on D.client_id = CL.manager and D.dogovor_type in (4,643) and date_sign is not null and date_end is null --ИТП
			--	where
			--	pt.account not in (70,73) 
			--	and PT.status_id in (1,2)
			--	and charged_date >='20231229'
			--	and cl.registr in (3,8) 