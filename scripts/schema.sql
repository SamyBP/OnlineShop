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
-- Name: users_address_count(integer); Type: FUNCTION; Schema: os; Owner: postgres
--

CREATE FUNCTION os.users_address_count(user_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare 
   address_count integer;
begin
   	select count(*) into address_count
	from user_address ua
	where ua.user_id = user_id;

	return address_count;	
end;
$$;


ALTER FUNCTION os.users_address_count(user_id integer) OWNER TO postgres;

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
    is_active boolean,
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
    updated_at timestamp without time zone DEFAULT now() NOT NULL
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
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_maxaddresscountforuser CHECK ((os.users_address_count(user_id) <= 5))
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
-- PostgreSQL database dump complete
--

