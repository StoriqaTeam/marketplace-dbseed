DELETE FROM attributes;
ALTER SEQUENCE attributes_id_seq RESTART WITH 1;

DELETE FROM attribute_values;
ALTER SEQUENCE attribute_values_id_seq RESTART WITH 1;

DELETE FROM base_products;
ALTER SEQUENCE base_products_id_seq RESTART WITH 1;
ALTER SEQUENCE base_products_slug_seq RESTART WITH 1;

DELETE FROM cat_attr_values;
ALTER SEQUENCE cat_attr_values_id_seq RESTART WITH 1;

DELETE FROM categories;
ALTER SEQUENCE categories_id_seq RESTART WITH 1;
ALTER SEQUENCE categories_slug_seq RESTART WITH 1;

DELETE FROM coupons;
ALTER SEQUENCE coupons_id_seq RESTART WITH 1;

DELETE FROM coupon_scope_base_products;
ALTER SEQUENCE coupon_scope_base_products_id_seq RESTART WITH 1;

DELETE FROM coupon_scope_categories;
ALTER SEQUENCE coupon_scope_categories_id_seq RESTART WITH 1;

DELETE FROM currency_exchange;

DELETE FROM custom_attributes;
ALTER SEQUENCE custom_attributes_id_seq RESTART WITH 1;

DELETE FROM moderator_product_comments;
ALTER SEQUENCE moderator_product_comments_id_seq RESTART WITH 1;

DELETE FROM moderator_store_comments;
ALTER SEQUENCE moderator_store_comments_id_seq RESTART WITH 1;

DELETE FROM prod_attr_values;
ALTER SEQUENCE prod_attr_values_id_seq RESTART WITH 1;

DELETE FROM products;
ALTER SEQUENCE products_id_seq RESTART WITH 1;

DELETE FROM stores;
ALTER SEQUENCE stores_id_seq RESTART WITH 1;

DELETE FROM used_coupons;

DELETE FROM user_roles;

DELETE FROM wizard_stores;
ALTER SEQUENCE wizard_stores_id_seq RESTART WITH 1;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;
