# 🗄️ Database Migration Guide - Railway to Local MySQL

## Overview
Migrate your production MySQL database from Railway to your local MySQL instance.

---

## 📋 Prerequisites

1. **Local MySQL installed** (version 8.0+ recommended)
2. **MySQL credentials** from Railway
3. **Command line access** (PowerShell or CMD)
4. **Network access** to Railway database

---

## 🔑 Step 1: Get Railway Database Credentials

You need these details from Railway:
- **Host**: `mysql-production-92d3.up.railway.app`
- **Port**: Usually `3306` (check Railway dashboard)
- **Username**: (from Railway dashboard)
- **Password**: (from Railway dashboard)
- **Database Name**: Usually `railway` or `brightbuy`

### How to Find Credentials:
1. Go to Railway dashboard
2. Select your MySQL service
3. Go to "Variables" or "Connect" tab
4. Copy the connection details

---

## 🚀 Method 1: Direct Database Dump (Recommended)

### Step 1: Export from Railway

```powershell
# Replace with your actual Railway credentials
$RAILWAY_HOST = "mysql-production-92d3.up.railway.app"
$RAILWAY_PORT = "3306"
$RAILWAY_USER = "your_railway_username"
$RAILWAY_PASS = "your_railway_password"
$RAILWAY_DB = "railway"  # or 'brightbuy'

# Export the database
mysqldump -h $RAILWAY_HOST -P $RAILWAY_PORT -u $RAILWAY_USER -p$RAILWAY_PASS $RAILWAY_DB > railway_backup.sql
```

**Or using one command:**
```bash
mysqldump -h mysql-production-92d3.up.railway.app -P 3306 -u USERNAME -pPASSWORD DATABASE_NAME > railway_backup.sql
```

### Step 2: Import to Local MySQL

```powershell
# Create local database first
mysql -u root -p -e "DROP DATABASE IF EXISTS brightbuy; CREATE DATABASE brightbuy;"

# Import the dump
mysql -u root -p brightbuy < railway_backup.sql
```

---

## 🔄 Method 2: Using MySQL Workbench (GUI)

### Export from Railway:
1. Open MySQL Workbench
2. Create new connection:
   - **Hostname**: `mysql-production-92d3.up.railway.app`
   - **Port**: `3306`
   - **Username**: Your Railway username
   - **Password**: Your Railway password
3. Connect to the database
4. Go to **Server** → **Data Export**
5. Select your database
6. Choose "Export to Self-Contained File"
7. Click **Start Export**

### Import to Local:
1. Connect to your local MySQL server
2. Go to **Server** → **Data Import**
3. Select "Import from Self-Contained File"
4. Choose the exported file
5. Create/Select target database: `brightbuy`
6. Click **Start Import**

---

## 🛠️ Method 3: Using Provided SQL Scripts (If no Railway access)

If you can't access Railway database, use the existing SQL scripts in your project:

### Step 1: Create Database Structure
```powershell
cd D:\Project\BrightBuy

# Create database and schema
mysql -u root -p < queries/01_schema/01_main_schema.sql
```

### Step 2: Populate Data
```powershell
# Initial data
mysql -u root -p brightbuy < queries/02_data/01_initial_population.sql
mysql -u root -p brightbuy < queries/02_data/02_additional_population.sql
mysql -u root -p brightbuy < queries/02_data/03_product_images.sql
```

### Step 3: Create Procedures
```powershell
mysql -u root -p brightbuy < queries/03_procedures/01_cart_procedures.sql
```

### Step 4: Setup Admin Users
```powershell
mysql -u root -p brightbuy < queries/04_admin_setup/01_create_admin.sql
mysql -u root -p brightbuy < queries/04_admin_setup/02_create_staff.sql
mysql -u root -p brightbuy < queries/04_admin_setup/03_link_admin_users.sql
```

### Step 5: Apply Maintenance Scripts
```powershell
mysql -u root -p brightbuy < queries/05_maintenance/01_fix_cart_schema.sql
mysql -u root -p brightbuy < queries/05_maintenance/02_allow_backorders.sql
mysql -u root -p brightbuy < queries/05_maintenance/03_recreate_users_table.sql
```

---

## 🔧 Method 4: Automated Migration Script

I've created an automated PowerShell script for you:

