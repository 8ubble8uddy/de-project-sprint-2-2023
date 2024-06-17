/*
Скрипт для инкрементального обновления витрины c отчётом по заказчикам за период.
*/

/* CTE-запрос, который будет выполнять инкрементальную загрузку. */
WITH
/* Выборка данных из таблиц хранилища "dwh.*" для витрины по заказчикам. */
dwh_result AS (
    SELECT  
    		dcs.customer_id AS customer_id,
    		dcs.customer_name AS customer_name,
    		dcs.customer_address AS customer_address,
    		dcs.customer_birthday AS customer_birthday,
    		dcs.customer_email AS customer_email,
            fo.order_id AS order_id,
            dp.product_id AS product_id,
            dp.product_price AS product_price,
            dp.product_type AS product_type,
            fo.craftsman_id AS craftsman_id,
            fo.order_completion_date - fo.order_created_date AS diff_order_date, 
            fo.order_status AS order_status,
            TO_CHAR(fo.order_created_date, 'yyyy-mm') AS report_period,
            fo.load_dttm AS order_load_dttm,
            dcs.load_dttm AS customer_load_dttm,
            dp.load_dttm AS product_load_dttm
            FROM dwh.f_order fo 
                INNER JOIN dwh.d_customer dcs ON dcs.customer_id = fo.customer_id 
                INNER JOIN dwh.d_product dp ON dp.product_id = fo.product_id
),
/* Выборка новых или изменённых данных из хранилища "dwh_result". */
dwh_delta AS (
    SELECT  
    		dr.*,
            csrd.customer_id AS exist_customer_id
            FROM dwh_result dr
                LEFT JOIN dwh.customer_report_datamart csrd ON csrd.customer_id = dr.customer_id AND csrd.report_period = dr.report_period
                    WHERE (dr.order_load_dttm > (SELECT COALESCE(MAX(load_dttm),'1900-01-01') FROM dwh.load_dates_customer_report_datamart)) OR
                          (dr.customer_load_dttm > (SELECT COALESCE(MAX(load_dttm),'1900-01-01') FROM dwh.load_dates_customer_report_datamart)) OR
                          (dr.product_load_dttm > (SELECT COALESCE(MAX(load_dttm),'1900-01-01') FROM dwh.load_dates_customer_report_datamart))
),
/* Выборка заказчиков из дельты изменений "dwh_delta", данные по которым нужно будет обновить в витрине. */
dwh_update_delta AS (
    SELECT DISTINCT
            dd.exist_customer_id AS customer_id
            FROM dwh_delta dd 
                WHERE dd.exist_customer_id IS NOT NULL        
),
/* Выборка по расчёту витрины для данных из дельты изменений "dwh_delta", которые нужно вставить. */
dwh_delta_insert_result AS (
    SELECT
	        dd.customer_id AS customer_id,
	        dd.customer_name AS customer_name,
	        dd.customer_address AS customer_address,
	        dd.customer_birthday AS customer_birthday,
	        dd.customer_email AS customer_email,
	        SUM(dd.product_price) AS customer_spending,
	        SUM(dd.product_price) * 0.1 AS platform_money,
	        COUNT(dd.order_id) AS count_order,
	        AVG(dd.product_price) AS avg_price_order,                                
	        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY dd.diff_order_date) AS median_time_order_completed,
	        MODE() WITHIN GROUP(ORDER BY dd.product_type) AS top_product_category,
	        MODE() WITHIN GROUP(ORDER BY dd.craftsman_id) AS top_craftsman_id,
	        SUM(CASE WHEN dd.order_status = 'created' THEN 1 ELSE 0 END) AS count_order_created,
	        SUM(CASE WHEN dd.order_status = 'in progress' THEN 1 ELSE 0 END) AS count_order_in_progress, 
	        SUM(CASE WHEN dd.order_status = 'delivery' THEN 1 ELSE 0 END) AS count_order_delivery, 
	        SUM(CASE WHEN dd.order_status = 'done' THEN 1 ELSE 0 END) AS count_order_done, 
	        SUM(CASE WHEN dd.order_status != 'done' THEN 1 ELSE 0 END) AS count_order_not_done,
	        dd.report_period AS report_period
	        FROM dwh_delta AS dd
	            WHERE dd.exist_customer_id IS NULL
	                GROUP BY dd.customer_id, dd.customer_name, dd.customer_address, dd.customer_birthday, dd.customer_email, dd.report_period        
),
/* Выборка по расчёту витрины для данных из хранилища "dwh_result", которые нужно обновить. */
dwh_delta_update_result AS (
    SELECT
	        dr.customer_id AS customer_id,
	        dr.customer_name AS customer_name,
	        dr.customer_address AS customer_address,
	        dr.customer_birthday AS customer_birthday,
	        dr.customer_email AS customer_email,
	        SUM(dr.product_price) AS customer_spending,
	        SUM(dr.product_price) * 0.1 AS platform_money,
	        COUNT(dr.order_id) AS count_order,
	        AVG(dr.product_price) AS avg_price_order,                                
	        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY dr.diff_order_date) AS median_time_order_completed,
	        MODE() WITHIN GROUP(ORDER BY dr.product_type) AS top_product_category,
	        MODE() WITHIN GROUP(ORDER BY dr.craftsman_id) AS top_craftsman_id,
	        SUM(CASE WHEN dr.order_status = 'created' THEN 1 ELSE 0 END) AS count_order_created,
	        SUM(CASE WHEN dr.order_status = 'in progress' THEN 1 ELSE 0 END) AS count_order_in_progress, 
	        SUM(CASE WHEN dr.order_status = 'delivery' THEN 1 ELSE 0 END) AS count_order_delivery, 
	        SUM(CASE WHEN dr.order_status = 'done' THEN 1 ELSE 0 END) AS count_order_done, 
	        SUM(CASE WHEN dr.order_status != 'done' THEN 1 ELSE 0 END) AS count_order_not_done,
	        dr.report_period AS report_period
	        FROM dwh_result dr
				GROUP BY dr.customer_id, dr.customer_name, dr.customer_address, dr.customer_birthday, dr.customer_email, dr.report_period        
),
/* Вставка новых показателей в витрину "customer_report_datamart" из выборки "dwh_delta_insert_result". */
insert_delta AS ( 
    INSERT INTO dwh.customer_report_datamart(
	        customer_id,
	        customer_name,
	        customer_address,
	        customer_birthday,
	        customer_email,
	        customer_spending,
	        platform_money,
	        count_order,
	        avg_price_order,                                
	        median_time_order_completed,
	        top_product_category,
	        top_craftsman_id,
	        count_order_created,
	        count_order_in_progress, 
	        count_order_delivery, 
	        count_order_done, 
	        count_order_not_done,
	        report_period
    ) SELECT 
	        customer_id,
	        customer_name,
	        customer_address,
	        customer_birthday,
	        customer_email,
	        customer_spending::NUMERIC(15,2),
	        platform_money::BIGINT,
	        count_order,
	        avg_price_order::NUMERIC(10,2),                                
	        median_time_order_completed::NUMERIC(10,1),
	        top_product_category::VARCHAR,
	        top_craftsman_id,
	        count_order_created,
	        count_order_in_progress, 
	        count_order_delivery, 
	        count_order_done, 
	        count_order_not_done,
	        report_period::VARCHAR
            FROM dwh_delta_insert_result
),
/* Обновление существующих показателей в витрине "customer_report_datamart" из выборки "dwh_delta_update_result". */
update_delta AS (
    UPDATE dwh.customer_report_datamart SET
	        customer_name = updates.customer_name, 
	        customer_address = updates.customer_address, 
	        customer_birthday = updates.customer_birthday, 
	        customer_email = updates.customer_email, 
	        customer_spending = updates.customer_spending, 
	        platform_money = updates.platform_money, 
	        count_order = updates.count_order, 
	        avg_price_order = updates.avg_price_order, 
	        median_time_order_completed = updates.median_time_order_completed, 
	        top_product_category = updates.top_product_category,
	        top_craftsman_id = updates.top_craftsman_id,
	        count_order_created = updates.count_order_created, 
	        count_order_in_progress = updates.count_order_in_progress, 
	        count_order_delivery = updates.count_order_delivery, 
	        count_order_done = updates.count_order_done,
	        count_order_not_done = updates.count_order_not_done, 
	        report_period = updates.report_period
			FROM (
				SELECT 
						customer_id,
						customer_name,
						customer_address,
						customer_birthday,
						customer_email,
						customer_spending::NUMERIC(15,2),
						platform_money::BIGINT,
						count_order,
						avg_price_order::NUMERIC(10,2),                                
						median_time_order_completed::NUMERIC(10,1),
						top_product_category::VARCHAR,
						top_craftsman_id,
						count_order_created,
						count_order_in_progress, 
						count_order_delivery, 
						count_order_done, 
						count_order_not_done,
						report_period::VARCHAR
						FROM dwh_delta_update_result
				) AS updates
				WHERE updates.customer_id = dwh.customer_report_datamart.customer_id AND
					  updates.report_period = dwh.customer_report_datamart.report_period
),
/* Вставка даты последней загрузки данных из дельты изменений "dwh_delta" в дополнительную таблицу "load_dates_customer_report_datamart". */
insert_load_date AS (
    INSERT INTO dwh.load_dates_customer_report_datamart (
        	load_dttm
    )
    SELECT 
			GREATEST(
				COALESCE(MAX(order_load_dttm), LOCALTIMESTAMP), 
				COALESCE(MAX(customer_load_dttm), LOCALTIMESTAMP), 
				COALESCE(MAX(product_load_dttm), LOCALTIMESTAMP)
			) AS max_load_dttm
        	FROM dwh_delta
)
/* Пустой запрос для запуска CTE-запроса. */
SELECT 'increment customer_report_datamart';
