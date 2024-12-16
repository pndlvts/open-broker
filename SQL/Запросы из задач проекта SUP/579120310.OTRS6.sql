USE opendb
--IF OBJECT_ID('tempdb..##temp_otrs_task') IS NOT NULL
IF EXISTS (SELECT 1 FROM ##temp_otrs_task) --работает быстре
    BEGIN
        SELECT  code AS [Код депонента],
                client_name AS [ФИО],
                Phone AS [Телефон],
                phone_cell AS [Мобильный],
                E_Mail_To AS [E-Mail]
        FROM client c
        --WHERE code IN (SELECT code FROM ##temp_otrs_task)
        INNER JOIN ##temp_otrs_task t ON c.code = t.code --работает быстрее
    END