USE retail_intelligence;
show tables;
select 1;
select*from customers limit 5;

#1.top 10 customers
select o.customer_id,sum(p.payment_value)as total_amt
from orders o
join payments p
on o.order_id=p.order_id
group by o.customer_id
order by total_amt desc
limit 10;

#2.top 10 cities by revenue
select 
c.customer_city,
sum(p.payment_value)as revenue
from customers c 
join orders o
on c.customer_id=o.customer_id
join payments p
on o.order_id=p.order_id
group by c.customer_city
order by revenue desc limit 10;

#3.top 10 products 

SELECT
    oi.product_id,pr.product_category_name,
    SUM(oi.price) AS revenue
FROM order_items oi
join products pr
on oi.product_id=pr.product_id
GROUP BY oi.product_id,pr.product_category_name
ORDER BY revenue DESC
LIMIT 10;

#4.top 10 category name
SELECT
    pr.product_category_name,
    SUM(oi.price) AS revenue
FROM order_items oi
join products pr
on oi.product_id=pr.product_id
GROUP BY pr.product_category_name
ORDER BY revenue DESC
LIMIT 10;

#5.customer and their payment type total amount
select 
o.customer_id,
p.payment_type,
sum(p.payment_value) as amount
from orders o
join payments p
on o.order_id=p.order_id
group by o.customer_id,p.payment_type
order by amount desc;

#6.payment type and total amount
select p.payment_type,sum(p.payment_value) as amount
from orders o
join payments p
on o.order_id=p.order_id
group by p.payment_type
order by amount desc;
with seller_revenue as(
select oi.seller_id,sum(oi.price)as revenue
from order_items oi 
group by oi.seller_id
),
ranked_sellers as(
 select 
 seller_id,
 revenue,
  row_number()over(order by revenue desc )as seller_rank
from seller_revenue
)
select
seller_id,
revenue,
seller_rank
from ranked_sellers
where seller_rank<10;
#8.
SELECT
    seller_id,
    SUM(price) AS revenue
FROM order_items
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;

#9.Top 3 products in each category by revenue

with rnk as (
select 
pr.product_id,
pr.product_category_name,
sum(oi.price)as total_revenue
from products pr
join order_items oi
on pr.product_id=oi.product_id
group by pr.product_id,pr.product_category_name
),
ranked_category as (
select
product_id,
product_category_name,
total_revenue,
dense_rank()over(partition by product_category_name order by total_revenue desc)as rak
from rnk
)
select
product_id,
product_category_name,
total_revenue
from ranked_category
where rak<=3;

#10.Revenue contribution %
select
pr.product_category_name,
sum(oi.price) as revenue,
sum(oi.price)/sum(sum(oi.price))over()*100 as revenue_pct
from products pr
join order_items oi
on pr.product_id=oi.product_id
group by product_category_name
order by revenue_pct desc;

#11.Top seller in each state
select
oi.seller_id,
sum(oi.price)as revenue,
s.seller_state,
dense_rank()over(partition by s.seller_state order by sum(oi.price)desc)as rnk
from order_items oi
join sellers s
on oi.seller_id=s.seller_id
group by oi.seller_id,s.seller_state
order by revenue desc;


#12.Monthly Revenue Growth
WITH monthly_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS yr,
        MONTH(o.order_purchase_timestamp) AS mn,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    GROUP BY yr, mn
)
SELECT
    yr,
    mn,
    revenue,
    LAG(revenue) OVER (ORDER BY yr, mn) AS prev_month_revenue
FROM monthly_revenue;

#13.Monthly Growth Percentage
WITH monthly_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS yr,
        MONTH(o.order_purchase_timestamp) AS mn,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    GROUP BY yr, mn
)
SELECT
    yr,
    mn,
    revenue,
    LAG(revenue) OVER (ORDER BY yr, mn) AS prev_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY yr, mn))
        / LAG(revenue) OVER (ORDER BY yr, mn) * 100
    ) AS growth_pct
FROM monthly_revenue;

#14.Customer's Previous Order Value
select 
o.customer_id,
o.order_purchase_timestamp,
p.payment_value,
lag(p.payment_value)over(partition by o.customer_id
order by o.order_purchase_timestamp ) as prev_order
from orders o
join payments p
on p.order_id=o.order_id;


#15.Days Between Customer Orders
SELECT
    customer_id,
    order_purchase_timestamp,
    LAG(order_purchase_timestamp) OVER (
        PARTITION BY customer_id
        ORDER BY order_purchase_timestamp
    ) AS previous_order_date
FROM orders;
# customers gaps between orders 
select
order_purchase_timestamp,
lag(order_purchase_timestamp)over(partition by customer_id
order by order_purchase_timestamp
)
as days_between_orders
from orders;

#16.customers revenue above avg revenue
WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    revenue
FROM customer_revenue
WHERE revenue > (
    SELECT AVG(revenue)
    FROM customer_revenue
);

#17.average order values
select 
sum(payment_value)as revenue,
count(distinct order_id)as total_orders,
round(sum(payment_value)/count(distinct(order_id)),
2)
as aov from payments;

#18.Repeat Customers

SELECT
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;

#19.Average delivery time by state.
select
c.customer_state,
avg(datediff(o.order_estimated_delivery_date,o.order_purchase_timestamp)) AS avg_delivery_days
FROM customers c
JOIN orders o
    ON c.customer_id=o.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days desc;

#20 cancelled orders
select
c.customer_state,
count(o.order_status)as os
FROM customers c
JOIN orders o
    ON c.customer_id=o.customer_id
WHERE o.order_status='canceled'
GROUP BY c.customer_state
ORDER BY os desc;

#21cancellation rate
SELECT
    c.customer_state,
    COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END) AS canceled_orders,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END) * 100.0
        / COUNT(*),
        2
    ) AS cancel_rate
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY cancel_rate DESC;



SELECT customer_id,
       COUNT(*) AS orders_count
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1
LIMIT 10;