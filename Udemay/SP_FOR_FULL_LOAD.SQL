CREATE OR REPLACE PROCEDURE EMP.PROCS.SP_FOR_FULL_LOAD("SRCTBL" VARCHAR, "TGTTBL" VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER

AS

BEGIN
-- HERE THE SRCTBL AND TGTTBL ARE THE FULLY QUILIFIED NAMES i.e.,(DB.SCH.TBL)

TRUNCATE IDENTIFIER(:TGTTBL);

INSERT INTO IDENTIFIER(:TGTTBL)
SELECT * FROM IDENTIFIER(:SRCTBL);


/* or simply write like
INSERT OVERWRITE INTO IDENTIFIER(:TARGET_TABLE)
SELECT * FROM IDENTIFIER(:SOURCE_TABLE);
*/

/* if Source and Target table DDL are different then you can't automate this procedure
   you have to write a new procedure for each and every table 
   and you have to mention the column names explicitly like shown below
   
INSERT INTO IDENTIFIER(:TARGET_TABLE)
( 	employee_id
   ,first_name
   ,last_name
   ,email
   ,phone_number
   ,hire_date
   ,job_id
   ,salary
   ,commission_pct
   ,manager_id
   ,dept_id
)
SELECT 
	employee_id
   ,first_name
   ,last_name
   ,email
   ,phone_number
   ,hire_date
   ,job_id
   ,salary
   ,commission_pct
   ,manager_id
   ,dept_id 
FROM IDENTIFIER(:SOURCE_TABLE);

*/


RETURN 'FULL LOAD HAS BEEN SUCCESSFULL';

END;

SELECT COUNT(*) FROM EMP.STAGING.EMPLOYEES; --107
SELECT COUNT(*) FROM EMP.HRDATA.EMPLOYEES;  --0



CALL EMP.PROCS.SP_FOR_FULL_LOAD('EMP.STAGING.EMPLOYEES', 'EMP.HRDATA.EMPLOYEES');


SELECT COUNT(*) FROM EMP.STAGING.EMPLOYEES; --107
SELECT COUNT(*) FROM EMP.HRDATA.EMPLOYEES;  --107