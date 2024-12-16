USE opendb
IF OBJECT_ID('tempdb..##temp_otrs_task') IS NOT NULL
    BEGIN
        SELECT  code AS [Код депонента],
                client_name AS [ФИО],
                Phone AS [Телефон],
                phone_cell AS [Мобильный],
                E_Mail_To AS [E-Mail]
        FROM client
        WHERE code IN (SELECT code FROM ##temp_otrs_task)
    END