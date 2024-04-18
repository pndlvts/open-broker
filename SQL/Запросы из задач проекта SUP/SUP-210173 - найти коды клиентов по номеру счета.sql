use [opendb]
select supdb.dbo.fn_get_client_base_code(c.code) as [Базовый код], c.code as [Номер счета] 
from client as c where code in (
--коды
)
