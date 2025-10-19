-- ============================================================================
-- DATABASE UPDATES - DELETE THIS FILE AFTER APPLYING TO YOUR LOCAL DATABASE
-- ============================================================================
-- This file contains database changes from recent remote commits
-- Created: October 19, 2025
-- Apply these changes to sync your local database with the team's changes
-- ============================================================================
USE brightbuy;
-- ============================================================================
-- SECTION 1: TRIGGER DELIMITER FIXES (from schema.sql updates)
-- ============================================================================
-- These fixes ensure triggers work properly with proper delimiter syntax
-- If triggers already exist with correct delimiters, you can skip this section
-- Fix ProductVariant category check trigger
DROP TRIGGER IF EXISTS trg_variant_category_check;
DELIMITER $$ CREATE TRIGGER trg_variant_category_check BEFORE
INSERT ON ProductVariant FOR EACH ROW BEGIN
DECLARE category_count INT;
SELECT COUNT(*) INTO category_count
FROM ProductCategory
WHERE product_id = NEW.product_id;
IF category_count = 0 THEN SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Cannot insert ProductVariant: parent Product not assigned to any Category';
END IF;
END $$ DELIMITER;
-- Fix Orders address check trigger
DROP TRIGGER IF EXISTS trg_orders_address_check;
DELIMITER $$ CREATE TRIGGER trg_orders_address_check BEFORE
INSERT ON Orders FOR EACH ROW BEGIN IF NEW.delivery_mode = 'Standard Delivery'
    AND NEW.address_id IS NULL THEN SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Standard Delivery requires a valid address_id';
END IF;
END $$ DELIMITER;
-- Fix delivery fee computation trigger
DROP TRIGGER IF EXISTS trg_compute_delivery_fee;
DELIMITER $$ CREATE TRIGGER trg_compute_delivery_fee BEFORE
INSERT ON Orders FOR EACH ROW BEGIN
DECLARE v_base_fee DECIMAL(10, 2);
DECLARE v_base_days INT;
delivery_block: BEGIN IF NEW.delivery_mode <> 'Standard Delivery' THEN
SET NEW.delivery_fee = 0;
LEAVE delivery_block;
END IF;
SELECT base_fee,
    estimated_days INTO v_base_fee,
    v_base_days
FROM ZipDeliveryZone
WHERE zip_code = (
        SELECT zip_code
        FROM Address
        WHERE address_id = NEW.address_id
    )
LIMIT 1;
SET NEW.delivery_fee = v_base_fee;
END delivery_block;
END $$ DELIMITER;
-- Fix variant create inventory trigger
DROP TRIGGER IF EXISTS trg_variant_create_inventory;
DELIMITER $$ CREATE TRIGGER trg_variant_create_inventory
AFTER
INSERT ON ProductVariant FOR EACH ROW BEGIN
INSERT INTO Inventory(variant_id, quantity)
VALUES (NEW.variant_id, 0) ON DUPLICATE KEY
UPDATE variant_id = variant_id;
END $$ DELIMITER;
-- Fix inventory update trigger
DROP TRIGGER IF EXISTS trg_inventory_update_before_insert;
DELIMITER $$ CREATE TRIGGER trg_inventory_update_before_insert BEFORE
INSERT ON Inventory_updates FOR EACH ROW BEGIN
DECLARE current_qty INT;
SELECT quantity INTO current_qty
FROM Inventory
WHERE variant_id = NEW.variant_id;
SET NEW.previous_quantity = current_qty;
SET NEW.new_quantity = current_qty + NEW.added_quantity;
IF NEW.new_quantity < 0 THEN SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Inventory quantity cannot be negative after update';
END IF;
UPDATE Inventory
SET quantity = quantity + NEW.added_quantity
WHERE variant_id = NEW.variant_id;
END $$ DELIMITER;
-- ============================================================================
-- SECTION 2: ALLOW BACKORDERS (Negative Inventory Feature)
-- ============================================================================
-- This allows customers to order out-of-stock items
-- Delivery time will automatically add 3 days for out-of-stock items
-- Drop the quantity constraint that prevents negative inventory
-- This will fail silently if the constraint doesn't exist
SET @sql = (
        SELECT CONCAT(
                'ALTER TABLE Inventory DROP CONSTRAINT ',
                CONSTRAINT_NAME
            )
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
        WHERE TABLE_NAME = 'Inventory'
            AND TABLE_SCHEMA = 'brightbuy'
            AND CONSTRAINT_NAME LIKE 'chk_inventory_quantity%'
        LIMIT 1
    );
-- Execute if constraint exists
SET @sql = IFNULL(
        @sql,
        'SELECT "No constraint to drop" as message'
    );
