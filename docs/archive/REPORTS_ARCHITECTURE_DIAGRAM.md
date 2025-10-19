# 📊 Staff Reports System - Architecture Diagram

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          FRONTEND (Next.js)                          │
│                    http://localhost:3000/staff/reports               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Staff Reports Page (page.jsx)                              │   │
│  │                                                               │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │   │
│  │  │ Sales    │ │   Top    │ │Quarterly │ │ Customer │       │   │
│  │  │ Summary  │ │ Products │ │  Sales   │ │ Summary  │       │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │   │
│  │                                                               │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │   │
│  │  │Inventory │ │ Category │ │Inventory │ │ Delivery │       │   │
│  │  │  Status  │ │  Orders  │ │ Updates  │ │Estimates │       │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │   │
│  │                                                               │   │
│  │  Features:                                                    │   │
│  │  • Tab-based navigation                                      │   │
│  │  • Dynamic filters (dates, years, status, cities)           │   │
│  │  • Real-time data fetching                                   │   │
│  │  • Responsive tables and cards                              │   │
│  │  • Color-coded status indicators                            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│                              ↓ HTTP Requests                         │
│                         (Authorization: Bearer JWT)                  │
└───────────────────────────────┼───────────────────────────────────────┘
                                │
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        BACKEND (Express.js)                          │
│                    http://localhost:5001/api/reports                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Routes (routes/reports.js)                                 │   │
│  │                                                               │   │
│  │  GET /sales-summary              → Controller Method         │   │
│  │  GET /top-selling-products       → Controller Method         │   │
│  │  GET /quarterly-sales            → Controller Method         │   │
│  │  GET /customer-order-summary     → Controller Method         │   │
│  │  GET /inventory                  → Controller Method         │   │
│  │  GET /category-orders            → Controller Method         │   │
│  │  GET /inventory-updates          → Controller Method         │   │
│  │  GET /order-delivery-estimate    → Controller Method         │   │
│  │  GET /available-years            → Controller Method         │   │
│  │  GET /available-cities           → Controller Method         │   │
│  │                                                               │   │
│  │  Middleware Chain:                                            │   │
│  │  authenticate → authorizeStaff → controller                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              ↓                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Controller (controllers/reportsController.js)              │   │
│  │                                                               │   │
│  │  • getTopSellingProducts()      • getSalesSummary()         │   │
│  │  • getQuarterlySales()          • getInventoryReport()      │   │
│  │  • getCategoryOrders()          • getInventoryUpdates()     │   │
│  │  • getCustomerOrderSummary()    • getOrderDeliveryEstimate()│   │
│  │  • getAllQuarterlySales()       • getAvailableYears()       │   │
│  │  • getAvailableCities()                                      │   │
│  │                                                               │   │
│  │  Business Logic:                                              │   │
│  │  • Parameter validation                                      │   │
│  │  • SQL query execution                                       │   │
│  │  • Data formatting                                           │   │
│  │  • Error handling                                            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              ↓                                        │
│                         SQL Queries                                  │
└───────────────────────────────┼───────────────────────────────────────┘
                                │
                                ↓
┌─────────────────────────────────────────────────────────────────────┐
│                        DATABASE (MySQL)                              │
│                         brightbuy database                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Stored Procedures                                           │   │
│  │                                                               │   │
│  │  CALL GetTopSellingProducts(start_date, end_date, top_n)    │   │
│  │  CALL GetQuarterlySalesByYear(year)                         │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Views (Pre-computed queries)                                │   │
│  │                                                               │   │
│  │  • Staff_CategoryOrders                                      │   │
│  │  • Staff_CustomerOrderSummary                                │   │
│  │  • Staff_OrderDeliveryEstimate                               │   │
│  │  • Staff_QuarterlySales                                      │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Tables (Direct queries)                                     │   │
│  │                                                               │   │
│  │  Orders          Order_item      Product       ProductVariant│   │
│  │  Customer        Category        ProductCategory             │   │
│  │  Inventory       Inventory_updates    Staff                  │   │
│  │  Address         Payment         ZipDeliveryZone            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Authentication & Authorization Flow

