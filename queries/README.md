# BrightBuy Database

This folder holds the full database definition and seed data. Files are
numbered by run order.

## Run order

Use the master runner from the `queries/` directory:

```bash
cd queries
mysql -h <host> -P <port> -u <user> -p < 00_run_all.sql
```

`00_run_all.sql` sources the files in this order:

1. `01_schema/01_main_schema.sql` — creates the `brightbuy` database, all
   tables, triggers, stored procedures, and views.
2. `05_maintenance/03_recreate_users_table.sql` — the `users` login table
   (depends on `Customer` and `Staff`).
3. `02_data/*` — seed categories, products, variants, and product images.
4. `03_procedures/01_cart_procedures.sql` — cart stored procedures.
5. `05_maintenance/01_fix_cart_schema.sql`, `02_allow_backorders.sql` — migrations.
6. `04_admin_setup/*` — creates the admin/staff accounts and links them to `users`.

## Hosting on a managed MySQL (e.g. Aiven free plan)

Managed hosts often (a) give you a fixed default database such as
`defaultdb` and (b) do **not** allow `CREATE DATABASE` / `DROP DATABASE`.

To load the schema there:

1. Open `01_schema/01_main_schema.sql` and **remove the first three lines**:
   ```sql
   DROP DATABASE IF EXISTS brightbuy;
   CREATE DATABASE brightbuy;
   USE brightbuy;
   ```
2. Connect directly to the provided database, e.g.:
   ```bash
   mysql -h <aiven-host> -P <aiven-port> -u avnadmin -p \
         --ssl-mode=REQUIRED defaultdb < 00_run_all.sql
   ```
   (Aiven requires SSL — use `--ssl-mode=REQUIRED`, and download the CA cert
   from the Aiven console for stricter verification.)
3. The other files contain `USE brightbuy;` — either replace those with your
   default database name, or create a `brightbuy` schema if your plan allows
   it and grant your user access.

Set the backend env vars to match (see `backend/.env.example`):

```
DB_HOST=<aiven-host>
DB_PORT=<aiven-port>
DB_USER=avnadmin
DB_PASSWORD=<aiven-password>
DB_NAME=defaultdb        # or brightbuy if you created it
DB_SSL=true
```

## Default accounts (seed data)

- Staff (Level01): `admin_jvishula@brightbuy.com` / `123456`
- Staff: `admin@brightbuy.com` / `123456`

**Change these passwords immediately after first login in any real deployment.**
