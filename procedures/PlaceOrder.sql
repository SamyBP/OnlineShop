CREATE OR REPLACE PROCEDURE os.place_order(
	IN integer,
	IN integer,
	IN integer,
	IN timestamp without time zone DEFAULT now())
LANGUAGE 'plpgsql'
AS $BODY$
declare
    _p record;
	_cart_id int;
	_order_price decimal(7,2) := 0.0;
begin
    select id into _cart_id from os.cart where user_id = $1 and is_active = true;
    if _cart_id is null then
        raise exception 'user % cannot place orders, he has no products in cart', $1;
    end if;

    for _p in select product_id, quantity, price from os.cart_product where cart_id = _cart_id
    loop
        update os.product
        set quantity = quantity - _p.quantity
        where id = _p.product_id;

        select _p.price * _p.quantity + _order_price into _order_price;
    end loop;

    insert into os.orders(user_id, cart_id, delivery_address, invoice_address, price, created_at, updated_at)
    values ($1, _cart_id, $2, $3, _order_price, $4, $4);

    update os.cart
    set is_active = false
    where user_id = $1;
end;
$BODY$;