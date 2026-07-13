// routes/support.js
const express = require("express");
const router = express.Router();
const {
  createTicket,
  getMyTickets,
  getAllTickets,
  getTicketById,
  addMessage,
  updateTicket,
  getStats,
} = require("../controllers/supportController");
const {
  authenticate,
  optionalAuthenticate,
  authorizeStaff,
} = require("../middleware/authMiddleware");

// Create a ticket — guests OR logged-in customers (binds to customer if authed).
router.post("/tickets", optionalAuthenticate, createTicket);

// Staff: dashboard stats + list all tickets. (Declare before /:id routes.)
router.get("/stats", authenticate, authorizeStaff, getStats);
router.get("/tickets", authenticate, authorizeStaff, getAllTickets);

// Customer: list own tickets.
router.get("/my-tickets", authenticate, getMyTickets);

// Owner (customer) or staff: view one ticket + thread.
router.get("/tickets/:id", authenticate, getTicketById);

// Owner (customer) or staff: post a reply.
router.post("/tickets/:id/messages", authenticate, addMessage);

// Staff: update status / priority.
router.patch("/tickets/:id", authenticate, authorizeStaff, updateTicket);

module.exports = router;
