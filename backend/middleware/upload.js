// middleware/upload.js
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { isConfigured } = require("../config/cloudinary");

// When Cloudinary is configured we keep the file in memory and stream it to the
// CDN in the controller. Otherwise we fall back to local disk (dev only).
let storage;
if (isConfigured) {
  storage = multer.memoryStorage();
} else {
  const uploadDir = path.join(__dirname, "..", "public", "images", "products");
  // Ensure the directory exists so disk writes don't fail.
  fs.mkdirSync(uploadDir, { recursive: true });

  storage = multer.diskStorage({
    destination: function (req, file, cb) {
      cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
      const uniqueSuffix =
        Date.now() + "-" + Math.round(Math.random() * 1e9);
      cb(null, uniqueSuffix + path.extname(file.originalname));
    },
  });
}

// File filter - accept only images
const fileFilter = (req, file, cb) => {
  const allowedTypes = /jpeg|jpg|png|gif|webp/;
  const extname = allowedTypes.test(
    path.extname(file.originalname).toLowerCase()
  );
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  }
  cb(new Error("Only image files are allowed (jpeg, jpg, png, gif, webp)"));
};

const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter,
});

module.exports = upload;
