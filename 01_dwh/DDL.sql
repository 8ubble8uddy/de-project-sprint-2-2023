/* 
Моделирование хранилища данных для маркетплейса хендмейд-товаров.
*/

/* Таблица "Мастеры". */
-- DROP TABLE IF EXISTS dwh.d_craftsman;
CREATE TABLE IF NOT EXISTS dwh.d_craftsman (
	craftsman_id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
	craftsman_name VARCHAR NOT NULL,
	craftsman_address VARCHAR NOT NULL,
	craftsman_birthday DATE NOT NULL,
	craftsman_email VARCHAR NOT NULL,
	load_dttm TIMESTAMP NOT NULL,
	CONSTRAINT craftsman_pk PRIMARY KEY (craftsman_id)
);
/* Индекс для таблицы "Мастеры". */
-- DROP INDEX IF EXISTS dwh.craftsman_load_dttm_idx;
CREATE INDEX IF NOT EXISTS craftsman_load_dttm_idx ON dwh.d_craftsman (load_dttm);
/* Комментарии к таблице "Мастеры". */
COMMENT ON COLUMN dwh.d_craftsman.craftsman_id IS 'идентификатор мастера';
COMMENT ON COLUMN dwh.d_craftsman.craftsman_name IS 'ФИО мастера';
COMMENT ON COLUMN dwh.d_craftsman.craftsman_address IS 'адрес мастера';
COMMENT ON COLUMN dwh.d_craftsman.craftsman_birthday IS 'дата рождения мастера';
COMMENT ON COLUMN dwh.d_craftsman.craftsman_email IS 'электронная почта мастера';
COMMENT ON COLUMN dwh.d_craftsman.load_dttm IS 'дата и время загрузки';

/* Таблица "Заказчики". */
-- DROP TABLE IF EXISTS dwh.d_customer;
CREATE TABLE IF NOT EXISTS dwh.d_customer (
	customer_id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
	customer_name VARCHAR NOT NULL,
	customer_address VARCHAR NOT NULL,
	customer_birthday DATE NOT NULL,
	customer_email VARCHAR NOT NULL,
	load_dttm TIMESTAMP NOT NULL,
	CONSTRAINT customers_pk PRIMARY KEY (customer_id)
);
/* Индекс для таблицы "Заказчики". */
--DROP INDEX IF EXISTS dwh.customer_load_dttm_idx;
CREATE INDEX IF NOT EXISTS customer_load_dttm_idx ON dwh.d_customer (load_dttm);
/* Комментарии к таблице "Заказчики". */
COMMENT ON COLUMN dwh.d_customer.customer_id IS 'идентификатор заказчика';
COMMENT ON COLUMN dwh.d_customer.customer_name IS 'ФИО заказчика';
COMMENT ON COLUMN dwh.d_customer.customer_address IS 'адрес заказчика';
COMMENT ON COLUMN dwh.d_customer.customer_birthday IS 'дата рождения заказчика';
COMMENT ON COLUMN dwh.d_customer.customer_email IS 'электронная почта заказчика';
COMMENT ON COLUMN dwh.d_customer.load_dttm IS 'дата и время загрузки';

/* Таблица "Товары". */
-- DROP TABLE IF EXISTS dwh.d_product;
CREATE TABLE IF NOT EXISTS dwh.d_product (
	product_id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
	product_name VARCHAR NOT NULL,
	product_description VARCHAR NOT NULL,
	product_type VARCHAR NOT NULL,
	product_price BIGINT NOT NULL,
	load_dttm TIMESTAMP NOT NULL,
	CONSTRAINT products_pk PRIMARY KEY (product_id),
	CONSTRAINT products_price_check CHECK (product_price > 0)
);
/* Индекс для таблицы "Товары". */
-- DROP INDEX IF EXISTS dwh.product_load_dttm_idx;
CREATE INDEX IF NOT EXISTS product_load_dttm_idx ON dwh.d_product (load_dttm);
/* Комментарии к таблице "Товары". */
COMMENT ON COLUMN dwh.d_product.product_id IS 'идентификатор товара ручной работы';
COMMENT ON COLUMN dwh.d_product.product_name IS 'наименование товара ручной работы';
COMMENT ON COLUMN dwh.d_product.product_description IS 'описание товара ручной работы';
COMMENT ON COLUMN dwh.d_product.product_type IS 'тип товара ручной работы';
COMMENT ON COLUMN dwh.d_product.product_price IS 'цена товара ручной работы';
COMMENT ON COLUMN dwh.d_product.load_dttm IS 'дата и время загрузки';

/* Таблица "Заказы". */
-- DROP TABLE IF EXISTS dwh.f_order;
CREATE TABLE IF NOT EXISTS dwh.f_order (
	order_id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
	product_id BIGINT NOT NULL,
	craftsman_id BIGINT NOT NULL,
	customer_id BIGINT NOT NULL,
	order_created_date DATE NOT NULL,
	order_completion_date DATE,
	order_status VARCHAR NOT NULL,
	load_dttm TIMESTAMP NOT NULL,
	CONSTRAINT orders_pk PRIMARY KEY (order_id),
	CONSTRAINT orders_status_check CHECK (order_status in ('created', 'in progress', 'delivery', 'done')),
	CONSTRAINT orders_completion_date_check CHECK (order_completion_date >= order_created_date),
	CONSTRAINT orders_craftsman_fk FOREIGN KEY (craftsman_id) REFERENCES dwh.d_craftsman(craftsman_id) ON DELETE RESTRICT,
	CONSTRAINT orders_customer_fk FOREIGN KEY (customer_id) REFERENCES dwh.d_customer(customer_id) ON DELETE RESTRICT,
	CONSTRAINT orders_product_fk FOREIGN KEY (product_id) REFERENCES dwh.d_product(product_id) ON DELETE RESTRICT
);
/* Индекс для таблицы "Заказы". */
-- DROP INDEX IF EXISTS dwh.order_load_dttm_idx;
CREATE INDEX IF NOT EXISTS order_load_dttm_idx ON dwh.f_order (load_dttm);
/* Комментарии к таблице "Заказы". */
COMMENT ON COLUMN dwh.f_order.order_id IS 'идентификатор заказа';
COMMENT ON COLUMN dwh.f_order.product_id IS 'идентификатор товара ручной работы';
COMMENT ON COLUMN dwh.f_order.craftsman_id IS 'идентификатор мастера';
COMMENT ON COLUMN dwh.f_order.customer_id IS 'идентификатор заказчика';
COMMENT ON COLUMN dwh.f_order.order_created_date IS 'дата создания заказа';
COMMENT ON COLUMN dwh.f_order.order_completion_date IS 'дата выполнения заказа';
COMMENT ON COLUMN dwh.f_order.order_status IS 'статус выполнения заказа (created, in progress, delivery, done)';
COMMENT ON COLUMN dwh.f_order.load_dttm IS 'дата и время загрузки';