PREPARE stmt
FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
-- Verify the constraint was removed
SELECT CONSTRAINT_NAME,
    TABLE_NAME,
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'Inventory'
    AND TABLE_SCHEMA = 'brightbuy';
-- ============================================================================
-- SECTION 3: REPORTS SETUP (Views and Stored Procedures)
-- ============================================================================
-- This section creates views and procedures for the new reporting system
-- 1. Sales Report View
DROP VIEW IF EXISTS vw_sales_report;
CREATE VIEW vw_sales_report AS
SELECT o.order_id,
    o.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    o.created_at as order_date,
    o.total as order_total,
    o.delivery_fee,
    COUNT(oi.order_item_id) as total_items,
    o.status as order_status,
    YEAR(o.created_at) as year,
    MONTH(o.created_at) as month,
    WEEK(o.created_at) as week
FROM Orders o
    LEFT JOIN Order_item oi ON o.order_id = oi.order_id
    LEFT JOIN Customer c ON o.customer_id = c.customer_id
GROUP BY o.order_id,
    o.customer_id,
    c.first_name,
    c.last_name,
    o.created_at,
    o.total,
    o.status;
-- 2. Inventory Report View
DROP VIEW IF EXISTS vw_inventory_report;
CREATE VIEW vw_inventory_report AS
SELECT pv.variant_id,
    p.product_id,
    p.name as product_name,
    p.brand,
    pv.sku,
    pv.color,
    pv.size,
    pv.price,
    i.quantity as current_stock,
    CASE
        WHEN i.quantity = 0 THEN 'Out of Stock'
        WHEN i.quantity < 5 THEN 'Critical'
        WHEN i.quantity < 20 THEN 'Low'
        ELSE 'In Stock'
    END as stock_status,
    (pv.price * i.quantity) as total_value
FROM ProductVariant pv
    LEFT JOIN Product p ON pv.product_id = p.product_id
    LEFT JOIN Inventory i ON pv.variant_id = i.variant_id
WHERE pv.is_default = 1;
-- 3. Product Performance View
DROP VIEW IF EXISTS vw_product_performance;
CREATE VIEW vw_product_performance AS
SELECT p.product_id,
    p.name as product_name,
    p.brand,
    COUNT(DISTINCT oi.order_id) as total_orders,
    SUM(oi.quantity) as total_units_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue,
    AVG(oi.unit_price) as avg_unit_price,
    MIN(o.created_at) as first_sale_date,
    MAX(o.created_at) as last_sale_date
FROM Product p
    LEFT JOIN ProductVariant pv ON p.product_id = pv.product_id
    LEFT JOIN Order_item oi ON pv.variant_id = oi.variant_id
    LEFT JOIN Orders o ON oi.order_id = o.order_id
GROUP BY p.product_id,
    p.name,
    p.brand;
-- 4. Customer Analysis View
DROP VIEW IF EXISTS vw_customer_analysis;
CREATE VIEW vw_customer_analysis AS
SELECT c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    c.email,
    c.phone,
    c.created_at as registration_date,
    COUNT(DISTINCT o.order_id) as total_orders,
    COALESCE(SUM(o.total), 0) as total_spent,
    AVG(o.total) as avg_order_value,
    MAX(o.created_at) as last_order_date,
    DATEDIFF(NOW(), MAX(o.created_at)) as days_since_last_order
FROM Customer c
    LEFT JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.created_at;
-- 5. Daily Sales Report Procedure
DROP PROCEDURE IF EXISTS GetDailySalesReport;
DELIMITER // CREATE PROCEDURE GetDailySalesReport(
    IN p_start_date DATE,
    IN p_end_date DATE
) BEGIN
SELECT DATE(o.created_at) as sale_date,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    SUM(o.total) as total_revenue,
    SUM(o.delivery_fee) as total_delivery_fees,
    AVG(o.total) as avg_order_value,
    COUNT(
        CASE
            WHEN o.status = 'paid' THEN 1
        END
    ) as completed_orders,
    COUNT(
        CASE
            WHEN o.status = 'pending' THEN 1
        END
    ) as pending_orders
FROM Orders o
WHERE DATE(o.created_at) BETWEEN p_start_date AND p_end_date
GROUP BY DATE(o.created_at)
ORDER BY sale_date DESC;
END // DELIMITER;
-- 6. Monthly Sales Report Procedure
DROP PROCEDURE IF EXISTS GetMonthlySalesReport;
DELIMITER // CREATE PROCEDURE GetMonthlySalesReport(IN p_year INT) BEGIN
SELECT MONTH(o.created_at) as month,
    MONTHNAME(o.created_at) as month_name,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    SUM(o.total) as total_revenue,
    SUM(o.delivery_fee) as total_delivery_fees,
    AVG(o.total) as avg_order_value
