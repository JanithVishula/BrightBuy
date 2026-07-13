# BrightBuy — Local Setup & Run Guide

A full-stack e-commerce app: **Next.js** frontend + **Express** backend + **MySQL** database. This guide runs everything **locally on one machine** — no cloud hosting required.

---

## 1. Prerequisites

Install these first:

| Tool | Version | Check with |
|------|---------|------------|
| **Node.js** | 18 or newer (tested on 22) | `node --version` |
| **npm** | comes with Node | `npm --version` |
| **MySQL Server** | 8.0 | `mysql --version` |
| **Git** | any recent | `git --version` |

> **Windows:** MySQL 8.0 usually installs to `C:\Program Files\MySQL\MySQL Server 8.0\bin`. If `mysql` isn't recognized in your terminal, either add that folder to your PATH or call the full path.

Make sure the **MySQL service is running**:
- **Windows:** open *Services* → find `MySQL80` → Status should be *Running*.
- **macOS/Linux:** `mysql.server start` or `sudo systemctl start mysql`.

---

## 2. Get the code

```bash
git clone https://github.com/JanithVishula/BrightBuy.git
cd BrightBuy
```

The project has three parts:

```
BrightBuy/
├── backend/      # Express API (port 5001)
├── frontend/     # Next.js app (port 3000)
└── queries/      # SQL schema + seed data
```

---

## 3. Set up the database

### 3a. Create and load the database

From the **project root**, run the master SQL script. It creates the `brightbuy` database and loads all tables, seed products, and accounts.

```bash
cd queries
mysql -u root -p < 00_run_all.sql
cd ..
```

Enter your MySQL root password when prompted.

> **Windows (if `mysql` isn't on PATH):**
> ```bash
> "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p < 00_run_all.sql
> ```

### 3b. Verify it loaded

```bash
mysql -u root -p -e "USE brightbuy; SHOW TABLES; SELECT COUNT(*) AS products FROM product;"
```

You should see ~16 tables and 40+ products.

---

## 4. Configure the backend

Create the backend environment file from the example:

```bash
cd backend
cp .env.example .env     # Windows PowerShell: copy .env.example .env
```

Open `backend/.env` and set your values:

```env
PORT=5001
NODE_ENV=development

# Local MySQL — use 127.0.0.1, NOT "localhost" (see the note below)
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password_here
DB_NAME=brightbuy

# REQUIRED — the server refuses to start without this.
JWT_SECRET=any_long_random_string_here

CORS_ORIGIN=http://localhost:3000,http://localhost:3001,http://127.0.0.1:3000,http://127.0.0.1:3001
```

> ⚠️ **`JWT_SECRET` is required.** If it's empty, the backend exits immediately.
> Generate a strong one: `openssl rand -base64 48`

> ⚡ **Use `127.0.0.1`, not `localhost`.** On Windows, `localhost` resolves to
> IPv6 first and adds a **~200ms delay to every request**. `127.0.0.1` avoids it.

Install backend dependencies:

```bash
npm install
```

---

## 5. Configure the frontend

```bash
cd ../frontend
cp .env.example .env.local     # Windows PowerShell: copy .env.example .env.local
```

Open `frontend/.env.local` and confirm it points at the backend:

```env
NEXT_PUBLIC_API_URL=http://127.0.0.1:5001/api
```

Install frontend dependencies:

```bash
npm install
```

---

## 6. Run the app

You need **two terminals** — one for each server.

### Terminal 1 — Backend

```bash
cd backend
npm run dev      # auto-restarts on changes (uses nodemon)
# or:  npm start   (plain node, no auto-restart)
```

Expected output:

```
Server running on port 5001
MySQL Database connected successfully!
Connected to: 127.0.0.1:3306
Database name: brightbuy
```

### Terminal 2 — Frontend

```bash
cd frontend
npm run dev
```

Expected output:

```
▲ Next.js — Local: http://localhost:3000
✓ Ready
```

### Open the app

Go to **http://localhost:3000** in your browser.

---

## 7. Log in

The database ships with seed accounts (password is the same for all): **`123456`**

| Role | Email | Password |
|------|-------|----------|
| **Staff / Admin** (Level01, full access) | `admin_jvishula@brightbuy.com` | `123456` |
| **Staff** | `admin@brightbuy.com` | `123456` |

To shop and use the cart you need a **customer** account — either:
- **Sign up** a new one at `/signup`, or
- Use a seeded customer if one exists in your DB.

> **Change these passwords** before using this anywhere real.

---

## 8. What you can do

- **Customers:** browse products, search, add to cart, checkout (Store Pickup or Standard Delivery), track orders, and raise **support tickets** (Contact page → replies appear under *Profile → Help → My Support Tickets*).
- **Staff:** dashboard, manage inventory & products, view/manage orders, generate **reports** (Excel export), and handle **customer support tickets** at `/staff/support`.

---

## 9. Common problems

| Symptom | Fix |
|---------|-----|
| `FATAL: JWT_SECRET ... required` | Set `JWT_SECRET` in `backend/.env`. |
| `Error connecting to MySQL` | MySQL service not running, or wrong `DB_PASSWORD`/`DB_HOST` in `.env`. |
| Backend starts but frontend shows no data | Backend not running, or `NEXT_PUBLIC_API_URL` wrong. Restart the frontend after editing `.env.local` (env vars are read at startup). |
| Everything feels slow (~200ms/request) | Use `127.0.0.1` instead of `localhost` in both env files. |
| `'mysql' is not recognized` (Windows) | Use the full path to `mysql.exe` or add MySQL's `bin` to PATH. |
| Blocked by CORS | Add your frontend origin to `CORS_ORIGIN` in `backend/.env`. |
| Port already in use | Change `PORT` in `backend/.env`, or stop the process using it. |

---

## 10. Production build (optional, faster)

Dev mode recompiles pages on first visit (slow the first time). For a snappier local run:

```bash
# Frontend
cd frontend
npm run build
npm start          # serves the optimized build on :3000

# Backend
cd backend
npm start
```

---

## Quick reference

| | Backend | Frontend |
|---|---|---|
| Folder | `backend/` | `frontend/` |
| Dev command | `npm run dev` | `npm run dev` |
| URL | http://127.0.0.1:5001 | http://localhost:3000 |
| Env file | `.env` | `.env.local` |
| Health check | http://127.0.0.1:5001/api/health | — |

**Database:** MySQL, database name `brightbuy`, loaded from `queries/00_run_all.sql`.
