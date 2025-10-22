# 🚀 Railway Backend Environment Variables Setup

## Copy these to Railway Dashboard → Backend Service → Variables

```bash
# ============================================
# REQUIRED ENVIRONMENT VARIABLES
# ============================================

# 1. Server Port (Railway requires 8080)
PORT=8080

# 2. Node Environment
NODE_ENV=production

# 3. JWT Secret (CHANGE THIS!)
# Generate strong secret: openssl rand -base64 32
JWT_SECRET=brightbuy_production_jwt_secret_change_this_to_something_strong_minimum_32_chars

# 4. CORS Origins (Your frontend domain)
# CRITICAL: Must match your frontend URL exactly!
CORS_ORIGIN=https://brightbuy-production.up.railway.app

# 5. Database Connection (Auto-generated when you link MySQL service)
# Railway will auto-create this when you link the MySQL service
# Format: mysql://username:password@mysql.railway.internal:3306/database
DATABASE_URL=mysql://root:password@mysql.railway.internal:3306/brightbuy

# ============================================
# OPTIONAL (but recommended)
# ============================================

# Database individual variables (if not using DATABASE_URL)
# DB_HOST=mysql.railway.internal
# DB_PORT=3306
# DB_USER=root
# DB_PASSWORD=<your_mysql_password>
# DB_NAME=brightbuy

```

---

## How to Add These Variables in Railway

### Method 1: Railway Dashboard (Recommended)

1. **Go to Railway Dashboard**: https://railway.app/dashboard
2. **Select your project**: BrightBuy
3. **Click backend service**: `gallant-friendship`
4. **Click "Variables" tab**
5. **For each variable above:**
   - Click **"New Variable"**
   - Enter variable name (e.g., `PORT`)
   - Enter value (e.g., `8080`)
   - Click **"Add"**

### Method 2: Copy-Paste All at Once

1. Go to Variables tab
2. Click **"RAW Editor"** (top right)
3. Paste all variables:
   ```
   PORT=8080
   NODE_ENV=production
   JWT_SECRET=your_strong_secret_here
   CORS_ORIGIN=https://brightbuy-production.up.railway.app
   ```
4. Click **"Update Variables"**

---

## Critical Notes

### ⚠️ CORS_ORIGIN Must Be Exact

**Wrong:**
```bash
CORS_ORIGIN=https://brightbuy-production.up.railway.app/  # ❌ No trailing slash!
CORS_ORIGIN=http://brightbuy-production.up.railway.app   # ❌ Wrong protocol!
CORS_ORIGIN=brightbuy-production.up.railway.app          # ❌ Missing https://
```

**Correct:**
```bash
CORS_ORIGIN=https://brightbuy-production.up.railway.app  # ✅ Perfect!
```

### 🔗 Link MySQL Service First

**Before setting DATABASE_URL manually:**
1. Backend Service → Variables
2. Click "New Variable" → "Add Reference"
3. Select your MySQL service
4. This automatically creates `DATABASE_URL`

**Railway auto-generates:**
```bash
DATABASE_URL=mysql://root:GENERATED_PASSWORD@mysql.railway.internal:3306/railway
```

### 🔐 JWT_SECRET Security

**Bad (Don't use these):**
```bash
JWT_SECRET=secret                    # ❌ Too simple
JWT_SECRET=brightbuy_jwt_secret      # ❌ Too common
JWT_SECRET=12345                     # ❌ Terrible!
```

**Good (Use these):**
```bash
# Generate with: openssl rand -base64 32
JWT_SECRET=K9x2L4m7P1q8R5t3W6y9Z2a5C8e1F4h7  # ✅ Random, 32+ chars
JWT_SECRET=$(openssl rand -base64 32)        # ✅ System-generated
```

---

## Multiple Frontend Domains (Optional)

If you have multiple frontends (e.g., Netlify + Railway):

```bash
CORS_ORIGIN=https://brightbuy-production.up.railway.app,https://brightbuy.netlify.app
```

Separate with commas, no spaces.

---

## After Setting Variables

### 1. Redeploy Backend

Railway should auto-redeploy after adding variables.

**If not, manually trigger:**
- Backend Service → Deployments → "Deploy Now"

### 2. Check Logs

**Look for:**
```
✅ Server running on port 8080
✅ MySQL Database connected successfully!
✅ Connected to database: brightbuy
```

**Watch for errors:**
```
❌ ECONNREFUSED - Database not linked
❌ Port 5001 already in use - Wrong PORT value
❌ ENOTFOUND mysql - Wrong database host
```

### 3. Test Backend

```powershell
# Root endpoint
curl https://gallant-friendship-production.up.railway.app/

# Products API
curl https://gallant-friendship-production.up.railway.app/api/products
```

### 4. Test from Frontend

1. Open: https://brightbuy-production.up.railway.app
2. Open DevTools (F12) → Console
3. Should see **NO CORS errors**
4. Products should load

---

## Verification Checklist

- [ ] All 5 variables added to Railway
- [ ] MySQL service linked (DATABASE_URL appears)
- [ ] CORS_ORIGIN exactly matches frontend domain
- [ ] JWT_SECRET is strong (32+ characters)
- [ ] PORT is 8080 (not 5001)
- [ ] Backend redeployed automatically
- [ ] Logs show "Server running on port 8080"
- [ ] Logs show "MySQL Database connected"
- [ ] curl test returns data
- [ ] Frontend loads without CORS errors

---

## Troubleshooting

### Backend won't start
**Check:** PORT must be 8080 for Railway

### CORS error persists
**Check:** 
1. CORS_ORIGIN set correctly?
2. Backend redeployed after setting?
3. No typos in frontend domain?

### Database connection fails
**Check:**
1. MySQL service linked?
2. DATABASE_URL format correct?
3. Using `mysql.railway.internal` not public host?

### 404 on all endpoints
**Check:**
1. Backend deployed successfully?
2. Check Railway logs for errors
3. Routes defined in server.js?

---

## Summary

**What to set in Railway Backend Variables:**

| Variable | Value | Required |
|----------|-------|----------|
| PORT | `8080` | ✅ Yes |
| NODE_ENV | `production` | ✅ Yes |
| JWT_SECRET | Strong secret (32+ chars) | ✅ Yes |
| CORS_ORIGIN | `https://brightbuy-production.up.railway.app` | ✅ Yes |
| DATABASE_URL | Auto-generated when MySQL linked | ✅ Yes |

**After setting:**
1. ✅ Backend redeploys
2. ✅ Check logs for success
3. ✅ Test with curl
4. ✅ Frontend works without CORS errors

---

**Ready? Go set these variables in Railway Dashboard now!** 🚀
