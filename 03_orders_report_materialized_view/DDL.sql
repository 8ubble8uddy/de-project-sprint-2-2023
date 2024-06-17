/* 
Создание материализованного представления с разовым отчётом по продажам за период.
*/

/* Материализованное представление "Отчёт по продажам". */
-- DROP MATERIALIZED VIEW IF EXISTS dwh.orders_report_materialized_view;
CREATE MATERIALIZED VIEW IF NOT EXISTS dwh.orders_report_materialized_view AS
WITH
/* Выборка данных из таблиц хранилища "dwh.*" для отчёта по продажам. */
dwh_result AS (
	SELECT 	
			fo.order_id AS order_id,
			fo.order_completion_date AS order_completion_date,
			fo.order_created_date AS order_created_date,
			dp.product_price AS product_price,
			dp.product_name AS product_name,
			fo.order_status AS order_status,
			to_char(fo.order_created_date, 'yyyy-mm') AS report_period,
			date_part('year', age(dc.craftsman_birthday)) AS craftsman_age,
			date_part('year' , age(dcs.customer_birthday)) AS customer_age
			FROM dwh.f_order fo 
				INNER JOIN dwh.d_craftsman dc ON dc.craftsman_id = fo.craftsman_id
				INNER JOIN dwh.d_customer dcs ON dcs.customer_id = fo.customer_id
				INNER JOIN dwh.d_product dp ON dp.product_id = fo.product_id
),
/* Выборка завершенных заказов с расчётом количества дней на их выполнение. */
orders_done AS (
	SELECT 	
			fo.order_id AS order_id_for_order_done,
			fo.order_completion_date - fo.order_created_date AS diff_order_date
			FROM dwh.f_order fo
				WHERE fo.order_completion_date IS NOT NULL
)
/* Выборка по расчёту показателей отчёта по продажам "orders_report_materialized_view". */
	SELECT 	
			SUM(dr.product_price) AS total_money,
			COUNT(dr.order_id) AS total_products,
			AVG(dr.craftsman_age) AS avg_age_craftsman,
			AVG(dr.customer_age) AS avg_age_customer,
			SUM(CASE WHEN dr.order_status = 'created' THEN 1 ELSE 0 END) AS count_order_created, 
			SUM(CASE WHEN dr.order_status = 'in progress' THEN 1 ELSE 0 END) AS count_order_in_progress,
			SUM(CASE WHEN dr.order_status = 'delivery' THEN 1 ELSE 0 END) AS count_order_delivery,
			SUM(CASE WHEN dr.order_status = 'done' THEN 1 ELSE 0 END) AS count_order_done,
			SUM(CASE WHEN dr.order_status != 'done' THEN 1 ELSE 0 END) AS count_order_not_done,
			AVG(od.diff_order_date) AS avg_days_complete_orders,
			PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY od.diff_order_date) AS median_days_complete_orders,
			dr.report_period AS report_period
			FROM dwh_result dr
				LEFT JOIN orders_done od ON od.order_id_for_order_done = dr.order_id
					GROUP BY dr.report_period
						ORDER BY total_money;

/* Запрос, который проверяет, что отчёт не пустой со строкой-примером данных. */
-- SELECT * FROM dwh.orders_report_materialized_view limit 1;
