// config/db.js
// Database connection — configured ENTIRELY via environment variables.
// Supports DB_* (preferred) and MYSQL* (Railway-style) variable names.
const mysql = require("mysql2/promise");

const dbConfig = {
  host: process.env.DB_HOST || process.env.MYSQLHOST || "localhost",
  port: Number(process.env.DB_PORT || process.env.MYSQLPORT || 3306),
  user: process.env.DB_USER || process.env.MYSQLUSER || "root",
  password: process.env.DB_PASSWORD || process.env.MYSQLPASSWORD || "",
  database: process.env.DB_NAME || process.env.MYSQLDATABASE || "brightbuy",
};

// Enable SSL when DB_SSL=true (required by managed hosts like Aiven).
// rejectUnauthorized:false lets us connect without bundling the CA cert;
// set DB_SSL_REJECT_UNAUTHORIZED=true and provide a CA for stricter checks.
const sslEnabled =
  String(process.env.DB_SSL).toLowerCase() === "true" ||
  String(process.env.MYSQL_SSL).toLowerCase() === "true";

if (sslEnabled) {
  dbConfig.ssl = {
    rejectUnauthorized:
      String(process.env.DB_SSL_REJECT_UNAUTHORIZED).toLowerCase() === "true",
  };
}

console.log(`Loading database configuration for: ${process.env.NODE_ENV || "development"}`);

// Create MySQL connection pool
const pool = mysql.createPool({
  host: dbConfig.host,
  port: dbConfig.port,
  user: dbConfig.user,
  password: dbConfig.password,
  database: dbConfig.database,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  ...(dbConfig.ssl && { ssl: dbConfig.ssl }),
});

pool
  .getConnection()
  .then((connection) => {
    console.log("MySQL Database connected successfully!");
    console.log(`Connected to: ${dbConfig.host}:${dbConfig.port}`);
    console.log(`Database name: ${dbConfig.database}`);
    console.log(`SSL: ${sslEnabled ? "enabled" : "disabled"}`);
    connection.release();
  })
  .catch((error) => {
    console.error("Error connecting to MySQL Database:", error.message);
    console.error("Connection details (password hidden for security):");
    console.error(`- Host: ${dbConfig.host ? "SET" : "MISSING"}`);
    console.error(`- User: ${dbConfig.user ? "SET" : "MISSING"}`);
    console.error(`- Password: ${dbConfig.password ? "SET" : "MISSING"}`);
    console.error(`- Database: ${dbConfig.database || "MISSING"}`);
  });

module.exports = pool;
