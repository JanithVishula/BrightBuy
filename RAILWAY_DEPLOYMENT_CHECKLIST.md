# ✅ Railway Deployment Checklist

Use this checklist to ensure your BrightBuy deployment is complete and production-ready.

---

## 📋 Pre-Deployment Checklist

### Railway Account Setup
- [ ] Railway account created at https://railway.app
- [ ] GitHub repository connected to Railway
- [ ] Railway CLI installed (optional): `npm i -g @railway/cli`

### Services Created
- [ ] MySQL service created in Railway project
- [ ] Backend service created and connected to GitHub
- [ ] Frontend service created (if hosting on Railway)

---

## 🗄️ Database Configuration

### MySQL Service Setup
- [ ] MySQL service is running in Railway
- [ ] Database name: `brightbuy` (or Railway default)
- [ ] Root password noted/saved securely
- [ ] MySQL variables visible in Railway dashboard

### Database Schema & Data Import
- [ ] `01_main_schema.sql` imported successfully
- [ ] `01_initial_population.sql` imported (100+ products)
- [ ] `02_additional_population.sql` imported
- [ ] `01_cart_procedures.sql` imported
- [ ] `02_allow_backorders.sql` applied (removes inventory constraint)

### Verify Database
- [ ] Connected to Railway MySQL successfully
- [ ] Run: `SELECT COUNT(*) FROM Product;` (should show 42+ products)
- [ ] Run: `SELECT COUNT(*) FROM ProductVariant;` (should show 150+ variants)
- [ ] Run: `SELECT COUNT(*) FROM Customer;` (should show 5+ customers)
- [ ] Run: `SHOW TABLES;` (should show 15+ tables)

---

## 🔧 Backend Configuration

### Environment Variables Set in Railway
- [ ] `PORT=8080` ✅
- [ ] `NODE_ENV=production` ✅
- [ ] `DATABASE_URL=mysql://...@mysql.railway.internal:3306/brightbuy` ✅ (auto-generated when linked)
- [ ] OR manually set: `DB_HOST=mysql.railway.internal` ✅
- [ ] OR manually set: `DB_PORT=3306` ✅
- [ ] OR manually set: `DB_USER=root` ✅
- [ ] OR manually set: `DB_PASSWORD=***` ✅
- [ ] OR manually set: `DB_NAME=brightbuy` ✅
- [ ] `JWT_SECRET=<strong_secret_32+_chars>` ✅ (CHANGE from default!)
- [ ] `CORS_ORIGIN=https://brightbuy-production.up.railway.app` ✅

### Backend Service Linked to MySQL
- [ ] MySQL service linked to Backend service in Railway
- [ ] `DATABASE_URL` appears in Backend variables (auto-added by Railway)

### Backend Deployment
- [ ] Backend service deployed successfully
- [ ] No build errors in Railway logs
- [ ] Server running on port 8080
- [ ] Backend logs show: "MySQL Database connected successfully!"
- [ ] Backend logs show: "Server running on port 8080"

### Backend API Testing
- [ ] Test root endpoint: `https://gallant-friendship-production.up.railway.app/`
  - Should return: "BrightBuy Backend API is running!"
- [ ] Test products API: `https://gallant-friendship-production.up.railway.app/api/products`
  - Should return JSON with products array
- [ ] Test health check (if implemented): `/api/health`

---

## 🎨 Frontend Configuration

### Environment Variables

**If on Netlify:**
- [ ] `NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api` set in Netlify
- [ ] Netlify site redeployed after adding variable

**If on Railway:**
- [ ] `NEXT_PUBLIC_API_URL=https://gallant-friendship-production.up.railway.app/api` set in Railway
- [ ] Frontend service deployed successfully

### Frontend Deployment
- [ ] Frontend builds without errors
- [ ] No TypeScript/ESLint errors
- [ ] Next.js 15 Suspense boundaries in place
- [ ] `next.config.mjs` configured for production
- [ ] `netlify.toml` exists (if on Netlify)

### Frontend Testing
- [ ] Site loads at `https://brightbuy-production.up.railway.app`
- [ ] No console errors in browser DevTools
- [ ] Open Network tab, refresh page
- [ ] API calls go to `gallant-friendship-production.up.railway.app/api/*`
- [ ] No CORS errors in console

