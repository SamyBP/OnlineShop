-- os_rguser
grant connect on database online_shop to os_rguser;
grant usage on schema os to os_rguser;

grant all privileges on all sequences in schema os to os_rguser;

grant select, insert on all tables in schema os to os_rguser;
grant update on all tables in schema os to os_rguser;
revoke update (is_active) on table os.users from os_rguser;
grant delete on all tables in schema os to os_rguser;
revoke delete on table os.users from os_rguser;

grant execute on all functions in schema os to os_rguser;
grant execute on all procedures in schema os to os_rguser;
revoke execute on procedure os.mark_users_deleted() from os_rguser;

-- os_admin
grant connect on database online_shop to os_admin;
grant usage on schema os to os_admin;

grant all privileges on all sequences in schema os to os_admin;

grant all privileges on all tables in schema os to os_admin;
revoke delete on table os.users from os_admin;

grant execute on all functions in schema os to os_admin;
grant execute on all procedures in schema os to os_admin;
