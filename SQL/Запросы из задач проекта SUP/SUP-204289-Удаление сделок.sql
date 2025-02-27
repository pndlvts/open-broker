USE opendb
BEGIN TRY
    BEGIN TRANSACTION
 if(object_id('tempdb..#deal') is not null)
begin
    drop table #deal
end
create table #deal
(
    deal_id int
)
insert into #deal (deal_id) values  (459390975)
									, (459392102)
                                  , (459391666) --подставить нужные deal_id
if(object_id('tempdb..#trade') is not null)
begin
    drop table #trade
end
create table #trade
(
    trade_n bigint
)
insert into #trade (trade_n) values  (2240108001458)
                                   , (2240108002585)
                                   , (2240108002149) --или подставить нужные trade_n
    --region DELETE
    SELECT
        pag.deal_id
      , pag.trade_n
      , pag.client_id
      , paga.id
      , paga.action_date
      , so.*
    FROM
        dbo.person_account_gko pag
        LEFT JOIN dbo.specrepo_orders so
            ON pag.client_id = so.client_id
            AND pag.trade_n = so.trade_n
        LEFT JOIN dbo.person_account_gko_actions paga
            ON pag.deal_id = paga.oper_id
    WHERE
        1 = 1
        AND pag.deal_id IN (select deal_id from #deal)  -- Находим по ИД сделок
        --AND pag.trade_n IN (select trade_n from #trade)  -- ИЛИ ПО номеру сделки
    DELETE
        so
    FROM
        dbo.person_account_gko pag
        LEFT JOIN dbo.specrepo_orders so
            ON pag.client_id = so.client_id
            AND pag.trade_n = so.trade_n
        LEFT JOIN dbo.person_account_gko_actions paga
            ON pag.deal_id = paga.oper_id
    WHERE
        1 = 1
        AND pag.deal_id IN (select deal_id from #deal)  -- Находим по ИД сделок
        --AND pag.trade_n IN (select trade_n from #trade)  -- ИЛИ ПО номеру сделки
    PRINT @@rowcount
    DELETE
        paga
    FROM
        dbo.person_account_gko pag
        LEFT JOIN dbo.specrepo_orders so
            ON pag.client_id = so.client_id
            AND pag.trade_n = so.trade_n
        LEFT JOIN dbo.person_account_gko_actions paga
            ON pag.deal_id = paga.oper_id
    WHERE
        1 = 1
        AND pag.deal_id IN (select deal_id from #deal)  -- Находим по ИД сделок
        --AND pag.trade_n IN (select trade_n from #trade)  -- ИЛИ ПО номеру сделки
    PRINT @@rowcount
    DELETE
        pag
    FROM
        dbo.person_account_gko pag
        LEFT JOIN dbo.specrepo_orders so
            ON pag.client_id = so.client_id
            AND pag.trade_n = so.trade_n
        LEFT JOIN dbo.person_account_gko_actions paga
            ON pag.deal_id = paga.oper_id
    WHERE
        1 = 1
        AND pag.deal_id IN (select deal_id from #deal)  -- Находим по ИД сделок
        --AND pag.trade_n IN (select trade_n from #trade)  -- ИЛИ ПО номеру сделки
    PRINT @@rowcount
    SELECT
        pag.deal_id
      , pag.trade_n
      , pag.client_id
      , paga.id
      , paga.action_date
      , so.*
    FROM
        dbo.person_account_gko pag
        LEFT JOIN dbo.specrepo_orders so
            ON pag.client_id = so.client_id
            AND pag.trade_n = so.trade_n
        LEFT JOIN dbo.person_account_gko_actions paga
            ON pag.deal_id = paga.oper_id
    WHERE
        1 = 1
        AND pag.deal_id IN (select deal_id from #deal)  -- Находим по ИД сделок
        --AND pag.trade_n IN (select trade_n from #trade)  -- ИЛИ ПО номеру сделки
    --endregion
    commit TRANSACTION  -- !!! МЕНЯЕМ НА COMMIT ЕСЛИ ВСЁ НОРМ
END TRY
BEGIN CATCH
    PRINT
    'Error ' + CONVERT(VARCHAR(50), ERROR_NUMBER()) +
    ', Severity ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +
    ', State ' + CONVERT(VARCHAR(5), ERROR_STATE()) +
    ', Line ' + CONVERT(VARCHAR(5), ERROR_LINE())
    PRINT ERROR_MESSAGE();
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION
    END
END CATCH