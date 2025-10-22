// server.js
const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const path = require("path");
const fs = require("fs");

// Load environment variables FIRST before requiring db
dotenv.config();

const db = require("./config/db"); // initializes the DB connection

const app = express();

// Load configuration from links.json
let config;
try {
  const linksPath = path.join(__dirname, "config", "links.json");
  const linksData = fs.readFileSync(linksPath, "utf8");
  const links = JSON.parse(linksData);
  
  const env = process.env.NODE_ENV || "development";
  config = links[env];
  console.log(`Loaded server configuration for: ${env}`);
} catch (error) {
  console.error("Error loading links.json for server config:", error.message);
  // Fallback to default config
  config = {
    server: {
      port: process.env.PORT || 5001,
      corsOrigin: ["http://localhost:3000", "http://localhost:3001"],
    },
    jwt: {
      secret: process.env.JWT_SECRET || "default_secret",
    },
  };
}

// Middleware
// Configure CORS to allow requests from specific origins
const corsOptions = {
  origin: config.server.corsOrigin,
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  optionsSuccessStatus: 200
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
  if (process.env.NODE_ENV !== "production") {
    console.log(`LAN access: http://192.168.8.129:${PORT}`);
  }
});
