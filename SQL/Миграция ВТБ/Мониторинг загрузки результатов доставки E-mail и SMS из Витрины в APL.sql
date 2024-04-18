--Ссылка на дашборд в графане https://grafana.open-broker.ru/d/c8feb4cb-e5ce-45c7-8383-5039d60c8af3/person-migrationcount?orgId=5&refresh=5s

-- за сегодня
select * from [Monitoring].[Workflow.Internal.Today]() where RequestType = 'personal.data.processing.rules'
-- за конкретную дату
select * from [Monitoring].[Workflow.Internal.Date]('2023-11-09') where RequestType = 'personal.data.processing.rules'