**Save as: `migrate_database.ps1`**

```powershell
# BrightBuy Database Migration Script
# Migrates Railway MySQL database to local MySQL

param(
    [string]$RailwayHost = "mysql-production-92d3.up.railway.app",
    [string]$RailwayPort = "3306",
    [string]$RailwayUser = "",
    [string]$RailwayPass = "",
    [string]$RailwayDB = "railway",
    [string]$LocalUser = "root",
    [string]$LocalPass = "",
    [string]$LocalDB = "brightbuy"
)

Write-Host "🗄️  BrightBuy Database Migration Tool" -ForegroundColor Cyan
Write-Host "=====================================`n" -ForegroundColor Cyan

# Prompt for credentials if not provided
if (-not $RailwayUser) {
    $RailwayUser = Read-Host "Enter Railway MySQL Username"
}
if (-not $RailwayPass) {
    $RailwayPassSecure = Read-Host "Enter Railway MySQL Password" -AsSecureString
    $RailwayPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($RailwayPassSecure)
    )
}
if (-not $LocalPass) {
    $LocalPassSecure = Read-Host "Enter Local MySQL Root Password" -AsSecureString
    $LocalPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($LocalPassSecure)
    )
}

# Step 1: Export from Railway
Write-Host "`n📤 Step 1: Exporting database from Railway..." -ForegroundColor Yellow
$dumpFile = "railway_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"

