# 🔧 CORS & 404 Error Fix Guide

## Issue Summary

Your frontend (`https://brightbuy-production.up.railway.app`) is getting:
1. **CORS Error**: "No 'Access-Control-Allow-Origin' header"
2. **404 Error**: Backend not responding at `https://gallant-friendship-production.up.railway.app/api/products`

---

## Root Cause

Your **backend is either:**
- ❌ Not deployed on Railway
- ❌ Not running/crashed
- ❌ Using wrong environment variables
- ❌ Missing CORS_ORIGIN configuration

---

## Solution Steps

### Step 1: Check Backend Deployment Status

**In Railway Dashboard:**
1. Go to your backend service (`gallant-friendship`)
2. Check the **Status** - should show 🟢 **Active**
3. If it shows 🔴 **Failed** or ⚠️ **Building**, check the logs

### Step 2: Set Environment Variables in Railway

**Backend Service → Variables tab:**

Add these **5 critical variables**:

```bash
# 1. Port (Railway requires 8080)
PORT=8080

# 2. Node Environment
NODE_ENV=production

# 3. Database URL (auto-generated when you link MySQL service)
DATABASE_URL=mysql://root:password@mysql.railway.internal:3306/brightbuy

# 4. JWT Secret
JWT_SECRET=your_strong_secret_here_minimum_32_characters

# 5. CORS Origin (IMPORTANT!)
CORS_ORIGIN=https://brightbuy-production.up.railway.app
```

**⚠️ MOST IMPORTANT: `CORS_ORIGIN` must match your frontend domain exactly!**

---

### Step 3: Update Backend server.js for Railway

The backend needs to use the `CORS_ORIGIN` environment variable:

**Current CORS config (allows all - not secure for production):**
```javascript
app.use(cors({
  origin: true, // Allow all origins
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
}));
```

**Should be (secure for production):**
```javascript
const corsOptions = {
  origin: process.env.CORS_ORIGIN 
    ? process.env.CORS_ORIGIN.split(',')
    : ['http://localhost:3000', 'https://brightbuy-production.up.railway.app'],
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
};

app.use(cors(corsOptions));
```

---

### Step 4: Redeploy Backend

**Option A: Via Git Push (Recommended)**
```powershell
cd D:\Project\BrightBuy
git add .
git commit -m "Fix: Add CORS_ORIGIN support and Railway environment"
git push origin dev
```
Railway will auto-deploy.

**Option B: Manual Deploy in Railway Dashboard**
1. Go to backend service
2. Click **Deployments** tab
3. Click **Deploy Now**

---

### Step 5: Verify Backend is Running

**Test the backend directly:**

```powershell
# Test root endpoint
curl https://gallant-friendship-production.up.railway.app/

# Expected: "BrightBuy Backend API is running!"

# Test products API
curl https://gallant-friendship-production.up.railway.app/api/products

# Expected: JSON array with products
```

**If you get 404:**
- Backend is not deployed
- Check Railway logs for errors
- Verify PORT=8080 is set

**If you get CORS error:**
- CORS_ORIGIN not set correctly
- Must be: `https://brightbuy-production.up.railway.app`

---

### Step 6: Check Railway Logs

**In Railway Dashboard:**
1. Backend service → **Logs** tab
2. Look for these success messages:
   ```
   Server running on port 8080
   MySQL Database connected successfully!
   Connected to database: brightbuy
   ```

**Common errors to look for:**
- `ECONNREFUSED` → Database not linked
- `Port already in use` → Wrong PORT value
- `Cannot find module` → Dependencies not installed
- `ENOTFOUND mysql` → Wrong database host

---

## Quick Fix Commands

### 1. Update Backend CORS (Run in your project)

I'll update the server.js file to properly use CORS_ORIGIN environment variable.

### 2. Verify Environment Variables

In Railway, your backend service should have:
- ✅ `PORT=8080`
- ✅ `NODE_ENV=production`
- ✅ `DATABASE_URL=mysql://...` (auto-generated)
- ✅ `JWT_SECRET=<your_secret>`
- ✅ `CORS_ORIGIN=https://brightbuy-production.up.railway.app`

### 3. Link MySQL Service

**In Railway Dashboard:**
1. Backend Service → **Variables**
2. Click **New Variable** → **Add Reference**
3. Select **MySQL Service**
4. This creates `DATABASE_URL` automatically

---

## Testing Checklist

After following the steps:

- [ ] Backend shows 🟢 Active in Railway
- [ ] `curl https://gallant-friendship-production.up.railway.app/` returns "BrightBuy Backend API is running!"
- [ ] `curl https://gallant-friendship-production.up.railway.app/api/products` returns JSON
- [ ] Railway logs show "Server running on port 8080"
- [ ] Railway logs show "MySQL Database connected successfully!"
- [ ] Frontend loads without CORS errors
- [ ] Products display on frontend

---

## Still Not Working?

### Issue: 404 on all endpoints
**Solution:** Backend not deployed. Check Railway logs and redeploy.

### Issue: CORS error persists
**Solution:** 
1. Verify `CORS_ORIGIN=https://brightbuy-production.up.railway.app` in Railway variables
2. Make sure no trailing slash
3. Redeploy backend after setting

### Issue: Connection timeout
**Solution:** Backend crashed. Check Railway logs for error details.

### Issue: Database connection failed
**Solution:** 
1. Link MySQL service to backend
2. Use internal URL: `mysql.railway.internal`
3. Check database credentials

---

## Next Steps

1. **I'll update your server.js** to properly use CORS_ORIGIN
2. **You set Railway environment variables** (especially CORS_ORIGIN)
3. **Push to deploy** or manually deploy in Railway
4. **Test the backend** with curl commands above
5. **Refresh frontend** to see if CORS errors are gone

---

**Let me update your backend code now...**
