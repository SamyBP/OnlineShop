CREATE OR REPLACE PROCEDURE os.add_to_cart(
	p_user_id integer,
	p_product_id integer,
	p_quantity integer)
LANGUAGE 'plpgsql'
AS $BODY$
declare
    _cart_id int;
begin
    select id into _cart_id from os.cart where user_id = p_user_id and is_active = true;
    if _cart_id is null then
            insert into os.cart(user_id) values (p_user_id) returning id into _cart_id;
    end if;

    with cart_product_info as (
        select
            _cart_id as cart_id,
            id as product_id,
            p_quantity as quantity,
            price
        from
            os.product
        where id = p_product_id
    )
    insert into os.cart_product(cart_id, product_id, quantity, price)
    select * from cart_product_info
    on conflict (cart_id, product_id) do update set quantity = cart_product.quantity + 1;

end;
$BODY$;