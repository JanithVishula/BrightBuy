# BrightBuy Database

This folder holds the full database definition and seed data. Files are
numbered by run order.

## Run order

Use the master runner from the `queries/` directory against your local MySQL:

```bash
cd queries
mysql -u root -p < 00_run_all.sql
```

`00_run_all.sql` sources the files in this order:

1. `01_schema/01_main_schema.sql` — creates the `brightbuy` database, all
   tables, triggers, stored procedures, and views.
2. `01_schema/02_support_schema.sql` — customer support tickets + messages.
3. `05_maintenance/03_recreate_users_table.sql` — the `users` login table
   (depends on `Customer` and `Staff`).
4. `02_data/*` — seed categories, products, variants, and product images.
5. `03_procedures/01_cart_procedures.sql` — cart stored procedures.
6. `05_maintenance/01_fix_cart_schema.sql`, `02_allow_backorders.sql` — migrations.
7. `04_admin_setup/*` — creates the admin/staff accounts and links them to `users`.

## Default accounts (seed data)

- Staff (Level01): `admin_jvishula@brightbuy.com` / `123456`
- Staff: `admin@brightbuy.com` / `123456`
