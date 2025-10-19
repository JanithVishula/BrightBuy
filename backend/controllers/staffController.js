// controllers/staffController.js
const bcrypt = require("bcryptjs");
const db = require("../config/db");

// Get all staff members
exports.getAllStaff = async (req, res) => {
  try {
    const [staff] = await db.query(
      `SELECT 
        s.staff_id,
        s.user_name,
        s.email,
        s.phone,
        s.role,
        s.created_at
      FROM Staff s
      ORDER BY s.role, s.created_at DESC`
    );

    res.json({
      success: true,
      staff,
    });
  } catch (error) {
    console.error("Get staff error:", error);
    res.status(500).json({
      success: false,
      message: "Server error. Please try again later.",
    });
  }
};

// Create new staff member
exports.createStaff = async (req, res) => {
  try {
    const { userName, email, password, phone, role } = req.body;

    // Validate input
    if (!userName || !email || !password || !role) {
      return res.status(400).json({
        success: false,
        message: "Username, email, password, and role are required",
      });
    }

    // Validate role
    if (!["Level01", "Level02"].includes(role)) {
      return res.status(400).json({
        success: false,
        message: "Invalid role. Must be Level01 or Level02",
      });
    }

    // Check if email already exists
    const [existingStaff] = await db.query(
      "SELECT staff_id FROM Staff WHERE email = ?",
      [email]
    );

    if (existingStaff.length > 0) {
      return res.status(409).json({
        success: false,
        message: "Email already registered",
      });
    }

    // Check if email exists in users table
    const [existingUsers] = await db.query(
      "SELECT user_id FROM users WHERE email = ?",
      [email]
    );

    if (existingUsers.length > 0) {
      return res.status(409).json({
        success: false,
        message: "Email already registered",
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Start transaction
    await db.query("START TRANSACTION");

    try {
      // Insert into Staff table
      const [staffResult] = await db.query(
        "INSERT INTO Staff (user_name, email, password_hash, phone, role) VALUES (?, ?, ?, ?, ?)",
        [userName, email, passwordHash, phone || null, role]
      );

      const staffId = staffResult.insertId;

      // Insert into users table
      await db.query(
        "INSERT INTO users (email, password_hash, role, is_active, staff_id) VALUES (?, ?, ?, ?, ?)",
        [email, passwordHash, "staff", 1, staffId]
      );

      // Commit transaction
      await db.query("COMMIT");

      res.status(201).json({
        success: true,
        message: "Staff member created successfully",
        staffId,
      });
    } catch (err) {
      // Rollback on error
      await db.query("ROLLBACK");
      throw err;
    }
  } catch (error) {
    console.error("Create staff error:", error);
    res.status(500).json({
      success: false,
      message: "Server error. Please try again later.",
    });
  }
};

// Delete staff member
exports.deleteStaff = async (req, res) => {
  try {
    const { staffId } = req.params;

    // Prevent deletion of own account
    if (parseInt(staffId) === req.user.staffId) {
      return res.status(400).json({
        success: false,
        message: "Cannot delete your own account",
      });
    }

    // Check if staff exists
    const [staff] = await db.query(
      "SELECT staff_id FROM Staff WHERE staff_id = ?",
      [staffId]
    );

    if (staff.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Staff member not found",
      });
    }

    // Delete staff (CASCADE will delete user record too)
    await db.query("DELETE FROM Staff WHERE staff_id = ?", [staffId]);

    res.json({
      success: true,
      message: "Staff member deleted successfully",
    });
  } catch (error) {
    console.error("Delete staff error:", error);
    res.status(500).json({
      success: false,
      message: "Server error. Please try again later.",
    });
  }
};

// Get all inventory (products with variants and stock)
exports.getInventory = async (req, res) => {
  try {
    const [inventory] = await db.query(
      `SELECT 
        p.product_id,
        p.name as product_name,
        p.brand,
        pv.variant_id,
        pv.sku,
        pv.color,
        pv.size,
        pv.price,
        COALESCE(i.quantity, 0) as stock,
        i.variant_id as inventory_variant_id
      FROM Product p
      INNER JOIN ProductVariant pv ON p.product_id = pv.product_id
      LEFT JOIN Inventory i ON pv.variant_id = i.variant_id
      ORDER BY p.name, pv.color, pv.size`
    );

    res.json({
      success: true,
      inventory,
    });
  } catch (error) {
    console.error("Get inventory error:", error);
    res.status(500).json({
      success: false,
      message: "Server error. Please try again later.",
      error: error.message,
    });
  }
};

// Update inventory
exports.updateInventory = async (req, res) => {
  const requestId = Math.random().toString(36).substring(7);
  console.log(`[${requestId}] ===== NEW UPDATE REQUEST =====`);

  try {
    const { variantId, quantityChange, notes } = req.body;
    // Handle both staffId and staff_id for backwards compatibility
    const staffId =
      req.user.staffId || req.user.staff_id || req.user.id || req.user.userId;

    console.log(`[${requestId}] Update inventory request:`);
    console.log(`[${requestId}] - Body:`, { variantId, quantityChange, notes });
    console.log(`[${requestId}] - User from token:`, req.user);
    console.log(`[${requestId}] - Extracted staffId:`, staffId);

    if (!variantId || quantityChange === undefined) {
      return res.status(400).json({
        success: false,
        message: "Variant ID and quantity change are required",
      });
    }

    if (!staffId) {
      console.error(
        `[${requestId}] Staff ID not found! Token content:`,
        JSON.stringify(req.user)
      );
      return res.status(401).json({
        success: false,
        message: "Staff ID not found in token. Please login again.",
        debug: { tokenContent: req.user },
      });
    }

    // Get current inventory
    const [currentInventory] = await db.query(
      "SELECT quantity FROM Inventory WHERE variant_id = ?",
      [variantId]
    );

    console.log(`[${requestId}] Current inventory:`, currentInventory);

    if (currentInventory.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Inventory not found for this variant",
      });
    }

    const currentQuantity = currentInventory[0].quantity;
    const newQuantity = currentQuantity + parseInt(quantityChange);

    console.log(
      `[${requestId}] Calculation: ${currentQuantity} + ${quantityChange} = ${newQuantity}`
    );

    if (newQuantity < 0) {
      return res.status(400).json({
        success: false,
        message: "Insufficient stock. Cannot reduce below 0.",
      });
    }

    console.log(`[${requestId}] Starting transaction...`);
    await db.query("START TRANSACTION");

    try {
      // Update Inventory table
      console.log(`[${requestId}] Updating Inventory table...`);
      await db.query("UPDATE Inventory SET quantity = ? WHERE variant_id = ?", [
        newQuantity,
        variantId,
      ]);

      // Insert into Inventory_updates table for tracking
      console.log(`[${requestId}] Inserting into Inventory_updates...`);
      await db.query(
        "INSERT INTO Inventory_updates (variant_id, staff_id, old_quantity, added_quantity, note) VALUES (?, ?, ?, ?, ?)",
        [variantId, staffId, currentQuantity, quantityChange, notes || null]
      );

      console.log(`[${requestId}] Committing transaction...`);
      await db.query("COMMIT");

      console.log(`[${requestId}] ===== UPDATE SUCCESS =====`);
      res.json({
        success: true,
        message: "Inventory updated successfully",
        newQuantity,
      });
    } catch (err) {
      console.error(`[${requestId}] Transaction error:`, err);
      await db.query("ROLLBACK");
      throw err;
    }
  } catch (error) {
    console.error(`[${requestId}] Update inventory error:`, error);
    console.error(`[${requestId}] Error stack:`, error.stack);
    res.status(500).json({
      success: false,
      message: "Server error. Please try again later.",
      error: error.message,
    });
  }
};

