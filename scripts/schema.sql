--
-- PostgreSQL database dump
--

-- Dumped from database version 15.7
-- Dumped by pg_dump version 15.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: os; Type: SCHEMA; Schema: -; Owner: os_admin
--

CREATE SCHEMA os;


ALTER SCHEMA os OWNER TO os_admin;

--
-- Name: add_to_cart(integer, integer, integer); Type: PROCEDURE; Schema: os; Owner: postgres
--

CREATE PROCEDURE os.add_to_cart(IN p_user_id integer, IN p_product_id integer, IN p_quantity integer)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER PROCEDURE os.add_to_cart(IN p_user_id integer, IN p_product_id integer, IN p_quantity integer) OWNER TO postgres;

--
-- Name: get_random_name(); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION os.get_random_name() RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
_name text;
begin
select array_to_string(
               array
               (
                   select substr('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', trunc(random() * 52)::integer + 1, 1)
              from   generate_series(1, 6)), ''
       )
into _name;

return _name;
end;
$$;


ALTER FUNCTION os.get_random_name() OWNER TO postgres;

--
-- Name: mark_users_deleted(); Type: PROCEDURE; Schema: os; Owner: postgres
--

CREATE PROCEDURE os.mark_users_deleted()
    LANGUAGE plpgsql
    AS $$
begin
	update os.users
	set is_active = false
	where last_login < now() - '2 years'::interval;
end;
$$;


ALTER PROCEDURE os.mark_users_deleted() OWNER TO postgres;

--
-- Name: place_order(integer, integer, integer, timestamp without time zone); Type: PROCEDURE; Schema: os; Owner: postgres
--

CREATE PROCEDURE os.place_order(IN p_user_id integer, IN p_delivery_address_id integer, IN p_invoice_address_id integer, IN p_timestamp timestamp without time zone DEFAULT now())
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER PROCEDURE os.place_order(IN p_user_id integer, IN p_delivery_address_id integer, IN p_invoice_address_id integer, IN p_timestamp timestamp without time zone) OWNER TO postgres;

