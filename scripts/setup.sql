-- n represents the number of users to be inserted
-- m represents the number of categories to be created
-- p represents the maximum number of products to be created for each category
-- q represents the maximum quantity a product can have
-- x represents the maximum price a product can have 
-- o represents the number of orders to be placed

begin;

set search_path = 'os';

insert into role(name) values ('Administrator'), ('Regular user');

insert into users(username, password, first_name, last_name, last_login)
select
	get_random_name() || idx as username,
	'ee11cbb19052e40b07aac0ca060c23ee' as password,
	get_random_name() as first_name, 
	get_random_name() as last_name,
	now() - '1 day'::INTERVAL * round(random() * 3*365) as last_login
from generate_series(1, :n) as idx;
	
-- Administrator for n / 3 users
insert into user_role(user_id, role_id)
select id, 1 
from users
order by random()
limit :n / 3;

-- Regular user for n / 3 users
insert into user_role(user_id, role_id)
select u.id, 2
from users u
left join user_role ur on u.id = ur.user_id
where ur.role_id is null
order by random()
limit :n / 3;

-- Both roles for the remaining users
insert into user_role(user_id, role_id)
with remaining_ids as (
	select u.id
	from users u
	left join user_role ur on u.id = ur.user_id
	where ur.role_id is null
	order by random()	
)
select id, 1 from remaining_ids
union all
select id, 2 from remaining_ids;

select setup_store_addresses(:n);

-- Category
insert into category(name)
select 'Category_' || idx 
from generate_series(1, :m) as idx;

-- Product
with random_products as (
	select
		'Product_' || get_random_name() || '_' || generate_series(1, (random() * (:p - 1) + 1)::int) as name,
		'Description_' || get_random_name() as description, 
		round((random() * (:x - 1) + 1)::numeric, 2) as price,
		(random() * (:q - 1) + 1)::int as quantity,
		id as category_id
	from category	
),
products as (
	insert into product(name, description, price, quantity, category_id)
	select * from random_products
	returning id, quantity
)
insert into stock_log(product_id, quantity) select id, quantity from products;


select setup_place_random_orders(:o, :n);

commit;