$exportCmd = "mysqldump -h $RailwayHost -P $RailwayPort -u $RailwayUser -p$RailwayPass $RailwayDB"
try {
    Invoke-Expression "$exportCmd > $dumpFile"
    Write-Host "✅ Export completed: $dumpFile" -ForegroundColor Green
} catch {
    Write-Host "❌ Export failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create local database
Write-Host "`n🔨 Step 2: Creating local database..." -ForegroundColor Yellow
$createDbCmd = "mysql -u $LocalUser -p$LocalPass -e `"DROP DATABASE IF EXISTS $LocalDB; CREATE DATABASE $LocalDB;`""
try {
    Invoke-Expression $createDbCmd
    Write-Host "✅ Local database created: $LocalDB" -ForegroundColor Green
} catch {
    Write-Host "❌ Database creation failed: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Import to local
Write-Host "`n📥 Step 3: Importing to local MySQL..." -ForegroundColor Yellow
$importCmd = "mysql -u $LocalUser -p$LocalPass $LocalDB"
try {
    Get-Content $dumpFile | & mysql -u $LocalUser -p$LocalPass $LocalDB
    Write-Host "✅ Import completed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Import failed: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Apply backorder fix
Write-Host "`n🔧 Step 4: Applying backorder configuration..." -ForegroundColor Yellow
try {
    Get-Content "queries\05_maintenance\02_allow_backorders.sql" | & mysql -u $LocalUser -p$LocalPass $LocalDB
    Write-Host "✅ Backorder configuration applied" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Backorder configuration skipped (file not found or already applied)" -ForegroundColor Yellow
}

# Step 5: Verify
Write-Host "`n✅ Step 5: Verifying migration..." -ForegroundColor Yellow
$verifyCmd = "mysql -u $LocalUser -p$LocalPass -e `"USE $LocalDB; SHOW TABLES;`""
try {
    $tables = Invoke-Expression $verifyCmd
    Write-Host $tables
    Write-Host "`n✅ Migration completed successfully!" -ForegroundColor Green
    Write-Host "`n📊 Database: $LocalDB" -ForegroundColor Cyan
    Write-Host "📁 Backup file: $dumpFile" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Verification failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 All done! You can now use your local database." -ForegroundColor Green
```

### Run the script:
```powershell
cd D:\Project\BrightBuy
.\migrate_database.ps1
```

---

## 📝 Method 5: Manual Table-by-Table Copy

If you need more control, copy tables individually:

```sql
-- On Railway (export)
SELECT * INTO OUTFILE '/tmp/customers.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM Customer;

-- On Local (import)
LOAD DATA INFILE '/path/to/customers.csv'
INTO TABLE Customer
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

---

## ⚙️ Update Backend Configuration

After migration, update your backend to use local database:

### File: `backend/.env`

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_local_password
DB_DATABASE=brightbuy

# For production (Railway), uncomment:
# DB_HOST=mysql-production-92d3.up.railway.app
# DB_PORT=3306
# DB_USER=your_railway_username
# DB_PASSWORD=your_railway_password
# DB_DATABASE=railway
```

---

## 🧪 Verification Steps

After migration, verify everything works:

### 1. Check Database Tables
```sql
USE brightbuy;
SHOW TABLES;

-- Should show:
-- Address, Cart_item, Category, Customer, Inventory, etc.
```

### 2. Check Data
```sql
-- Check products
SELECT COUNT(*) FROM Product;

-- Check customers
SELECT COUNT(*) FROM Customer;

-- Check orders
SELECT COUNT(*) FROM Orders;

-- Check inventory
SELECT COUNT(*) FROM Inventory;
```

### 3. Test Backend Connection
```powershell
cd backend
npm start
```

Check console for: "✅ Database connected successfully"

### 4. Test Frontend
```powershell
cd frontend
npm run dev
```

Visit: `http://localhost:3000/products`

---

## 🔒 Security Notes

1. **Keep credentials secure** - Don't commit `.env` files
2. **Use different passwords** for local vs production
3. **Backup Railway database** before any changes
4. **Test locally first** before deploying changes

---

## 📊 Expected Database Structure

After migration, you should have these tables:

```
✓ Address
✓ Cart_item
✓ Category
✓ Customer
✓ Inventory
✓ Inventory_updates
✓ Order_item
✓ Orders
✓ Payment
✓ Product
✓ ProductCategory
✓ ProductVariant
✓ Shipment
✓ Staff
✓ ZipDeliveryZone
```

---

## 🐛 Troubleshooting

### Issue: "Access denied for user"
**Solution:** Check Railway credentials, ensure IP is whitelisted

### Issue: "mysqldump: command not found"
**Solution:** Add MySQL bin to PATH:
```powershell
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.0\bin"
```

### Issue: "Table already exists"
**Solution:** Drop database first:
```sql
DROP DATABASE IF EXISTS brightbuy;
CREATE DATABASE brightbuy;
```

### Issue: Import hangs/slow
**Solution:** Disable foreign key checks temporarily:
```sql
SET FOREIGN_KEY_CHECKS=0;
-- Import data
SET FOREIGN_KEY_CHECKS=1;
```

### Issue: Character encoding problems
**Solution:** Specify charset in dump:
```bash
mysqldump --default-character-set=utf8mb4 ...
```

---

## 🔄 Keeping Databases in Sync

For ongoing development:

1. **Export from Railway weekly:**
   ```bash
   mysqldump -h railway... > backup_$(date +%Y%m%d).sql
   ```

2. **Version control schema changes:**
   - Keep SQL scripts in `/queries`
   - Apply same changes to both databases

3. **Use migrations for schema updates:**
   - Document all schema changes
   - Test locally first
   - Apply to Railway after verification

---

## 📞 Quick Reference Commands

```powershell
# Export from Railway
mysqldump -h mysql-production-92d3.up.railway.app -P 3306 -u USER -pPASS DATABASE > backup.sql

# Import to Local
mysql -u root -p brightbuy < backup.sql

# Connect to Railway
mysql -h mysql-production-92d3.up.railway.app -P 3306 -u USER -pPASS DATABASE

# Connect to Local
mysql -u root -p brightbuy

# Backup local
mysqldump -u root -p brightbuy > local_backup.sql
```

---

## ✅ Migration Checklist

- [ ] Get Railway credentials
- [ ] Export Railway database
- [ ] Create local database
- [ ] Import data to local
- [ ] Apply backorder configuration
- [ ] Verify table structure
- [ ] Test backend connection
- [ ] Test frontend functionality
- [ ] Update `.env` configuration
- [ ] Test all CRUD operations
- [ ] Verify cart and checkout work
- [ ] Check staff and admin access

---

## 🎯 Summary

Choose the method that works best for you:

1. **Direct Dump** (Fastest) - Use `mysqldump` command
2. **MySQL Workbench** (Easiest) - GUI-based migration
3. **SQL Scripts** (No Railway access) - Use existing project scripts
4. **Automated Script** (Most convenient) - Run PowerShell script
5. **Manual Copy** (Most control) - Table-by-table migration

After migration, your local database will be an exact copy of Railway production! 🎉
