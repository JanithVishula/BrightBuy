const express = require("express");
const router = express.Router();
const orderController = require("../controllers/orderController");
const {
  authenticate,
  authorizeStaff,
} = require("../middleware/authMiddleware");

// Create a new order (authenticated customer; order is bound to their account)
router.post("/", authenticate, orderController.createOrder);

// Get all orders (staff only)
router.get("/all", authenticate, authorizeStaff, orderController.getAllOrders);

// Get order by ID (owner or staff — enforced in controller)
router.get("/:order_id", authenticate, orderController.getOrderById);

// Get orders by customer ID (owner or staff — enforced in controller)
router.get(
  "/customer/:customer_id",
  authenticate,
  orderController.getOrdersByCustomer
);

// Update order status (staff only)
router.patch(
  "/:order_id/status",
  authenticate,
  authorizeStaff,
  orderController.updateOrderStatus
);

// Update order status (PUT method for staff page)
router.put(
  "/:order_id/status",
  authenticate,
  authorizeStaff,
  orderController.updateOrderStatus
);

// Update shipment information (staff only)
router.put(
  "/:order_id/shipment",
  authenticate,
  authorizeStaff,
  orderController.updateShipmentInfo
);

module.exports = router;