---

## 🔌 Integration Testing

### User Features
- [ ] **Homepage loads** with hero section and features
- [ ] **Products page** displays all products from database
- [ ] **Product images** display correctly
- [ ] **Product details page** shows variant options (size, color)
- [ ] **Color selection** changes product images dynamically
- [ ] **Add to cart** works (items added to cart)
- [ ] **Cart page** shows added items
- [ ] **Quantity updates** work in cart
- [ ] **Remove from cart** works
- [ ] **User registration** creates new customer account
- [ ] **User login** authenticates and stores JWT
- [ ] **Checkout process** completes successfully
- [ ] **Order confirmation** displays after checkout

### Backorder Testing
- [ ] Products with 0 inventory show "Out of Stock"
- [ ] "Order Anyway" button visible for out-of-stock items
- [ ] Orange styling applied to out-of-stock variants
- [ ] Backorder message displayed: "+3 days for out-of-stock items"
- [ ] Backorders can be placed (inventory goes negative)
- [ ] Orders table shows backorders correctly

### Admin/Staff Features
- [ ] **Admin login** works at `/admin`
- [ ] **Manager login** works at `/manager`
- [ ] **Staff dashboard** displays correctly
- [ ] **Add new product** functionality works
- [ ] **Update inventory** works
- [ ] **View orders** displays all orders
- [ ] **Reports page** shows analytics

### Search & Filters
- [ ] **Search functionality** finds products by name
- [ ] **Category filtering** works correctly
- [ ] **Price range filtering** works
- [ ] **Sort by price** (low to high, high to low) works
- [ ] **Pagination** works if implemented

---

## 🔒 Security Checklist

### Environment Variables
- [ ] `JWT_SECRET` is strong (32+ random characters)
- [ ] No secrets in code (all in Railway variables)
- [ ] `NODE_ENV=production` set
- [ ] Database credentials NOT exposed in frontend

### Database Security
- [ ] MySQL only accessible via `mysql.railway.internal` (internal network)
- [ ] No public MySQL access enabled
- [ ] Strong database password used
- [ ] SQL injection protection via parameterized queries

### API Security
- [ ] CORS configured with specific frontend domain
- [ ] JWT tokens expire after reasonable time
- [ ] Passwords hashed with bcrypt
- [ ] Authentication required for protected routes
- [ ] Input validation on all API endpoints

### HTTPS
- [ ] All services use HTTPS (Railway provides SSL)
- [ ] No mixed content warnings in browser
- [ ] Secure cookies for authentication (if using cookies)

---

## 📊 Performance Checklist

### Backend Performance
- [ ] Database connection pooling configured (connectionLimit: 10)
- [ ] API responses under 500ms for simple queries
- [ ] No N+1 query problems
- [ ] Proper indexes on frequently queried columns

### Frontend Performance
- [ ] Images optimized (Next.js Image component used where possible)
- [ ] Code splitting (Next.js does this automatically)
- [ ] No unnecessary re-renders
- [ ] Lazy loading for heavy components

### Railway Configuration
- [ ] Health checks enabled
- [ ] Restart policy configured: `ON_FAILURE`
- [ ] Resource limits appropriate for traffic
- [ ] Monitoring enabled

---

## 📝 Logging & Monitoring

### Railway Logs
- [ ] Backend logs accessible in Railway dashboard
- [ ] No error patterns in logs
- [ ] Database connection logs show success
- [ ] API request logs visible

### Error Tracking
- [ ] Frontend console clean (no errors)
- [ ] Backend logs clean (no uncaught exceptions)
- [ ] Database queries executing successfully
- [ ] No 404s or 500s in production

### Metrics to Monitor
- [ ] API response times
- [ ] Database connection pool usage
- [ ] Memory usage (backend < 400MB, frontend < 600MB)
- [ ] CPU usage (< 80%)
- [ ] Request count and patterns

---

## 🚀 Go-Live Checklist

### Final Pre-Launch Steps
- [ ] All test users can complete full purchase flow
- [ ] Admin panel accessible and functional
- [ ] All product images displaying correctly
- [ ] Payment integration configured (if applicable)
- [ ] Email notifications working (if implemented)
- [ ] Contact form working (if implemented)

