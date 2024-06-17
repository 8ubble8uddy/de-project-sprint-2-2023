/* 
Скрипт для перерасчёта данных для разового отчёта по продажам за период.
*/

/* Запрос для обновления материализованного представления "orders_report_materialized_view". */
REFRESH MATERIALIZED VIEW dwh.orders_report_materialized_view;