```
┌──────────────┐
│   User       │
│  (Staff)     │
└──────┬───────┘
       │
       │ 1. Login Request
       │ POST /api/auth/login
       │ { email, password }
       ↓
┌──────────────────────┐
│   Auth Controller    │
│                      │
│  • Verify password   │
│  • Generate JWT      │
│  • Return token      │
└──────┬───────────────┘
       │
       │ 2. JWT Token
       │ { userId, email, role: "staff", staffId, staffRole }
       ↓
┌──────────────┐
│   Frontend   │
│              │
│ localStorage │
│   .setItem   │
│  ("token")   │
└──────┬───────┘
       │
       │ 3. Report Request
       │ GET /api/reports/sales-summary
       │ Authorization: Bearer {JWT}
       ↓
┌──────────────────────────────┐
│   Middleware Chain           │
│                              │
│  authenticate()              │
│    ├─ Verify JWT             │
│    ├─ Decode token           │
│    └─ Attach user to req     │
│                              │
│  authorizeStaff()            │
│    ├─ Check role === "staff" │
│    ├─ Allow Level01          │
│    └─ Allow Level02          │
└──────┬───────────────────────┘
       │
       │ 4. Authorized Request
       ↓
┌──────────────────────┐
│   Report Controller  │
│                      │
│  • Execute query     │
│  • Format data       │
│  • Return response   │
└──────┬───────────────┘
       │
       │ 5. JSON Response
       │ { success: true, data: [...] }
       ↓
┌──────────────┐
│   Frontend   │
│              │
│  • Update UI │
│  • Show data │
└──────────────┘
```

---

## Data Flow for Each Report Type

### 1. Sales Summary Report

```
User → Select "Sales Summary" → Pick Date Range
                ↓
Frontend sends: GET /api/reports/sales-summary?startDate=...&endDate=...
                ↓
Backend executes 3 queries:
    1. Total sales stats (Orders + Order_item)
    2. Top category (Category + ProductCategory)
    3. Inventory summary (Inventory)
                ↓
Backend returns: { sales: {...}, topCategory: {...}, inventory: {...} }
                ↓
Frontend displays: 4 metric cards + category card + inventory grid
```

### 2. Top Selling Products Report

```
User → Select "Top Products" → Pick Date Range
                ↓
Frontend sends: GET /api/reports/top-selling-products?startDate=...&endDate=...
                ↓
Backend calls: CALL GetTopSellingProducts(start, end, 10)
                ↓
Stored procedure:
    - Joins Order_item + ProductVariant + Product + Orders
    - Groups by product
    - Sums quantities and sales
    - Orders by quantity DESC
    - Limits to top N
                ↓
Backend returns: [{ product_id, product_name, total_quantity_sold, total_sales }]
                ↓
Frontend displays: Ranked table with medals for top 3
```

### 3. Quarterly Sales Report

```
User → Select "Quarterly Sales" → Pick Year
                ↓
Frontend sends: GET /api/reports/quarterly-sales?year=2025
                ↓
Backend calls: CALL GetQuarterlySalesByYear(2025)
                ↓
Stored procedure:
    - Joins Orders + Order_item
    - Filters by year
    - Groups by QUARTER(created_at)
    - Sums sales and counts orders
                ↓
Backend returns: [{ quarter: 1, total_sales, total_orders }, ...]
                ↓
Frontend displays: 4 gradient cards (Q1, Q2, Q3, Q4)
```

### 4. Inventory Status Report

