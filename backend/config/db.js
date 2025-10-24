// config/db.js
const mysql = require("mysql2/promise");

// Parse DATABASE_URL if provided, otherwise use individual variables
let poolConfig;

if (process.env.DATABASE_URL) {
  // Parse DATABASE_URL (format: mysql://user:password@host:port/database)
  try {
    const url = new URL(process.env.DATABASE_URL);
    poolConfig = {
      host: url.hostname,
      port: parseInt(url.port) || 3306,
      user: url.username,
      password: url.password,
      database: url.pathname.slice(1), // Remove leading '/'
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
    };
    console.log(`✅ Using DATABASE_URL for connection to ${url.hostname}:${url.port || 3306}`);
  } catch (error) {
    console.error("Error parsing DATABASE_URL:", error.message);
    throw error;
  }
} else {
  // Fall back to individual environment variables
  // Railway uses MYSQL* prefix, also support DB_* for local development
  poolConfig = {
    host: process.env.MYSQLHOST || process.env.DB_HOST || "localhost",
    port: parseInt(process.env.MYSQLPORT || process.env.DB_PORT || 3306),
    user: process.env.MYSQLUSER || process.env.DB_USER,
    password: process.env.MYSQLPASSWORD || process.env.DB_PASSWORD,
    database: process.env.MYSQLDATABASE || process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  };
  console.log(`📋 Using individual environment variables for connection`);
}

const pool = mysql.createPool(poolConfig);

pool
  .getConnection()
  .then((connection) => {
    console.log("✅ MySQL Database connected successfully!");
    console.log(`📊 Connected to database: ${poolConfig.database}`);
    connection.release();
  })
  .catch((error) => {
    console.error("❌ Error connecting to MySQL Database:", error.message);
    console.error("Connection details (host hidden for security):");
    console.error(`- Host: ${poolConfig.host ? "SET" : "MISSING"}`);
    console.error(`- User: ${poolConfig.user ? "SET" : "MISSING"}`);
    console.error(`- Password: ${poolConfig.password ? "SET" : "MISSING"}`);
    console.error(`- Database: ${poolConfig.database || "MISSING"}`);
  });

module.exports = pool;
