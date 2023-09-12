USE opendb
DECLARE @paynum NVARCHAR(8)
, @paydate NVARCHAR(8)
, @id INT
, @new_sum NVARCHAR(32)
, @rq_id INT
SET @paynum = '' -- Номер платежного поручения
SET @paydate = '' -- Дата платежа
SET @new_sum = '' -- Новая сумма платежа
SELECT @id = ordersnotradein.id, @rq_id = ordersnotradein.request_id FROM ordersnotradein WHERE paynum = @paynum AND paydate = @paydate
BEGIN TRAN
--меняем данные в поручении:
--было:
SELECT * FROM ordersnotradein WHERE paynum = @paynum AND paydate = @paydate
--обновляем
UPDATE ordersnotradein
SET tsum = @new_sum
WHERE id = @id
--стало:
SELECT * FROM ordersnotradein WHERE paynum = @paynum AND paydate = @paydate
--меняем данные в очереди (в xml), в разделе <sum error = 0>, сохраняя 4 знака после запятой
--было:
SELECT * FROM request_queue WHERE request_id = @rq_id
--обновляем
UPDATE request_queue
SET request_xml.modify('replace value of (order/sum/text())[1] with sql:variable("@new_sum")')
WHERE request_id = @rq_id
--стало:
SELECT * FROM request_queue WHERE request_id = @rq_id
ROLLBACK --проверяем, если все ок, то коммитим
--COMMIT