```
User → Select "Inventory Status" → Pick Filter (low_stock)
                ↓
Frontend sends: GET /api/reports/inventory?status=low_stock&limit=100
                ↓
Backend queries:
    - Joins Product + ProductVariant + Inventory
    - Filters by: WHERE quantity > 0 AND quantity < 10
    - Orders by quantity ASC
    - Limits results
                ↓
Backend returns: [{ product_name, sku, color, size, stock, status }]
                ↓
Frontend displays: Table with color-coded status badges
```

### 5. Inventory Updates Report

```
User → Select "Inventory Updates"
                ↓
Frontend sends: GET /api/reports/inventory-updates?days=30&limit=50
                ↓
Backend queries:
    - Joins Inventory_updates + Staff + ProductVariant + Product
    - Filters by: WHERE updated_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    - Orders by updated_time DESC
                ↓
Backend returns: [{ update_id, staff_name, product_name, old_quantity, added_quantity, note }]
                ↓
Frontend displays: Audit trail table with staff actions
```

---

## Security Layers

```
┌─────────────────────────────────────┐
│  1. HTTPS (Production)              │
│     └─ Encrypted communication      │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  2. CORS Policy                     │
│     └─ Only localhost:3000 allowed  │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  3. JWT Authentication              │
│     └─ Valid token required         │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  4. Role Authorization              │
│     └─ Must be "staff" role         │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  5. Staff Level Check               │
│     └─ Level01 or Level02           │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  6. SQL Injection Prevention        │
│     └─ Parameterized queries        │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  7. Input Validation                │
│     └─ Parameter checking           │
└─────────────────────────────────────┘
```

---

## Performance Optimization

```
┌─────────────────────────────────────┐
│  Database Level                     │
│  • Indexes on key columns           │
│  • Pre-computed views               │
│  • Stored procedures                │
│  • Query optimization               │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Backend Level                      │
│  • Result limits                    │
│  • Efficient joins                  │
│  • Connection pooling               │
│  • Error handling                   │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│  Frontend Level                     │
│  • Lazy loading                     │
│  • Conditional rendering            │
│  • State management                 │
│  • Loading indicators               │
└─────────────────────────────────────┘
```

---

## Component Interaction Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                        Staff Reports Page                       │
│                         (React Component)                       │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  State Management:                                              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ useState:                                                 │ │
│  │  • activeReport                                          │ │
│  │  • dateRange, selectedYear, inventoryFilter, selectedCity│ │
│  │  • salesSummary, topProducts, quarterlySales, etc.       │ │
│  │  • loading, user                                         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Effects:                                                       │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ useEffect #1: Check authentication                       │ │
│  │ useEffect #2: Fetch helper data (years, cities)          │ │
│  │ useEffect #3: Fetch active report data                   │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
│  UI Sections:                                                   │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ 1. Header (title + back button)                          │ │
│  │ 2. Report Navigation (8 buttons)                         │ │
│  │ 3. Report Content (conditional render based on active)   │ │
│  │    ├─ Filters (date pickers, dropdowns)                  │ │
│  │    ├─ Loading spinner                                    │ │
│  │    └─ Data display (tables, cards)                       │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

---

## Error Handling Flow

```
┌─────────────────────────────────────┐
│   API Request                       │
└────────────┬────────────────────────┘
             │
             ↓
┌─────────────────────────────────────┐
│   Try-Catch Block                   │
│   (Controller)                      │
└────────────┬────────────────────────┘
             │
        ╭────┴────╮
        │ Success │ Error
        ↓         ↓
┌───────────┐ ┌──────────────────────┐
│  Return   │ │  Catch Error         │
│  200 OK   │ │  • Log error         │
│  + Data   │ │  • Return 500/400    │
└───────────┘ │  + Error message     │
              └──────────┬───────────┘
                         │
                         ↓
              ┌──────────────────────┐
              │  Frontend Receives   │
              │  • Check response.ok │
              │  • Show error state  │
              │  • Log to console    │
              └──────────────────────┘
```

---

**Documentation Version:** 1.0  
**Last Updated:** October 19, 2025