FROM Orders o
WHERE YEAR(o.created_at) = p_year
GROUP BY MONTH(o.created_at),
    MONTHNAME(o.created_at)
ORDER BY MONTH(o.created_at);
END // DELIMITER;
-- 7. Top Products Procedure
DROP PROCEDURE IF EXISTS GetTopProducts;
DELIMITER // CREATE PROCEDURE GetTopProducts(IN p_limit INT, IN p_days INT) BEGIN
SELECT p.product_id,
    p.name as product_name,
    p.brand,
    SUM(oi.quantity) as units_sold,
    SUM(oi.quantity * oi.unit_price) as revenue,
    COUNT(DISTINCT oi.order_id) as order_count,
    AVG(oi.unit_price) as avg_price
FROM Product p
    INNER JOIN ProductVariant pv ON p.product_id = pv.product_id
    INNER JOIN Order_item oi ON pv.variant_id = oi.variant_id
    INNER JOIN Orders o ON oi.order_id = o.order_id
WHERE DATE(o.created_at) >= DATE_SUB(NOW(), INTERVAL p_days DAY)
GROUP BY p.product_id,
    p.name,
    p.brand
ORDER BY revenue DESC
LIMIT p_limit;
END // DELIMITER;
-- 8. Low Stock Alert Procedure
DROP PROCEDURE IF EXISTS GetLowStockItems;
DELIMITER // CREATE PROCEDURE GetLowStockItems(IN p_threshold INT) BEGIN
SELECT pv.variant_id,
    p.product_id,
    p.name as product_name,
    p.brand,
    pv.sku,
    pv.color,
    i.quantity as current_stock,
    pv.price,
    (pv.price * i.quantity) as total_value
FROM ProductVariant pv
    INNER JOIN Product p ON pv.product_id = p.product_id
    INNER JOIN Inventory i ON pv.variant_id = i.variant_id
WHERE i.quantity <= p_threshold
ORDER BY i.quantity ASC;
END // DELIMITER;
-- 9. Category Performance Procedure
DROP PROCEDURE IF EXISTS GetCategoryPerformance;
DELIMITER // CREATE PROCEDURE GetCategoryPerformance() BEGIN
SELECT c.category_id,
    c.name as category_name,
    COUNT(DISTINCT p.product_id) as total_products,
    SUM(oi.quantity) as units_sold,
    SUM(oi.quantity * oi.unit_price) as total_revenue,
    AVG(oi.unit_price) as avg_price
FROM Category c
    LEFT JOIN ProductCategory pc ON c.category_id = pc.category_id
    LEFT JOIN Product p ON pc.product_id = p.product_id
    LEFT JOIN ProductVariant pv ON p.product_id = pv.product_id
    LEFT JOIN Order_item oi ON pv.variant_id = oi.variant_id
WHERE c.parent_id IS NULL
GROUP BY c.category_id,
    c.name
ORDER BY total_revenue DESC;
END // DELIMITER;
-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Check current inventory status (including backorders)
SELECT i.variant_id,
    i.quantity,
    CASE
        WHEN i.quantity < 0 THEN 'BACKORDER'
        WHEN i.quantity = 0 THEN 'OUT OF STOCK'
        WHEN i.quantity > 0
        AND i.quantity <= 10 THEN 'LOW STOCK'
        ELSE 'IN STOCK'
    END as stock_status,
    p.name as product_name,
    pv.sku,
    pv.color,
    pv.size
FROM Inventory i
    JOIN ProductVariant pv ON i.variant_id = pv.variant_id
    JOIN Product p ON pv.product_id = p.product_id
ORDER BY i.quantity ASC
LIMIT 20;
-- Verify all triggers are created
SELECT TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE TRIGGER_SCHEMA = 'brightbuy'
ORDER BY EVENT_OBJECT_TABLE,
    ACTION_TIMING,
    EVENT_MANIPULATION;
-- Verify all procedures are created
SELECT ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED,
    LAST_ALTERED
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'brightbuy'
    AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;
-- Verify all views are created
SELECT TABLE_NAME as VIEW_NAME,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'brightbuy'
ORDER BY TABLE_NAME;
-- ============================================================================
-- END OF FILE
-- ============================================================================
-- REMEMBER TO DELETE THIS FILE AFTER APPLYING THE CHANGES!
-- ============================================================================
SELECT 'Database updates applied successfully! Please review the verification queries above.' as STATUS;
SELECT 'REMEMBER: Delete this file after applying changes to your database.' as REMINDER;