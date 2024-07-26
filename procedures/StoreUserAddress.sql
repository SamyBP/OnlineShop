CREATE OR REPLACE PROCEDURE os.store_user_address(
	IN integer,
	IN text,
	IN text,
	IN text)
LANGUAGE 'plpgsql'
AS $BODY$

declare
    _country_id int;
	_city_id int;
	_address_id int;
	_address_count int;
begin
    select count(user_id) into _address_count from os.user_address where user_id = $1;

    if _address_count = 5 then
        raise exception 'user % cannot store more addresses', $1;
    end if;

    select id into _country_id from os.country where country = $2;
    if _country_id is null then
        insert into os.country(country) values ($2) returning id into _country_id;
    end if;

    select id into _city_id from os.city where city = $3;
    if _city_id is null then
        insert into os.city(city, country_id) values ($3, _country_id) returning id into _city_id;
    end if;

    insert into os.address(address, city_id) values ($4, _city_id) returning id into _address_id;
    insert into os.user_address(user_id, address_id) values ($1, _address_id);

end;
$BODY$;