// Get all customers
exports.getCustomers = async (req, res) => {
  try {
    const [customers] = await db.query(
      `SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.created_at,
        COUNT(DISTINCT o.order_id) as total_orders,
        COALESCE(SUM(oi.quantity * oi.unit_price), 0) as total_spent
      FROM Customer c
      LEFT JOIN Orders o ON c.customer_id = o.customer_id
      LEFT JOIN Order_item oi ON o.order_id = oi.order_id
      GROUP BY c.customer_id
      ORDER BY total_spent DESC, c.created_at DESC`
    );

    res.json({
      success: true,
      customers,
    });
  } catch (error) {
    console.error("Get customers error:", error);
    res.status(500).json({
      success: false,
      message: "Server error. Please try again later.",
    });
  }
};

// Get customer details by ID
exports.getCustomerDetails = async (req, res) => {
  try {
    const { customerId } = req.params;

    // Get customer basic info
    const [customer] = await db.query(
      "SELECT * FROM Customer WHERE customer_id = ?",
      [customerId]
    );

    if (customer.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Customer not found",
      });
    }

    // Get customer orders
    const [orders] = await db.query(
      `SELECT 
        o.order_id,
        o.order_date,
        o.total_price,
        o.status,
        COUNT(oi.order_item_id) as item_count
      FROM Orders o
      LEFT JOIN Order_item oi ON o.order_id = oi.order_id
      WHERE o.customer_id = ?
      GROUP BY o.order_id
      ORDER BY o.order_date DESC`,
      [customerId]
    );

    // Get customer addresses
    const [addresses] = await db.query(
      "SELECT * FROM Address WHERE customer_id = ?",
      [customerId]
    );

    // Calculate stats
    const totalOrders = orders.length;
    const totalSpent = orders.reduce(
      (sum, order) => sum + parseFloat(order.total_price || 0),
      0
    );
    const avgOrderValue = totalOrders > 0 ? totalSpent / totalOrders : 0;

    res.json({
      success: true,
      customer: {
        ...customer[0],
        totalOrders,
        totalSpent,
        avgOrderValue,
        orders,
        addresses,
      },
    });
  } catch (error) {
    console.error("Get customer details error:", error);
    res.status(500).json({
      success: false,
      message: "Server error. Please try again later.",
    });
  }
};

