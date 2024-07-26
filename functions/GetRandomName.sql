CREATE OR REPLACE FUNCTION os.get_random_name(
)
    RETURNS text
    LANGUAGE 'plpgsql'
AS $BODY$
declare
    _name text;
begin
    select array_to_string
        (
                   array
                   (
                       select substr('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', trunc(random() * 52)::integer + 1, 1)
                        from   generate_series(1, 6)
                   ), ''
        )
    into _name;

    return _name;
end;
$BODY$;