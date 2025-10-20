# 🚂 Railway Deployment Guide - Complete Setup

## Your Railway Services

Based on your setup, you have:

1. **MySQL Database**: `mysql.railway.internal` (also `gallant-friendship.railway.internal`)
2. **Backend API**: `gallant-friendship` service
3. **Frontend**: `brightbuy-production.up.railway.app` (Port 8080)

---

## 🔧 Step 1: Configure Backend Environment Variables

### In Railway Dashboard (Backend Service)

1. Go to your **backend service** (`gallant-friendship`) in Railway
2. Click on **Variables** tab
3. Add/Update these environment variables:

```bash
# Server Configuration
PORT=8080
NODE_ENV=production

# Database Configuration - Use Railway's internal MySQL connection
DB_HOST=mysql.railway.internal
DB_PORT=3306
DB_USER=<your_mysql_username>
DB_PASSWORD=<your_mysql_password>
DB_NAME=brightbuy

# Alternative: Use DATABASE_URL (Railway auto-generates this)
DATABASE_URL=mysql://<username>:<password>@mysql.railway.internal:3306/brightbuy

# JWT Secret (use a strong secret for production)
JWT_SECRET=<your_strong_jwt_secret_here>

# CORS Origins (allow your frontend domain)
CORS_ORIGIN=https://brightbuy-production.up.railway.app,https://*.netlify.app
```

### Important Notes:

- ✅ **Use `mysql.railway.internal`** for internal Railway networking (faster, free)
- ✅ Railway automatically injects `DATABASE_URL` if you linked MySQL service
- ✅ Backend listens on **Port 8080** (Railway requirement)

---

## 🌐 Step 2: Configure Frontend Environment Variables

### Option A: If Frontend is on Railway

1. Go to your **frontend service** in Railway
2. Click on **Variables** tab
3. Add this variable:

```bash
NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api
```

### Option B: If Frontend is on Netlify

Create `frontend/.env.production`:

```bash
NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api
```

Then in **Netlify Dashboard** → Site Settings → Environment Variables:

```bash
NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api
```

---

## 🔗 Step 3: Link Services in Railway (Important!)

### Link MySQL to Backend:

1. In Railway Dashboard, click your **Backend Service**
2. Go to **Settings** → **Service Variables**
3. Click **Link** → Select your **MySQL service**
4. Railway will automatically add `DATABASE_URL` variable

This creates:
```bash
DATABASE_URL=mysql://root:password@mysql.railway.internal:3306/railway
```

### Verify the Link:

```bash
# In your backend logs, you should see:
# ✅ MySQL Database connected successfully!
# Connected to database: brightbuy
```

---

## 📝 Step 4: Update Backend for Railway

### Update `backend/.env` for Local Development:

```env
# Server Configuration
PORT=5001
NODE_ENV=development

# Database Configuration (MySQL)
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=1234
DB_NAME=brightbuy

# JWT Secrets
JWT_SECRET=brightbuy_jwt_secret_key_2025

# CORS Origins (allow localhost for development)
CORS_ORIGIN=http://localhost:3000,http://localhost:3001
```

### Update `backend/server.js` for CORS:

Add this CORS configuration to allow your frontend domain:

```javascript
const cors = require('cors');

// CORS Configuration
const corsOptions = {
  origin: process.env.CORS_ORIGIN 
    ? process.env.CORS_ORIGIN.split(',')
    : ['http://localhost:3000'],
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
```

---

## 🚀 Step 5: Deploy Backend to Railway

### Option A: Auto Deploy (Recommended)

Railway automatically deploys when you push to GitHub:

```powershell
git add .
git commit -m "Configure Railway environment"
git push origin main
```

### Option B: Manual Deploy via Railway CLI

```powershell
# Install Railway CLI
npm i -g @railway/cli

# Login to Railway
railway login

# Link to your project
railway link

# Deploy backend
cd backend
railway up
```

---

## 🎨 Step 6: Deploy Frontend

### If on Netlify (Current Setup):

1. Update `frontend/.env.production`:

```bash
NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api
```

2. Deploy to Netlify:

```powershell
cd frontend
npm run build
netlify deploy --prod
```

### If Moving to Railway:

1. Create new service in Railway
2. Set root directory to `frontend`
3. Add environment variable:

```bash
NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api
```

4. Deploy automatically via GitHub integration

---

## 🗄️ Step 7: Populate Railway MySQL Database

### Get Railway MySQL Credentials:

1. In Railway Dashboard → MySQL Service → Variables
2. Copy these values:
   - `MYSQL_HOST` (or use `mysql.railway.internal` internally)
   - `MYSQL_USER`
   - `MYSQL_PASSWORD`
   - `MYSQL_DATABASE`

### Connect and Import Data:

```powershell
# Connect to Railway MySQL
mysql -h gallant-friendship.railway.internal -P 3306 -u <username> -p

# Or use Railway's public host (if available)
mysql -h mysql.railway.app -P <public_port> -u <username> -p
```

### Import Your Database Schema and Data:

```powershell
# From your local machine
mysql -h <railway_mysql_host> -P <port> -u <username> -p<password> brightbuy < queries/01_schema/01_main_schema.sql
mysql -h <railway_mysql_host> -P <port> -u <username> -p<password> brightbuy < queries/02_data/01_initial_population.sql
mysql -h <railway_mysql_host> -P <port> -u <username> -p<password> brightbuy < queries/02_data/02_additional_population.sql
mysql -h <railway_mysql_host> -P <port> -u <username> -p<password> brightbuy < queries/03_procedures/01_cart_procedures.sql
mysql -h <railway_mysql_host> -P <port> -u <username> -p<password> brightbuy < queries/05_maintenance/02_allow_backorders.sql
```

