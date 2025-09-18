-- Automate this process to run every day

CREATE OR REPLACE TASK staging.task_automated_data_load
SCHEDULE = 'USING CRON 0 7 * * * UTC'
AS
call mydb.staging.sp_automate_data_copy();

-- Process different files at different timings
CREATE OR REPLACE PROCEDURE mydb.staging.sp_automate_data_copy("table_name" VARCHAR)

curs cursor for select * from mydb.control.copy_ctrl where is_active = TRUE and stage_table_name =: table_name;

-- every day at 8 am customer_data
CREATE OR REPLACE TASK staging.task_automated_data_load
schedule = 'USING CRON 0 8 * * * UTC'
AS
call mydb.staging.sp_automate_data_copy('customer_data');

-- Every Day at 10 am and 10 pm emp_data
CREATE OR REPLACE TASK staging.task_automated_data_load
schedule = 'USING CRON 0 10,22 * * * UTC'
AS
call mydb.staging.sp_automate_data_copy('emp_data');


-- every monday at 6.30 am pets_data_raw
CREATE OR REPLACE TASK staging.task_automated_data_load
schedule = 'USING CRON 30 6 * * 1 UTC'
AS
call mydb.staging.sp_automate_data_copy('pets_data_raw');


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
/* Parameterized SP*/

CREATE OR REPLACE PROCEDURE mydb.staging.sp_automate_data_copy(table_name VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
DECLARE
    curs CURSOR FOR 
        SELECT * 
        FROM mydb.control.copy_ctrl 
        WHERE is_active = TRUE
          AND stage_table_name = :table_name;

    tbl STRING;
    sch STRING;
    db STRING;
    st_int STRING;
    st_loc STRING;
    file_typ STRING;
    file_pat STRING;
    fld_dlm STRING;
    skp_hdr STRING;
    forc STRING;
    on_err STRING;
    trun_col STRING;
    cnt INTEGER;
    ret STRING;
    file_format1 STRING;
    copy_stmt STRING;
    create_stage_stmt STRING;
    fp STRING;

BEGIN
    ret := '';

    FOR rec IN curs DO
        tbl := rec.stage_table_name;
        sch := rec.schema_name;
        db := rec.database_name;
        st_int := rec.storage_int;
        st_loc := rec.storage_loc;
        file_typ := rec.files_typ;
        file_pat := rec.files_pattern;
        fld_dlm := rec.field_delim;
        skp_hdr := rec.skip_header;
        forc := rec.force;
        on_err := rec.on_error;
        trun_col := rec.truncate_cols;

        IF (LOWER(:file_typ) = 'csv') THEN
            file_format1 := '(TYPE='||:file_typ||' SKIP_HEADER='||:skp_hdr||
                            ' FIELD_DELIMITER=\''||:fld_dlm||'\' EMPTY_FIELD_AS_NULL=TRUE)';
        ELSE
            file_format1 := '(TYPE='||:file_typ||')';
        END IF;

        create_stage_stmt := 'CREATE OR REPLACE TEMPORARY STAGE mydb.external_stages.s3_stage
                              URL = \''|| :st_loc || '\'
                              STORAGE_INTEGRATION = '|| :st_int ||'
                              FILE_FORMAT = ' ||:file_format1 ;

        EXECUTE IMMEDIATE create_stage_stmt;

        list @mydb.external_stages.s3_stage;
        SELECT COUNT(1) INTO cnt FROM table(result_scan(last_query_id()));

        IF (:cnt > 0) THEN
            copy_stmt := 'COPY INTO '||:db||'.'||:sch||'.'||:tbl||'
                          FROM @mydb.external_stages.s3_stage
                          PATTERN = \''||:file_pat||'\' 
                          ON_ERROR = '||:on_err||'
                          FORCE = '||:forc||'
                          TRUNCATECOLUMNS = '||:trun_col;

            EXECUTE IMMEDIATE copy_stmt;
            ret := :ret || :tbl || ' files loaded successfully.\n';
        ELSE
            ret := :ret || :tbl || ' no matching files in stage.\n';
        END IF;
    END FOR;

    RETURN :ret;
END;










-- Creating tasks with different schedules

-- Run customer_data every day at 8 am UTC
CREATE OR REPLACE TASK staging.task_customer_data_load
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON 0 8 * * * UTC'
AS
CALL mydb.staging.sp_automate_data_copy('CUSTOMER_DATA');

-- Run emp_data every day at 10 am and 10 pm UTC
CREATE OR REPLACE TASK staging.task_emp_data_load
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON 0 10,22 * * * UTC'
AS
CALL mydb.staging.sp_automate_data_copy('EMP_DATA');

-- Run pets_data_raw every Monday at 6:30 am UTC
CREATE OR REPLACE TASK staging.task_pets_data_load
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON 30 6 * * 1 UTC'
AS
CALL mydb.staging.sp_automate_data_copy('PETS_DATA_RAW');

-- Run customer every day at 11 am and 11 pm UTC
CREATE OR REPLACE TASK staging.task_customer_load
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON 0 11,23 * * * UTC'
AS
CALL mydb.staging.sp_automate_data_copy('customer');





