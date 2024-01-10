declare
	@date date = '20231229'

drop table if exists #user_planned_transactions_filter
create table #user_planned_transactions_filter (
	id int
)

drop table if exists #outer_planned_transactions_charge_settings
create table #outer_planned_transactions_charge_settings (
	use_margin_type						int				not null	-- 0 - ������� �����, 6 - �� ��� �����, 7 - �� ��� �����
	,use_margin_type_stock_mask				int				null		-- ��������, � ������� ��������� �� ����� use_margin_type
	,use_plan_limit							bit				not null	-- 1 - ��������� �������� �������
	,use_plan_limit_stock_mask				int				null		-- ��������, �� ������� ��������� �������� �������
	,go_limit								decimal(19,6)	null		-- ������� �� (�� ��������� ������� �� ���� ���������� ��������)
	,min_percent_liquidity_go				decimal(19,2)	null		-- ��� ������� ����������� ��
	,margin_limit_coef						decimal(19,6)	not null	-- �����-�, �� ������� ����� �������� ������������� ������������ �����
	,margin_limit_coef_stock_mask			int				null		-- ��������, � ������� ����� ��������� ����������� margin_limit_coef
	,round_charge_amount_by_integer			bit				not null	-- 1 - ��������� �� ������ �����
	,except_close_day_stock_mask			int				not null	-- ��������, ������� ��������� ��� �������� � �������� ���
	,use_portfolio_evaluation				int				null		-- 1 - ��������� �� ������ ��������� ��������
	,use_portfolio_evaluation_stock_mask	int				null		-- ��������, �� ������� ��������� �� ������ ��
)

drop table if exists #min_balances
create table #min_balances (
	id						int				not null identity(1,1) primary key
	,client_id				int				null
	,stock_id				int				null
	,[value]				decimal(28,8)	null
	,min_balance_type_id	int				not null default(2)	-- 0 - �� ������������, 1 - ��������� �� ����, 2 - ������� ���. ������� = value
	,refill_entity_id		int				null
	,refill_source_code		varchar(50)		null
)

-- ��������� �������� �������, ����� �� �������������� �� ������-������ � ��������� ��������
insert into #outer_planned_transactions_charge_settings (
	use_margin_type
	,use_margin_type_stock_mask
	,use_plan_limit
	,use_plan_limit_stock_mask
	,go_limit
	,min_percent_liquidity_go
	,margin_limit_coef
	,margin_limit_coef_stock_mask
	,round_charge_amount_by_integer
	,except_close_day_stock_mask
	,use_portfolio_evaluation
	,use_portfolio_evaluation_stock_mask
)
select
	6			as use_margin_type
	,-328706	as use_margin_type_stock_mask
	,1			as use_plan_limit
	,-327682	as use_plan_limit_stock_mask
	,null		as go_limit
	,1			as min_percent_liquidity_go
	,1			as margin_limit_coef
	,0			as margin_limit_coef_stock_mask
	,1			as round_charge_amount_by_integer
	,0			as except_close_day_stock_mask
	,0			as use_portfolio_evaluation
	,0			as use_portfolio_evaluation_stock_mask
	
-- �������, �� ������� ����� ����� ��������. ������ ������ �������� ��� ������ SUP-203906!!!
insert into #min_balances (
	client_id
	,stock_id
	,[value]
)
select 
	client_id
	,stock_id
	,quantity
from 
	dbo.totals
where
	date = @date
	and asset_id = 810
	and type_id = 1
	and asset_type_id = 1
	and client_id in (1301325, 1459738, 1506400)


-- ������ ���������� �������� ��� ��������
 insert into #user_planned_transactions_filter (
	id
)
select
	id
from
	dbo.planned_transactions
where
	id in (68275245, 68281861, 68285200)

exec dbo.context_info_set
	@process_name = 'disable_checks'

exec dbo.planned_transactions_charge
	@p_type						= 0			-- 0 - ��-�� ������������� ���������� �������� ���������� � ������� #user_planned_transactions_filter
	,@p_action_mask					= 0			-- ��. <action_mask_enum>
	,@p_only_min_balances			= 1			-- ����� ����� ��� �������� ������ �� ������� #min_balances
	,@p_use_outer_charge_settings	= 1			-- ��������� ��� �������� ���������� ����� ��������� ������� #outer_planned_transactions_charge_settings
	,@p_current_date				= @date		-- ���� ��������

exec dbo.context_info_set
	@process_name = ''



