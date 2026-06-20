// config/cloudinary.js
// Configures the Cloudinary SDK from environment variables.
// If credentials are absent, isConfigured is false and the app falls back
// to local-disk storage (fine for local dev; ephemeral on cloud hosts).
const { v2: cloudinary } = require("cloudinary");

const isConfigured = Boolean(
  process.env.CLOUDINARY_CLOUD_NAME &&
    process.env.CLOUDINARY_API_KEY &&
    process.env.CLOUDINARY_API_SECRET
);

if (isConfigured) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true,
  });
  console.log("Cloudinary configured — product images use the CDN.");
} else {
  console.log(
    "Cloudinary NOT configured — product image uploads fall back to local disk (ephemeral on cloud hosts)."
  );
}

/**
 * Upload an image buffer to Cloudinary.
 * @param {Buffer} buffer - raw file bytes
 * @returns {Promise<string>} the secure CDN URL
 */
const uploadBuffer = (buffer) =>
  new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder: "brightbuy/products", resource_type: "image" },
      (error, result) => {
        if (error) return reject(error);
        resolve(result.secure_url);
      }
    );
    stream.end(buffer);
  });

module.exports = { cloudinary, isConfigured, uploadBuffer };
