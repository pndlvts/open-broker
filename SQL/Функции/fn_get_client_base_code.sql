USE [supdb]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_get_client_base_code]    Script Date: 18.04.2024 14:43:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Поиск базового кода персоны по коду клиента --  
ALTER function [dbo].[fn_get_client_base_code]  
(  
 @code varchar(20)  
)  
returns varchar(20)  
begin  
  
declare @client_base_code nvarchar(15)  
  
select @client_base_code = cb.code  
  from opendb.dbo.client as cc with(nolock)   
  join opendb.dbo.client as cb with(nolock) on cb.client_id = cc.client_base_id  
 where cc.code = @code  
  
return @client_base_code  
  
end