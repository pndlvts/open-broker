USE opendb
OPEN SYMMETRIC KEY SK_QORT_QUIK_NOTIFICATION
DECRYPTION BY PASSWORD = '';
SELECT
a.person_guid as Guid,
a.client_code as CLIENT_CODE, 
a.firstname as FIRSTNAME, 
a.lastname as    LASTNAME, 
REPLACE(e.Email, ',',';') as MAIL,
REPLACE(e.Phones, '+','') as PHONE,
a.client_codespb as CLIENT_CODESPB,
a.client_codefrm as CLIENT_CODEFRM,
a.login as LOGIN,
CONVERT(varchar(max), DecryptByKey(a.password)) as PASSWORD
from [QUORT].[QORT_DB].[dbo].[Firms] e
right join [opendb].[dbo].[vwQuikUserNotification] a on a.client_code=e.BOcode
where a.client_code in
(
'841281', '840732'
)