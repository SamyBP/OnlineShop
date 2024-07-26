
CREATE OR REPLACE FUNCTION os.setup_place_random_orders(
	integer,
	integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'
AS $BODY$
declare
    _product_cart_count int := 0;
	_user_id int;
	_product_id int;
	_address_id int;
	_products_count int;
begin
    select count(id) from product into _products_count;
    for i in 1..$1
    loop
        select random() * 5 + 1 into _product_cart_count;
        select random() * $2 + 1 into _user_id;
        select address_id from user_address where user_id = _user_id limit 1 into _address_id;

        for j in 1.._product_cart_count
        loop
            select random() * _products_count + 1 into _product_id;
            call add_to_cart(_user_id, _product_id, 1);
        end loop;

        call place_order(_user_id, _address_id, _address_id,( now() - '1 day'::interval * round(random() * 100))::timestamp);
    end loop;

    return true;
end;
$BODY$;