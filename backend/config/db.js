// config/db.js
const mysql = require("mysql2/promise");
const path = require("path");
const fs = require("fs");

// Load configuration from links.json
const linksPath = path.join(__dirname, "links.json");
let config;

try {
  const linksData = fs.readFileSync(linksPath, "utf8");
  const links = JSON.parse(linksData);

  // Determine environment (production or development)
  const env = process.env.NODE_ENV || "development";
  config = links[env];

  console.log(`Loading database configuration for: ${env}`);
} catch (error) {
  console.error("Error loading links.json:", error.message);
  console.log("Falling back to environment variables");

  // Fallback to environment variables if links.json not found
  // Railway uses MYSQL* prefix, but also support DB_* for compatibility
  config = {
    database: {
      host: process.env.MYSQLHOST || process.env.DB_HOST || "localhost",
      port: process.env.MYSQLPORT || process.env.DB_PORT || 3306,
      user: process.env.MYSQLUSER || process.env.DB_USER || "root",
      password: process.env.MYSQLPASSWORD || process.env.DB_PASSWORD,
      database: process.env.MYSQLDATABASE || process.env.DB_NAME || "railway",
    },
  };
}

// If in production and Railway MySQL variables exist, override config
if (process.env.NODE_ENV === "production" && process.env.MYSQLHOST) {
  console.log("Using Railway MySQL environment variables");
  config.database = {
    host: process.env.MYSQLHOST,
    port: process.env.MYSQLPORT || 3306,
    user: process.env.MYSQLUSER,
    password: process.env.MYSQLPASSWORD,
    database: process.env.MYSQLDATABASE || "railway",
  };
}

// Create MySQL connection pool
const pool = mysql.createPool({
  host: config.database.host,
  port: config.database.port,
  user: config.database.user,
  password: config.database.password,
  database: config.database.database,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  // Enable SSL for production (Railway proxy)
  ...(config.database.ssl && { ssl: config.database.ssl }),
});

pool
  .getConnection()
  .then((connection) => {
    console.log("MySQL Database connected successfully!");
    console.log(
      `Connected to: ${config.database.host}:${config.database.port}`
    );
    console.log(`Database name: ${config.database.database}`);
    connection.release();
  })
  .catch((error) => {
    console.error("Error connecting to MySQL Database:", error.message);
    console.error("Connection details (host hidden for security):");
    console.error(`- Host: ${config.database.host ? "SET" : "MISSING"}`);
    console.error(`- User: ${config.database.user ? "SET" : "MISSING"}`);
    console.error(
      `- Password: ${config.database.password ? "SET" : "MISSING"}`
    );
    console.error(`- Database: ${config.database.database || "MISSING"}`);
  });

module.exports = pool;
