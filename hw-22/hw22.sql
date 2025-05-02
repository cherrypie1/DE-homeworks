CREATE DATABASE TechGadgets;
CREATE SCHEMA production;
CREATE SCHEMA  analytics;
CREATE TABLE production.products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50),
    stock_quantity INT NOT NULL
);

CREATE TABLE production.customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    registration_date DATE NOT NULL
);

CREATE TABLE production.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES production.customers(customer_id),
    order_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL
);

CREATE TABLE production.order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES production.orders(order_id),
    product_id INT REFERENCES production.products(product_id),
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

-- Таблицы в схеме analytics
CREATE TABLE analytics.sales_stats (
    stat_id SERIAL PRIMARY KEY,
    period DATE NOT NULL,
    total_sales DECIMAL(12,2) NOT NULL,
    top_product_id INT REFERENCES production.products(product_id)
);

CREATE TABLE analytics.customer_segments (
    segment_id SERIAL PRIMARY KEY,
    segment_name VARCHAR(50) NOT NULL,
    criteria TEXT NOT NULL,
    customer_count INT NOT NULL
);

--Создайте представление (VIEW) в схеме analytics с продажами по категориям
--В запросе посчитать сумму продаж по категориям
--- Дайте доступ менеджерам только к этому представлению, а не ко всем таблицам
--- Создайте роль senior_analysts с правами аналитиков + возможностью создавать временные таблицы

CREATE OR REPLACE VIEW analytics.category_sales AS
SELECT 
    p.category,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.price * oi.quantity) AS total_sales
FROM production.order_items oi
JOIN production.products p ON oi.product_id = p.product_id
GROUP BY p.category;

CREATE ROLE managers;
GRANT SELECT ON analytics.category_sales TO managers;

CREATE ROLE analysts;
CREATE ROLE senior_analysts;
GRANT analysts TO senior_analysts;

GRANT TEMP ON DATABASE TechGadgets TO senior_analysts;