DELETE FROM moderator_product_comments;
DELETE FROM moderator_store_comments;
DELETE FROM prod_attr_values;
DELETE FROM products;
DELETE FROM base_products;
DELETE FROM stores;
DELETE FROM cat_attr_values;
DELETE FROM attributes;
DELETE FROM categories;
DELETE FROM user_roles;
DELETE FROM currency_exchange;

ALTER SEQUENCE categories_id_seq RESTART WITH 1;
ALTER SEQUENCE attributes_id_seq RESTART WITH 1;
ALTER SEQUENCE prod_attr_values_id_seq RESTART WITH 1;
ALTER SEQUENCE products_id_seq RESTART WITH 1;
ALTER SEQUENCE base_products_id_seq RESTART WITH 1;
ALTER SEQUENCE stores_id_seq RESTART WITH 1;
ALTER SEQUENCE cat_attr_values_id_seq RESTART WITH 67;


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;