--
-- Name: setup_place_random_orders(integer, integer); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION os.setup_place_random_orders(integer, integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
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
        select random() * ($2 - 1) + 1 into _user_id;
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
$_$;


ALTER FUNCTION os.setup_place_random_orders(integer, integer) OWNER TO postgres;

--
-- Name: setup_store_addresses(integer); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION os.setup_store_addresses(integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
declare
_country text;
	_city text;
	_address text;
begin

for i in 1..$1
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
$_$;


ALTER FUNCTION os.setup_store_addresses(integer) OWNER TO postgres;

--
-- Name: store_user_address(integer, text, text, text); Type: PROCEDURE; Schema: os; Owner: postgres
--

CREATE PROCEDURE os.store_user_address(IN p_user_id integer, IN p_country text, IN p_city text, IN p_address text)
    LANGUAGE plpgsql
    AS $$

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
$$;


ALTER PROCEDURE os.store_user_address(IN p_user_id integer, IN p_country text, IN p_city text, IN p_address text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: address; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.address (
    id integer NOT NULL,
    address text NOT NULL,
    city_id integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE os.address OWNER TO postgres;

--
-- Name: address_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.address_id_seq OWNER TO postgres;

--
-- Name: address_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.address_id_seq OWNED BY os.address.id;


--
-- Name: cart; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.cart (
    id integer NOT NULL,
    user_id integer,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE os.cart OWNER TO postgres;

--
-- Name: cart_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.cart_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.cart_id_seq OWNER TO postgres;

--
-- Name: cart_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.cart_id_seq OWNED BY os.cart.id;


--
-- Name: cart_product; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.cart_product (
    cart_id integer NOT NULL,
    product_id integer NOT NULL,
    quantity integer,
    price numeric(7,2) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT cart_product_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE os.cart_product OWNER TO postgres;

--
-- Name: category; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.category (
    id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE os.category OWNER TO postgres;

--
-- Name: category_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.category_id_seq OWNER TO postgres;

--
-- Name: category_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.category_id_seq OWNED BY os.category.id;


--
-- Name: city; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.city (
    id integer NOT NULL,
    city text NOT NULL,
    country_id integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE os.city OWNER TO postgres;

--
-- Name: city_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.city_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.city_id_seq OWNER TO postgres;

--
-- Name: city_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.city_id_seq OWNED BY os.city.id;


--
-- Name: country; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.country (
    id integer NOT NULL,
    country text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE os.country OWNER TO postgres;

--
-- Name: country_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.country_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.country_id_seq OWNER TO postgres;

--
-- Name: country_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.country_id_seq OWNED BY os.country.id;


--
-- Name: orders; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.orders (
    id integer NOT NULL,
    user_id integer,
    cart_id integer,
    delivery_address integer,
    invoice_address integer,
    status text DEFAULT 'Pending'::text,
    price numeric(7,2) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT orders_status_check CHECK ((status = ANY (ARRAY['Pending'::text, 'Shipped'::text, 'Delivered'::text])))
);


ALTER TABLE os.orders OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.orders_id_seq OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.orders_id_seq OWNED BY os.orders.id;


--
-- Name: product; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.product (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    price numeric(7,2),
    quantity integer,
    category_id integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT product_quantity_check CHECK ((quantity >= 0))
);


ALTER TABLE os.product OWNER TO postgres;

--
-- Name: product_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.product_id_seq OWNER TO postgres;

--
-- Name: product_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.product_id_seq OWNED BY os.product.id;


--
-- Name: role; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.role (
    id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE os.role OWNER TO postgres;

--
-- Name: role_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.role_id_seq OWNER TO postgres;

--
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.role_id_seq OWNED BY os.role.id;


--
-- Name: stock_log; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.stock_log (
    id integer NOT NULL,
    quantity integer,
    product_id integer,
    CONSTRAINT stock_log_quantity_check CHECK ((quantity > 0))
);


ALTER TABLE os.stock_log OWNER TO postgres;

--
-- Name: stock_log_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.stock_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.stock_log_id_seq OWNER TO postgres;

--
-- Name: stock_log_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.stock_log_id_seq OWNED BY os.stock_log.id;


--
-- Name: user_address; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.user_address (
    user_id integer NOT NULL,
    address_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE os.user_address OWNER TO postgres;

--
-- Name: user_role; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.user_role (
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE os.user_role OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: os; Owner: postgres
--

CREATE TABLE os.users (
    id integer NOT NULL,
    username text NOT NULL,
    password text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE os.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: os; Owner: postgres
--

CREATE SEQUENCE os.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE os.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: os; Owner: postgres
--

ALTER SEQUENCE os.users_id_seq OWNED BY os.users.id;


--
-- Name: address id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.address ALTER COLUMN id SET DEFAULT nextval('os.address_id_seq'::regclass);


--
-- Name: cart id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.cart ALTER COLUMN id SET DEFAULT nextval('os.cart_id_seq'::regclass);


--
-- Name: category id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.category ALTER COLUMN id SET DEFAULT nextval('os.category_id_seq'::regclass);


--
-- Name: city id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.city ALTER COLUMN id SET DEFAULT nextval('os.city_id_seq'::regclass);


--
-- Name: country id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.country ALTER COLUMN id SET DEFAULT nextval('os.country_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.orders ALTER COLUMN id SET DEFAULT nextval('os.orders_id_seq'::regclass);


--
-- Name: product id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.product ALTER COLUMN id SET DEFAULT nextval('os.product_id_seq'::regclass);


--
-- Name: role id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.role ALTER COLUMN id SET DEFAULT nextval('os.role_id_seq'::regclass);


--
-- Name: stock_log id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.stock_log ALTER COLUMN id SET DEFAULT nextval('os.stock_log_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.users ALTER COLUMN id SET DEFAULT nextval('os.users_id_seq'::regclass);


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (id);


--
-- Name: cart cart_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.cart
    ADD CONSTRAINT cart_pkey PRIMARY KEY (id);


--
-- Name: cart_product cart_product_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.cart_product
    ADD CONSTRAINT cart_product_pkey PRIMARY KEY (cart_id, product_id);


--
-- Name: category category_name_key; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.category
    ADD CONSTRAINT category_name_key UNIQUE (name);


--
-- Name: category category_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);


--
-- Name: city city_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (id);


--
-- Name: country country_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: product product_name_key; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.product
    ADD CONSTRAINT product_name_key UNIQUE (name);


--
-- Name: product product_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (id);


--
-- Name: role role_name_key; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.role
    ADD CONSTRAINT role_name_key UNIQUE (name);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: stock_log stock_log_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.stock_log
    ADD CONSTRAINT stock_log_pkey PRIMARY KEY (id);


--
-- Name: user_address user_address_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.user_address
    ADD CONSTRAINT user_address_pkey PRIMARY KEY (user_id, address_id);


--
-- Name: user_role user_role_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.user_role
    ADD CONSTRAINT user_role_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: address_cityid_fkey; Type: INDEX; Schema: os; Owner: postgres
--

CREATE INDEX address_cityid_fkey ON os.address USING btree (city_id);


--
-- Name: city_countryid_fkey; Type: INDEX; Schema: os; Owner: postgres
--

CREATE INDEX city_countryid_fkey ON os.city USING btree (country_id);


--
-- Name: orders_cartid_fkey; Type: INDEX; Schema: os; Owner: postgres
--

CREATE INDEX orders_cartid_fkey ON os.orders USING btree (cart_id);


--
-- Name: orders_deliveryaddress_fkey; Type: INDEX; Schema: os; Owner: postgres
--

CREATE INDEX orders_deliveryaddress_fkey ON os.orders USING btree (cart_id);


--
-- Name: orders_userid_fkey; Type: INDEX; Schema: os; Owner: postgres
--

CREATE INDEX orders_userid_fkey ON os.orders USING btree (user_id);


--
-- Name: product_categoryid_fkey; Type: INDEX; Schema: os; Owner: postgres
--

CREATE INDEX product_categoryid_fkey ON os.product USING btree (category_id);


--
-- Name: userid_isactive_idx; Type: INDEX; Schema: os; Owner: postgres
--

CREATE UNIQUE INDEX userid_isactive_idx ON os.cart USING btree (user_id, is_active) WHERE (is_active = true);


--
-- Name: address fk_address_city; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.address
    ADD CONSTRAINT fk_address_city FOREIGN KEY (city_id) REFERENCES os.city(id);


--
-- Name: cart fk_cart_users; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.cart
    ADD CONSTRAINT fk_cart_users FOREIGN KEY (user_id) REFERENCES os.users(id);


--
-- Name: cart_product fk_cartproduct_cart; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.cart_product
    ADD CONSTRAINT fk_cartproduct_cart FOREIGN KEY (cart_id) REFERENCES os.cart(id);


--
-- Name: cart_product fk_cartproduct_product; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.cart_product
    ADD CONSTRAINT fk_cartproduct_product FOREIGN KEY (product_id) REFERENCES os.product(id);


--
-- Name: city fk_city_country; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.city
    ADD CONSTRAINT fk_city_country FOREIGN KEY (country_id) REFERENCES os.country(id);


--
-- Name: orders fk_order_cart; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.orders
    ADD CONSTRAINT fk_order_cart FOREIGN KEY (cart_id) REFERENCES os.cart(id);


--
-- Name: orders fk_order_deliveraddress; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.orders
    ADD CONSTRAINT fk_order_deliveraddress FOREIGN KEY (delivery_address) REFERENCES os.address(id);


--
-- Name: orders fk_order_invoiceaddress; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.orders
    ADD CONSTRAINT fk_order_invoiceaddress FOREIGN KEY (invoice_address) REFERENCES os.address(id);


--
-- Name: orders fk_order_users; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.orders
    ADD CONSTRAINT fk_order_users FOREIGN KEY (user_id) REFERENCES os.users(id);


--
-- Name: product fk_product_category; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.product
    ADD CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES os.category(id);


--
-- Name: stock_log fk_stocklog_product; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.stock_log
    ADD CONSTRAINT fk_stocklog_product FOREIGN KEY (product_id) REFERENCES os.product(id);


--
-- Name: user_address fk_useraddress_address; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.user_address
    ADD CONSTRAINT fk_useraddress_address FOREIGN KEY (address_id) REFERENCES os.address(id);


--
-- Name: user_address fk_useraddress_users; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.user_address
    ADD CONSTRAINT fk_useraddress_users FOREIGN KEY (user_id) REFERENCES os.users(id);


--
-- Name: user_role fk_userrole_role; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.user_role
    ADD CONSTRAINT fk_userrole_role FOREIGN KEY (role_id) REFERENCES os.role(id);


--
-- Name: user_role fk_userrole_users; Type: FK CONSTRAINT; Schema: os; Owner: postgres
--

ALTER TABLE ONLY os.user_role
    ADD CONSTRAINT fk_userrole_users FOREIGN KEY (user_id) REFERENCES os.users(id);


--
-- Name: SCHEMA os; Type: ACL; Schema: -; Owner: os_admin
--

GRANT USAGE ON SCHEMA os TO os_rguser;


--
-- Name: PROCEDURE add_to_cart(IN p_user_id integer, IN p_product_id integer, IN p_quantity integer); Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON PROCEDURE os.add_to_cart(IN p_user_id integer, IN p_product_id integer, IN p_quantity integer) TO os_rguser;
GRANT ALL ON PROCEDURE os.add_to_cart(IN p_user_id integer, IN p_product_id integer, IN p_quantity integer) TO os_admin;


--
-- Name: FUNCTION get_random_name(); Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON FUNCTION os.get_random_name() TO os_rguser;
GRANT ALL ON FUNCTION os.get_random_name() TO os_admin;


--
-- Name: PROCEDURE mark_users_deleted(); Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON PROCEDURE os.mark_users_deleted() TO os_admin;


--
-- Name: PROCEDURE place_order(IN p_user_id integer, IN p_delivery_address_id integer, IN p_invoice_address_id integer, IN p_timestamp timestamp without time zone); Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON PROCEDURE os.place_order(IN p_user_id integer, IN p_delivery_address_id integer, IN p_invoice_address_id integer, IN p_timestamp timestamp without time zone) TO os_rguser;
GRANT ALL ON PROCEDURE os.place_order(IN p_user_id integer, IN p_delivery_address_id integer, IN p_invoice_address_id integer, IN p_timestamp timestamp without time zone) TO os_admin;


--
-- Name: FUNCTION setup_place_random_orders(integer, integer); Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON FUNCTION os.setup_place_random_orders(integer, integer) TO os_rguser;
GRANT ALL ON FUNCTION os.setup_place_random_orders(integer, integer) TO os_admin;


--
-- Name: FUNCTION setup_store_addresses(integer); Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON FUNCTION os.setup_store_addresses(integer) TO os_rguser;
GRANT ALL ON FUNCTION os.setup_store_addresses(integer) TO os_admin;


--
-- Name: PROCEDURE store_user_address(IN p_user_id integer, IN p_country text, IN p_city text, IN p_address text); Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON PROCEDURE os.store_user_address(IN p_user_id integer, IN p_country text, IN p_city text, IN p_address text) TO os_rguser;
GRANT ALL ON PROCEDURE os.store_user_address(IN p_user_id integer, IN p_country text, IN p_city text, IN p_address text) TO os_admin;


--
-- Name: TABLE address; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.address TO os_rguser;
GRANT ALL ON TABLE os.address TO os_admin;


--
-- Name: SEQUENCE address_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.address_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.address_id_seq TO os_rguser;


--
-- Name: TABLE cart; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.cart TO os_rguser;
GRANT ALL ON TABLE os.cart TO os_admin;


--
-- Name: SEQUENCE cart_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.cart_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.cart_id_seq TO os_rguser;


--
-- Name: TABLE cart_product; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.cart_product TO os_rguser;
GRANT ALL ON TABLE os.cart_product TO os_admin;


--
-- Name: TABLE category; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.category TO os_rguser;
GRANT ALL ON TABLE os.category TO os_admin;


--
-- Name: SEQUENCE category_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.category_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.category_id_seq TO os_rguser;


--
-- Name: TABLE city; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.city TO os_rguser;
GRANT ALL ON TABLE os.city TO os_admin;


--
-- Name: SEQUENCE city_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.city_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.city_id_seq TO os_rguser;


--
-- Name: TABLE country; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.country TO os_rguser;
GRANT ALL ON TABLE os.country TO os_admin;


--
-- Name: SEQUENCE country_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.country_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.country_id_seq TO os_rguser;


--
-- Name: TABLE orders; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.orders TO os_rguser;
GRANT ALL ON TABLE os.orders TO os_admin;


--
-- Name: SEQUENCE orders_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.orders_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.orders_id_seq TO os_rguser;


--
-- Name: TABLE product; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.product TO os_rguser;
GRANT ALL ON TABLE os.product TO os_admin;


--
-- Name: SEQUENCE product_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.product_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.product_id_seq TO os_rguser;


--
-- Name: TABLE role; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.role TO os_rguser;
GRANT ALL ON TABLE os.role TO os_admin;


--
-- Name: SEQUENCE role_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.role_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.role_id_seq TO os_rguser;


--
-- Name: TABLE stock_log; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.stock_log TO os_rguser;
GRANT ALL ON TABLE os.stock_log TO os_admin;


--
-- Name: SEQUENCE stock_log_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.stock_log_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.stock_log_id_seq TO os_rguser;


--
-- Name: TABLE user_address; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.user_address TO os_rguser;
GRANT ALL ON TABLE os.user_address TO os_admin;


--
-- Name: TABLE user_role; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE os.user_role TO os_rguser;
GRANT ALL ON TABLE os.user_role TO os_admin;


--
-- Name: TABLE users; Type: ACL; Schema: os; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE os.users TO os_rguser;
GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,UPDATE ON TABLE os.users TO os_admin;


--
-- Name: SEQUENCE users_id_seq; Type: ACL; Schema: os; Owner: postgres
--

GRANT ALL ON SEQUENCE os.users_id_seq TO os_admin;
GRANT ALL ON SEQUENCE os.users_id_seq TO os_rguser;


--
-- PostgreSQL database dump complete
--

