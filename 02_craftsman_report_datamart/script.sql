/*
Скрипт для инкрементального обновления витрины c отчётом по мастерам за период.
*/

/* CTE-запрос, который будет выполнять инкрементальную загрузку.*/
WITH
/* Выборка данных из таблиц хранилища "dwh.*" для витрины по мастерам. */
dwh_result AS (
    SELECT
            dc.craftsman_id AS craftsman_id,
            dc.craftsman_name AS craftsman_name,
            dc.craftsman_address AS craftsman_address,
            dc.craftsman_birthday AS craftsman_birthday,
            dc.craftsman_email AS craftsman_email,
            fo.order_id AS order_id,
            dp.product_id AS product_id,
            dp.product_price AS product_price,
            dp.product_type AS product_type,
            DATE_PART('year', AGE(dcs.customer_birthday)) AS customer_age,
            fo.order_completion_date - fo.order_created_date AS diff_order_date, 
            fo.order_status AS order_status,
            TO_CHAR(fo.order_created_date, 'yyyy-mm') AS report_period,
            fo.load_dttm AS order_load_dttm,
            dc.load_dttm AS craftsman_load_dttm,
            dcs.load_dttm AS customer_load_dttm,
            dp.load_dttm AS product_load_dttm
            FROM dwh.f_order fo 
                INNER JOIN dwh.d_craftsman dc ON dc.craftsman_id = fo.craftsman_id 
                INNER JOIN dwh.d_customer dcs ON dcs.customer_id = fo.customer_id 
                INNER JOIN dwh.d_product dp ON dp.product_id = fo.product_id
),
/* Выборка новых или изменённых данных из хранилища "dwh_result". */
dwh_delta AS (
    SELECT     
            dr.*,
            crd.craftsman_id AS exist_craftsman_id
            FROM dwh_result dr
                LEFT JOIN dwh.craftsman_report_datamart crd ON crd.craftsman_id = dr.craftsman_id AND crd.report_period = dr.report_period
                    WHERE (dr.order_load_dttm > (SELECT COALESCE(MAX(load_dttm),'1900-01-01') FROM dwh.load_dates_craftsman_report_datamart)) OR
                          (dr.craftsman_load_dttm > (SELECT COALESCE(MAX(load_dttm),'1900-01-01') FROM dwh.load_dates_craftsman_report_datamart)) OR
                          (dr.customer_load_dttm > (SELECT COALESCE(MAX(load_dttm),'1900-01-01') FROM dwh.load_dates_craftsman_report_datamart)) OR
                          (dr.product_load_dttm > (SELECT COALESCE(MAX(load_dttm),'1900-01-01') FROM dwh.load_dates_craftsman_report_datamart))
),
/* Выборка мастеров из дельты изменений "dwh_delta", данные по которым нужно будет обновить в витрине. */
dwh_update_delta AS (
    SELECT DISTINCT    
            dd.exist_craftsman_id AS craftsman_id
            FROM dwh_delta dd
                WHERE dd.exist_craftsman_id IS NOT NULL        
),
/* Выборка по расчёту витрины для данных из дельты изменений "dwh_delta", которые нужно вставить. */
dwh_delta_insert_result AS (
    SELECT
	        dd.craftsman_id AS craftsman_id,
	        dd.craftsman_name AS craftsman_name,
	        dd.craftsman_address AS craftsman_address,
	        dd.craftsman_birthday AS craftsman_birthday,
	        dd.craftsman_email AS craftsman_email,
	        SUM(dd.product_price) - (SUM(dd.product_price) * 0.1) AS craftsman_money,
	        SUM(dd.product_price) * 0.1 AS platform_money,
	        COUNT(dd.order_id) AS count_order,
	        AVG(dd.product_price) AS avg_price_order,
	        AVG(dd.customer_age) AS avg_age_customer,
	        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY dd.diff_order_date) AS median_time_order_completed,
	        MODE() WITHIN GROUP(ORDER BY dd.product_type) AS top_product_category,
	        SUM(CASE WHEN dd.order_status = 'created' THEN 1 ELSE 0 END) AS count_order_created,
	        SUM(CASE WHEN dd.order_status = 'in progress' THEN 1 ELSE 0 END) AS count_order_in_progress, 
	        SUM(CASE WHEN dd.order_status = 'delivery' THEN 1 ELSE 0 END) AS count_order_delivery, 
	        SUM(CASE WHEN dd.order_status = 'done' THEN 1 ELSE 0 END) AS count_order_done, 
	        SUM(CASE WHEN dd.order_status != 'done' THEN 1 ELSE 0 END) AS count_order_not_done,
	        dd.report_period AS report_period
	        FROM dwh_delta dd
	            WHERE dd.exist_craftsman_id IS NULL
	                GROUP BY dd.craftsman_id, dd.craftsman_name, dd.craftsman_address, dd.craftsman_birthday, dd.craftsman_email, dd.report_period
),
/* Выборка по расчёту витрины для данных из хранилища "dwh_result", которые нужно обновить. */
dwh_delta_update_result AS (
    SELECT
	        dr.craftsman_id AS craftsman_id,
	        dr.craftsman_name AS craftsman_name,
	        dr.craftsman_address AS craftsman_address,
	        dr.craftsman_birthday AS craftsman_birthday,
	        dr.craftsman_email AS craftsman_email,
	        SUM(dr.product_price) - (SUM(dr.product_price) * 0.1) AS craftsman_money,
	        SUM(dr.product_price) * 0.1 AS platform_money,
	        COUNT(dr.order_id) AS count_order,
	        AVG(dr.product_price) AS avg_price_order,
	        AVG(dr.customer_age) AS avg_age_customer,
	        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY dr.diff_order_date) AS median_time_order_completed,
	        MODE() WITHIN GROUP(ORDER BY dr.product_type) AS top_product_category,
	        SUM(CASE WHEN dr.order_status = 'created' THEN 1 ELSE 0 END) AS count_order_created, 
	        SUM(CASE WHEN dr.order_status = 'in progress' THEN 1 ELSE 0 END) AS count_order_in_progress, 
	        SUM(CASE WHEN dr.order_status = 'delivery' THEN 1 ELSE 0 END) AS count_order_delivery, 
	        SUM(CASE WHEN dr.order_status = 'done' THEN 1 ELSE 0 END) AS count_order_done, 
	        SUM(CASE WHEN dr.order_status != 'done' THEN 1 ELSE 0 END) AS count_order_not_done,
	        dr.report_period AS report_period
            FROM dwh_result dr
            	INNER JOIN dwh_update_delta ud ON ud.craftsman_id = dr.craftsman_id
                	GROUP BY dr.craftsman_id, dr.craftsman_name, dr.craftsman_address, dr.craftsman_birthday, dr.craftsman_email, dr.report_period
),
/* Вставка новых показателей в витрину "craftsman_report_datamart" из выборки "dwh_delta_insert_result".  */
insert_delta AS (
    INSERT INTO dwh.craftsman_report_datamart (
	        craftsman_id,
	        craftsman_name,
	        craftsman_address,
	        craftsman_birthday, 
	        craftsman_email, 
	        craftsman_money, 
	        platform_money, 
	        count_order, 
	        avg_price_order, 
	        avg_age_customer,
	        median_time_order_completed,
	        top_product_category, 
	        count_order_created, 
	        count_order_in_progress, 
	        count_order_delivery, 
	        count_order_done, 
	        count_order_not_done, 
	        report_period
    ) SELECT 
            craftsman_id,
            craftsman_name,
            craftsman_address,
            craftsman_birthday,
            craftsman_email,
            craftsman_money::NUMERIC(15,2),
            platform_money::BIGINT,
            count_order,
            avg_price_order::NUMERIC(10,2),
            avg_age_customer::NUMERIC(3,1),
            median_time_order_completed::NUMERIC(10,1),
            top_product_category::VARCHAR,
            count_order_created, 
            count_order_in_progress,
            count_order_delivery, 
            count_order_done, 
            count_order_not_done,
            report_period::VARCHAR
            FROM dwh_delta_insert_result
),
/* Обновление существующих показателей в витрине "craftsman_report_datamart" из выборки "dwh_delta_update_result". */
update_delta AS (
    UPDATE dwh.craftsman_report_datamart SET
            craftsman_name = updates.craftsman_name, 
            craftsman_address = updates.craftsman_address, 
            craftsman_birthday = updates.craftsman_birthday, 
            craftsman_email = updates.craftsman_email, 
            craftsman_money = updates.craftsman_money, 
            platform_money = updates.platform_money, 
            count_order = updates.count_order, 
            avg_price_order = updates.avg_price_order, 
            avg_age_customer = updates.avg_age_customer, 
            median_time_order_completed = updates.median_time_order_completed, 
            top_product_category = updates.top_product_category, 
            count_order_created = updates.count_order_created, 
            count_order_in_progress = updates.count_order_in_progress, 
            count_order_delivery = updates.count_order_delivery, 
            count_order_done = updates.count_order_done,
            count_order_not_done = updates.count_order_not_done, 
            report_period = updates.report_period
            FROM (
                SELECT 
                        craftsman_id,
                        craftsman_name,
                        craftsman_address,
                        craftsman_birthday,
                        craftsman_email,
                        craftsman_money::NUMERIC(15,2),
                        platform_money::BIGINT,
                        count_order,
                        avg_price_order::NUMERIC(10,2),
                        avg_age_customer::NUMERIC(3,1),
                        median_time_order_completed::NUMERIC(10,1),
                        top_product_category::VARCHAR,
                        count_order_created,
                        count_order_in_progress,
                        count_order_delivery,
                        count_order_done,
                        count_order_not_done,
                        report_period::VARCHAR 
                        FROM dwh_delta_update_result
                ) AS updates
                WHERE updates.craftsman_id = dwh.craftsman_report_datamart.craftsman_id AND
                      updates.report_period = dwh.craftsman_report_datamart.report_period
),
/* Вставка даты последней загрузки данных из дельты изменений "dwh_delta" в дополнительную таблицу "load_dates_craftsman_report_datamart". */
insert_load_date AS (
    INSERT INTO dwh.load_dates_craftsman_report_datamart (
            load_dttm
    )
    SELECT 
            GREATEST(
    			COALESCE(MAX(order_load_dttm), LOCALTIMESTAMP),
    			COALESCE(MAX(craftsman_load_dttm), LOCALTIMESTAMP),
                COALESCE(MAX(customer_load_dttm), LOCALTIMESTAMP), 
                COALESCE(MAX(product_load_dttm), LOCALTIMESTAMP)
            ) AS max_load_dttm
            FROM dwh_delta
)
/* Пустой запрос для запуска CTE-запроса. */
SELECT 'increment craftsman_report_datamart';
