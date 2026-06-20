-- ===================================================================
-- BrightBuy — Master bootstrap script
-- ===================================================================
-- Runs all schema/data/procedure/admin scripts in the correct
-- dependency order. Use with the MySQL CLI:
--
--     mysql -h <host> -P <port> -u <user> -p < queries/00_run_all.sql
--
-- or from inside the mysql shell:
--
--     mysql> SOURCE queries/00_run_all.sql;
--
-- IMPORTANT — run order matters:
--   1. Schema (creates the `brightbuy` database + all tables/triggers/views)
--   2. users table (depends on Customer + Staff from the schema)
--   3. Seed data (categories, products, variants, images)
--   4. Stored procedures
--   5. Maintenance migrations (cart schema fix, backorders)
--   6. Admin / staff accounts (depend on Staff + users tables)
--
-- NOTE for managed hosts (e.g. Aiven free plan) that DO NOT allow
-- CREATE DATABASE: see queries/README.md — you run the same files but
-- skip the DROP/CREATE DATABASE lines and target the host's default db.
-- ===================================================================

-- 1. Core schema (this file creates and USEs the `brightbuy` database)
SOURCE 01_schema/01_main_schema.sql;

-- 2. users login table (links Customer <-> Staff <-> login)
SOURCE 05_maintenance/03_recreate_users_table.sql;

-- 3. Seed data
SOURCE 02_data/01_initial_population.sql;
SOURCE 02_data/02_additional_population.sql;
SOURCE 02_data/03_product_images.sql;

-- 4. Stored procedures
SOURCE 03_procedures/01_cart_procedures.sql;

-- 5. Maintenance migrations
SOURCE 05_maintenance/01_fix_cart_schema.sql;
SOURCE 05_maintenance/02_allow_backorders.sql;

-- 6. Admin / staff accounts
SOURCE 04_admin_setup/01_create_admin.sql;
SOURCE 04_admin_setup/02_create_staff.sql;
SOURCE 04_admin_setup/03_link_admin_users.sql;

SELECT 'BrightBuy database bootstrap complete.' AS Status;
