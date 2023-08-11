use opendb
open symmetric key sk_qort_quik_notification
decription by password = '' --указать
select a.person_guid as Guid ,
a.client_code as client_code,
a.firstname as firstname,
a.lastname as lastname,
replace(e.Email, ',', ';') as mail,
replace(e.Phones, ',', ';') as phone,
a.client_codespb as client_codespb,
a.client_codefrm as client_codefrm,
a.login as login,
convert(varchar(max), DecryptByKey(a.password)) as password
from qort.qort_db.dbo.firms e 
join opendb.dbo.vwQuikUserNotification a on a.client_code=e.BOcode
where a.client_code in (
'коды клиентов',
'коды клиентов'
)
close symmetric key sk_qort_quik_notification