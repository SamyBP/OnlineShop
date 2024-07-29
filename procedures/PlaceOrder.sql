CREATE OR REPLACE PROCEDURE os.place_order(
	p_user_id integer,
	p_delivery_address_id integer,
	p_invoice_address_id integer,
	p_timestamp timestamp without time zone DEFAULT now())
LANGUAGE 'plpgsql'
AS $BODY$
declare
    _p record;
	_cart_id int;
	_order_price decimal(7,2) := 0.0;
begin
    select id into _cart_id from os.cart where user_id = p_user_id and is_active = true;
    if _cart_id is null then
        raise exception 'user % cannot place orders, he has no products in cart', p_user_id;
    end if;

    for _p in select product_id, quantity, price from os.cart_product where cart_id = _cart_id
    loop
        with updated_product as (
            update os.product
            set quantity = quantity - _p.quantity, updated_at = now()
            where id = _p.product_id
            returning id, quantity
        )
        insert into os.stock_log(product_id, quantity) select id, quantity from updated_product;

        select _p.price * _p.quantity + _order_price into _order_price;
    end loop;

    insert into os.orders(user_id, cart_id, delivery_address, invoice_address, price, created_at, updated_at)
    values (p_user_id, _cart_id, p_delivery_address_id, p_invoice_address_id, _order_price, p_timestamp, p_timestamp);

    update os.cart
    set is_active = false
    where user_id = p_user_id;
end;
$BODY$;