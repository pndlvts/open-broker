USE opendb
DECLARE @usr_id NVARCHAR(8), @sales_id  NVARCHAR(8), @old_name NVARCHAR(100), @new_name NVARCHAR(100), @counter INT
SET @old_name = 'СТАРЫЕ ФИО' --СТАРЫЕ ФИО
SET @new_name = 'НОВЫЕ ФИО' --НОВЫЕ ФИО (на что меняем)
BEGIN TRAN
SELECT @counter = count(full_name) FROM appcom_system_users WHERE full_name= @old_name  
IF @counter = 1
	BEGIN
		SELECT @usr_id = appcom_system_users.appcom_system_user_id FROM appcom_system_users WHERE full_name= @old_name
		SELECT @sales_id = sales.sales_id FROM sales WHERE sales_name = @old_name
		SELECT appcom_system_user_id, full_name AS [СТАРОЕ полное имя] FROM appcom_system_users WHERE full_name= @old_name 
		SELECT sales_id, sales_name AS [СТАРОЕ полное имя - сейлз] FROM sales WHERE sales_name = @old_name 
		UPDATE appcom_system_users SET full_name = @new_name WHERE appcom_system_user_id = @usr_id
		UPDATE sales SET sales_name =  @new_name WHERE sales_id = @sales_id
		SELECT appcom_system_user_id, full_name AS [НОВОЕ полное имя] FROM appcom_system_users WHERE appcom_system_user_id = @usr_id
		SELECT sales_id, sales_name AS [НОВОЕ полное имя - сейлз] FROM sales WHERE sales_id = @sales_id
		ROLLBACK --ЕСЛИ ВСЕ ОК, ТО НЕ ЗАБЫВАЕМ КОММИТИТЬ
		--COMMIT
	END
ELSE
	BEGIN
		SELECT @counter AS [Количество УЗ с такими ФИО], 'Пользователь не найден или их несколько. Выполните вручную' AS [Коммент]
		ROLLBACK
	END