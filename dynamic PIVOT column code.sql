---- Create PIVOT VIEW ----

DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX);

select @cols = STUFF((SELECT distinct ',' + QUOTENAME([Risk Parameter]) 
            FROM test_pivot
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

set @query = 'SELECT [Customer ID], ' + @cols + ' from 
            (
                select [Customer ID], [Customer Type], [Risk Score Model], [Risk Parameter], [Parameter Risk Score]
                from test_pivot
           ) a
            pivot 
            (
               max([Parameter Risk Score])
                for [Risk Parameter] in (' + @cols + ')
            ) pvt
            ORDER BY pvt.[Customer ID]'

execute(@query)