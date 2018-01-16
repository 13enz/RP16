/**** Create a combined table *****/
/* ----Start of Step 2 ----*/
drop table RISK_SCORE_KYC_ALL;

SELECT N_RA_ID as N_RA_ID,
	   V_CUST_NUMBER as Customer_ID,
	   V_CUST_TYPE_CD as Customer_Type,
       V_CUSTOMER_NAME as Customer_Name,
       N_EFFECTIVE_RISK_CTGRY_KEY as Risk_Category,
       N_EFFECTIVE_RISK_SCORE as Customer_RiskScore,
       v_risk_param_code as Risk_parameter,
       v_risk_details as Risk_Details,
       N_RISK_SCORE as Risk_Score,
       V_RISK_SCORING_TYPE as Risk_Scoring_Model
INTO   RISK_SCORE_KYC_ALL
FROM (
SELECT *
FROM   RISK_SCORE_KYC_Slice1
UNION ALL
SELECT *
FROM   RISK_SCORE_KYC_Slice2
UNION ALL
SELECT *
FROM   RISK_SCORE_KYC_Slice3
UNION ALL
SELECT *
FROM   RISK_SCORE_KYC_Slice4
UNION ALL
SELECT *
FROM   RISK_SCORE_KYC_Slice5
) M

/* ----END of Step 1 ----*/

/***** Missing customer names *****/
/*
SELECT   V_CUST_NUMBER, SUM(CASE WHEN V_CUSTOMER_NAME = '' THEN 0 ELSE 1 END) AS COUNT
FROM     RISK_SCORE_KYC_ALL
GROUP BY V_CUST_NUMBER
HAVING   SUM(CASE WHEN V_CUSTOMER_NAME = '' THEN 0 ELSE 1 END) = 0
-- count = 420371 rows
-- examples: IP0366273D, PG0142182K, 151095M, 403218H, JM0304417H
*/


/* ----Start of Step 2 ----*/
/*###### Create PIVOT VIEW ###### */

DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX);

