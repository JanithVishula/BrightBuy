// config/db.js
// Local MySQL connection, configured via DB_* environment variables (.env).
const mysql = require("mysql2/promise");

const dbConfig = {
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "brightbuy",
};

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
});

pool
  .getConnection()
  .then((connection) => {
    console.log("MySQL Database connected successfully!");
    console.log(`Connected to: ${dbConfig.host}:${dbConfig.port}`);
    console.log(`Database name: ${dbConfig.database}`);
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
