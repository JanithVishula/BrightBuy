# 🚀 Quick Start: Migrate Railway Database to Local

## One-Command Migration

```powershell
cd D:\Project\BrightBuy
.\migrate_railway_to_local.ps1
```

The script will prompt you for:
1. Railway MySQL username
2. Railway MySQL password  
3. Railway database name (default: railway)
4. Local MySQL root password

That's it! The script handles everything automatically.

---

## What You Need

Before running the script, make sure you have:

### ✅ Railway Database Credentials

Get these from your Railway dashboard:
- **Host**: `mysql-production-92d3.up.railway.app` ✓ (already configured)
- **Port**: `3306` (default)
- **Username**: _______________ (you need this)
- **Password**: _______________ (you need this)
- **Database Name**: `railway` or `brightbuy` (you need this)

### ✅ Local MySQL Installed

Check if MySQL is installed:
```powershell
mysql --version
```

If not installed, download from: https://dev.mysql.com/downloads/mysql/

---

## Step-by-Step Guide

### 1. Find Railway Credentials

**Option A: Railway Dashboard (Web)**
1. Go to https://railway.app/dashboard
2. Select your project
3. Click on MySQL service
4. Go to "Variables" tab
5. Copy these values:
   - `MYSQLUSER`
   - `MYSQLPASSWORD`
   - `MYSQLDATABASE`

**Option B: Railway CLI**
```powershell
railway login
railway variables
```

### 2. Run Migration Script

```powershell
cd D:\Project\BrightBuy
.\migrate_railway_to_local.ps1
```

### 3. Follow the Prompts

```
Enter Railway MySQL Username: [paste your username]
Enter Railway MySQL Password: [paste your password]
Enter Railway Database Name: [railway or brightbuy]
Enter Local MySQL Root Password: [your local mysql password]
```

### 4. Confirm Migration

When asked:
```
⚠️  This will DROP and recreate database 'brightbuy'. Continue? (yes/no)
```

Type `yes` and press Enter.

### 5. Wait for Completion

The script will:
- ✅ Test Railway connection
- ✅ Export database from Railway
- ✅ Create local database
- ✅ Import data
- ✅ Apply configurations
- ✅ Verify migration

---

## After Migration

### Update Backend Configuration

The script will ask:
```
Would you like to update backend/.env file now? (yes/no)
```

**Recommended**: Type `yes`

Or manually update `backend/.env`:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_local_password
DB_DATABASE=brightbuy
```

### Test the Connection

```powershell
# Start backend
cd backend
npm start

# Should see: "✅ Database connected successfully"
```

```powershell
# Start frontend (in new terminal)
cd frontend
npm run dev

# Visit: http://localhost:3000
```

---

## Manual Method (If Script Fails)

### Export from Railway

```powershell
mysqldump -h mysql-production-92d3.up.railway.app -P 3306 -u YOUR_USERNAME -pYOUR_PASSWORD YOUR_DATABASE > railway_backup.sql
```

### Import to Local

```powershell
mysql -u root -p -e "DROP DATABASE IF EXISTS brightbuy; CREATE DATABASE brightbuy;"
mysql -u root -p brightbuy < railway_backup.sql
```

---

## Troubleshooting

### "MySQL command not found"

**Fix**: Add MySQL to PATH:
```powershell
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.0\bin"
```

### "Access denied"

**Fix**: Check Railway credentials are correct. Verify in Railway dashboard.

### "Connection timeout"

**Fix**: Check internet connection. Railway host should be accessible.

### "Table already exists"

**Fix**: Script automatically drops database. If manual, use:
```sql
DROP DATABASE IF EXISTS brightbuy;
CREATE DATABASE brightbuy;
```

---

## Files Created

After migration, you'll have:

- `railway_backup_YYYYMMDD_HHMMSS.sql` - Database dump
- `backend/.env` - Updated configuration (if you chose to update)
- `backend/.env.backup_YYYYMMDD_HHMMSS` - Backup of old .env

**Keep the backup file safe!** You can use it to restore later.

---

## Verify Migration

### Check Tables

```powershell
mysql -u root -p brightbuy -e "SHOW TABLES;"
```

Should show 15+ tables including:
- Product
- Customer
- Orders
- Inventory
- Cart_item
- etc.

### Check Data

```powershell
mysql -u root -p brightbuy -e "SELECT COUNT(*) as products FROM Product;"
mysql -u root -p brightbuy -e "SELECT COUNT(*) as customers FROM Customer;"
mysql -u root -p brightbuy -e "SELECT COUNT(*) as orders FROM Orders;"
```

---

## Next Steps

1. ✅ Backend is connected to local database
2. ✅ Test all features work
3. ✅ Make changes locally
4. ✅ Test thoroughly
5. ✅ Deploy to production when ready

---

## Need Help?

### Common Issues

**Q: Can I use a different local database name?**
A: Yes! Run with parameter:
```powershell
.\migrate_railway_to_local.ps1 -LocalDB "my_database_name"
```

**Q: Can I migrate to a different user?**
A: Yes! Run with parameters:
```powershell
.\migrate_railway_to_local.ps1 -LocalUser "myuser" -LocalPass "mypass"
```

**Q: How do I migrate back to Railway?**
A: Export local and import to Railway:
```powershell
mysqldump -u root -p brightbuy > local_backup.sql
mysql -h mysql-production-92d3.up.railway.app -P 3306 -u USER -pPASS DATABASE < local_backup.sql
```

**Q: Can I schedule automatic backups?**
A: Yes! Set up a Windows Task Scheduler to run the export command daily.

---

## Summary

✅ **Simple**: One command does everything  
✅ **Safe**: Keeps backups automatically  
✅ **Fast**: Usually completes in 1-3 minutes  
✅ **Reliable**: Tests connections before proceeding  
✅ **Verified**: Checks migration success  

**Ready to migrate? Run:**
```powershell
cd D:\Project\BrightBuy
.\migrate_railway_to_local.ps1
```

🎉 **That's it! Your local database will match Railway exactly!**
