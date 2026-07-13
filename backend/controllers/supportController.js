// controllers/supportController.js
// Customer support tickets + threaded messages.
const db = require("../config/db");

const VALID_STATUS = ["open", "in_progress", "resolved", "closed"];
const VALID_PRIORITY = ["low", "medium", "high"];

// @desc   Create a support ticket. Works for logged-in customers and guests.
// @route  POST /api/support/tickets   (authenticate optional — see route)
const createTicket = async (req, res) => {
  try {
    const { name, email, subject, message, priority } = req.body;

    if (!name || !email || !subject || !message) {
      return res.status(400).json({
        success: false,
        message: "Name, email, subject and message are required.",
      });
    }

    // If the request is authenticated as a customer, bind the ticket to them.
    const customerId =
      req.user && req.user.role === "customer" ? req.user.customerId : null;

    const safePriority = VALID_PRIORITY.includes(priority) ? priority : "medium";

    const [result] = await db.execute(
      `INSERT INTO support_ticket
         (customer_id, name, email, subject, message, priority)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [customerId, name, email, subject, message, safePriority]
    );

    const ticketId = result.insertId;

    // Store the opening message as the first entry in the thread.
    await db.execute(
      `INSERT INTO support_message (ticket_id, sender_role, sender_name, body)
       VALUES (?, 'customer', ?, ?)`,
      [ticketId, name, message]
    );

    res.status(201).json({
      success: true,
      message: "Your support request has been submitted.",
      ticket_id: ticketId,
    });
  } catch (error) {
    console.error("Create ticket error:", error);
    res.status(500).json({ success: false, message: "Server error." });
  }
};

// @desc   List the authenticated customer's own tickets.
// @route  GET /api/support/my-tickets   (customer)
const getMyTickets = async (req, res) => {
  try {
    const customerId = req.user.customerId;
    if (!customerId) {
      return res
        .status(403)
        .json({ success: false, message: "Customers only." });
    }

    const [tickets] = await db.execute(
      `SELECT t.*,
              (SELECT COUNT(*) FROM support_message m WHERE m.ticket_id = t.ticket_id) AS message_count
       FROM support_ticket t
       WHERE t.customer_id = ?
       ORDER BY t.updated_at DESC`,
      [customerId]
    );

    res.json({ success: true, tickets });
  } catch (error) {
    console.error("Get my tickets error:", error);
    res.status(500).json({ success: false, message: "Server error." });
  }
};

// @desc   List all tickets (staff). Optional ?status= filter.
// @route  GET /api/support/tickets   (staff)
const getAllTickets = async (req, res) => {
  try {
    const { status } = req.query;

    let sql = `
      SELECT t.*,
             (SELECT COUNT(*) FROM support_message m WHERE m.ticket_id = t.ticket_id) AS message_count
      FROM support_ticket t`;
    const params = [];

    if (status && VALID_STATUS.includes(status)) {
      sql += " WHERE t.status = ?";
      params.push(status);
    }
    sql += " ORDER BY FIELD(t.status,'open','in_progress','resolved','closed'), t.updated_at DESC";

    const [tickets] = await db.execute(sql, params);
    res.json({ success: true, tickets });
  } catch (error) {
    console.error("Get all tickets error:", error);
    res.status(500).json({ success: false, message: "Server error." });
  }
};

// @desc   Get one ticket with its full message thread.
// @route  GET /api/support/tickets/:id   (owner customer or staff)
const getTicketById = async (req, res) => {
  try {
    const { id } = req.params;

    const [rows] = await db.execute(
      `SELECT * FROM support_ticket WHERE ticket_id = ?`,
      [id]
    );
    if (rows.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: "Ticket not found." });
    }
    const ticket = rows[0];

    // Ownership: staff can view any; a customer only their own.
    if (
      req.user.role !== "staff" &&
      ticket.customer_id !== req.user.customerId
    ) {
      return res
        .status(403)
        .json({ success: false, message: "Access denied." });
    }

    const [messages] = await db.execute(
      `SELECT message_id, sender_role, sender_name, body, created_at
       FROM support_message WHERE ticket_id = ? ORDER BY created_at ASC`,
      [id]
    );

    res.json({ success: true, ticket, messages });
  } catch (error) {
    console.error("Get ticket error:", error);
    res.status(500).json({ success: false, message: "Server error." });
  }
};

// @desc   Post a reply to a ticket (customer owner or staff).
// @route  POST /api/support/tickets/:id/messages
const addMessage = async (req, res) => {
  try {
    const { id } = req.params;
    const { body } = req.body;

    if (!body || !body.trim()) {
      return res
        .status(400)
        .json({ success: false, message: "Message body is required." });
    }

    const [rows] = await db.execute(
      `SELECT * FROM support_ticket WHERE ticket_id = ?`,
      [id]
    );
    if (rows.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: "Ticket not found." });
    }
    const ticket = rows[0];

    const isStaff = req.user.role === "staff";
    if (!isStaff && ticket.customer_id !== req.user.customerId) {
      return res
        .status(403)
        .json({ success: false, message: "Access denied." });
    }

    const senderRole = isStaff ? "staff" : "customer";
    const senderName = req.user.name || (isStaff ? "Support Staff" : ticket.name);

    await db.execute(
      `INSERT INTO support_message (ticket_id, sender_role, sender_name, body)
       VALUES (?, ?, ?, ?)`,
      [id, senderRole, senderName, body.trim()]
    );

    // A staff reply moves an open ticket to in_progress; touch updated_at either way.
    if (isStaff && ticket.status === "open") {
      await db.execute(
        `UPDATE support_ticket SET status = 'in_progress' WHERE ticket_id = ?`,
        [id]
      );
    } else {
      await db.execute(
        `UPDATE support_ticket SET updated_at = CURRENT_TIMESTAMP WHERE ticket_id = ?`,
        [id]
      );
    }

    res.status(201).json({ success: true, message: "Reply sent." });
  } catch (error) {
    console.error("Add message error:", error);
    res.status(500).json({ success: false, message: "Server error." });
  }
};

// @desc   Update ticket status / priority (staff only).
// @route  PATCH /api/support/tickets/:id
const updateTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, priority } = req.body;

    const fields = [];
    const params = [];
    if (status) {
      if (!VALID_STATUS.includes(status)) {
        return res
          .status(400)
          .json({ success: false, message: "Invalid status." });
      }
      fields.push("status = ?");
      params.push(status);
    }
    if (priority) {
      if (!VALID_PRIORITY.includes(priority)) {
        return res
          .status(400)
          .json({ success: false, message: "Invalid priority." });
      }
      fields.push("priority = ?");
      params.push(priority);
    }
    if (fields.length === 0) {
      return res
        .status(400)
        .json({ success: false, message: "Nothing to update." });
    }

    params.push(id);
    const [result] = await db.execute(
      `UPDATE support_ticket SET ${fields.join(", ")} WHERE ticket_id = ?`,
      params
    );
    if (result.affectedRows === 0) {
      return res
        .status(404)
        .json({ success: false, message: "Ticket not found." });
    }

    res.json({ success: true, message: "Ticket updated." });
  } catch (error) {
    console.error("Update ticket error:", error);
    res.status(500).json({ success: false, message: "Server error." });
  }
};

// @desc   Ticket counts by status (staff dashboard stats).
// @route  GET /api/support/stats   (staff)
const getStats = async (req, res) => {
  try {
    const [rows] = await db.execute(
      `SELECT status, COUNT(*) AS count FROM support_ticket GROUP BY status`
    );
    const stats = { open: 0, in_progress: 0, resolved: 0, closed: 0 };
    rows.forEach((r) => (stats[r.status] = r.count));
    res.json({ success: true, stats });
  } catch (error) {
    console.error("Get support stats error:", error);
    res.status(500).json({ success: false, message: "Server error." });
  }
};

module.exports = {
  createTicket,
  getMyTickets,
  getAllTickets,
  getTicketById,
  addMessage,
  updateTicket,
  getStats,
};
