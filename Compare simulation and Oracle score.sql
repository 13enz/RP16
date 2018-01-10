/* -- Compare KYC scoring  --*/
--- Code to Check ---

drop table #temp_unmatch
select --* ,
	a.CUSTOMER_ID, 
	a.CUSTOMER_NAME, 
	a.CUSTOMER_TYPE_CODE,
	a.KYC_RISK_SCORE,
	a.P1_RISK,
	a.P2_RISK,
	a.P3_RISK,
	a.P5_RISK,
	a.C1_RISK,
	a.C2_RISK,
	a.C3_RISK,
	a.C4_RISK,
	b.Customer_RiskScore,
	b.[MB_CCR_GEO_CTZ],
	b.[MB_CCR_GEO_RES],
	b.[MB_CCR_OCP_RSK],	
	b.[MB_CCR_ACT_PRD_RSK],
	[MB_CCR_IND_RSK],
	[MB_CCR_REL_PRD],
	[MB_CCR_COR_AGE],
	[RB_CCR_INDUS_RISK],
	[RB_CCR_OCCUP],
	[RB_CCR_PRMRY_CTZSHP],
	[RB_CCR_RES]
into #temp_unmatch
from T_KYC_RISK_SCORE a
JOIN vUATOracleScore b ON a.CUSTOMER_ID = b.Customer_ID
where a.KYC_RISK_SCORE <> b.Customer_RiskScore

select * from #temp_unmatch 

--#### USE for crete PIVOT View for Oracle ####--
--- Check column to do PIVOT
select distinct Risk_Parameter from ['UAT_ORACLE_KYC_SCORING']

--- PIVOT 
select [Customer_ID],[Customer_RiskScore], 
	[MB_CCR_ACT_PRD_RSK] AS MB_CCR_ACT_PRD_RSK,
	[MB_CCR_COR_AGE] AS MB_CCR_COR_AGE,
	[MB_CCR_GEO_CTZ] AS MB_CCR_GEO_CTZ,
	[MB_CCR_GEO_RES] AS MB_CCR_GEO_RES,
	[MB_CCR_IND_RSK] AS MB_CCR_IND_RSK,
	[MB_CCR_OCP_RSK] AS MB_CCR_OCP_RSK,
	[MB_CCR_REL_PRD] AS MB_CCR_REL_PRD,
	[RB_CCR_INDUS_RISK] AS RB_CCR_INDUS_RISK,
	[RB_CCR_OCCUP] AS RB_CCR_OCCUP,
	[RB_CCR_PRMRY_CTZSHP] AS RB_CCR_PRMRY_CTZSHP,
	[RB_CCR_RES] AS RB_CCR_RES
FROM 
( SELECT [Customer_ID],[Customer_RiskScore], Risk_Parameter, Parameter_risk_score 
FROM ['UAT_ORACLE_KYC_SCORING'] ) p
PIVOT
(
max(Parameter_risk_score) FOR Risk_Parameter IN (
	[MB_CCR_ACT_PRD_RSK],
	[MB_CCR_COR_AGE],
	[MB_CCR_GEO_CTZ],
	[MB_CCR_GEO_RES],
	[MB_CCR_IND_RSK],
	[MB_CCR_OCP_RSK],
	[MB_CCR_REL_PRD],
	[RB_CCR_INDUS_RISK],
	[RB_CCR_OCCUP],
	[RB_CCR_PRMRY_CTZSHP],
	[RB_CCR_RES])
) AS pvt
ORDER BY pvt.Customer_ID

--- PIVOT parameter scoring from UAT_oracle_score --- 
select * from [dbo].[UAT_oracle_score] where customer_id = '000551814U'
select [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name, 
	[MB_CCR_ACT_PRD_RSK] AS MB_CCR_ACT_PRD_RSK_S,
	[MB_CCR_COR_AGE] AS MB_CCR_COR_AGE_S,
	[MB_CCR_GEO_CTZ] AS MB_CCR_GEO_CTZ_S,
	[MB_CCR_GEO_RES] AS MB_CCR_GEO_RES_S,
	[MB_CCR_IND_RSK] AS MB_CCR_IND_RSK_S,
	[MB_CCR_OCP_RSK] AS MB_CCR_OCP_RSK_S,
	[MB_CCR_REL_PRD] AS MB_CCR_REL_PRD_S,
	[RB_CCR_INDUS_RISK] AS RB_CCR_INDUS_RISK_S,
	[RB_CCR_OCCUP] AS RB_CCR_OCCUP_S,
	[RB_CCR_PRMRY_CTZSHP] AS RB_CCR_PRMRY_CTZSHP_S,
	[RB_CCR_RES] AS RB_CCR_RES
FROM 
( SELECT [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name, Risk_Parameter, Risk_Score 
FROM [dbo].[UAT_oracle_score] ) p
PIVOT
(
max(Risk_Score) FOR Risk_Parameter IN (
	[MB_CCR_ACT_PRD_RSK],
	[MB_CCR_COR_AGE],
	[MB_CCR_GEO_CTZ],
	[MB_CCR_GEO_RES],
	[MB_CCR_IND_RSK],
	[MB_CCR_OCP_RSK],
	[MB_CCR_REL_PRD],
	[RB_CCR_INDUS_RISK],
	[RB_CCR_OCCUP],
	[RB_CCR_PRMRY_CTZSHP],
	[RB_CCR_RES])
) AS pvt
ORDER BY pvt.Customer_ID


--- PIVOT parameter detail from UAT_oracle_score ---
select [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name, 
	[MB_CCR_ACT_PRD_RSK] AS MB_CCR_ACT_PRD_RSK_D,
	[MB_CCR_COR_AGE] AS MB_CCR_COR_AGE_D,
	[MB_CCR_GEO_CTZ] AS MB_CCR_GEO_CTZ_D,
	[MB_CCR_GEO_RES] AS MB_CCR_GEO_RES_D,
	[MB_CCR_IND_RSK] AS MB_CCR_IND_RSK_D,
	[MB_CCR_OCP_RSK] AS MB_CCR_OCP_RSK_D,
	[MB_CCR_REL_PRD] AS MB_CCR_REL_PRD_D,
	[RB_CCR_INDUS_RISK] AS RB_CCR_INDUS_RISK_D,
	[RB_CCR_OCCUP] AS RB_CCR_OCCUP_D,
	[RB_CCR_PRMRY_CTZSHP] AS RB_CCR_PRMRY_CTZSHP_D,
	[RB_CCR_RES] AS RB_CCR_RES_D
FROM 
( SELECT [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name, Risk_Parameter, Risk_Details 
FROM [dbo].[UAT_oracle_score] ) p
PIVOT
(
max(Risk_Details) FOR Risk_Parameter IN (
	[MB_CCR_ACT_PRD_RSK],
	[MB_CCR_COR_AGE],
	[MB_CCR_GEO_CTZ],
	[MB_CCR_GEO_RES],
	[MB_CCR_IND_RSK],
	[MB_CCR_OCP_RSK],
	[MB_CCR_REL_PRD],
	[RB_CCR_INDUS_RISK],
	[RB_CCR_OCCUP],
	[RB_CCR_PRMRY_CTZSHP],
	[RB_CCR_RES])
) AS pvt
ORDER BY pvt.Customer_ID

-------

select * from vUATOracleDetails a
join #temp_unmatch b on a.customer_id = b.CUSTOMER_ID