### Documentation
- [ ] README.md updated with production URLs
- [ ] API documentation reviewed (API_DOCUMENTATION.md)
- [ ] Environment variables documented
- [ ] Deployment process documented

### Backup & Recovery
- [ ] Railway automatic backups enabled for MySQL
- [ ] Database backup SQL files saved locally
- [ ] Environment variables backed up securely
- [ ] Git repository up to date

### Communication
- [ ] Team informed of production URLs
- [ ] Stakeholders notified of launch
- [ ] Support channels established
- [ ] Incident response plan in place

---

## 🎯 Post-Launch Monitoring (First 24 Hours)

### Hour 1
- [ ] Check Railway logs every 15 minutes
- [ ] Monitor error rates
- [ ] Verify all services running

### Hour 6
- [ ] Review performance metrics
- [ ] Check database connection stability
- [ ] Verify no memory leaks

### Hour 24
- [ ] Complete functional test of all features
- [ ] Review all logs for patterns
- [ ] Check database backup completed
- [ ] Verify auto-scaling if traffic spike

---

## 📈 Ongoing Maintenance

### Daily
- [ ] Check Railway dashboard for any alerts
- [ ] Review error logs
- [ ] Monitor uptime

### Weekly
- [ ] Review performance metrics
- [ ] Check database size and growth
- [ ] Review user feedback/issues
- [ ] Test backups

### Monthly
- [ ] Update dependencies (security patches)
- [ ] Review and optimize database queries
- [ ] Analyze usage patterns
- [ ] Plan capacity upgrades if needed

---

## ✅ Final Verification Commands

Run these to verify everything is working:

### Test Backend API
```powershell
# Root endpoint
curl https://gallant-friendship-production.up.railway.app/

# Products API
curl https://gallant-friendship-production.up.railway.app/api/products

# Categories API
curl https://gallant-friendship-production.up.railway.app/api/categories
```

### Test Database Connection
```powershell
# Connect to Railway MySQL
mysql -h <MYSQLHOST> -P <MYSQLPORT> -u <MYSQLUSER> -p<MYSQLPASSWORD> brightbuy

# Run test queries
SELECT COUNT(*) FROM Product;
SELECT COUNT(*) FROM ProductVariant;
SELECT COUNT(*) FROM Orders;
```

### Test Frontend
```powershell
# Open in browser
start https://brightbuy-production.up.railway.app

# Check specific pages
start https://brightbuy-production.up.railway.app/products
start https://brightbuy-production.up.railway.app/login
start https://brightbuy-production.up.railway.app/cart
```

---

## 🎉 Deployment Complete!

When all checkboxes are ✅, your BrightBuy e-commerce platform is:

- ✅ **Live** on Railway
- ✅ **Secure** with HTTPS and JWT
- ✅ **Fast** with optimized queries
- ✅ **Reliable** with health checks
- ✅ **Scalable** with Railway auto-scaling
- ✅ **Monitored** with logs and metrics

---

## 🆘 If Something Fails

### Quick Troubleshooting
1. Check Railway logs first (90% of issues visible here)
2. Verify all environment variables are set correctly
3. Ensure MySQL service is linked to backend
4. Test backend API directly (bypass frontend)
5. Check browser console for frontend errors

### Common Issues & Fixes
| Issue | Solution |
|-------|----------|
| 404 errors on frontend | Check `NEXT_PUBLIC_API_URL` is correct |
| CORS errors | Verify `CORS_ORIGIN` includes frontend domain |
| Database connection fails | Use `mysql.railway.internal` not public host |
| Port errors | Ensure `PORT=8080` in Railway |
| Build fails | Check logs, update dependencies |

### Get Help
- 📚 Review: `RAILWAY_DEPLOYMENT_GUIDE.md`
- 🏗️ Architecture: `RAILWAY_ARCHITECTURE.md`
- 🚀 Quick Start: `QUICK_RAILWAY_SETUP.md`
- 💬 Railway Discord: https://discord.gg/railway
- 📧 Support: https://help.railway.app

---

**Last Updated**: Use this checklist every deployment to ensure consistency!

**Estimated Time**: 30 minutes for complete verification

Good luck! 🚀
