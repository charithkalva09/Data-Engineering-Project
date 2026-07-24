-- Explore All Countries
SELECT DISTINCT country
FROM dim_customers;

-- Explore All Categories
SELECT DISTINCT category, subcategory, product_name
FROM dim_products
ORDER BY 1,2,3;

-- Explore Dates
SELECT
    MIN(birth_date) oldest_bdate,
    EXTRACT(YEAR FROM AGE(MIN(birth_date))) oldest_age,
    MAX(birth_date) youngest_bdate,
    EXTRACT(YEAR FROM AGE(MAX(birth_date))) youngest_age
FROM dim_customers;

-- Explore Measures

-- Calculate Business metrics
SELECT
    SUM(sales_amount) total_sales,
    ROUND(AVG(price),0) avg_sales,
    SUM(quantity) total_quantity
FROM fact_sales;

-- Total Orders
SELECT
    COUNT(DISTINCT (order_number)) total_orders
FROM fact_sales;

-- Total Products
SELECT
    COUNT(product_key) total_products
FROM dim_products;

-- Total Customers and Total Customers who placed an order
SELECT
    COUNT(customer_key) total_unique_customers
FROM dim_customers;

-- Total no. of customers by countries
SELECT
    country,
    COUNT(customer_key) total_customers
FROM dim_customers
GROUP BY country
ORDER BY 2 DESC;

-- Total customer by gender
SELECT
    gender,
    COUNT(customer_key) total_customers
FROM dim_customers
GROUP BY gender
ORDER BY 2 DESC;

-- Total products by category
SELECT
    category,
    COUNT(product_key) total_products
FROM dim_products
GROUP BY category
ORDER BY 2 DESC;

-- Average cost for each category?
SELECT
    category,
    ROUND(AVG(cost),1) avg_cost
FROM dim_products
GROUP BY category
ORDER BY 2 DESC;

-- Total revenue for each category?
SELECT
    p.category,
    SUM(s.sales_amount) total_revenue
FROM fact_sales s
LEFT JOIN dim_products p on s.product_key = p.product_key
GROUP BY 1
ORDER BY 2 DESC;


-- Total revenue for each customer?
SELECT
    c.customer_key,
    CONCAT(first_name,' ',last_name) customer_name,
    SUM(s.sales_amount) total_revenue
FROM dim_customers c
LEFT JOIN fact_sales s on c.customer_key = s.customer_key
GROUP BY 1,2
ORDER BY 3 DESC;

-- Total quantities by countries?
SELECT
    c.country,
    SUM(s.quantity) totla_quantity
FROM dim_customers c
FULL OUTER JOIN fact_sales s ON s.customer_key = c.customer_key
GROUP BY 1
ORDER BY 2 DESC;

-- Which 5 products generate the highest revenue?
SELECT
    p.product_name,
    SUM(s.sales_amount) total_revenue
FROM fact_sales s
LEFT JOIN dim_products p ON p.product_key = s.product_key
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Which are the 5 worst-performing products in terms of sales?
SELECT
    p.product_name,
    SUM(s.sales_amount) total_revenue
FROM fact_sales s
LEFT JOIN dim_products p ON p.product_key = s.product_key
GROUP BY 1
ORDER BY 2
LIMIT 5;

-- Top 5 Best & Worst selling products (Using Window Functions)?
SELECT *
FROM (
        SELECT
            p.product_name,
            SUM(s.sales_amount) total_revenue,
            row_number() OVER (ORDER BY SUM(s.sales_amount) DESC) rk
        FROM fact_sales s
        LEFT JOIN dim_products p ON p.product_key = s.product_key
        GROUP BY 1
      )t
WHERE rk <=5
ORDER BY 2 DESC;

SELECT *
FROM (
        SELECT
            p.product_name,
            SUM(s.sales_amount) total_revenue,
            row_number() OVER (ORDER BY SUM(s.sales_amount)) rk
        FROM fact_sales s
        LEFT JOIN dim_products p ON p.product_key = s.product_key
        GROUP BY 1
      )t
WHERE rk <=5
ORDER BY 2;

-- Top 10 customers with highest revenue
SELECT
    c.customer_key,
    CONCAT(first_name,' ',last_name) customer_name,
    SUM(s.sales_amount) total_revenue
FROM dim_customers c
LEFT JOIN fact_sales s on c.customer_key = s.customer_key
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10;

-- Top 3 customers with fewer orders
SELECT
    c.customer_key,
    CONCAT(first_name,' ',last_name) customer_name,
    COUNT(DISTINCT(s.order_number)) total_orders
FROM dim_customers c
LEFT JOIN fact_sales s on c.customer_key = s.customer_key
GROUP BY 1,2
ORDER BY 3
LIMIT 3;