// Update staff account profile
exports.updateStaffAccount = async (req, res) => {
  try {
    const { staffId } = req.params;
    const { name, email, phone } = req.body;

    // Validate input
    if (!name && !email && !phone) {
      return res.status(400).json({
        success: false,
        message: "No fields to update",
      });
    }

    const updateFields = [];
    const values = [];

    if (name !== undefined) {
      updateFields.push("user_name = ?");
      values.push(name);
    }
    if (email !== undefined) {
      updateFields.push("email = ?");
      values.push(email);
    }
    if (phone !== undefined) {
      updateFields.push("phone = ?");
      values.push(phone);
    }

    values.push(staffId);

    // Update Staff table
    const query = `UPDATE Staff SET ${updateFields.join(
      ", "
    )} WHERE staff_id = ?`;
    await db.query(query, values);

    // Update users table if email changed
    if (email) {
      await db.query("UPDATE users SET email = ? WHERE staff_id = ?", [
        email,
        staffId,
      ]);
    }

    res.json({
      success: true,
      message: "Profile updated successfully",
    });
  } catch (error) {
    console.error("Update staff account error:", error);
    res.status(500).json({
      success: false,
      message: "Server error. Please try again later.",
    });
  }
};

// Delete staff own account
exports.deleteStaffAccount = async (req, res) => {
  const connection = await db.getConnection();

  try {
    const { staffId } = req.params;
    const { password } = req.body;

    // Validate password
    if (!password) {
      return res.status(400).json({
        success: false,
        message: "Password is required",
      });
    }

    // Verify password
    const [staff] = await connection.query(
      "SELECT password_hash FROM Staff WHERE staff_id = ?",
      [staffId]
    );

    if (staff.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Staff member not found",
      });
    }

    const isPasswordValid = await bcrypt.compare(
      password,
      staff[0].password_hash
    );

    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: "Incorrect password",
      });
    }

    // Start transaction
    await connection.beginTransaction();

    // Delete from users table
    await connection.query("DELETE FROM users WHERE staff_id = ?", [staffId]);

    // Delete staff
    await connection.query("DELETE FROM Staff WHERE staff_id = ?", [staffId]);

    await connection.commit();

    res.json({
      success: true,
      message: "Account deleted successfully",
    });
  } catch (error) {
    await connection.rollback();
    console.error("Delete staff account error:", error);
    res.status(500).json({
      success: false,
      message: "Server error. Please try again later.",
    });
  } finally {
    connection.release();
  }
};
