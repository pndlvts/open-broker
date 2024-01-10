use opendb

declare
	 @date date = '20231230'--'20190607'
	,@prev_day date

set @prev_day = dbo.getprevworkday(@date)

--insert into 
--	dbo.gko_close_price (
--		 contract_id
--		,operation_date
--		,max_price
--		,min_price
--		,close_price
--		,volume
--		,open_position
--		,middle_price
--		,go_prod
--		,go_pok
--		,max_front_price
--		,min_front_price
--		,optcast
--		,futcastpre
--		,qclassid
--		,close_price_forts
--		,settlement_price
--		,import_source_id
--		,last_clearing_price
--		,intermediate_clearing_price
--	)
--begin tran
select
	CCP.close_price
	,CCPP.close_price
	,CCP.middle_price
	,CCPP.middle_price
	,CCP.close_price_curr
	,CCPP.close_price_curr
	,CCP.legal_close_price
	,CCPP.legal_close_price
	,CCP.close_price_curr
	,CCPP.close_price_curr
	,CCP.middle_price_curr
	,CCPP.middle_price_curr
	,CCP.close_price_main_session
	,CCPP.close_price_main_session
	,CCP.close_price_curr_main_session
	,CCPP.close_price_curr_main_session
	,CCPP.*
	,g.stock_id
from
	dbo.gko_close_price CCP
	inner join gko_tuning g on ccp.contract_id = g.contract_id
	left join dbo.gko_close_price CCPP
		on CCPP.contract_id = CCP.contract_id
		and CCPP.operation_date = @date
where 
	CCP.operation_date = @prev_day	
	--and CCPP.contract_id is null

update CCPP
set
	legal_close_price = CCP.legal_close_price
	,close_price_main_session = CCP.close_price_main_session
	,CCPP.close_price_curr_main_session = CCP.close_price_curr_main_session
	,close_price = CCP.close_price
	,middle_price = CCP.middle_price
	,close_price_curr = CCP.close_price_curr
	,middle_price_curr = CCP.middle_price_curr
from
	dbo.gko_close_price CCP
	inner join gko_tuning g on ccp.contract_id = g.contract_id
	left join dbo.gko_close_price CCPP
		on CCPP.contract_id = CCP.contract_id
		and CCPP.operation_date = @date
where 
	CCP.operation_date = @prev_day	
	--and CCPP.contract_id is null

select
	CCP.close_price
	,CCPP.close_price
	,CCP.middle_price
	,CCPP.middle_price
	,CCP.close_price_curr
	,CCPP.close_price_curr
	,CCP.legal_close_price
	,CCPP.legal_close_price
	,CCP.close_price_curr
	,CCPP.close_price_curr
	,CCP.middle_price_curr
	,CCPP.middle_price_curr
	,CCP.close_price_main_session
	,CCPP.close_price_main_session
	,CCP.close_price_curr_main_session
	,CCPP.close_price_curr_main_session
	,CCPP.*
	,g.stock_id
from
	dbo.gko_close_price CCP
	inner join gko_tuning g on ccp.contract_id = g.contract_id
	left join dbo.gko_close_price CCPP
		on CCPP.contract_id = CCP.contract_id
		and CCPP.operation_date = @date
where 
	CCP.operation_date = @prev_day	
	--and CCPP.contract_id is null

--rollback tran