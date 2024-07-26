create or replace procedure mark_users_deleted() language 'plpgsql'
as
$$
begin
	update os.users
	set is_active = false
	where last_login < now() - '2 years'::interval;
end;
$$;