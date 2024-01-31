-- По вопросам писать pandelov_ts@open.ru. tg-pndlvts
USE opendb 
SELECT TOP 10 * FROM mt5.object_queue oq
LEFT JOIN dbo.request_queue rq 
ON oq.request_id = rq.request_id
WHERE oq.ts > CONVERT(NVARCHAR, GETDATE(), 112) AND oq.status <> 2 AND oq.handled_error = 0


--Проверяем команды с ошибками. В идеале обрабатываются день в день. 
USE opendb
SELECT TOP 10 * FROM mt5.object_queue WHERE ts > '20230721' AND status <> 2 AND handeled_error = 0 -- СТАВИМ НУЖНУЮ ДАТУ В УСЛОВИЕ!



-- Транзакция для установки handeled_error = 1. Так ошибка не будет попадать в графану и алерт. 
USE opendb
DECLARE @id INT
SET @id = <id_команды> --ВПИСЫВАЕМ ID  В ПЕРЕМЕННУЮ!
BEGIN TRAN
UPDATE mt5.object_queue
SET handeled_error = 1
WHERE id = @id
SELECT * FROM mt5.object_queue WHERE id = @id
ROLLBACK --Если все ок, то коммитим.Если нет-роллбэк
--COMMIT



--Если команда долго висит в статусе 4 (долго отрабатывает), то скидываем в первоначальный статус 1 (новая), result = NULL, скорее всего там ничео и не будет, тк команда не отработала и xml не записался.
USE opendb
DECLARE @request_id INT
SET @request_id = <id_заявки> -- вписываем реквест_ид, можно и по обычному ид
BEGIN TRAN
UPDATE mt5.object_queue
SET status = 1, result = NULL
WHERE request_id = @request_id
SELECT * FROM mt5.object_queue WHERE request_id = @request_id
ROLLBACK --Если все ок, то коммитим.Если нет-роллбэк
--COMMIT



--Выборка заявки (не команды) для проверки статуса, типа заявки и пр.
SELECT * FROM dbo.request_queue WHERE request_id = <id_заявки> --берете нужный вам идентификатор



--Ошибка обновления клиентской записи по таймауту при отключении метатрейдера
BEGIN TRAN
UPDATE dbo.request_queue
SET state_id = 687, condition_mask = 0
WHERE request_id = <id_заявки>
UPDATE mt5.object_queue
SET status = 1, result = NULL
WHERE request_id = <id_заявки>
ROLLBACK --Если все ок, то коммитим.Если нет-роллбэк
--COMMIT
--далее проверяем статус ответа от мт5 в object_queue. Если все ок, то обрабатываем диспатчером
EXEC dbo.wf_dispatcher_async @request_id = <id_заявки>