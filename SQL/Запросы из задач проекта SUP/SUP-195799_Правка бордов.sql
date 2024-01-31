USE opendb
-- id  бордов - 522 и 528
BEGIN TRAN
UPDATE opendb.dbo.[spr_mcx_cmn_boards]
SET currency_id = 840, 
section_code = 'FS'
WHERE id IN (522, 528)
SELECT * FROM opendb.dbo.[spr_mcx_cmn_boards] WHERE id IN (522, 528)
--ROLLBACK
COMMIT