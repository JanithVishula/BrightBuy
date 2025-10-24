# 🗺️ BrightBuy Railway Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRODUCTION ENVIRONMENT                       │
│                            (Railway Platform)                        │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐
│   USER'S BROWSER         │
│                          │
│  brightbuy-production    │
│  .up.railway.app         │
│  (Port 8080)             │
└────────────┬─────────────┘
             │
             │ HTTPS Requests
             │
             ▼
┌───────────────────────────────────────────────────────────────┐
│                     FRONTEND SERVICE                           │
│                   (Next.js Application)                        │
│                                                                │
│  Domain: brightbuy-production.up.railway.app                  │
│  Port: 8080                                                    │
│                                                                │
│  Environment Variables:                                        │
│  ├─ NEXT_PUBLIC_API_URL=https://gallant-friendship-           │
│  │                      production.up.railway.app/api         │
│  └─ NODE_ENV=production                                        │
│                                                                │
└────────────────────────┬──────────────────────────────────────┘
                         │
                         │ API Calls (HTTPS)
                         │ https://gallant-friendship-production
                         │         .up.railway.app/api/*
                         │
                         ▼
┌───────────────────────────────────────────────────────────────┐
│                     BACKEND SERVICE                            │
│                (Node.js + Express API)                         │
│                                                                │
│  Service Name: gallant-friendship                              │
│  Domain: gallant-friendship-production.up.railway.app         │
│  Port: 8080                                                    │
│                                                                │
│  Environment Variables:                                        │
│  ├─ PORT=8080                                                  │
│  ├─ NODE_ENV=production                                        │
│  ├─ DATABASE_URL=mysql://root:***@mysql.railway.internal:     │
│  │                3306/brightbuy                               │
│  ├─ JWT_SECRET=***                                             │
│  └─ CORS_ORIGIN=https://brightbuy-production.up.railway.app   │
│                                                                │
│  API Endpoints:                                                │
│  ├─ GET  /api/products                                         │
│  ├─ POST /api/auth/login                                       │
│  ├─ GET  /api/cart                                             │
│  ├─ POST /api/orders                                           │
│  └─ ... (see API_DOCUMENTATION.md)                            │
│                                                                │
└────────────────────────┬──────────────────────────────────────┘
                         │
                         │ Internal Railway Network
                         │ mysql.railway.internal:3306
                         │ (No public internet required)
                         │
                         ▼
┌───────────────────────────────────────────────────────────────┐
│                     MYSQL DATABASE                             │
│                   (Railway MySQL Service)                      │
│                                                                │
│  Service Name: mysql (or gallant-friendship)                  │
│  Internal Host: mysql.railway.internal                        │
│  Port: 3306                                                    │
│                                                                │
│  Connection Details:                                           │
│  ├─ Host: mysql.railway.internal (internal only)              │
│  ├─ Port: 3306                                                 │
│  ├─ Database: brightbuy                                        │
│  ├─ User: root                                                 │
│  └─ Password: *** (set in Railway variables)                  │
│                                                                │
│  Tables:                                                       │
│  ├─ Product                                                    │
│  ├─ ProductVariant                                             │
│  ├─ Inventory                                                  │
│  ├─ Customer                                                   │
│  ├─ Cart_item                                                  │
│  ├─ Orders                                                     │
│  └─ ... (15+ tables total)                                    │
│                                                                │
└───────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════
                         DATA FLOW DIAGRAM
═══════════════════════════════════════════════════════════════════

1. USER ACTION (Browser)
   ↓
   Opens: https://brightbuy-production.up.railway.app

2. FRONTEND (Next.js)
   ↓
   - Renders React components
   - User clicks "View Products"
   - Frontend makes API call

3. API REQUEST
   ↓
   fetch('https://gallant-friendship-production.up.railway.app/api/products')

4. BACKEND (Express)
   ↓
   - Receives request
   - Validates JWT token (if needed)
   - Queries database

5. DATABASE QUERY (MySQL)
   ↓
   SELECT p.*, v.* FROM Product p 
   JOIN ProductVariant v ON p.product_id = v.product_id

6. DATABASE RESPONSE
   ↓
   Returns 100+ product variants with details

7. API RESPONSE (Backend → Frontend)
   ↓
   {
     "status": "success",
     "data": [...products...]
   }

8. FRONTEND RENDERING
   ↓
   Displays products in beautiful UI

9. USER SEES PRODUCTS
   ✅ Mission accomplished!


═══════════════════════════════════════════════════════════════════
                      NETWORK COMMUNICATION
═══════════════════════════════════════════════════════════════════

External (Public Internet):
┌──────────┐  HTTPS   ┌──────────┐
│  User    │ ────────▶│ Frontend │
└──────────┘          └──────────┘
                           │
                           │ HTTPS (API calls)
                           ▼
                      ┌──────────┐
                      │ Backend  │
                      └──────────┘

Internal (Railway Private Network):
                      ┌──────────┐
                      │ Backend  │
                      └────┬─────┘
                           │
                           │ mysql.railway.internal:3306
                           │ (Private, Fast, Free bandwidth)
                           │
                           ▼
                      ┌──────────┐
                      │  MySQL   │
                      └──────────┘


═══════════════════════════════════════════════════════════════════
                      DEPLOYMENT WORKFLOW
═══════════════════════════════════════════════════════════════════

┌─────────────────┐
│ LOCAL DEV       │
│                 │
│ 1. Write code   │
│ 2. Test locally │
│ 3. Commit       │
└────────┬────────┘
         │
         │ git push origin main
         │
         ▼
┌─────────────────┐
│ GITHUB          │
│                 │
│ Repository      │
│ (Source Code)   │
└────────┬────────┘
         │
         │ Webhook trigger
         │
         ▼
┌─────────────────┐
│ RAILWAY         │
│                 │
│ 1. Pull code    │
│ 2. Install deps │
│ 3. Build        │
│ 4. Deploy       │
│ 5. Health check │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ PRODUCTION      │
│                 │
│ ✅ Live!        │
└─────────────────┘


═══════════════════════════════════════════════════════════════════
                     ENVIRONMENT VARIABLES MAP
═══════════════════════════════════════════════════════════════════

FRONTEND SERVICE:
┌──────────────────────────────────────────────────┐
│ NEXT_PUBLIC_API_URL                              │
│   ↓                                              │
│   Points to backend API                          │
│   "https://gallant-friendship-production         │
│    .up.railway.app/api"                          │
└──────────────────────────────────────────────────┘

BACKEND SERVICE:
┌──────────────────────────────────────────────────┐
│ DATABASE_URL (auto-generated by Railway)         │
│   ↓                                              │
│   "mysql://root:pass@mysql.railway.internal:     │
│    3306/brightbuy"                               │
│                                                  │
│ OR manually set:                                 │
│   DB_HOST=mysql.railway.internal                │
│   DB_PORT=3306                                   │
│   DB_USER=root                                   │
│   DB_PASSWORD=***                                │
│   DB_NAME=brightbuy                              │
└──────────────────────────────────────────────────┘

MYSQL SERVICE:
┌──────────────────────────────────────────────────┐
│ MYSQLHOST=mysql.railway.internal                │
│ MYSQLPORT=3306                                   │
│ MYSQLUSER=root                                   │
│ MYSQLPASSWORD=*** (Railway generates)            │
│ MYSQLDATABASE=railway (or brightbuy)             │
└──────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════
                          SECURITY LAYERS
═══════════════════════════════════════════════════════════════════

Layer 1: HTTPS Encryption
  ├─ All public traffic encrypted
  └─ Railway provides SSL certificates

Layer 2: Private Network
  ├─ Backend ←→ MySQL uses internal network
  ├─ No public internet exposure for database
  └─ Faster and more secure

Layer 3: Authentication
  ├─ JWT tokens for user sessions
  ├─ Password hashing (bcrypt)
  └─ Token expiration

Layer 4: CORS Protection
  ├─ Only allowed frontend domains can call API
  └─ Prevents unauthorized cross-origin requests

Layer 5: Environment Variables
  ├─ Secrets never in code
  ├─ Railway encrypts all variables
  └─ Different values for dev/prod


═══════════════════════════════════════════════════════════════════
                         URL REFERENCE GUIDE
═══════════════════════════════════════════════════════════════════

PUBLIC URLS (Accessible from anywhere):
┌────────────────────────────────────────────────────────────────┐
│ Frontend:  https://brightbuy-production.up.railway.app         │
│ Backend:   https://gallant-friendship-production.up.railway.app│
└────────────────────────────────────────────────────────────────┘

INTERNAL URLS (Only within Railway):
┌────────────────────────────────────────────────────────────────┐
│ MySQL:     mysql.railway.internal:3306                         │
│ Backend:   gallant-friendship.railway.internal:8080            │
└────────────────────────────────────────────────────────────────┘

API ENDPOINTS (Full paths):
┌────────────────────────────────────────────────────────────────┐
│ Products:  https://gallant-friendship-production.up.railway.app│
│            /api/products                                        │
│                                                                 │
│ Auth:      https://gallant-friendship-production.up.railway.app│
│            /api/auth/login                                      │
│                                                                 │
│ Cart:      https://gallant-friendship-production.up.railway.app│
│            /api/cart                                            │
└────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════
                       RAILWAY SERVICE OVERVIEW
═══════════════════════════════════════════════════════════════════

Project: BrightBuy E-Commerce

Services:
  ┌─────────────────────────────────────┐
  │ 🖥️  Frontend (Next.js)              │
  │ Name: brightbuy-production          │
  │ Memory: ~512MB                      │
  │ Framework: Next.js 15.5.3           │
  └─────────────────────────────────────┘

  ┌─────────────────────────────────────┐
  │ ⚙️  Backend (Node.js/Express)       │
  │ Name: gallant-friendship            │
  │ Memory: ~256MB                      │
  │ Framework: Express                  │
  └─────────────────────────────────────┘

  ┌─────────────────────────────────────┐
  │ 🗄️  Database (MySQL)                │
  │ Name: mysql                         │
  │ Memory: ~512MB                      │
  │ Version: MySQL 8.0                  │
  └─────────────────────────────────────┘

Total Railway Services: 3
Total Monthly Cost: ~$20-30 (depends on usage)


═══════════════════════════════════════════════════════════════════
                           SUCCESS METRICS
═══════════════════════════════════════════════════════════════════

✅ Deployment Success Indicators:

  Frontend:
    ✓ Site loads at brightbuy-production.up.railway.app
    ✓ No console errors in browser
    ✓ Products display correctly
    ✓ Images load properly

  Backend:
    ✓ API responds at /api/products
    ✓ Logs show "MySQL Database connected successfully!"
    ✓ No 500 errors
    ✓ CORS allows frontend domain

  Database:
    ✓ Connection established from backend
    ✓ Tables populated with data
    ✓ Queries execute successfully
    ✓ Inventory updates correctly

  Integration:
    ✓ Add to cart works
    ✓ Checkout completes
    ✓ Orders save to database
    ✓ User authentication works


═══════════════════════════════════════════════════════════════════
                          MONITORING TIPS
═══════════════════════════════════════════════════════════════════

Watch These Metrics in Railway Dashboard:

  CPU Usage:
    Normal: 5-20%
    Alert if: >80% sustained

  Memory Usage:
    Normal: 200-400MB (backend), 400-600MB (frontend)
    Alert if: >90% of allocated

  Network:
    Monitor: Request count, response times
    Alert if: Response time >3 seconds

  Database:
    Monitor: Connection pool usage, query times
    Alert if: Connections maxed out

  Logs:
    Watch for: Error patterns, failed requests
    Set up: Log aggregation and alerts


═══════════════════════════════════════════════════════════════════

🎉 Your BrightBuy platform is production-ready on Railway!

This architecture provides:
  ✅ Scalability (Railway auto-scales)
  ✅ Security (Private network, HTTPS, JWT)
  ✅ Performance (CDN, internal networking)
  ✅ Reliability (Health checks, auto-restarts)
  ✅ Observability (Logs, metrics, monitoring)

═══════════════════════════════════════════════════════════════════
