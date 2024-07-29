CREATE OR REPLACE FUNCTION os.setup_store_addresses(
	p_users_count integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'
AS $BODY$
declare
    _country text;
	_city text;
	_address text;
begin

    for i in 1..p_users_count
    loop
        select (array['Romania', 'Spain'])[floor(random() * 2 + 1)] into _country;
        if _country = 'Romania' then
            select (array['Cluj-Napoca', 'Targu-Mures', 'Bucuresti'])[floor(random() * 3 + 1)] into _city;
        else
            select (array['Madrid', 'Barcelona'])[floor(random() * 2 + 1)] into _city;
        end if;
            select 'no. ' || i into _address;
        call store_user_address(i, _country, _city, _address);
    end loop;

    return true;
end;
$BODY$;