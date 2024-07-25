CREATE OR REPLACE PROCEDURE os.add_to_cart(
	IN integer,
	IN integer,
	IN integer)
LANGUAGE 'plpgsql'
AS $BODY$
declare
_cart_id int;
begin
select id into _cart_id from cart where user_id = $1 and is_active = true;
if _cart_id is null then
		insert into cart(user_id) values ($1) returning id into _cart_id;
end if;

with cart_product_info as (
    select
        _cart_id as cart_id,
        id as product_id,
        $3 as quantity,
        price
    from
        product
    where id = $2
)
insert into cart_product(cart_id, product_id, quantity, price) select * from cart_product_info;

end;
$BODY$;