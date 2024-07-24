select p.code, g.GUId, pc.Value from [Base].[Persons] p
LEFT JOIN [Base].[Objects:GUIds@Primary] g ON g.[Id] = p.[Id] 
LEFT JOIN [Base].[Persons:Contacts] pc ON p.Id = pc.Person_Id
where pc.Type_Id = 12 
AND p.code IN ()
--и провприть с файлом, который обогощаем