// server.js
const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const path = require("path");

// Load environment variables FIRST before requiring db
dotenv.config();

// Fail fast if the JWT secret is missing — never run with a default secret.
if (!process.env.JWT_SECRET) {
  console.error(
    "FATAL: JWT_SECRET environment variable is required and was not set."
  );
  process.exit(1);
}

const db = require("./config/db"); // initializes the DB connection

const app = express();

const env = process.env.NODE_ENV || "development";

// Server configuration — entirely from environment variables.
const config = {
  server: {
    port: Number(process.env.PORT) || 5001,
  },
  database: {
    host: process.env.DB_HOST || process.env.MYSQLHOST || "localhost",
  },
};
console.log(`Loaded server configuration for: ${env}`);

// Middleware
// CORS allowed origins come ONLY from the CORS_ORIGIN env var
// (comma-separated). In development we default to common localhost ports.
let allowedOrigins;
if (process.env.CORS_ORIGIN) {
  allowedOrigins = process.env.CORS_ORIGIN.split(",").map((origin) =>
    origin.trim()
  );
} else {
  allowedOrigins = ["http://localhost:3000", "http://localhost:3001"];
}
console.log("CORS allowed origins:", allowedOrigins);

const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps, Postman, or same-origin)
    if (!origin) return callback(null, true);

    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      console.log("Blocked by CORS:", origin);
      callback(new Error("Not allowed by CORS"));
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  optionsSuccessStatus: 200,
};

app.use(cors(corsOptions));
app.use(express.json()); // To accept JSON data in the body

// Make config available to other modules
app.locals.config = config;

// Serve static assets (product images)
app.use("/assets", express.static(path.join(__dirname, "../assets")));
app.use("/images", express.static(path.join(__dirname, "public/images")));

// --- API Routes ---
app.use("/api/products", require("./routes/products"));
app.use("/api/categories", require("./routes/categories"));
app.use("/api/variants", require("./routes/variants"));
app.use("/api/cart", require("./routes/cart"));
app.use("/api/auth", require("./routes/auth"));
app.use("/api/staff", require("./routes/staff"));
app.use("/api/customers", require("./routes/customer"));
app.use("/api/orders", require("./routes/orders"));
app.use("/api/reports", require("./routes/reports"));

// Basic Test Route
app.get("/", (req, res) => {
  res.send("BrightBuy Backend API is running!");
});

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    environment: process.env.NODE_ENV || "development",
    database: config.database.host,
    timestamp: new Date().toISOString(),
  });
});

const PORT = config.server.port;

// Listen on all network interfaces (0.0.0.0) to allow LAN access
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
  console.log(`Local access: http://localhost:${PORT}`);
});
