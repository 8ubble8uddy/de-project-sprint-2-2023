/* 
Проектирование витрины с инкрементальным отчётом по мастерам за период.
*/

/* Таблица "Отчёт по мастерам". */
-- DROP TABLE IF EXISTS dwh.craftsman_report_datamart;
CREATE TABLE IF NOT EXISTS dwh.craftsman_report_datamart (
    id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    craftsman_id BIGINT NOT NULL,
    craftsman_name VARCHAR NOT NULL,
    craftsman_address VARCHAR NOT NULL,
    craftsman_birthday DATE NOT NULL,
    craftsman_email VARCHAR NOT NULL,
    craftsman_money NUMERIC(15,2) NOT NULL,
    platform_money BIGINT NOT NULL,
    count_order BIGINT NOT NULL,
    avg_price_order NUMERIC(10,2) NOT NULL,
    avg_age_customer NUMERIC(3,1) NOT NULL,
    median_time_order_completed NUMERIC(10,1),
    top_product_category VARCHAR NOT NULL,
    count_order_created BIGINT NOT NULL,
    count_order_in_progress BIGINT NOT NULL,
    count_order_delivery BIGINT NOT NULL,
    count_order_done BIGINT NOT NULL,
    count_order_not_done BIGINT NOT NULL,
    report_period VARCHAR NOT NULL,
    CONSTRAINT craftsman_report_datamart_pk PRIMARY KEY (id)
);
/* Индекс для таблицы "Отчёт по мастерам". */
-- DROP INDEX IF EXISTS dwh.craftsman_report_datamart_report_period_idx;
CREATE UNIQUE INDEX IF NOT EXISTS craftsman_report_datamart_report_period_idx ON dwh.craftsman_report_datamart (craftsman_id, report_period);
/* Комментарии к таблице "Отчёт по мастерам". */
COMMENT ON COLUMN dwh.craftsman_report_datamart.id IS 'идентификатор записи';
COMMENT ON COLUMN dwh.craftsman_report_datamart.craftsman_id IS 'идентификатор мастера';
COMMENT ON COLUMN dwh.craftsman_report_datamart.craftsman_name IS 'ФИО мастера';
COMMENT ON COLUMN dwh.craftsman_report_datamart.craftsman_address IS 'адрес мастера';
COMMENT ON COLUMN dwh.craftsman_report_datamart.craftsman_birthday IS 'дата рождения мастера';
COMMENT ON COLUMN dwh.craftsman_report_datamart.craftsman_email IS 'электронная почта мастера';
COMMENT ON COLUMN dwh.craftsman_report_datamart.craftsman_money IS 'сумма, которую заработал мастер за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.platform_money IS 'сумма, которую заработала платформа от продаж мастера за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.count_order IS 'количество заказов у мастера за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.avg_price_order IS 'средняя стоимость одного заказа у мастера за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.avg_age_customer IS 'средний возраст покупателей';
COMMENT ON COLUMN dwh.craftsman_report_datamart.median_time_order_completed IS 'медианное время в днях от момента создания заказа до его завершения за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.top_product_category IS 'самая популярная категория товаров у этого мастера за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.count_order_created IS 'количество созданных заказов за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.count_order_in_progress IS 'количество заказов в процессе изготовки за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.count_order_delivery IS 'количество заказов в доставке за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.count_order_done IS 'количество завершённых заказов за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.count_order_not_done IS 'количество незавершённых заказов за месяц';
COMMENT ON COLUMN dwh.craftsman_report_datamart.report_period IS 'отчётный период год и месяц';

/* Таблица "Даты загрузок отчёта по мастерам". */
-- DROP TABLE IF EXISTS dwh.load_dates_craftsman_report_datamart;
CREATE TABLE IF NOT EXISTS dwh.load_dates_craftsman_report_datamart (
    id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    load_dttm TIMESTAMP NOT NULL,
    CONSTRAINT load_dates_craftsman_report_datamart_pk PRIMARY KEY (id)
);
/* Индекс для таблицы "Даты загрузок отчёта по мастерам". */
-- DROP INDEX IF EXISTS dwh.load_dates_craftsman_report_datamart_load_dttm_idx;
CREATE INDEX IF NOT EXISTS load_dates_craftsman_report_datamart_load_dttm_idx ON dwh.load_dates_craftsman_report_datamart (load_dttm);
/* Комментарии к таблице "Даты загрузок отчёта по мастерам". */
COMMENT ON COLUMN dwh.load_dates_craftsman_report_datamart.id IS 'идентификатор записи';
COMMENT ON COLUMN dwh.load_dates_craftsman_report_datamart.load_dttm IS 'дата загрузки данных';
