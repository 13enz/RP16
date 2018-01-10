/*###### Create PIVOT VIEW ###### */

DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX);

select @cols = STUFF((SELECT distinct ',' + QUOTENAME([Risk_parameter]) 
            FROM [UAT_oracle_score]
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

/*******Create PIVOT View for Oracle Score ********/
IF OBJECT_ID('vUATOracleScore', 'V') IS NOT NULL
	DROP VIEW vUATOracleScore   

set @query = 'CREATE VIEW vUATOracleScore AS SELECT [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name,' + @cols + ' from 
            (
                select [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name, Risk_Parameter, Risk_Score 
                from [UAT_oracle_score]
           ) a
            pivot 
            (
               max(Risk_Score)
                for Risk_Parameter in (' + @cols + ')
            ) pvt'
execute(@query)

/*******Create PIVOT View for Oracle parameters Detail********/
IF OBJECT_ID('vUATOracleDetails', 'V') IS NOT NULL
	DROP VIEW vUATOracleDetails   
set @query = 'CREATE VIEW vUATOracleDetails AS SELECT [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name,' + @cols + ' from 
            (
                select [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name, Risk_Parameter, Risk_Details, Risk_Score
                from [UAT_oracle_score]
           ) a
            pivot 
            (
               max(Risk_Details)
                for Risk_Parameter in (' + @cols + ')
            ) pvt'
execute(@query)

/*###### Create PIVOT VIEW ###### */