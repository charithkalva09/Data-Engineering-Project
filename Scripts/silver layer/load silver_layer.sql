DROP PROCEDURE IF EXISTS silver.load_silver();

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Truncate Table before Inserting Data into silver.crm_cstr_info
    TRUNCATE TABLE silver.crm_cstr_info;

    -- Inserting Cleaned Data into silver.crm_cstr_info
    INSERT INTO silver.crm_cstr_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname) cst_firstname,
        TRIM(cst_lastname) cst_lastname,
        CASE UPPER(cst_marital_status)
            WHEN 'S' THEN 'Single'
            WHEN 'M' THEN 'Married'
            ELSE 'n/a'
        END AS cst_marital_status,
        CASE UPPER(cst_gndr)
            WHEN 'M' THEN 'Male'
            WHEN 'F' THEN 'Female'
            ELSE 'n/a'
        END AS cst_gender,
        cst_create_date
    FROM (
            SELECT
                *,
                row_number() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) flag
            FROM bronze.crm_cstr_info) t
    WHERE flag = 1;


    -- Truncate Table before Inserting Data into silver.crm_prd_info
    TRUNCATE TABLE silver.crm_prd_info;

    -- Inserting Cleaned Data into silver.crm_prd_info
    INSERT INTO silver.crm_prd_info(prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
    SELECT
        prd_id,
        REPLACE(SUBSTR(prd_key,1,5),'-','_') cat_id,
        SUBSTR(prd_key,7,LENGTH(prd_key)) prd_key,
        prd_nm,
        COALESCE(prd_cost,0) prd_cost,
        CASE UPPER(TRIM(prd_line))
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'M' THEN 'Mountain'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,
        prd_start_dt,
        LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 prd_end_dt
    FROM bronze.crm_prd_info;


    -- Truncate Table before Inserting Data into silver.crm_sales_details
    TRUNCATE TABLE silver.crm_sales_details;

    -- Inserting Cleaned Data into silver.crm_sales_details
    INSERT INTO silver.crm_sales_details(sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE
            WHEN sls_order_dt = 0 OR LENGTH(CAST(sls_order_dt AS VARCHAR)) != 8 THEN NULL
            ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
        END AS sls_order_dt,
        CASE
            WHEN sls_ship_dt = 0 OR LENGTH(CAST(sls_ship_dt AS VARCHAR)) != 8 THEN NULL
            ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
        CASE
            WHEN sls_due_dt = 0 OR LENGTH(CAST(sls_due_dt AS VARCHAR)) != 8 THEN NULL
            ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
        CASE
            WHEN sls_sales ISNULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,
        sls_quantity,
        CASE
            WHEN sls_price <= 0 OR sls_price ISNULL THEN sls_sales/NULLIF(sls_quantity,0)
            ELSE sls_price
        END AS sls_price
    FROM bronze.crm_sales_details;


    -- Truncate Table before Inserting Data into silver.crm_cust_az12
    TRUNCATE TABLE silver.erp_cust_az12;

    -- Inserting Cleaned Data into silver.erp_cust_az12
    INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTR(cid,4,LENGTH(cid))
            ELSE cid
        END AS cid,
        CASE
            WHEN bdate > CURRENT_DATE THEN NULL
            ELSE bdate
        END AS bdate,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
            ELSE 'n/a'
        END AS gen
    FROM bronze.erp_cust_az12;


    -- Truncate Table before Inserting Data into silver.erp_loc_a101
    TRUNCATE TABLE silver.erp_loc_a101;

    -- Inserting Cleaned Data into silver.erp_loc_a101
    INSERT INTO silver.erp_loc_a101 (cid, cntry)
    SELECT
        REPLACE(cid,'-','') cid,
        CASE
            WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
            WHEN TRIM(cntry) IN ('DE') THEN 'Germany'
            WHEN TRIM(cntry) = '' OR cntry ISNULL THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cntry
    FROM bronze.erp_loc_a101;


    -- Truncate Table before Inserting Data into silver.erp_px_cat_g1v2
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    -- Inserting Cleaned Data into silver.erp_px_cat_g1v2
    INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT
        id,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;
END;
$$;