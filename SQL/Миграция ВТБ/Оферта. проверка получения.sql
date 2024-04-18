use [opendb_esb]
go

/*
    � ������ �� ������ ���� [���-�� �� ���������� ���������], ���� ��� �� ������ 200
    "���-�� �� ������������ ������:" �� ������ ���� ������ 100

    ���� ���������� ����, �� �������� ������� ������-�������
        -����� � ������� https://grafana.open-broker.ru/d/9kuxSrjWk/ntp?orgId=10 ������ "������� Opendb_ESB"
        - ���� ������ select count(1) from  [InOut].[Queue:Message@Receive?Request:8] with (nolock)
    ���� ������� �� ������������, �� ����� ��� ��� ����������� �������
*/


declare 
    @datetime_from datetime = '2023-10-02 00:00:00',
    @type_id int;

select @type_id = id from [opendb_esb].[InOut].[Requests->Types] where Code = 'OPENDB:VTB-OFFER:SYNC'

select 
    [������� ����� ��������� ������] = count(1),
    [����� ������� ���������] = min([RecieveDateTime]), 
    [����� ���������� ���������] = max([RecieveDateTime]),
    [���-�� �� ���������� ���������] = sum(iif(DispatchDateTime is null,1,0))
from  [opendb_esb].[InOut].[Messages:In] MI  
where 
    MI.type = 'OPENDB:VTB-OFFER:SYNC'
    and MI.[RecieveDateTime] >= @datetime_from

drop table if exists #requests
 
 SELECT 
    IN_ID                   = MI.Id,
    IN_RecieveDateTime      = MI.RecieveDateTime,
    IN_DispatchDateTime     = MI.DispatchDateTime,

    Request_GUID            = MI.guid, 
    Request_Status          = R.Status_Id,
    Request_CreateDateTime  = R.CreateDateTime, 
    Request_UpdateDateTime  = R.UpdateDateTime,
    Request_Data            = MI.Data,

    Response_GUID            = RE.GUId,
    Response_Status_Id       = RE.Status_Id, 
    Response_CreateDateTime  = RE.CreateDateTime, 
    Response_UpdateDateTime  = RE.UpdateDateTime,
    Response_Data            = MO.Data,

    OUT_CreateDateTime       = MO.CreateDateTime, 
    OUT_OutgoDateTime        = MO.OutgoDateTime, 

    Person_GUId              = cast(null as varchar(50)), 
    Send_Date                = cast(null as datetime), 
    Error_text               = cast(null as varchar(max))

into #requests

FROM [opendb_esb].[InOut].[Messages:In] MI
left join [opendb_esb].[InOut].[Requests] R
on R.guid = MI.guid
left join [opendb_esb].[InOut].[Requests->Types] RT
on RT.id = R.type_id
left join [opendb_esb].[InOut].[Responses] RE
on RE.Request_Id = R.id
left join [opendb_esb].[InOut].[Messages:Out] MO
on MO.GUId = RE.GUId
where 
    MI.type = 'OPENDB:VTB-OFFER:SYNC'
    and [RecieveDateTime] >= @datetime_from
order by MI.id

update #requests set
    Person_GUId = Request_Data.value('(/REQUEST/OFFER/@Person_GUId)[1]','varchar(50)'),
    Send_Date   = Request_Data.value('(/REQUEST/OFFER/@Send_Date)[1]','varchar(100)'),
    Error_text  = Response_Data.value('(//@Message)[1]','varchar(1000)')
update #requests set
     Error_text  = left(replace(Error_text,'PROCEDURE �[InOut].[Request=Opendb:Vtb-Offer:Sync@Execute]�, ',''),114)

--������� ����� ��������� ������� ��������
;with ccount as
(
    select n = DATEDIFF(millisecond,IN_RecieveDateTime, OUT_OutgoDateTime) from #requests 
)
select 
    '������� ����� ��������� ������� ��������, ������',  SUM(n)/count(1)
from ccount
union all
select 
    '������� ����� ��������� ��������� �� ��, ������', 182


select '������� ���-�� ������������ ��������� � ������', sum(cc)/count(1)
from 
    (select time =  format(IN_DispatchDateTime,'yyyy-MM-dd hh:mm'), cc = count(1) from #requests group by format(IN_DispatchDateTime,'yyyy-MM-dd hh:mm')) t


;with cte as (
select 
    name = case Request_Status
                when 't' then '���-�� �� ������������ ������: '
                when 'R' then '���-�� ������ � ������: '
            end
    , 
    v     = case Request_Status
                when 't' then 1
                when 'R' then 1
            end,*
from 
    #requests 
where 
    Request_Status in ('t','R') 
    and isnull(Error_text,'') != 'LINE 697: Cannot insert duplicate key row in object ''dbo.dogovor'' with unique index ''ix_uniq_1047_not_end_dogovor'''
)
select name , count(1) from cte group by name



