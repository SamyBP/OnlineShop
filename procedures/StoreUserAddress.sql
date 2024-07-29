CREATE OR REPLACE PROCEDURE os.store_user_address(
	p_user_id integer,
	p_country text,
	p_city text,
	p_address text)
LANGUAGE 'plpgsql'
AS $BODY$

declare
    _country_id int;
	_city_id int;
	_address_id int;
	_address_count int;
begin
    select count(user_id) into _address_count from os.user_address where user_id = p_user_id;

    if _address_count = 5 then
        raise exception 'user % cannot store more addresses', p_user_id;
    end if;

    select id into _country_id from os.country where country = p_country;
    if _country_id is null then
        insert into os.country(country) values (p_country) returning id into _country_id;
    end if;

    select id into _city_id from os.city where city = p_city;
    if _city_id is null then
        insert into os.city(city, country_id) values (p_city, _country_id) returning id into _city_id;
    end if;

    insert into os.address(address, city_id) values (p_address, _city_id) returning id into _address_id;
    insert into os.user_address(user_id, address_id) values (p_user_id, _address_id);

end;
$BODY$;