select @cols = STUFF((SELECT distinct ',' + QUOTENAME([Risk_parameter]) 
            FROM [RISK_SCORE_KYC_ALL]
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

/*******Create PIVOT View for Oracle Score ********/
IF OBJECT_ID('vUATOracleScore', 'V') IS NOT NULL
	DROP VIEW vUATOracleScore   

set @query = 'CREATE VIEW vUATOracleScore AS SELECT [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name,' + @cols + ' from 
            (
                select [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name, Risk_Parameter, Risk_Score 
                from [RISK_SCORE_KYC_ALL]
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
                select [Customer_ID],[Customer_RiskScore], Customer_Type, Customer_Name, Risk_Parameter, Risk_Details
                from [RISK_SCORE_KYC_ALL]
           ) a
            pivot 
            (
               max(Risk_Details)
                for Risk_Parameter in (' + @cols + ')
            ) pvt'
execute(@query)

/*###### Create PIVOT VIEW ###### */

/* ----END of Step 2 ----*/


/* ----Start of Step 3 ----*/
/*----- Compare simulation with Oracle KYC -----*/
drop table RISK_SCORE_KYC_UNMATCH;

select   -- Oracle Parameters from PIVOT views
         b.Customer_ID,
         b.Customer_Name,
         b.Customer_Type,
	     b.Customer_RiskScore as FCCM_KYC_SCORE,
		 a.KYC_RISK_SCORE as SIM_KYC_SCORE,

		 -- Citizenship risk
    	 b.[MB_CCR_GEO_CTZ],
		 b.[RB_CCR_PRMRY_CTZSHP],
		 a.P1_RISK AS SIM_CITIZENSHIP_RISK,

		 -- Residency Risk
	     b.[MB_CCR_GEO_RES],
		 b.[RB_CCR_RES],
		 a.P2_RISK AS SIM_RESIDENCY_RISK,

		 -- Occupation Risk
	     b.[MB_CCR_OCP_RSK],	
		 b.[RB_CCR_OCCUP],
		 a.P3_RISK AS SIM_OCCUPATION_RISK,

		 -- Industry Risk
	     b.[MB_CCR_IND_RSK],
		 b.[RB_CCR_INDUS_RISK],
		 a.C2_RISK AS SIM_INDUSTRY_RISK,

		 -- Length of relationship
	     b.[MB_CCR_REL_PRD],
		 a.C3_RISK AS SIM_LEN_REL_RISK,

		 -- Corporate age
	     b.[MB_CCR_COR_AGE],
	     a.C1_RISK AS SIM_CORP_AGE_RISK,

	     -- Account type risk
	     b.[MB_CCR_ACT_PRD_RSK],
	     a.P5_RISK AS SIM_ACCTTYPE_IND_RISK,
		 a.C4_RISK AS SIM_ACCTTYPE_ORG_RISK
	     
into     RISK_SCORE_KYC_UNMATCH
from     vUATOracleScore b 
		 left join T_KYC_RISK_SCORE a on b.Customer_ID = a.CUSTOMER_ID
where    b.Customer_RiskScore <> a.KYC_RISK_SCORE;
/* ----End of Step 3 ----*/

/*
select count(*) from RISK_SCORE_KYC_UNMATCH  
select count(distinct CUSTOMER_ID) from vUATOracleScore 
*/


/* ----Start of Step 4 ----*/
/***** Determine cause of failure *****/
--- Induvidual
select   Customer_Type,

         sum(case when SIM_CITIZENSHIP_RISK = [RB_CCR_PRMRY_CTZSHP] then 0
		          when SIM_CITIZENSHIP_RISK = [MB_CCR_GEO_CTZ] then 0
			      else 1 end) as CITIZENSHIP_FAILED,

         sum(case when SIM_RESIDENCY_RISK = [RB_CCR_RES] then 0
		          when SIM_RESIDENCY_RISK = [MB_CCR_GEO_RES] then 0
			      else 1 end) as RESIDENCY_FAILED,

         sum(case when SIM_OCCUPATION_RISK = [RB_CCR_OCCUP] then 0
		          when SIM_OCCUPATION_RISK = [MB_CCR_OCP_RSK] then 0
			      else 1 end) as OCCUPATION_FAILED,

         sum(case when SIM_ACCTTYPE_IND_RISK = [MB_CCR_ACT_PRD_RSK] then 0
		          else 1 end) as ACCT_TYPE_FAILED

from     RISK_SCORE_KYC_UNMATCH
where    Customer_Type = 'IND'
group by Customer_Type;
		 
--- Cooperate		 
select   Customer_Type,

         sum(case when SIM_INDUSTRY_RISK = [RB_CCR_INDUS_RISK] then 0
		          when SIM_INDUSTRY_RISK = [MB_CCR_IND_RSK] then 0
			      else 1 end) as INDUSTRY_FAILED,

         sum(case when SIM_LEN_REL_RISK = [MB_CCR_REL_PRD] then 0
			      else 1 end) as LEN_REL_FAILED,

         sum(case when SIM_CORP_AGE_RISK = [MB_CCR_COR_AGE] then 0
			      else 1 end) as CORP_AGE_FAILED,

         sum(case when SIM_ACCTTYPE_ORG_RISK = [MB_CCR_ACT_PRD_RSK] then 0
			      else 1 end) as ACCT_TYPE_FAILED

from     RISK_SCORE_KYC_UNMATCH
where    Customer_Type = 'ORG'
group by Customer_Type;         



-----------------------------------------------------------------------------------------------------------------
/***** Citizenship Failed *****/
/*
select   a.Customer_ID,
         a.Customer_Name,
         a.Customer_Type,
	     a.FCCM_KYC_SCORE,
		 a.SIM_KYC_SCORE,
		 a.SIM_CITIZENSHIP_RISK,
		 a.[RB_CCR_PRMRY_CTZSHP],
		 max(b.[RB_CCR_PRMRY_CTZSHP]) as RB_CCR_PRMRY_CTZSHP_DTLS,
		 a.[MB_CCR_GEO_CTZ],
		 b.[MB_CCR_GEO_CTZ] as MB_CCR_GEO_CTZ_DTLS,
		 c.NATIONALITY_CODE
from     RISK_SCORE_KYC_UNMATCH a
         left join [dbo].[vUATOracleDetails] b on a.Customer_ID = b.Customer_ID
		 left join T_KYC_RISK_SCORE c on a.Customer_ID = c.CUSTOMER_ID
where    a.customer_type = 'IND'
         and a.SIM_CITIZENSHIP_RISK <> (case when a.[RB_CCR_PRMRY_CTZSHP] is null then a.[MB_CCR_GEO_CTZ] else a.[RB_CCR_PRMRY_CTZSHP] end)
group by a.Customer_ID,
         a.Customer_Name,
         a.Customer_Type,
	     a.FCCM_KYC_SCORE,
		 a.SIM_KYC_SCORE,
		 a.SIM_CITIZENSHIP_RISK,
		 a.[RB_CCR_PRMRY_CTZSHP],
		 a.[MB_CCR_GEO_CTZ],
		 b.[MB_CCR_GEO_CTZ],
		 c.NATIONALITY_CODE;
*/


/** Individual **/
/***** Occupation failed *****/
select   a.Customer_ID,
         a.Customer_Name,
         a.Customer_Type,
		 a.SIM_OCCUPATION_RISK,
		 a.[RB_CCR_OCCUP],
		 a.[MB_CCR_OCP_RSK],
		 c.OCCUPATION,
		 c.FCCM_OCCUPATION,
         b.[RB_CCR_OCCUP] as [RB_CCR_OCCUP],
         b.[MB_CCR_OCP_RSK] as [MB_CCR_OCP_RSK]
from     RISK_SCORE_KYC_UNMATCH a
         left join [dbo].[vUATOracleDetails] b on a.Customer_ID = b.Customer_ID
		 left join T_KYC_RISK_SCORE c on a.Customer_ID = c.CUSTOMER_ID
where    a.customer_type = 'IND'
         and a.SIM_OCCUPATION_RISK <> (case when a.[RB_CCR_OCCUP] is null then a.[MB_CCR_OCP_RSK] else a.[RB_CCR_OCCUP] end)

---- Account Type failed ----    
select   a.Customer_ID,
         a.Customer_Name,
         a.Customer_Type,
		 a.SIM_ACCTTYPE_IND_RISK,
		 a.[MB_CCR_ACT_PRD_RSK] as [MB_CCR_ACT_PRD_RSK_SCORE],
		 c.Product_source_type_code,
		 c.FCCM_ACCT_TYPE,
		 b.[MB_CCR_ACT_PRD_RSK] as [MB_CCR_ACT_PRD_RSK_DETAIL]
from     RISK_SCORE_KYC_UNMATCH a
         left join [dbo].[vUATOracleDetails] b on a.Customer_ID = b.Customer_ID
		 left join T_KYC_RISK_SCORE c on a.Customer_ID = c.CUSTOMER_ID
where    a.customer_type = 'IND' and a.SIM_ACCTTYPE_IND_RISK <> a.[MB_CCR_ACT_PRD_RSK]


/* Cooperate  */
----- LEN_REL failed -----
select   a.Customer_ID,
         a.Customer_Name,
         a.Customer_Type,
		 a.SIM_LEN_REL_RISK,
		 a.[MB_CCR_REL_PRD],
		 c.ACQUISITION_DATE,
		 c.DATE_OPENED,
		 c.LEN_OF_REL_MTH,
		 b.[MB_CCR_REL_PRD]
from     RISK_SCORE_KYC_UNMATCH a
         left join [dbo].[vUATOracleDetails] b on a.Customer_ID = b.Customer_ID
		 left join T_KYC_RISK_SCORE c on a.Customer_ID = c.CUSTOMER_ID
where    a.customer_type = 'ORG' and a.SIM_LEN_REL_RISK <> a.[MB_CCR_REL_PRD]

----- CORP_AGE failed -----
select   a.Customer_ID,
         a.Customer_Name,
         a.Customer_Type,
		 a.SIM_CORP_AGE_RISK,
		 a.[MB_CCR_COR_AGE],
		 c.INCORPORATION_DATE,
		 c.CORP_AGE_MTH,
		 b.[MB_CCR_COR_AGE]
from     RISK_SCORE_KYC_UNMATCH a
         left join [dbo].[vUATOracleDetails] b on a.Customer_ID = b.Customer_ID
		 left join T_KYC_RISK_SCORE_ORIG c on a.Customer_ID = c.CUSTOMER_ID
where    a.customer_type = 'ORG' and a.SIM_CORP_AGE_RISK <> a.[MB_CCR_COR_AGE]



----- ACCT_TYPE failed -----
select   a.Customer_ID,
         a.Customer_Name,
         a.Customer_Type,
		 a.SIM_ACCTTYPE_ORG_RISK,
		 a.[MB_CCR_ACT_PRD_RSK],
		 c.Product_source_type_code,
		 c.FCCM_ACCT_TYPE,
		 b.[MB_CCR_ACT_PRD_RSK]
from     RISK_SCORE_KYC_UNMATCH a
         left join [dbo].[vUATOracleDetails] b on a.Customer_ID = b.Customer_ID
		 left join T_KYC_RISK_SCORE_ORIG c on a.Customer_ID = c.CUSTOMER_ID
where    a.customer_type = 'ORG' and a.SIM_ACCTTYPE_ORG_RISK <> a.[MB_CCR_ACT_PRD_RSK]


---- More detail for Account information ---
--- For our simulation
select * from [dbo].[TAMLA_STG_ACCOUNTS_BASE_KYC] where CUSTOMER_SOURCE_UNIQUE_ID = '000118080756'

--- For Oracle KYC result
select * from [dbo].[RISK_SCORE_KYC_ALL] where Customer_ID = '000118080756'

