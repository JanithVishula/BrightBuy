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
  config = {
    database: {
      host: process.env.DB_HOST || "localhost",
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || "root",
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME || "brightbuy",
    },
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
      `Connected to database: ${process.env.DB_NAME || "from DATABASE_URL"}`
    );
    connection.release();
  })
  .catch((error) => {
    console.error("Error connecting to MySQL Database:", error.message);
    console.error(
      "Please check your DATABASE_URL or individual DB_* environment variables"
    );
  });

module.exports = pool;