### Or Use Railway's Web MySQL Client:

1. Go to Railway Dashboard → MySQL Service
2. Click **Data** tab
3. Use the web interface to run SQL scripts

---

## 🧪 Step 8: Test the Connection

### Test Backend Health:

```powershell
# Test backend is running
curl https://gallant-friendship-production.up.railway.app/api/health

# Test database connection
curl https://gallant-friendship-production.up.railway.app/api/products
```

### Test Frontend to Backend Connection:

1. Open `https://brightbuy-production.up.railway.app`
2. Open Browser DevTools → Network tab
3. Navigate to products page
4. Check API requests are going to `gallant-friendship-production.up.railway.app`

### Verify in Railway Logs:

```
Backend Service Logs:
- ✅ Server running on port 8080
- ✅ MySQL Database connected successfully!
- ✅ Connected to database: brightbuy
```

---

## 🔐 Step 9: Security Checklist

### Backend Environment Variables:

- ✅ Use strong `JWT_SECRET` (at least 32 characters)
- ✅ Set `NODE_ENV=production`
- ✅ Use `mysql.railway.internal` for internal DB connection
- ✅ Configure `CORS_ORIGIN` with your frontend domain

### Database:

- ✅ Use strong MySQL password
- ✅ Database is only accessible internally via `mysql.railway.internal`
- ✅ Apply backorder configuration (02_allow_backorders.sql)

### Frontend:

- ✅ Only expose `NEXT_PUBLIC_*` variables (never backend secrets)
- ✅ Use HTTPS for all production URLs

---

## 📋 Complete Environment Variables Reference

### Backend Service Variables (Railway):

```bash
# Auto-generated by Railway (when MySQL is linked)
DATABASE_URL=mysql://root:password@mysql.railway.internal:3306/brightbuy

# Or manual configuration
DB_HOST=mysql.railway.internal
DB_PORT=3306
DB_USER=root
DB_PASSWORD=<your_mysql_password>
DB_NAME=brightbuy

# Application
PORT=8080
NODE_ENV=production
JWT_SECRET=<strong_secret_here>
CORS_ORIGIN=https://brightbuy-production.up.railway.app
```

### Frontend Service Variables:

```bash
NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api
```

---

## 🐛 Troubleshooting

### Backend Can't Connect to MySQL:

**Problem:** `Error connecting to MySQL Database: ENOTFOUND`

**Solution:**
1. Verify MySQL service is running in Railway
2. Check backend and MySQL are in the same Railway project
3. Link the services in Railway Dashboard
4. Use `mysql.railway.internal` (not public host)

### Frontend Can't Reach Backend:

**Problem:** `Network Error` or `CORS Error` in browser console

**Solution:**
1. Check `NEXT_PUBLIC_API_URL` is set correctly
2. Verify backend `CORS_ORIGIN` includes frontend domain
3. Test backend directly: `curl https://gallant-friendship-production.up.railway.app/api/products`
4. Check Railway backend logs for errors

### Backend Returns 502 Bad Gateway:

**Problem:** Backend not responding

**Solution:**
1. Check backend logs in Railway Dashboard
2. Verify `PORT=8080` in environment variables
3. Ensure `server.js` listens on `process.env.PORT`
4. Check database connection is successful

### Database Connection Timeout:

**Problem:** `connect ETIMEDOUT`

**Solution:**
1. Use internal Railway URL: `mysql.railway.internal`
2. Don't use public MySQL URLs from backend
3. Verify MySQL service is deployed and running
4. Check `DATABASE_URL` format is correct

---

## 🎯 Quick Deploy Checklist

- [ ] Link MySQL service to Backend in Railway
- [ ] Set `DATABASE_URL` or `DB_*` variables in Backend
- [ ] Set `PORT=8080` in Backend
- [ ] Set `JWT_SECRET` in Backend
- [ ] Set `CORS_ORIGIN` with frontend domain in Backend
- [ ] Import database schema and data to Railway MySQL
- [ ] Apply backorder configuration (02_allow_backorders.sql)
- [ ] Set `NEXT_PUBLIC_API_URL` in Frontend
- [ ] Deploy backend (auto or manual)
- [ ] Deploy frontend (Netlify or Railway)
- [ ] Test API health endpoint
- [ ] Test frontend → backend connection
- [ ] Verify in browser: products load correctly

---

## 🔄 Next Steps After Deployment

1. **Test All Features:**
   - User registration/login
   - Product browsing
   - Add to cart
   - Checkout process
   - Order tracking
   - Admin/Manager dashboards

2. **Monitor Logs:**
   - Check Railway logs for errors
   - Monitor API performance
   - Watch for database connection issues

3. **Performance:**
   - Railway automatically scales
   - Monitor database connection pool
   - Consider Redis for session management

4. **Backups:**
   - Railway provides automatic MySQL backups
   - Export production data regularly
   - Keep backup SQL files

---

## 📞 Support

### Railway Documentation:
- https://docs.railway.app

### Useful Railway Commands:

```powershell
# View logs
railway logs

# Open service in browser
railway open

# Run command in Railway environment
railway run node --version

# Check service status
railway status
```

---

## ✅ Success Indicators

When everything is connected correctly, you should see:

✅ **Backend Logs:**
```
Server running on port 8080
MySQL Database connected successfully!
Connected to database: brightbuy
```

✅ **Frontend:**
- Products load from database
- Images display correctly
- Add to cart works
- Checkout completes successfully

✅ **Railway Dashboard:**
- Backend service: ✅ Active
- MySQL service: ✅ Active
- Frontend service: ✅ Active (if hosted on Railway)

🎉 **Your BrightBuy e-commerce platform is now live on Railway!**
