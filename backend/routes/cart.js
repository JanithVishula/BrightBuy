// routes/cart.js
const express = require("express");
const router = express.Router();
const {
  getCartDetails,
  getCartSummary,
  addToCart,
  updateCartItem,
  removeCartItem,
  clearCart,
  getCartItemCount,
} = require("../controllers/cartController");
const { authenticate } = require("../middleware/authMiddleware");

// SECURITY: a customer may only touch their OWN cart. This runs as a
// ROUTE-level middleware (not router.use) so req.params is populated.
const authorizeCartOwner = (req, res, next) => {
  const body = req.body || {};
  const target =
    req.params.customerId || req.query.customer_id || body.customer_id;

  // Staff are not customers and have no cart; block them explicitly.
  if (req.user.role !== "customer" || !req.user.customerId) {
    return res
      .status(403)
      .json({ message: "Only customers can access a cart." });
  }

  // If a target id is supplied it must match the logged-in customer.
  if (target && Number(target) !== Number(req.user.customerId)) {
    return res.status(403).json({ message: "Access denied to this cart." });
  }

  // Force the customer id to the authenticated user for downstream handlers.
  req.params.customerId = String(req.user.customerId);
  next();
};

// Apply auth + ownership to every cart route individually.
const guard = [authenticate, authorizeCartOwner];

// @route   GET /api/cart  (current customer)
router.get("/", guard, getCartDetails);

// @route   POST /api/cart/items
router.post("/items", guard, addToCart);

// @route   GET /api/cart/:customerId
router.get("/:customerId", guard, getCartDetails);

// @route   GET /api/cart/:customerId/summary
router.get("/:customerId/summary", guard, getCartSummary);

// @route   GET /api/cart/:customerId/count
router.get("/:customerId/count", guard, getCartItemCount);

// @route   POST /api/cart/:customerId/items
router.post("/:customerId/items", guard, addToCart);

// @route   PUT /api/cart/:customerId/items/:variantId
router.put("/:customerId/items/:variantId", guard, updateCartItem);

// @route   DELETE /api/cart/:customerId/items/:variantId
router.delete("/:customerId/items/:variantId", guard, removeCartItem);

// @route   DELETE /api/cart/:customerId
router.delete("/:customerId", guard, clearCart);

module.exports = router;
