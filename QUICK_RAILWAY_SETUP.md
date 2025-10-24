# 🚀 Quick Start - Railway Deployment

## Prerequisites Checklist

Before deploying, make sure you have:

- [ ] Railway account created at https://railway.app
- [ ] GitHub repository connected to Railway
- [ ] MySQL service created in Railway
- [ ] Backend service created in Railway
- [ ] (Optional) Frontend service created in Railway

---

## 🎯 5-Minute Setup

### Step 1: Link MySQL to Backend (30 seconds)

In Railway Dashboard:
1. Click your **Backend Service** (`gallant-friendship`)
2. Go to **Settings** → **Service Variables**
3. Click **+ New Variable** → **Add Reference** 
4. Select your **MySQL Service**
5. This automatically adds `DATABASE_URL`

✅ **Result:** Backend can now talk to MySQL internally!

---

### Step 2: Add Backend Environment Variables (1 minute)

In Railway Backend Service → **Variables** tab, add:

```bash
PORT=8080
NODE_ENV=production
JWT_SECRET=brightbuy_production_secret_change_this_to_something_strong
CORS_ORIGIN=https://brightbuy-production.up.railway.app
```

💡 **Tip:** Railway auto-generates `DATABASE_URL` when you link MySQL!

---

### Step 3: Configure Frontend API URL (1 minute)

**If on Netlify:**
- Netlify Dashboard → Site Settings → Environment Variables
- Add: `NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api`

**If on Railway:**
- Frontend Service → Variables tab
- Add: `NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api`

---

### Step 4: Import Database (2 minutes)

**Option A: Using Railway's Web Interface**
1. Go to MySQL Service → **Data** tab
2. Copy contents of `queries/01_schema/01_main_schema.sql`
3. Paste and execute
4. Repeat for other SQL files in order

**Option B: Using MySQL Command Line**

Get your Railway MySQL credentials first:
- Railway Dashboard → MySQL Service → **Variables** tab
- Copy: `MYSQLHOST`, `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD`, `MYSQLDATABASE`

Then run:

```powershell
# Connect to Railway MySQL (replace with your credentials)
mysql -h <MYSQLHOST> -P <MYSQLPORT> -u <MYSQLUSER> -p<MYSQLPASSWORD> <MYSQLDATABASE>

# Once connected, import files:
source D:/Project/BrightBuy/queries/01_schema/01_main_schema.sql
source D:/Project/BrightBuy/queries/02_data/01_initial_population.sql
source D:/Project/BrightBuy/queries/02_data/02_additional_population.sql
source D:/Project/BrightBuy/queries/03_procedures/01_cart_procedures.sql
source D:/Project/BrightBuy/queries/05_maintenance/02_allow_backorders.sql
```

Or use a one-liner per file:

```powershell
mysql -h <HOST> -P <PORT> -u <USER> -p<PASSWORD> <DATABASE> < queries/01_schema/01_main_schema.sql
mysql -h <HOST> -P <PORT> -u <USER> -p<PASSWORD> <DATABASE> < queries/02_data/01_initial_population.sql
# ... repeat for other files
```

---

### Step 5: Deploy! (30 seconds)

**Auto Deploy (Recommended):**
```powershell
git add .
git commit -m "Configure Railway deployment"
git push origin main
```

Railway automatically deploys on push!

**Manual Deploy:**
```powershell
# In Railway Dashboard
# Backend Service → Deployments → "Deploy Now"
```

---

## ✅ Verify Deployment

### Test Backend:

```powershell
# Health check
curl https://gallant-friendship-production.up.railway.app/

# Test API
curl https://gallant-friendship-production.up.railway.app/api/products
```

Expected response:
```json
{
  "status": "success",
  "data": [...]
}
```

### Test Frontend:

1. Open: `https://brightbuy-production.up.railway.app`
2. Products should load from Railway backend
3. Check browser console - no CORS errors
4. Test add to cart, checkout, etc.

### Check Railway Logs:

Backend logs should show:
```
✅ Server running on port 8080
✅ MySQL Database connected successfully!
✅ Connected to database: brightbuy
```

---

## 🔧 Troubleshooting

### ❌ Backend: "Cannot connect to database"

**Fix:**
1. Verify MySQL service is running (Railway Dashboard)
2. Check backend has `DATABASE_URL` variable (auto-added when linked)
3. Or manually set `DB_HOST=mysql.railway.internal`

### ❌ Frontend: "Network Error"

**Fix:**
1. Check `NEXT_PUBLIC_API_URL` is set correctly
2. Verify backend is deployed and running
3. Test backend URL directly in browser
4. Check CORS_ORIGIN includes your frontend domain

### ❌ Backend: "Port already in use"

**Fix:**
- Ensure `PORT=8080` is set in Railway variables
- Railway requires port 8080

### ❌ Database: "Access denied"

**Fix:**
- Use internal Railway URL: `mysql.railway.internal`
- Don't use public MySQL host from backend
- Verify MySQL credentials in environment variables

---

## 📊 Monitor Your Deployment

### Railway Dashboard Sections:

- **Metrics**: CPU, Memory, Network usage
- **Logs**: Real-time application logs
- **Deployments**: Deployment history
- **Variables**: Environment configuration

### Useful Commands:

```powershell
# View live logs
railway logs --follow

# Check service status
railway status

# Run commands in Railway environment
railway run npm --version
```

---

## 🎉 You're Live!

Your BrightBuy e-commerce platform is now running on Railway:

- ✅ MySQL Database: Internal Railway network
- ✅ Backend API: `gallant-friendship-production.up.railway.app`
- ✅ Frontend: `brightbuy-production.up.railway.app`

**Next steps:**
1. Test all features thoroughly
2. Monitor logs for any errors
3. Set up Railway's automatic backups
4. Configure custom domain (optional)
5. Enable Railway's built-in monitoring

---

## 📚 Additional Resources

- **Railway Docs**: https://docs.railway.app
- **MySQL Best Practices**: https://docs.railway.app/databases/mysql
- **Next.js Deployment**: https://nextjs.org/docs/deployment
- **Express on Railway**: https://docs.railway.app/guides/express

---

## 🆘 Need Help?

1. Check Railway logs first (most issues show here)
2. Review this guide's troubleshooting section
3. Check `RAILWAY_DEPLOYMENT_GUIDE.md` for detailed info
4. Railway Discord: https://discord.gg/railway
5. Railway Support: https://help.railway.app

---

**Estimated Total Setup Time: 5 minutes** ⏱️

Good luck! 🚀
