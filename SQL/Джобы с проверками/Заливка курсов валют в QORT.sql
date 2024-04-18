if (select count(*)
    from [QUORT].QORT_DB.dbo.CrossRates with(NOLOCK) --за линк QUORT отвечают дба
    where modified_date = convert(nvarchar(MAX), getdate(), 112)
      And InfoSource = 'MainCurBank') > 10

	exec msdb.dbo.sp_send_dbmail
			@subject = 'BackQORT ИП Загрузка курсов валют с сайта ЦБ - ОК'
			,@recipients = 'opps_ob@open.ru'
			,@body = 'ЕСТЬ записи за дату от источника MainCurBank в количестве больше 10'
else
	exec msdb.dbo.sp_send_dbmail
			@subject = 'BackQORT ИП Загрузка курсов валют с сайта ЦБ - ОШИБКА'
			,@recipients = 'opps_ob@open.ru'
			,@body = 'НЕТ записей за дату от источника MainCurBank в количестве больше 10. Инструкция https://conf.open-broker.ru/pages/viewpage.action?pageId=101304695'