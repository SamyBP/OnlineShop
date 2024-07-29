-- List all products sold in the last week
select	p.id, p.name, o.id as order
from os.product p
join os.cart_product cp on p.id = cp.product_id
join os.cart c on cp.cart_id = c.id
join os.orders o on c.id = o.cart_id
where o.created_at >= now() - '7 days'::interval;

-- Create a report which lists the most sold product in every day in last 7 days.
with quantity_per_product as (
	select to_char(o.created_at, 'Day') as day, p.id as product_id, sum(cp.quantity) as quantity
	from os.product p
	join os.cart_product cp on p.id = cp.product_id
	join os.cart c on cp.cart_id = c.id
	join os.orders o on c.id = o.cart_id and o.created_at >= now() - '7 days'::interval
	group by day, p.id
),
max_per_day as (
	select day, max(quantity) as quantity
	from quantity_per_product
	group by day
)
select qp.day, qp.product_id, qp.quantity 
from quantity_per_product qp
join max_per_day mpd on qp.day = mpd.day and qp.quantity = mpd.quantity

-- List all products for a given category.
select p.id, p.name
from os.category c
join os.product p on c.id = p.category_id
where c.name = 'Category_1';

-- Write an SQL query to generate a report showing total sales for each product category.
select c.id, c.name as category, sum(o.price) as total_price
from os.category c
join os.product p on c.id = p.category_id
join os.cart_product ctp on p.id = ctp.product_id
join os.cart ct on ctp.cart_id = ct.id
join os.orders o on ct.id = o.cart_id
group by c.id;

-- Write an SQL query to list all products that have a stock quantity below a certain threshold
select id, name, quantity
from os.product
where quantity < 1500;

-- Write an SQL query to find the top 5 users who have placed the most orders.If multiple users with same number of orders(on last) then all should be listed
select u.id, u.first_name || ' ' || u.last_name as name, count(o.id) as orders_placed
from os.users u
join os.orders o on u.id = o.user_id
group by u.id, name
order by orders_placed desc
offset 0 rows
fetch first 5 rows with ties;

-- Write an SQL query to find all products where name starts with a given search field
select id, name
from os.product
where name like 'Product_%';

-- Write an SQL query to find all products where name starts with a given search field or the category name starts with a given search field.
select p.id as product_id, p.name as product_name, c.name as category
from os.category c
join os.product p on c.id = p.category_id
where p.name like 'Product_a%' or c.name like 'Category_%';

-- Write an SQL query to generate a report showing total sales for each month in the current year.
select to_char(created_at, 'Month') as Month, sum(price) as total_sales
from os.orders
where date_part('year', created_at) = date_part('year', now())
group by Month

-- Write an SQL query to calculate the average value of all orders placed.
select round(avg(price), 2) as average_value from os.orders;

-- Write an SQL query to retrieve the order history for a specific user, including order date, product details, and quantities.
select
	o.id as order_id,
	o.created_at as order_date,
	p.name as product_name,
	p.description as product_description,
	ctp.price as product_price,
	ctp.quantity as ordered_quantity
from os.orders o
join os.cart c on o.cart_id = c.id
join os.cart_product ctp on c.id = ctp.cart_id
join os.product p on ctp.product_id = p.id
where o.user_id = 1;

-- Write an SQL query to count the number of orders in each status (e.g., Pending, Shipped, Delivered).
select 
	sum(
		case when status = 'Pending' then 1 else 0 end
	) as pending_count,
	sum (
		case when status = 'Shipped' then 1 else 0 end
	) as shipped_count,
	sum (
		case when status = 'Delivered' then 1 else 0 end
	) as delivered_count
from os.orders;	

-- Write an SQL query to find the most popular product categories based on the number of products sold.
select c.name as category, sum(ctp.quantity) as quantity_sold
from os.category c
join os.product p on c.id = p.category_id
join os.cart_product ctp on p.id = ctp.product_id
join os.cart ct on ctp.cart_id = ct.id
join os.orders o on ct.id = o.cart_id
group by c.name
order by quantity_sold desc;

-- Write an SQL query to find users who have placed at least one order in the past month.
select user_id, count(id) as orders_placed
from os.orders
where created_at >= now() - '1 month'::interval
group by user_id;


-- Write an SQL query to find users who have not placed any orders in the last month.
select u.id
from os.users u
left join os.orders o on u.id = o.user_id and o.created_at >= now() - '1 month'::interval
where o.user_id is null;

-- Write an SQL query to calculate the inventory turnover rate for each product.
-- Inventory turnover rate can be calculated as the ratio of the total quantity sold to the average inventory
-- over a period.


-- Write an SQL query to list all addresses for each user, including the count of orders shipped to each address.
select o.user_id, co.country || ' ' || ci.city || ' ' || a.address as delivery_address, count(o.id)
from os.orders o
join os.address a on o.delivery_address = a.id
join os.city ci on a.city_id = ci.id
join os.country co on ci.country_id = co.id
group by o.user_id, co.country, ci.city, a.address
order by o.user_id;

-- Write an SQL query to update the price of a specific product.
prepare update_product_price(int, numeric(7,2)) as
	update os.product
	set price = $2
	where id = $1;
	
execute update_product_price(3, 500.45);

-- Write an SQL query to update the status of an order to 'shipped'.
prepare set_order_shipped(int) as
	update os.orders
	set status = 'Shipped'
	where id = $1;

execute set_order_shipped(4);

-- Write an SQL query to delete all orders that were placed more than a year ago.
begin
delete from os.orders
where created_at < now() - '1 year'::interval;
commit;

-- Write an SQL query to update the category of all products that belong to a specific old category to a new category.
update os.product
set category_id = 15
where category_id = 14;





	