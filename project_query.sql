-- 1- Top 10 customers by purchase volume

select * from order_details
limit 5;

select * from orders
limit 5;

select 
	c.customer_id,
	c.company_name,
	sum(odts.unit_price * odts.quantity) as total_price
from customers as c
 join orders as ods
on c.customer_id = ods.customer_id
 join order_details as odts
on ods.order_id = odts.order_id

group by c.customer_id
order by total_price desc 

limit 10 ;

-- -- -- -- -- -- -- -- -- -- -- -- 

-- 2- Top 10 Product sold

select  
	p.product_name, 
	sum(odts.quantity) as counts
from products as p
join order_details as odts
on p.product_id = odts.product_id

group by p.product_name
order by counts desc
limit 10;

-- 3- Monthly sales trends

select 
	to_char(od.order_date,'Month') as month,
	sum(odts.unit_price * odts.quantity) as total_sales
from orders as od
join order_details as odts
on od.order_id = odts.order_id

group by month 
order by total_sales desc; 

-- 4- Best spending countries

select 
	distinct country,
	sum(unit_price * quantity) as total_spent
from orders as od
join customers as c 
on od.customer_id = c.customer_id
join order_details as odts
on od.order_id = odts.order_id

group by country
order by total_spent desc;

-- 5- Sales per Employee

select 
	e.first_name || ' ' || e.last_name as employee_name,
	sum(odts.unit_price * odts.quantity) as total_sales
from employees as e
join orders as od
on e.employee_id = od.employee_id
join order_details as odts
on od.order_id = odts.order_id

group by employee_name
order by total_sales desc;


-- Advanced Query -- 

-- Sub Query
-- 6- Above average spending customers

(select
		avg(unit_price * quantity) as avg
		from order_details)
-- avg  = 628.5190674901285 
		
select 
	distinct c.customer_id,
	 c.company_name,
	odts.unit_price * odts.quantity as total_spend
from orders as od
join customers as c 
on od.customer_id = c.customer_id
join order_details as odts
on od.order_id = odts.order_id 

where odts.unit_price * odts.quantity > 
	(select
		avg(unit_price * quantity) as avg
		from order_details)
		
--=================

SELECT c.customer_id, c.company_name, SUM(odts.unit_price * odts.quantity) AS total_spent
FROM customers c
JOIN orders od ON c.customer_id = od.customer_id
JOIN order_details odts ON od.order_id = odts.order_id
GROUP BY c.customer_id, c.company_name
HAVING SUM(odts.unit_price * odts.quantity) > (
    SELECT AVG(total_spent) 
    FROM (
        SELECT SUM(odts.unit_price * odts.quantity) AS total_spent
        FROM orders od
        JOIN order_details odts ON od.order_id = odts.order_id
        GROUP BY od.customer_id
    ) AS sub
);


-- 7- Calculate monthly sales and then extract the highest month

with monthly_sales as(
	select 	DATE_TRUNC('month',od.order_date) as month,
	sum(odts.unit_price * odts.quantity) as totals
	from orders as od 
	join order_details as odts
	on od.order_id = odts.order_id

	group by month
)
select to_char(month,'month') as months, totals -- to return name of month
from monthly_sales
order by totals desc
limit 1;


-- 8- Customers ranked by spending within each country < window functions >

SELECT c.country, c.company_name,
       SUM(odts.unit_price * odts.quantity) AS total_spent,
       RANK() OVER (PARTITION BY c.country ORDER BY SUM(odts.unit_price * odts.quantity) DESC) AS rank_in_country
FROM customers c
JOIN orders od ON c.customer_id = od.customer_id
JOIN order_details odts ON od.order_id = odts.order_id
GROUP BY c.country, c.company_name
ORDER BY c.country, rank_in_country;


-- 9- Customers who purchased products from the "Seafood" category < Nested Query + IN >


SELECT DISTINCT c.customer_id, c.company_name
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
WHERE od.product_id IN (
    SELECT product_id FROM products WHERE category_id = (
        SELECT category_id FROM categories WHERE category_name = 'Seafood'
    )
);


-- 10- Create View 

CREATE OR REPLACE VIEW sales_by_country AS
SELECT c.country, SUM(od.unit_price * od.quantity) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.country;

SELECT * FROM sales_by_country ORDER BY total_sales DESC;


-- 11- Running Total Sales 

SELECT DATE_TRUNC('month', od.order_date) AS month,
       SUM(odts.unit_price * odts.quantity) AS monthly_sales,
       SUM(SUM(odts.unit_price * odts.quantity)) OVER (ORDER BY DATE_TRUNC('month', od.order_date)) AS running_total
FROM orders od
JOIN order_details odts ON od.order_id = odts.order_id
GROUP BY month
ORDER BY month; 


-- 12- Customer classification based on their spending < CASE Statement >
-- Customers are divided into levels (VIP / Regular / Low Spender)

select 
	c.customer_id,
	c.company_name,
	sum(odts.unit_price * odts.quantity) AS total_spent,
	case
		when sum(odts.unit_price * odts.quantity) > 50000 THEN 'VIP'
		when sum(odts.unit_price * odts.quantity) Between 20000 and 50000 THEN 'Regular'
		Else 'Low spender'
		END AS  customer_category
FROM customers c
JOIN orders od ON c.customer_id = od.customer_id
JOIN order_details odts ON od.order_id = odts.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_spent DESC;


-- 13- Managers & Employees     < self join >

SELECT
	e1.employee_id, 
	e1.first_name || ' ' || e1.last_name AS employee,
    e2.first_name || ' ' || e2.last_name AS manager
FROM employees as e1
LEFT JOIN employees as e2 
ON e1.reports_to = e2.employee_id;








	 