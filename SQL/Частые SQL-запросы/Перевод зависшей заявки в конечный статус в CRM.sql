USE siebeldb
 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 
DECLARE @ROW_ID NVARCHAR(15);
SET @ROW_ID = '<подставить ROW_ID>';                            --подставить ROW_ID
 
SELECT STATUS,* FROM CX_DOC_REQUEST WHERE ROW_ID = @ROW_ID;     --статус был
 
UPDATE CX_DOC_REQUEST
SET STATUS = CASE SOURCE_TYPE
                WHEN 'Личный кабинет' THEN 'Отказ клиента'
                WHEN 'Визит в офис'   THEN 'Отказ БД'
             END
WHERE ROW_ID = @ROW_ID;                                         --апдейт статуса
 
SELECT STATUS,* FROM CX_DOC_REQUEST WHERE ROW_ID = @ROW_ID;     --статус стал