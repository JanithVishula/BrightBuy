-- ===================================================================
-- BrightBuy — Aiven-ready single bootstrap (target database: defaultdb)
-- ===================================================================
-- Generated for Aiven free MySQL where you cannot CREATE DATABASE and
-- the provided database is `defaultdb`.
--
-- HOW TO RUN (MySQL Workbench or DBeaver, SSL required):
--   1. Connect to your Aiven host with SSL enabled.
--   2. Open this file and run the whole script once.
--   3. Verify with: SHOW TABLES;  (you should see ~15 tables)
--
-- Idempotency: this drops existing BrightBuy tables first, so it is
-- safe to re-run if you need to reset.
-- ===================================================================

USE defaultdb;

-- Clean slate (drop in FK-safe order) so the script can be re-run.
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Inventory_updates;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Cart_item;
DROP TABLE IF EXISTS Order_item;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS Address;
DROP TABLE IF EXISTS Shipment;
DROP TABLE IF EXISTS ZipDeliveryZone;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS Staff;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS ProductCategory;
DROP TABLE IF EXISTS ProductVariant;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Category;
DROP VIEW IF EXISTS Staff_CategoryOrders;
DROP VIEW IF EXISTS Staff_CustomerOrderSummary;
DROP VIEW IF EXISTS Staff_OrderDeliveryEstimate;
DROP VIEW IF EXISTS Staff_QuarterlySales;
SET FOREIGN_KEY_CHECKS = 1;


-- ===================================================================
-- 1. SCHEMA (tables, triggers, procedures, views)
-- ===================================================================



CREATE TABLE Category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id INT NULL,
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_id) REFERENCES Category(category_id) ON UPDATE CASCADE ON DELETE SET NULL
);


CREATE TABLE Product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


CREATE TABLE ProductCategory (
    product_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_pc_product FOREIGN KEY (product_id) REFERENCES Product(product_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_pc_category FOREIGN KEY (category_id) REFERENCES Category(category_id) ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE ProductVariant (
    variant_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    sku VARCHAR(50) UNIQUE,
    price DECIMAL(10, 2) NOT NULL,
    size VARCHAR(20),
    color VARCHAR(30),
    description TEXT,
    image_url VARCHAR(512),
    is_default TINYINT(1) DEFAULT 0,
    CONSTRAINT fk_variant_product FOREIGN KEY (product_id) REFERENCES Product(product_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_variant_price CHECK (price > 0)
);
CREATE INDEX idx_productvariant_product ON ProductVariant(product_id);

DELIMITER //
CREATE TRIGGER trg_variant_category_check BEFORE INSERT ON ProductVariant FOR EACH ROW 
BEGIN
    DECLARE category_count INT;
    SELECT COUNT(*) INTO category_count
    FROM ProductCategory
    WHERE product_id = NEW.product_id;
    IF category_count = 0 THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot insert ProductVariant: parent Product not assigned to any Category';
    END IF;
END//
DELIMITER ;

CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    user_name VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Address (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    line1 VARCHAR(255) NOT NULL,
    line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    zip_code VARCHAR(10),
    is_default TINYINT(1) DEFAULT 0,
    CONSTRAINT fk_address_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Shipment (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_provider VARCHAR(100),
    tracking_number VARCHAR(100),
    shipped_date TIMESTAMP NULL,
    delivered_date TIMESTAMP NULL,
    notes VARCHAR(255)
);

CREATE TABLE ZipDeliveryZone (
    zip_code VARCHAR(10) PRIMARY KEY,
    state CHAR(2) NOT NULL,
    is_texas TINYINT(1) NOT NULL DEFAULT 0,
    is_main_city TINYINT(1) NOT NULL DEFAULT 0,
    base_fee DECIMAL(10, 2) NOT NULL DEFAULT 10.00,
    base_days INT NOT NULL DEFAULT 7,
    nearest_main_zip VARCHAR(10) NULL,
    city_name VARCHAR(100)
);
CREATE INDEX ix_zip_state ON ZipDeliveryZone(is_texas, is_main_city);

INSERT INTO ZipDeliveryZone(zip_code, state, is_texas, is_main_city, base_fee, base_days, nearest_main_zip, city_name)
VALUES 
    ('78701', 'TX', 1, 1, 5.00, 5, NULL, 'Austin'),
    ('78702', 'TX', 1, 1, 5.00, 5, NULL, 'Austin'),
    ('75001', 'TX', 1, 1, 8.00, 5, NULL, 'Dallas'),
    ('77001', 'TX', 1, 1, 7.00, 5, NULL, 'Houston'),
    ('78201', 'TX', 1, 1, 6.00, 5, NULL, 'San Antonio');


CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    address_id INT NULL,
    customer_id INT NOT NULL,
    payment_id INT NULL,
    shipment_id INT NULL,
    delivery_mode ENUM('Standard Delivery', 'Store Pickup') NOT NULL,
    delivery_zip VARCHAR(10) NULL,
    status ENUM('pending', 'paid', 'shipped', 'delivered') DEFAULT 'pending',
    sub_total DECIMAL(10, 2) NOT NULL,
    delivery_fee DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) DEFAULT 0,
    estimated_delivery_days INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_address FOREIGN KEY (address_id) REFERENCES Address(address_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_order_shipment FOREIGN KEY (shipment_id) REFERENCES Shipment(shipment_id) ON UPDATE CASCADE ON DELETE SET NULL
);
CREATE INDEX idx_orders_customer_created ON Orders(customer_id, created_at);

DELIMITER //
CREATE TRIGGER trg_orders_address_check BEFORE INSERT ON Orders FOR EACH ROW 
BEGIN 
    IF NEW.delivery_mode = 'Standard Delivery' AND NEW.address_id IS NULL THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Standard Delivery requires a valid address_id';
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_compute_delivery_fee BEFORE INSERT ON Orders FOR EACH ROW 
BEGIN
    DECLARE v_base_fee DECIMAL(10, 2);
    DECLARE v_base_days INT;
    
    delivery_block: BEGIN 
        IF NEW.delivery_mode = 'Store Pickup' THEN
            SET NEW.delivery_fee = 0;
            LEAVE delivery_block;
        END IF;
        
        SELECT base_fee INTO v_base_fee
        FROM ZipDeliveryZone
        WHERE zip_code = NEW.delivery_zip;
        
        IF v_base_fee IS NULL THEN
            SET v_base_fee = 10.00;
        END IF;
        
        SET NEW.delivery_fee = v_base_fee;
    END delivery_block;
END//
DELIMITER ;

CREATE TABLE Order_item (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    variant_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_orderitem_order FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_orderitem_variant FOREIGN KEY (variant_id) REFERENCES ProductVariant(variant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_orderitem_quantity CHECK (quantity > 0)
);
CREATE INDEX idx_orderitem_variant ON Order_item(variant_id);

CREATE TABLE Inventory (
    variant_id INT PRIMARY KEY,
    quantity INT NOT NULL,
    CONSTRAINT fk_inventory_variant FOREIGN KEY (variant_id) REFERENCES ProductVariant(variant_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_inventory_quantity CHECK (quantity >= 0)
);
CREATE INDEX idx_inventory_variant ON Inventory(variant_id);

DELIMITER //
CREATE TRIGGER trg_variant_create_inventory AFTER INSERT ON ProductVariant FOR EACH ROW 
BEGIN
    INSERT INTO Inventory(variant_id, quantity)
    VALUES (NEW.variant_id, 0) 
    ON DUPLICATE KEY UPDATE variant_id = variant_id;
END//
DELIMITER ;


CREATE TABLE Cart_item (
    cart_item_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    variant_id INT NOT NULL,
    quantity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cartitem_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cartitem_variant FOREIGN KEY (variant_id) REFERENCES ProductVariant(variant_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_cartitem_quantity CHECK (quantity > 0),
    CONSTRAINT uc_customer_variant UNIQUE(customer_id, variant_id)
);
CREATE INDEX idx_cartitem_customer ON Cart_item(customer_id);


CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(15),
    role ENUM('Level01', 'Level02') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE Inventory_updates (
    update_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    variant_id INT NOT NULL,
    updated_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_quantity INT NOT NULL,
    added_quantity INT NOT NULL,
    note VARCHAR(255),
    CONSTRAINT fk_update_staff FOREIGN KEY (staff_id) REFERENCES Staff(staff_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_update_variant FOREIGN KEY (variant_id) REFERENCES ProductVariant(variant_id) ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER trg_inventory_update_before_insert BEFORE INSERT ON Inventory_updates FOR EACH ROW 
BEGIN
    DECLARE current_qty INT;
    SELECT quantity INTO current_qty
    FROM Inventory
    WHERE variant_id = NEW.variant_id FOR UPDATE;
    
    IF current_qty IS NULL THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Variant not found in Inventory';
    END IF;
    
    SET NEW.old_quantity = current_qty;
    
    IF (current_qty + NEW.added_quantity) < 0 THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory cannot be negative';
    END IF;
    
    UPDATE Inventory
    SET quantity = quantity + NEW.added_quantity
    WHERE variant_id = NEW.variant_id;
END//
DELIMITER ;


CREATE TABLE Payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NULL,
    method ENUM('Cash on Delivery', 'Card Payment') NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    date_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transaction_id VARCHAR(255) NULL,
    status ENUM('pending', 'completed', 'failed') NOT NULL DEFAULT 'pending',
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON UPDATE CASCADE ON DELETE SET NULL
);
CREATE INDEX idx_payment_status ON Payment(status);

DELIMITER //
CREATE TRIGGER trg_payment_after_insert AFTER INSERT ON Payment FOR EACH ROW 
BEGIN 
    IF NEW.order_id IS NOT NULL THEN
        UPDATE Orders
        SET payment_id = NEW.payment_id
        WHERE order_id = NEW.order_id;
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_order_paid_update_payment AFTER UPDATE ON Orders FOR EACH ROW 
BEGIN 
    IF NEW.status = 'paid' AND NEW.payment_id IS NOT NULL THEN
        UPDATE Payment
        SET status = 'completed',
            date_time = IF(date_time IS NULL, NOW(), date_time)
        WHERE payment_id = NEW.payment_id;
    END IF;
END//
DELIMITER ;


DELIMITER //
CREATE PROCEDURE GetTopSellingProducts(
    IN start_date DATE,
    IN end_date DATE,
    IN top_n INT
) 
BEGIN
    SELECT p.product_id,
        p.name AS product_name,
        SUM(oi.quantity) AS total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) AS total_sales
    FROM Order_item oi
        JOIN ProductVariant pv ON oi.variant_id = pv.variant_id
        JOIN Product p ON pv.product_id = p.product_id
        JOIN Orders o ON oi.order_id = o.order_id
    WHERE o.created_at BETWEEN start_date AND end_date
    GROUP BY p.product_id, p.name
    ORDER BY total_quantity_sold DESC
    LIMIT top_n;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE GetQuarterlySalesByYear(IN p_year INT) 
BEGIN
    SELECT QUARTER(o.created_at) AS quarter,
        SUM(oi.quantity * oi.unit_price) AS total_sales,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM Orders o
        JOIN Order_item oi ON o.order_id = oi.order_id
    WHERE YEAR(o.created_at) = p_year
    GROUP BY QUARTER(o.created_at)
    ORDER BY quarter;
END//
DELIMITER ;

CREATE OR REPLACE VIEW Staff_CategoryOrders AS
SELECT c.category_id,
    c.name AS category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM Order_item oi
    JOIN ProductVariant pv ON oi.variant_id = pv.variant_id
    JOIN ProductCategory pc ON pv.product_id = pc.product_id
    JOIN Category c ON pc.category_id = c.category_id
GROUP BY c.category_id, c.name;

CREATE OR REPLACE VIEW Staff_CustomerOrderSummary AS
SELECT c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(o.total) AS total_spent,
    GROUP_CONCAT(
        DISTINCT CONCAT('Order ', o.order_id, ': ', IFNULL(p.status, 'no-payment')) 
        SEPARATOR '; '
    ) AS payment_statuses
FROM Customer c
    LEFT JOIN Orders o ON c.customer_id = o.customer_id
    LEFT JOIN Payment p ON o.payment_id = p.payment_id
GROUP BY c.customer_id, c.first_name, c.last_name;
    
CREATE OR REPLACE VIEW Staff_OrderDeliveryEstimate AS
SELECT o.order_id,
    o.customer_id,
    a.city,
    a.zip_code,
    o.estimated_delivery_days,
    o.created_at AS order_date
FROM Orders o
    LEFT JOIN Address a ON o.address_id = a.address_id;

CREATE OR REPLACE VIEW Staff_QuarterlySales AS
SELECT YEAR(o.created_at) AS year,
    QUARTER(o.created_at) AS quarter,
    SUM(oi.quantity * oi.unit_price) AS total_sales,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM Orders o
    JOIN Order_item oi ON o.order_id = oi.order_id
GROUP BY YEAR(o.created_at), QUARTER(o.created_at);


CREATE INDEX idx_productcategory_category ON ProductCategory(category_id);

SELECT 'BrightBuy Database Schema (Customer ID Approach) created successfully!' AS Status;
SELECT 'Next: Run recreate_users_table.sql, then cart_procedures_customer.sql' AS Next_Step;

-- ===================================================================
-- 2. USERS LOGIN TABLE
-- ===================================================================

-- ============================
-- Recreate users table
-- ============================
-- This file recreates the `users` table exactly as it exists in the brightbuy database
-- Retrieved using: SHOW CREATE TABLE users
-- Date: 2025-10-17


DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
    `user_id` int(11) NOT NULL AUTO_INCREMENT,
    `email` varchar(255) NOT NULL,
    `password_hash` varchar(255) NOT NULL,
    `role` enum('customer', 'staff') NOT NULL DEFAULT 'customer',
    `is_active` tinyint(1) DEFAULT 1,
    `created_at` timestamp NULL DEFAULT current_timestamp(),
    `last_login` timestamp NULL DEFAULT NULL,
    `customer_id` int(11) DEFAULT NULL,
    `staff_id` int(11) DEFAULT NULL,
    PRIMARY KEY (`user_id`),
    UNIQUE KEY `email` (`email`),
    UNIQUE KEY `customer_id` (`customer_id`),
    UNIQUE KEY `staff_id` (`staff_id`),
    KEY `idx_email` (`email`),
    KEY `idx_role` (`role`),
    KEY `idx_customer` (`customer_id`),
    KEY `idx_staff` (`staff_id`),
    CONSTRAINT `fk_users_customer` FOREIGN KEY (`customer_id`) REFERENCES `Customer` (`customer_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_users_staff` FOREIGN KEY (`staff_id`) REFERENCES `Staff` (`staff_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- ============================
-- Table Description:
-- ============================
-- user_id       : Primary key, auto-increment
-- email         : Unique email address for login
-- password_hash : Bcrypt hashed password
-- role          : User role (customer, staff, manager, admin)
-- is_active     : Account status flag (1=active, 0=inactive)
-- created_at    : Account creation timestamp
-- last_login    : Last login timestamp
-- customer_id   : Foreign key to Customer table (unique, one-to-one)
-- staff_id      : Foreign key to Staff table (unique, one-to-one)
--
-- Foreign Keys:
-- - Links to Customer table via customer_id (CASCADE delete/update)
-- - Links to Staff table via staff_id (CASCADE delete/update)
--
-- Indexes:
-- - Primary key on user_id
-- - Unique indexes on email, customer_id, staff_id
-- - Additional indexes on email, role, customer_id, staff_id for query performance
-- ===================================================================
-- 3. ALLOW BACKORDERS (drop chk_inventory_quantity)
-- ===================================================================

-- Migration: Allow Backorders (Negative Inventory)
-- This allows customers to order out-of-stock items
-- Delivery time will automatically add 3 days for out-of-stock items

-- Drop the quantity constraint that prevents negative inventory
ALTER TABLE Inventory DROP CONSTRAINT chk_inventory_quantity;

-- Verify the constraint was removed
SELECT 
    CONSTRAINT_NAME, 
    TABLE_NAME, 
    CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = 'Inventory' 
    AND TABLE_SCHEMA = 'defaultdb';

-- Check current inventory status
SELECT 
    i.variant_id,
    i.quantity,
    CASE 
        WHEN i.quantity < 0 THEN 'BACKORDER'
        WHEN i.quantity = 0 THEN 'OUT OF STOCK'
        WHEN i.quantity > 0 AND i.quantity <= 10 THEN 'LOW STOCK'
        ELSE 'IN STOCK'
    END as stock_status,
    p.name as product_name,
    pv.sku,
    pv.color,
    pv.size
FROM Inventory i
JOIN ProductVariant pv ON i.variant_id = pv.variant_id
JOIN Product p ON pv.product_id = p.product_id
ORDER BY i.quantity ASC;

-- Test query: Show how many items are in backorder status
SELECT 
    COUNT(*) as backorder_count,
    SUM(ABS(quantity)) as total_backorder_quantity
FROM Inventory
WHERE quantity < 0;

-- ===================================================================
-- 4a. SEED DATA — initial population
-- ===================================================================

-- ============================
-- BrightBuy Database Population Script
-- This script populates the database with sample data
-- Including 100+ Product Variants
-- ============================


-- ============================
-- 1. Categories
-- ============================
INSERT INTO Category (name, parent_id) VALUES
-- Main Categories (Level 1)
('Electronics', NULL),
('Computers & Laptops', NULL),
('Mobile Devices', NULL),
('Gaming', NULL),
('Audio', NULL),
('Wearables', NULL),
('Smart Home', NULL),
('Camera & Photography', NULL),
('Accessories', NULL),
('Storage', NULL);

-- Sub Categories (Level 2)
INSERT INTO Category (name, parent_id) VALUES
('Smartphones', 3),
('Tablets', 3),
('Smartwatches', 6),
('Fitness Trackers', 6),
('Headphones', 5),
('Speakers', 5),
('Gaming Consoles', 4),
('Gaming Accessories', 4),
('Laptop Accessories', 9),
('Phone Accessories', 9);

-- ============================
-- 2. Products
-- ============================
INSERT INTO Product (name, brand) VALUES
-- Smartphones
('Galaxy S24 Ultra', 'Samsung'),
('iPhone 15 Pro Max', 'Apple'),
('Pixel 8 Pro', 'Google'),
('OnePlus 12', 'OnePlus'),
('Xiaomi 14 Pro', 'Xiaomi'),

-- Laptops
('MacBook Pro 16"', 'Apple'),
('ThinkPad X1 Carbon', 'Lenovo'),
('XPS 15', 'Dell'),
('ZenBook Pro', 'ASUS'),
('Surface Laptop 5', 'Microsoft'),

-- Tablets
('iPad Pro 12.9"', 'Apple'),
('Galaxy Tab S9', 'Samsung'),
('Surface Pro 9', 'Microsoft'),

-- Smartwatches
('Apple Watch Series 9', 'Apple'),
('Galaxy Watch 6', 'Samsung'),
('Pixel Watch 2', 'Google'),

-- Gaming
('PlayStation 5', 'Sony'),
('Xbox Series X', 'Microsoft'),
('Nintendo Switch OLED', 'Nintendo'),

-- Headphones
('AirPods Pro', 'Apple'),
('WH-1000XM5', 'Sony'),
('QuietComfort Ultra', 'Bose'),
('Momentum 4', 'Sennheiser'),

-- Speakers
('HomePod', 'Apple'),
('Echo Studio', 'Amazon'),
('Sonos One', 'Sonos'),

-- Cameras
('EOS R6 Mark II', 'Canon'),
('Alpha A7 IV', 'Sony'),
('Z6 III', 'Nikon'),

-- Storage
('Portable SSD T7', 'Samsung'),
('My Passport', 'WD'),
('Extreme Pro SSD', 'SanDisk'),

-- Accessories
('Magic Keyboard', 'Apple'),
('MX Master 3S', 'Logitech'),
('PowerCore 20000', 'Anker'),
('USB-C Hub', 'Anker'),
('Phone Case Pro', 'Spigen'),
('Screen Protector', 'ESR'),
('Wireless Charger', 'Belkin'),
('HDMI Cable', 'AmazonBasics'),
('Lightning Cable', 'Apple'),
('USB-C Cable', 'Anker');

-- ============================
-- 3. Product Categories (Many-to-Many)
-- ============================
INSERT INTO ProductCategory (product_id, category_id) VALUES
-- Smartphones
(1, 3), (1, 11),
(2, 3), (2, 11),
(3, 3), (3, 11),
(4, 3), (4, 11),
(5, 3), (5, 11),

-- Laptops
(6, 2),
(7, 2),
(8, 2),
(9, 2),
(10, 2),

-- Tablets
(11, 3), (11, 12),
(12, 3), (12, 12),
(13, 3), (13, 12),

-- Smartwatches
(14, 6), (14, 13),
(15, 6), (15, 13),
(16, 6), (16, 13),

-- Gaming
(17, 4), (17, 17),
(18, 4), (18, 17),
(19, 4), (19, 17),

-- Headphones
(20, 5), (20, 15),
(21, 5), (21, 15),
(22, 5), (22, 15),
(23, 5), (23, 15),

-- Speakers
(24, 5), (24, 16),
(25, 5), (25, 16),
(26, 5), (26, 16),

-- Cameras
(27, 8),
(28, 8),
(29, 8),

-- Storage
(30, 10),
(31, 10),
(32, 10),

-- Accessories
(33, 9), (33, 19),
(34, 9),
(35, 9),
(36, 9),
(37, 9), (37, 20),
(38, 9), (38, 20),
(39, 9),
(40, 9),
(41, 9), (41, 20),
(42, 9);

-- ============================
-- 4. Product Variants (100+ variants)
-- ============================

-- Galaxy S24 Ultra Variants (8 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(1, 'SAM-S24U-256-BLK', 1199.99, '256GB', 'Titanium Black', 'Galaxy S24 Ultra 256GB Titanium Black', 1),
(1, 'SAM-S24U-256-GRY', 1199.99, '256GB', 'Titanium Gray', 'Galaxy S24 Ultra 256GB Titanium Gray', 0),
(1, 'SAM-S24U-512-BLK', 1399.99, '512GB', 'Titanium Black', 'Galaxy S24 Ultra 512GB Titanium Black', 0),
(1, 'SAM-S24U-512-GRY', 1399.99, '512GB', 'Titanium Gray', 'Galaxy S24 Ultra 512GB Titanium Gray', 0),
(1, 'SAM-S24U-1TB-BLK', 1599.99, '1TB', 'Titanium Black', 'Galaxy S24 Ultra 1TB Titanium Black', 0),
(1, 'SAM-S24U-1TB-GRY', 1599.99, '1TB', 'Titanium Gray', 'Galaxy S24 Ultra 1TB Titanium Gray', 0),
(1, 'SAM-S24U-256-VIO', 1199.99, '256GB', 'Titanium Violet', 'Galaxy S24 Ultra 256GB Titanium Violet', 0),
(1, 'SAM-S24U-512-VIO', 1399.99, '512GB', 'Titanium Violet', 'Galaxy S24 Ultra 512GB Titanium Violet', 0);

-- iPhone 15 Pro Max Variants (8 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(2, 'APL-IP15PM-256-BLU', 1199.99, '256GB', 'Blue Titanium', 'iPhone 15 Pro Max 256GB Blue Titanium', 1),
(2, 'APL-IP15PM-256-NAT', 1199.99, '256GB', 'Natural Titanium', 'iPhone 15 Pro Max 256GB Natural Titanium', 0),
(2, 'APL-IP15PM-256-WHT', 1199.99, '256GB', 'White Titanium', 'iPhone 15 Pro Max 256GB White Titanium', 0),
(2, 'APL-IP15PM-256-BLK', 1199.99, '256GB', 'Black Titanium', 'iPhone 15 Pro Max 256GB Black Titanium', 0),
(2, 'APL-IP15PM-512-BLU', 1399.99, '512GB', 'Blue Titanium', 'iPhone 15 Pro Max 512GB Blue Titanium', 0),
(2, 'APL-IP15PM-512-NAT', 1399.99, '512GB', 'Natural Titanium', 'iPhone 15 Pro Max 512GB Natural Titanium', 0),
(2, 'APL-IP15PM-1TB-BLU', 1599.99, '1TB', 'Blue Titanium', 'iPhone 15 Pro Max 1TB Blue Titanium', 0),
(2, 'APL-IP15PM-1TB-BLK', 1599.99, '1TB', 'Black Titanium', 'iPhone 15 Pro Max 1TB Black Titanium', 0);

-- Pixel 8 Pro Variants (6 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(3, 'GOO-P8P-128-OBS', 999.99, '128GB', 'Obsidian', 'Pixel 8 Pro 128GB Obsidian', 1),
(3, 'GOO-P8P-128-POR', 999.99, '128GB', 'Porcelain', 'Pixel 8 Pro 128GB Porcelain', 0),
(3, 'GOO-P8P-128-BAY', 999.99, '128GB', 'Bay Blue', 'Pixel 8 Pro 128GB Bay Blue', 0),
(3, 'GOO-P8P-256-OBS', 1099.99, '256GB', 'Obsidian', 'Pixel 8 Pro 256GB Obsidian', 0),
(3, 'GOO-P8P-256-POR', 1099.99, '256GB', 'Porcelain', 'Pixel 8 Pro 256GB Porcelain', 0),
(3, 'GOO-P8P-512-OBS', 1299.99, '512GB', 'Obsidian', 'Pixel 8 Pro 512GB Obsidian', 0);

-- OnePlus 12 Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(4, 'OPL-OP12-256-BLK', 799.99, '256GB', 'Flowy Emerald', 'OnePlus 12 256GB Flowy Emerald', 1),
(4, 'OPL-OP12-256-WHT', 799.99, '256GB', 'Silky Black', 'OnePlus 12 256GB Silky Black', 0),
(4, 'OPL-OP12-512-BLK', 899.99, '512GB', 'Flowy Emerald', 'OnePlus 12 512GB Flowy Emerald', 0),
(4, 'OPL-OP12-512-WHT', 899.99, '512GB', 'Silky Black', 'OnePlus 12 512GB Silky Black', 0);

-- Xiaomi 14 Pro Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(5, 'XIA-X14P-256-BLK', 899.99, '256GB', 'Black', 'Xiaomi 14 Pro 256GB Black', 1),
(5, 'XIA-X14P-256-WHT', 899.99, '256GB', 'White', 'Xiaomi 14 Pro 256GB White', 0),
(5, 'XIA-X14P-512-BLK', 999.99, '512GB', 'Black', 'Xiaomi 14 Pro 512GB Black', 0),
(5, 'XIA-X14P-512-WHT', 999.99, '512GB', 'White', 'Xiaomi 14 Pro 512GB White', 0);

-- MacBook Pro 16" Variants (6 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(6, 'APL-MBP16-M3P-512-SG', 2499.99, '512GB', 'Space Gray', 'MacBook Pro 16" M3 Pro 512GB Space Gray', 1),
(6, 'APL-MBP16-M3P-512-SV', 2499.99, '512GB', 'Silver', 'MacBook Pro 16" M3 Pro 512GB Silver', 0),
(6, 'APL-MBP16-M3P-1TB-SG', 2899.99, '1TB', 'Space Gray', 'MacBook Pro 16" M3 Pro 1TB Space Gray', 0),
(6, 'APL-MBP16-M3P-1TB-SV', 2899.99, '1TB', 'Silver', 'MacBook Pro 16" M3 Pro 1TB Silver', 0),
(6, 'APL-MBP16-M3M-1TB-SG', 3499.99, '1TB', 'Space Gray', 'MacBook Pro 16" M3 Max 1TB Space Gray', 0),
(6, 'APL-MBP16-M3M-2TB-SG', 3999.99, '2TB', 'Space Gray', 'MacBook Pro 16" M3 Max 2TB Space Gray', 0);

-- ThinkPad X1 Carbon Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(7, 'LEN-X1C-I5-256', 1299.99, '256GB', 'Black', 'ThinkPad X1 Carbon i5 256GB', 1),
(7, 'LEN-X1C-I5-512', 1499.99, '512GB', 'Black', 'ThinkPad X1 Carbon i5 512GB', 0),
(7, 'LEN-X1C-I7-512', 1699.99, '512GB', 'Black', 'ThinkPad X1 Carbon i7 512GB', 0),
(7, 'LEN-X1C-I7-1TB', 1899.99, '1TB', 'Black', 'ThinkPad X1 Carbon i7 1TB', 0);

-- Dell XPS 15 Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(8, 'DEL-XPS15-I7-512', 1799.99, '512GB', 'Platinum Silver', 'XPS 15 i7 512GB Platinum Silver', 1),
(8, 'DEL-XPS15-I7-1TB', 1999.99, '1TB', 'Platinum Silver', 'XPS 15 i7 1TB Platinum Silver', 0),
(8, 'DEL-XPS15-I9-1TB', 2299.99, '1TB', 'Graphite', 'XPS 15 i9 1TB Graphite', 0),
(8, 'DEL-XPS15-I9-2TB', 2599.99, '2TB', 'Graphite', 'XPS 15 i9 2TB Graphite', 0);

-- ASUS ZenBook Pro Variants (3 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(9, 'ASU-ZBP-I7-512', 1599.99, '512GB', 'Pine Gray', 'ZenBook Pro i7 512GB Pine Gray', 1),
(9, 'ASU-ZBP-I7-1TB', 1799.99, '1TB', 'Pine Gray', 'ZenBook Pro i7 1TB Pine Gray', 0),
(9, 'ASU-ZBP-I9-1TB', 2099.99, '1TB', 'Deep Blue', 'ZenBook Pro i9 1TB Deep Blue', 0);

-- Surface Laptop 5 Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(10, 'MSF-SL5-I5-256', 999.99, '256GB', 'Platinum', 'Surface Laptop 5 i5 256GB Platinum', 1),
(10, 'MSF-SL5-I5-512', 1199.99, '512GB', 'Platinum', 'Surface Laptop 5 i5 512GB Platinum', 0),
(10, 'MSF-SL5-I7-512', 1399.99, '512GB', 'Matte Black', 'Surface Laptop 5 i7 512GB Matte Black', 0),
(10, 'MSF-SL5-I7-1TB', 1699.99, '1TB', 'Matte Black', 'Surface Laptop 5 i7 1TB Matte Black', 0);

-- iPad Pro 12.9" Variants (6 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(11, 'APL-IPP129-128-SG', 1099.99, '128GB', 'Space Gray', 'iPad Pro 12.9" 128GB Space Gray WiFi', 1),
(11, 'APL-IPP129-128-SV', 1099.99, '128GB', 'Silver', 'iPad Pro 12.9" 128GB Silver WiFi', 0),
(11, 'APL-IPP129-256-SG', 1199.99, '256GB', 'Space Gray', 'iPad Pro 12.9" 256GB Space Gray WiFi', 0),
(11, 'APL-IPP129-256-SV', 1199.99, '256GB', 'Silver', 'iPad Pro 12.9" 256GB Silver WiFi', 0),
(11, 'APL-IPP129-512-SG', 1399.99, '512GB', 'Space Gray', 'iPad Pro 12.9" 512GB Space Gray WiFi', 0),
(11, 'APL-IPP129-1TB-SG', 1799.99, '1TB', 'Space Gray', 'iPad Pro 12.9" 1TB Space Gray WiFi', 0);

-- Galaxy Tab S9 Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(12, 'SAM-TABS9-128-BLK', 799.99, '128GB', 'Graphite', 'Galaxy Tab S9 128GB Graphite', 1),
(12, 'SAM-TABS9-128-BEI', 799.99, '128GB', 'Beige', 'Galaxy Tab S9 128GB Beige', 0),
(12, 'SAM-TABS9-256-BLK', 899.99, '256GB', 'Graphite', 'Galaxy Tab S9 256GB Graphite', 0),
(12, 'SAM-TABS9-256-BEI', 899.99, '256GB', 'Beige', 'Galaxy Tab S9 256GB Beige', 0);

-- Surface Pro 9 Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(13, 'MSF-SP9-I5-256', 999.99, '256GB', 'Platinum', 'Surface Pro 9 i5 256GB Platinum', 1),
(13, 'MSF-SP9-I5-512', 1199.99, '512GB', 'Graphite', 'Surface Pro 9 i5 512GB Graphite', 0),
(13, 'MSF-SP9-I7-512', 1399.99, '512GB', 'Platinum', 'Surface Pro 9 i7 512GB Platinum', 0),
(13, 'MSF-SP9-I7-1TB', 1699.99, '1TB', 'Graphite', 'Surface Pro 9 i7 1TB Graphite', 0);

-- Apple Watch Series 9 Variants (6 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(14, 'APL-AWS9-41-MID', 399.99, '41mm', 'Midnight', 'Apple Watch Series 9 41mm Midnight Aluminum', 1),
(14, 'APL-AWS9-41-STL', 399.99, '41mm', 'Starlight', 'Apple Watch Series 9 41mm Starlight Aluminum', 0),
(14, 'APL-AWS9-41-RED', 399.99, '41mm', 'Red', 'Apple Watch Series 9 41mm Red Aluminum', 0),
(14, 'APL-AWS9-45-MID', 429.99, '45mm', 'Midnight', 'Apple Watch Series 9 45mm Midnight Aluminum', 0),
(14, 'APL-AWS9-45-STL', 429.99, '45mm', 'Starlight', 'Apple Watch Series 9 45mm Starlight Aluminum', 0),
(14, 'APL-AWS9-45-RED', 429.99, '45mm', 'Red', 'Apple Watch Series 9 45mm Red Aluminum', 0);

-- Galaxy Watch 6 Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(15, 'SAM-GW6-40-GRY', 299.99, '40mm', 'Graphite', 'Galaxy Watch 6 40mm Graphite', 1),
(15, 'SAM-GW6-40-GLD', 299.99, '40mm', 'Gold', 'Galaxy Watch 6 40mm Gold', 0),
(15, 'SAM-GW6-44-GRY', 329.99, '44mm', 'Graphite', 'Galaxy Watch 6 44mm Graphite', 0),
(15, 'SAM-GW6-44-SLV', 329.99, '44mm', 'Silver', 'Galaxy Watch 6 44mm Silver', 0);

-- Pixel Watch 2 Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(16, 'GOO-PW2-WIFI-BLK', 349.99, 'WiFi', 'Matte Black', 'Pixel Watch 2 WiFi Matte Black', 1),
(16, 'GOO-PW2-WIFI-SLV', 349.99, 'WiFi', 'Polished Silver', 'Pixel Watch 2 WiFi Polished Silver', 0),
(16, 'GOO-PW2-LTE-BLK', 399.99, 'LTE', 'Matte Black', 'Pixel Watch 2 LTE Matte Black', 0),
(16, 'GOO-PW2-LTE-SLV', 399.99, 'LTE', 'Polished Silver', 'Pixel Watch 2 LTE Polished Silver', 0);

-- PlayStation 5 Variants (3 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(17, 'SNY-PS5-STD', 499.99, 'Standard', 'White', 'PlayStation 5 Standard Edition', 1),
(17, 'SNY-PS5-DIG', 449.99, 'Digital', 'White', 'PlayStation 5 Digital Edition', 0),
(17, 'SNY-PS5-SLIM', 449.99, 'Slim', 'White', 'PlayStation 5 Slim Edition', 0);

-- Xbox Series X Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(18, 'MSF-XBX-1TB', 499.99, '1TB', 'Black', 'Xbox Series X 1TB', 1),
(18, 'MSF-XBS-512', 299.99, '512GB', 'White', 'Xbox Series S 512GB', 0);

-- Nintendo Switch OLED Variants (3 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(19, 'NIN-NSW-OLED-WHT', 349.99, 'OLED', 'White', 'Nintendo Switch OLED White', 1),
(19, 'NIN-NSW-OLED-NEO', 349.99, 'OLED', 'Neon', 'Nintendo Switch OLED Neon Blue/Red', 0),
(19, 'NIN-NSW-STD', 299.99, 'Standard', 'Neon', 'Nintendo Switch Standard Neon', 0);

-- AirPods Pro Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(20, 'APL-APP2-USBC', 249.99, 'Gen 2', 'White', 'AirPods Pro 2nd Gen USB-C', 1),
(20, 'APL-APP2-LIGHT', 249.99, 'Gen 2', 'White', 'AirPods Pro 2nd Gen Lightning', 0);

-- Sony WH-1000XM5 Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(21, 'SNY-WH1000XM5-BLK', 399.99, 'Standard', 'Black', 'WH-1000XM5 Wireless Noise Canceling Black', 1),
(21, 'SNY-WH1000XM5-SLV', 399.99, 'Standard', 'Silver', 'WH-1000XM5 Wireless Noise Canceling Silver', 0);

-- Bose QuietComfort Ultra Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(22, 'BOS-QCULT-BLK', 429.99, 'Standard', 'Black', 'QuietComfort Ultra Headphones Black', 1),
(22, 'BOS-QCULT-WHT', 429.99, 'Standard', 'White Smoke', 'QuietComfort Ultra Headphones White Smoke', 0);

-- Sennheiser Momentum 4 Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(23, 'SEN-MOM4-BLK', 379.99, 'Standard', 'Black', 'Momentum 4 Wireless Black', 1),
(23, 'SEN-MOM4-WHT', 379.99, 'Standard', 'White', 'Momentum 4 Wireless White', 0);

-- HomePod Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(24, 'APL-HP2-WHT', 299.99, '2nd Gen', 'White', 'HomePod 2nd Gen White', 1),
(24, 'APL-HP2-MID', 299.99, '2nd Gen', 'Midnight', 'HomePod 2nd Gen Midnight', 0);

-- Echo Studio Variants (1 variant)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(25, 'AMZ-ECHOST-CHR', 199.99, 'Standard', 'Charcoal', 'Echo Studio Smart Speaker Charcoal', 1);

-- Sonos One Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(26, 'SON-ONE-BLK', 219.99, 'Gen 2', 'Black', 'Sonos One Gen 2 Black', 1),
(26, 'SON-ONE-WHT', 219.99, 'Gen 2', 'White', 'Sonos One Gen 2 White', 0);

-- Canon EOS R6 Mark II Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(27, 'CAN-R6M2-BODY', 2499.99, 'Body Only', 'Black', 'EOS R6 Mark II Body Only', 1),
(27, 'CAN-R6M2-KIT', 2899.99, 'Kit', 'Black', 'EOS R6 Mark II with 24-105mm Lens', 0);

-- Sony Alpha A7 IV Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(28, 'SNY-A7IV-BODY', 2499.99, 'Body Only', 'Black', 'Alpha A7 IV Body Only', 1),
(28, 'SNY-A7IV-KIT', 2899.99, 'Kit', 'Black', 'Alpha A7 IV with 28-70mm Lens', 0);

-- Nikon Z6 III Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(29, 'NIK-Z6III-BODY', 2499.99, 'Body Only', 'Black', 'Z6 III Body Only', 1),
(29, 'NIK-Z6III-KIT', 2899.99, 'Kit', 'Black', 'Z6 III with 24-70mm Lens', 0);

-- Samsung Portable SSD T7 Variants (6 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(30, 'SAM-T7-500-GRY', 79.99, '500GB', 'Gray', 'Portable SSD T7 500GB Gray', 1),
(30, 'SAM-T7-1TB-GRY', 129.99, '1TB', 'Gray', 'Portable SSD T7 1TB Gray', 0),
(30, 'SAM-T7-1TB-BLU', 129.99, '1TB', 'Blue', 'Portable SSD T7 1TB Blue', 0),
(30, 'SAM-T7-2TB-GRY', 229.99, '2TB', 'Gray', 'Portable SSD T7 2TB Gray', 0),
(30, 'SAM-T7-2TB-RED', 229.99, '2TB', 'Red', 'Portable SSD T7 2TB Red', 0),
(30, 'SAM-T7-4TB-GRY', 449.99, '4TB', 'Gray', 'Portable SSD T7 4TB Gray', 0);

-- WD My Passport Variants (5 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(31, 'WD-MP-1TB-BLK', 59.99, '1TB', 'Black', 'My Passport 1TB Portable HDD Black', 1),
(31, 'WD-MP-2TB-BLK', 79.99, '2TB', 'Black', 'My Passport 2TB Portable HDD Black', 0),
(31, 'WD-MP-4TB-BLK', 119.99, '4TB', 'Black', 'My Passport 4TB Portable HDD Black', 0),
(31, 'WD-MP-5TB-BLK', 149.99, '5TB', 'Black', 'My Passport 5TB Portable HDD Black', 0),
(31, 'WD-MP-2TB-BLU', 79.99, '2TB', 'Blue', 'My Passport 2TB Portable HDD Blue', 0);

-- SanDisk Extreme Pro SSD Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(32, 'SAN-EXTP-500', 99.99, '500GB', 'Black', 'Extreme Pro Portable SSD 500GB', 1),
(32, 'SAN-EXTP-1TB', 159.99, '1TB', 'Black', 'Extreme Pro Portable SSD 1TB', 0),
(32, 'SAN-EXTP-2TB', 289.99, '2TB', 'Black', 'Extreme Pro Portable SSD 2TB', 0),
(32, 'SAN-EXTP-4TB', 549.99, '4TB', 'Black', 'Extreme Pro Portable SSD 4TB', 0);

-- Magic Keyboard Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(33, 'APL-MK-USBC-WHT', 99.99, 'USB-C', 'White', 'Magic Keyboard with Touch ID USB-C White', 1),
(33, 'APL-MK-USBC-BLK', 99.99, 'USB-C', 'Black', 'Magic Keyboard with Touch ID USB-C Black', 0);

-- Logitech MX Master 3S Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(34, 'LOG-MX3S-BLK', 99.99, 'Standard', 'Black', 'MX Master 3S Wireless Mouse Black', 1),
(34, 'LOG-MX3S-GREY', 99.99, 'Standard', 'Pale Grey', 'MX Master 3S Wireless Mouse Pale Grey', 0);

-- Anker PowerCore 20000 Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(35, 'ANK-PC20K-BLK', 49.99, '20000mAh', 'Black', 'PowerCore 20000mAh Power Bank Black', 1),
(35, 'ANK-PC20K-WHT', 49.99, '20000mAh', 'White', 'PowerCore 20000mAh Power Bank White', 0);

-- Anker USB-C Hub Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(36, 'ANK-HUB7-GRY', 49.99, '7-in-1', 'Gray', 'USB-C Hub 7-in-1 Adapter Gray', 1),
(36, 'ANK-HUB10-GRY', 69.99, '10-in-1', 'Gray', 'USB-C Hub 10-in-1 Adapter Gray', 0);

-- Spigen Phone Case Pro Variants (4 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(37, 'SPG-IP15PM-BLK', 29.99, 'iPhone 15 Pro Max', 'Black', 'Tough Armor Case iPhone 15 Pro Max Black', 1),
(37, 'SPG-IP15PM-CLR', 24.99, 'iPhone 15 Pro Max', 'Clear', 'Ultra Hybrid Case iPhone 15 Pro Max Clear', 0),
(37, 'SPG-S24U-BLK', 29.99, 'Galaxy S24 Ultra', 'Black', 'Tough Armor Case Galaxy S24 Ultra Black', 0),
(37, 'SPG-S24U-CLR', 24.99, 'Galaxy S24 Ultra', 'Clear', 'Ultra Hybrid Case Galaxy S24 Ultra Clear', 0);

-- ESR Screen Protector Variants (3 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(38, 'ESR-IP15PM-GLASS', 19.99, 'iPhone 15 Pro Max', 'Clear', 'Tempered Glass Screen Protector 3-Pack', 1),
(38, 'ESR-S24U-GLASS', 19.99, 'Galaxy S24 Ultra', 'Clear', 'Tempered Glass Screen Protector 3-Pack', 0),
(38, 'ESR-IPP129-GLASS', 24.99, 'iPad Pro 12.9"', 'Clear', 'Tempered Glass Screen Protector 2-Pack', 0);

-- Belkin Wireless Charger Variants (3 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(39, 'BEL-BOOSTC-WHT', 39.99, '15W', 'White', 'BoostCharge 15W Wireless Charger White', 1),
(39, 'BEL-BOOSTC-BLK', 39.99, '15W', 'Black', 'BoostCharge 15W Wireless Charger Black', 0),
(39, 'BEL-BOOSTC3-WHT', 79.99, '3-in-1', 'White', 'BoostCharge 3-in-1 Wireless Charger White', 0);

-- AmazonBasics HDMI Cable Variants (3 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(40, 'AMZ-HDMI-6FT', 9.99, '6ft', 'Black', 'High-Speed HDMI Cable 6ft', 1),
(40, 'AMZ-HDMI-10FT', 12.99, '10ft', 'Black', 'High-Speed HDMI Cable 10ft', 0),
(40, 'AMZ-HDMI-15FT', 15.99, '15ft', 'Black', 'High-Speed HDMI Cable 15ft', 0);

-- Apple Lightning Cable Variants (2 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(41, 'APL-LIGHT-1M-WHT', 19.99, '1m', 'White', 'Lightning to USB Cable 1m White', 1),
(41, 'APL-LIGHT-2M-WHT', 29.99, '2m', 'White', 'Lightning to USB Cable 2m White', 0);

-- Anker USB-C Cable Variants (3 variants)
INSERT INTO ProductVariant (product_id, sku, price, size, color, description, is_default) VALUES
(42, 'ANK-USBC-3FT-BLK', 14.99, '3ft', 'Black', 'USB-C to USB-C Cable 100W 3ft Black', 1),
(42, 'ANK-USBC-6FT-BLK', 16.99, '6ft', 'Black', 'USB-C to USB-C Cable 100W 6ft Black', 0),
(42, 'ANK-USBC-10FT-BLK', 19.99, '10ft', 'Black', 'USB-C to USB-C Cable 100W 10ft Black', 0);

-- ============================
-- 5. Inventory (Set initial stock for all variants)
-- ============================
UPDATE Inventory SET quantity = FLOOR(10 + (RAND() * 90)) WHERE variant_id BETWEEN 1 AND 30;
UPDATE Inventory SET quantity = FLOOR(20 + (RAND() * 80)) WHERE variant_id BETWEEN 31 AND 60;
UPDATE Inventory SET quantity = FLOOR(15 + (RAND() * 85)) WHERE variant_id BETWEEN 61 AND 90;
UPDATE Inventory SET quantity = FLOOR(25 + (RAND() * 75)) WHERE variant_id BETWEEN 91 AND 120;
UPDATE Inventory SET quantity = FLOOR(30 + (RAND() * 70)) WHERE variant_id > 120;

-- ============================
-- 6. Customers
-- ============================
INSERT INTO Customer (first_name, last_name, user_name, password_hash, email, phone) VALUES
('John', 'Doe', 'johndoe', '$2a$10$xZQZ8Z8Z8Z8Z8Z8Z8Z8Z8O', 'john.doe@email.com', '512-555-0101'),
('Jane', 'Smith', 'janesmith', '$2a$10$yYYY8Y8Y8Y8Y8Y8Y8Y8Y8O', 'jane.smith@email.com', '512-555-0102'),
('Bob', 'Johnson', 'bobjohnson', '$2a$10$zZZZ8Z8Z8Z8Z8Z8Z8Z8Z8O', 'bob.johnson@email.com', '512-555-0103'),
('Alice', 'Williams', 'alicew', '$2a$10$aAAA8A8A8A8A8A8A8A8A8O', 'alice.williams@email.com', '512-555-0104'),
('Charlie', 'Brown', 'charlieb', '$2a$10$bBBB8B8B8B8B8B8B8B8B8O', 'charlie.brown@email.com', '512-555-0105');

-- ============================
-- 7. Addresses
-- ============================
INSERT INTO Address (customer_id, line1, line2, city, state, zip_code, is_default) VALUES
(1, '123 Main St', 'Apt 4B', 'Austin', 'TX', '78701', 1),
(2, '456 Oak Ave', NULL, 'Dallas', 'TX', '75001', 1),
(3, '789 Pine Rd', 'Suite 200', 'Houston', 'TX', '77001', 1),
(4, '321 Elm St', NULL, 'San Antonio', 'TX', '78201', 1),
(5, '654 Maple Dr', 'Unit 5', 'Austin', 'TX', '78702', 1);

-- ============================
-- 8. Staff
-- ============================
INSERT INTO Staff (user_name, email, password_hash, phone, role) VALUES
('admin', 'admin@brightbuy.com', '$2a$10$adminHashHere', '512-555-9999', 'Level01'),
('manager', 'manager@brightbuy.com', '$2a$10$managerHashHere', '512-555-9998', 'Level02'),
('staff1', 'staff1@brightbuy.com', '$2a$10$staff1HashHere', '512-555-9997', 'Level02');

-- ============================
-- Population Complete!
-- Total Product Variants: 150+
-- ============================

-- ===================================================================
-- 4b. SEED DATA — additional population
-- ===================================================================

-- ============================
-- BrightBuy Inventory Population Script
-- This script adds inventory quantities for all product variants
-- Uses the trg_variant_create_inventory trigger (which auto-creates inventory rows)
-- Then updates them with specific quantities
-- ============================
-- ============================
-- Update Inventory for All Variants
-- Note: Inventory rows are automatically created by trigger when variants are inserted
-- This script updates those rows with realistic stock quantities
-- ============================
-- ============================
-- Smartphones (Variants 1-30)
-- High demand items - moderate to high stock
-- ============================
-- Galaxy S24 Ultra (Variants 1-8) - Popular flagship
UPDATE Inventory
SET quantity = 45
WHERE variant_id = 1;
-- 256GB Titanium Black (default)
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 2;
-- 256GB Titanium Gray
UPDATE Inventory
SET quantity = 50
WHERE variant_id = 3;
-- 512GB Titanium Black
UPDATE Inventory
SET quantity = 40
WHERE variant_id = 4;
-- 512GB Titanium Gray
UPDATE Inventory
SET quantity = 30
WHERE variant_id = 5;
-- 1TB Titanium Black
UPDATE Inventory
SET quantity = 25
WHERE variant_id = 6;
-- 1TB Titanium Gray
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 7;
-- 256GB Titanium Violet
UPDATE Inventory
SET quantity = 22
WHERE variant_id = 8;
-- 512GB Titanium Violet
-- iPhone 15 Pro Max (Variants 9-16) - Very popular
UPDATE Inventory
SET quantity = 60
WHERE variant_id = 9;
-- 256GB Blue Titanium (default)
UPDATE Inventory
SET quantity = 55
WHERE variant_id = 10;
-- 256GB Natural Titanium
UPDATE Inventory
SET quantity = 50
WHERE variant_id = 11;
-- 256GB White Titanium
UPDATE Inventory
SET quantity = 48
WHERE variant_id = 12;
-- 256GB Black Titanium
UPDATE Inventory
SET quantity = 42
WHERE variant_id = 13;
-- 512GB Blue Titanium
UPDATE Inventory
SET quantity = 38
WHERE variant_id = 14;
-- 512GB Natural Titanium
UPDATE Inventory
SET quantity = 25
WHERE variant_id = 15;
-- 1TB Blue Titanium
UPDATE Inventory
SET quantity = 20
WHERE variant_id = 16;
-- 1TB Black Titanium
-- Pixel 8 Pro (Variants 17-22)
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 17;
-- 128GB Obsidian (default)
UPDATE Inventory
SET quantity = 30
WHERE variant_id = 18;
-- 128GB Porcelain
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 19;
-- 128GB Bay Blue
UPDATE Inventory
SET quantity = 32
WHERE variant_id = 20;
-- 256GB Obsidian
UPDATE Inventory
SET quantity = 27
WHERE variant_id = 21;
-- 256GB Porcelain
UPDATE Inventory
SET quantity = 18
WHERE variant_id = 22;
-- 512GB Obsidian
-- OnePlus 12 (Variants 23-26)
UPDATE Inventory
SET quantity = 40
WHERE variant_id = 23;
-- 256GB Flowy Emerald (default)
UPDATE Inventory
SET quantity = 38
WHERE variant_id = 24;
-- 256GB Silky Black
UPDATE Inventory
SET quantity = 30
WHERE variant_id = 25;
-- 512GB Flowy Emerald
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 26;
-- 512GB Silky Black
-- Xiaomi 14 Pro (Variants 27-30)
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 27;
-- 256GB Black (default)
UPDATE Inventory
SET quantity = 32
WHERE variant_id = 28;
-- 256GB White
UPDATE Inventory
SET quantity = 25
WHERE variant_id = 29;
-- 512GB Black
UPDATE Inventory
SET quantity = 22
WHERE variant_id = 30;
-- 512GB White
-- ============================
-- Laptops (Variants 31-51)
-- Premium items - lower stock, higher value
-- ============================
-- MacBook Pro 16" (Variants 31-36)
UPDATE Inventory
SET quantity = 25
WHERE variant_id = 31;
-- M3 Pro 512GB Space Gray (default)
UPDATE Inventory
SET quantity = 22
WHERE variant_id = 32;
-- M3 Pro 512GB Silver
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 33;
-- M3 Pro 1TB Space Gray
UPDATE Inventory
SET quantity = 24
WHERE variant_id = 34;
-- M3 Pro 1TB Silver
UPDATE Inventory
SET quantity = 15
WHERE variant_id = 35;
-- M3 Max 1TB Space Gray
UPDATE Inventory
SET quantity = 12
WHERE variant_id = 36;
-- M3 Max 2TB Space Gray
-- ThinkPad X1 Carbon (Variants 37-40)
UPDATE Inventory
SET quantity = 30
WHERE variant_id = 37;
-- i5 256GB (default)
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 38;
-- i5 512GB
UPDATE Inventory
SET quantity = 25
WHERE variant_id = 39;
-- i7 512GB
UPDATE Inventory
SET quantity = 20
WHERE variant_id = 40;
-- i7 1TB
-- Dell XPS 15 (Variants 41-44)
UPDATE Inventory
SET quantity = 24
WHERE variant_id = 41;
-- i7 512GB Platinum Silver (default)
UPDATE Inventory
SET quantity = 22
WHERE variant_id = 42;
-- i7 1TB Platinum Silver
UPDATE Inventory
SET quantity = 18
WHERE variant_id = 43;
-- i9 1TB Graphite
UPDATE Inventory
SET quantity = 15
WHERE variant_id = 44;
-- i9 2TB Graphite
-- ASUS ZenBook Pro (Variants 45-47)
UPDATE Inventory
SET quantity = 26
WHERE variant_id = 45;
-- i7 512GB Pine Gray (default)
UPDATE Inventory
SET quantity = 22
WHERE variant_id = 46;
-- i7 1TB Pine Gray
UPDATE Inventory
SET quantity = 18
WHERE variant_id = 47;
-- i9 1TB Deep Blue
-- Surface Laptop 5 (Variants 48-51)
UPDATE Inventory
SET quantity = 32
WHERE variant_id = 48;
-- i5 256GB Platinum (default)
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 49;
-- i5 512GB Platinum
UPDATE Inventory
SET quantity = 24
WHERE variant_id = 50;
-- i7 512GB Sage
UPDATE Inventory
SET quantity = 20
WHERE variant_id = 51;
-- i7 1TB Graphite
-- ============================
-- Tablets (Variants 52-61)
-- Moderate stock levels
-- ============================
-- iPad Pro 12.9" (Variants 52-57)
UPDATE Inventory
SET quantity = 30
WHERE variant_id = 52;
-- 128GB Space Gray (default)
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 53;
-- 128GB Silver
UPDATE Inventory
SET quantity = 32
WHERE variant_id = 54;
-- 256GB Space Gray
UPDATE Inventory
SET quantity = 30
WHERE variant_id = 55;
-- 256GB Silver
UPDATE Inventory
SET quantity = 20
WHERE variant_id = 56;
-- 512GB Space Gray
UPDATE Inventory
SET quantity = 18
WHERE variant_id = 57;
-- 1TB Space Gray
-- Galaxy Tab S9 (Variants 58-61)
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 58;
-- 128GB Beige (default)
UPDATE Inventory
SET quantity = 32
WHERE variant_id = 59;
-- 256GB Beige
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 60;
-- 256GB Graphite
UPDATE Inventory
SET quantity = 25
WHERE variant_id = 61;
-- 512GB Graphite
-- Surface Pro 9 (Variants 62-65)
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 62;
-- i5 256GB Platinum (default)
UPDATE Inventory
SET quantity = 26
WHERE variant_id = 63;
-- i5 512GB Platinum
UPDATE Inventory
SET quantity = 22
WHERE variant_id = 64;
-- i7 512GB Graphite
UPDATE Inventory
SET quantity = 18
WHERE variant_id = 65;
-- i7 1TB Sapphire
-- ============================
-- Smartwatches (Variants 66-77)
-- High turnover - good stock
-- ============================
-- Apple Watch Series 9 (Variants 66-71)
UPDATE Inventory
SET quantity = 50
WHERE variant_id = 66;
-- 41mm Midnight (default)
UPDATE Inventory
SET quantity = 48
WHERE variant_id = 67;
-- 41mm Starlight
UPDATE Inventory
SET quantity = 45
WHERE variant_id = 68;
-- 41mm Pink
UPDATE Inventory
SET quantity = 42
WHERE variant_id = 69;
-- 45mm Midnight
UPDATE Inventory
SET quantity = 40
WHERE variant_id = 70;
-- 45mm Starlight
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 71;
-- 45mm Product Red
-- Galaxy Watch 6 (Variants 72-75)
UPDATE Inventory
SET quantity = 38
WHERE variant_id = 72;
-- 40mm Graphite (default)
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 73;
-- 40mm Gold
UPDATE Inventory
SET quantity = 32
WHERE variant_id = 74;
-- 44mm Graphite
UPDATE Inventory
SET quantity = 30
WHERE variant_id = 75;
-- 44mm Silver
-- Pixel Watch 2 (Variants 76-77)
UPDATE Inventory
SET quantity = 30
WHERE variant_id = 76;
-- Polished Silver (default)
UPDATE Inventory
SET quantity = 28
WHERE variant_id = 77;
-- Matte Black
-- ============================
-- Gaming Consoles (Variants 78-86)
-- High demand - controlled stock
-- ============================
-- PlayStation 5 (Variants 78-80)
UPDATE Inventory
SET quantity = 45
WHERE variant_id = 78;
-- Standard Edition (default)
UPDATE Inventory
SET quantity = 40
WHERE variant_id = 79;
-- Digital Edition
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 80;
-- Standard + Extra Controller
-- Xbox Series X (Variants 81-83)
UPDATE Inventory
SET quantity = 42
WHERE variant_id = 81;
-- 1TB (default)
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 82;
-- 1TB + Game Pass
UPDATE Inventory
SET quantity = 30
WHERE variant_id = 83;
-- 1TB Carbon Black
-- Nintendo Switch OLED (Variants 84-86)
UPDATE Inventory
SET quantity = 55
WHERE variant_id = 84;
-- White (default)
UPDATE Inventory
SET quantity = 50
WHERE variant_id = 85;
-- Neon Red/Blue
UPDATE Inventory
SET quantity = 45
WHERE variant_id = 86;
-- Splatoon Edition
-- ============================
-- Headphones (Variants 87-102)
-- Popular accessories - high stock
-- ============================
-- AirPods Pro (Variants 87-88)
UPDATE Inventory
SET quantity = 80
WHERE variant_id = 87;
-- 2nd Gen (default)
UPDATE Inventory
SET quantity = 75
WHERE variant_id = 88;
-- 2nd Gen + MagSafe
-- Sony WH-1000XM5 (Variants 89-91)
UPDATE Inventory
SET quantity = 55
WHERE variant_id = 89;
-- Black (default)
UPDATE Inventory
SET quantity = 50
WHERE variant_id = 90;
-- Silver
UPDATE Inventory
SET quantity = 45
WHERE variant_id = 91;
-- Midnight Blue
-- Bose QuietComfort Ultra (Variants 92-94)
UPDATE Inventory
SET quantity = 48
WHERE variant_id = 92;
-- Black (default)
UPDATE Inventory
SET quantity = 45
WHERE variant_id = 93;
-- White Smoke
UPDATE Inventory
SET quantity = 42
WHERE variant_id = 94;
-- Sandstone
-- Sennheiser Momentum 4 (Variants 95-96)
UPDATE Inventory
SET quantity = 40
WHERE variant_id = 95;
-- Black (default)
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 96;
-- White
-- Gaming Headsets (Variants 97-102)
UPDATE Inventory
SET quantity = 60
WHERE variant_id = 97;
-- SteelSeries Arctis Nova Pro
UPDATE Inventory
SET quantity = 55
WHERE variant_id = 98;
-- Logitech G Pro X
UPDATE Inventory
SET quantity = 50
WHERE variant_id = 99;
-- Razer BlackShark V2
UPDATE Inventory
SET quantity = 52
WHERE variant_id = 100;
-- HyperX Cloud Alpha
UPDATE Inventory
SET quantity = 48
WHERE variant_id = 101;
-- Corsair HS80
UPDATE Inventory
SET quantity = 45
WHERE variant_id = 102;
-- Astro A50
-- ============================
-- Speakers (Variants 103-112)
-- ============================
-- HomePod (Variants 103-104)
UPDATE Inventory
SET quantity = 40
WHERE variant_id = 103;
-- White (default)
UPDATE Inventory
SET quantity = 38
WHERE variant_id = 104;
-- Midnight
-- Echo Studio (Variants 105-106)
UPDATE Inventory
SET quantity = 50
WHERE variant_id = 105;
-- Charcoal (default)
UPDATE Inventory
SET quantity = 45
WHERE variant_id = 106;
-- Glacier White
-- Sonos One (Variants 107-108)
UPDATE Inventory
SET quantity = 52
WHERE variant_id = 107;
-- Black (default)
UPDATE Inventory
SET quantity = 48
WHERE variant_id = 108;
-- White
-- Portable Speakers (Variants 109-112)
UPDATE Inventory
SET quantity = 65
WHERE variant_id = 109;
-- JBL Flip 6
UPDATE Inventory
SET quantity = 60
WHERE variant_id = 110;
-- UE Boom 3
UPDATE Inventory
SET quantity = 55
WHERE variant_id = 111;
-- Bose SoundLink Flex
UPDATE Inventory
SET quantity = 58
WHERE variant_id = 112;
-- Sony SRS-XB43
-- ============================
-- Cameras (Variants 113-124)
-- Professional equipment - lower stock
-- ============================
-- Canon EOS R6 Mark II (Variants 113-115)
UPDATE Inventory
SET quantity = 15
WHERE variant_id = 113;
-- Body Only (default)
UPDATE Inventory
SET quantity = 12
WHERE variant_id = 114;
-- With 24-105mm Lens
UPDATE Inventory
SET quantity = 10
WHERE variant_id = 115;
-- With 24-70mm Lens
-- Sony Alpha A7 IV (Variants 116-118)
UPDATE Inventory
SET quantity = 18
WHERE variant_id = 116;
-- Body Only (default)
UPDATE Inventory
SET quantity = 14
WHERE variant_id = 117;
-- With 28-70mm Lens
UPDATE Inventory
SET quantity = 11
WHERE variant_id = 118;
-- With 24-105mm Lens
-- Nikon Z6 III (Variants 119-121)
UPDATE Inventory
SET quantity = 16
WHERE variant_id = 119;
-- Body Only (default)
UPDATE Inventory
SET quantity = 13
WHERE variant_id = 120;
-- With 24-70mm Lens
UPDATE Inventory
SET quantity = 10
WHERE variant_id = 121;
-- With 24-120mm Lens
-- Action Cameras (Variants 122-124)
UPDATE Inventory
SET quantity = 45
WHERE variant_id = 122;
-- GoPro Hero 12
UPDATE Inventory
SET quantity = 40
WHERE variant_id = 123;
-- DJI Osmo Action 4
UPDATE Inventory
SET quantity = 35
WHERE variant_id = 124;
-- Insta360 X3
-- ============================
-- Storage Devices (Variants 125-136)
-- High demand accessories - good stock
-- ============================
-- Samsung Portable SSD T7 (Variants 125-128)
UPDATE Inventory
SET quantity = 70
WHERE variant_id = 125;
-- 500GB Gray (default)
UPDATE Inventory
SET quantity = 75
WHERE variant_id = 126;
-- 1TB Gray
UPDATE Inventory
SET quantity = 65
WHERE variant_id = 127;
-- 2TB Gray
UPDATE Inventory
SET quantity = 55
WHERE variant_id = 128;
-- 2TB Blue
-- WD My Passport (Variants 129-132)
UPDATE Inventory
SET quantity = 80
WHERE variant_id = 129;
-- 1TB Black (default)
UPDATE Inventory
SET quantity = 75
WHERE variant_id = 130;
-- 2TB Black
UPDATE Inventory
SET quantity = 70
WHERE variant_id = 131;
-- 4TB Black
UPDATE Inventory
SET quantity = 60
WHERE variant_id = 132;
-- 5TB Black
-- SanDisk Extreme Pro SSD (Variants 133-136)
UPDATE Inventory
SET quantity = 65
WHERE variant_id = 133;
-- 500GB (default)
UPDATE Inventory
SET quantity = 70
WHERE variant_id = 134;
-- 1TB
UPDATE Inventory
SET quantity = 60
WHERE variant_id = 135;
-- 2TB
UPDATE Inventory
SET quantity = 50
WHERE variant_id = 136;
-- 4TB
-- ============================
-- Accessories (Variants 137-150+)
-- Very high stock - fast movers
-- ============================
-- Keyboards (Variants 137-140)
UPDATE Inventory
SET quantity = 90
WHERE variant_id = 137;
-- Apple Magic Keyboard (default)
UPDATE Inventory
SET quantity = 85
WHERE variant_id = 138;
-- Logitech MX Keys
UPDATE Inventory
SET quantity = 80
WHERE variant_id = 139;
-- Keychron K2
UPDATE Inventory
SET quantity = 75
WHERE variant_id = 140;
-- Corsair K70
-- Mice (Variants 141-144)
UPDATE Inventory
SET quantity = 95
WHERE variant_id = 141;
-- Logitech MX Master 3S (default)
UPDATE Inventory
SET quantity = 90
WHERE variant_id = 142;
-- Apple Magic Mouse
UPDATE Inventory
SET quantity = 85
WHERE variant_id = 143;
-- Razer DeathAdder V3
UPDATE Inventory
SET quantity = 80
WHERE variant_id = 144;
-- Logitech G502
-- Power Banks (Variants 145-147)
UPDATE Inventory
SET quantity = 100
WHERE variant_id = 145;
-- Anker PowerCore 20000 (default)
UPDATE Inventory
SET quantity = 95
WHERE variant_id = 146;
-- Anker PowerCore 26800
UPDATE Inventory
SET quantity = 90
WHERE variant_id = 147;
-- RAVPower 30000mAh
-- USB-C Hubs (Variants 148-150)
UPDATE Inventory
SET quantity = 85
WHERE variant_id = 148;
-- Anker 7-in-1 Hub (default)
UPDATE Inventory
SET quantity = 80
WHERE variant_id = 149;
-- Satechi Aluminum Hub
UPDATE Inventory
SET quantity = 75
WHERE variant_id = 150;
-- HyperDrive 8-in-1 Hub
-- Phone Cases (Variants 151-155) - If they exist
UPDATE Inventory
SET quantity = 120
WHERE variant_id = 151;
-- Spigen Tough Armor
UPDATE Inventory
SET quantity = 115
WHERE variant_id = 152;
-- OtterBox Defender
UPDATE Inventory
SET quantity = 110
WHERE variant_id = 153;
-- Apple Silicone Case
UPDATE Inventory
SET quantity = 105
WHERE variant_id = 154;
-- Caseology Parallax
UPDATE Inventory
SET quantity = 100
WHERE variant_id = 155;
-- UAG Plasma
-- Screen Protectors (Variants 156-158)
UPDATE Inventory
SET quantity = 150
WHERE variant_id = 156;
-- ESR Tempered Glass (default)
UPDATE Inventory
SET quantity = 140
WHERE variant_id = 157;
-- Spigen GlasTR
UPDATE Inventory
SET quantity = 130
WHERE variant_id = 158;
-- amFilm Glass
-- Wireless Chargers (Variants 159-161)
UPDATE Inventory
SET quantity = 95
WHERE variant_id = 159;
-- Belkin BoostCharge (default)
UPDATE Inventory
SET quantity = 90
WHERE variant_id = 160;
-- Anker PowerWave
UPDATE Inventory
SET quantity = 85
WHERE variant_id = 161;
-- Apple MagSafe Charger
-- Cables (Variants 162-170)
UPDATE Inventory
SET quantity = 200
WHERE variant_id = 162;
-- HDMI Cable 6ft
UPDATE Inventory
SET quantity = 195
WHERE variant_id = 163;
-- HDMI Cable 10ft
UPDATE Inventory
SET quantity = 180
WHERE variant_id = 164;
-- Lightning Cable 3ft
UPDATE Inventory
SET quantity = 175
WHERE variant_id = 165;
-- Lightning Cable 6ft
UPDATE Inventory
SET quantity = 190
WHERE variant_id = 166;
-- USB-C Cable 3ft
UPDATE Inventory
SET quantity = 185
WHERE variant_id = 167;
-- USB-C Cable 6ft
UPDATE Inventory
SET quantity = 170
WHERE variant_id = 168;
-- USB-C to Lightning
UPDATE Inventory
SET quantity = 160
WHERE variant_id = 169;
-- Thunderbolt 4 Cable
UPDATE Inventory
SET quantity = 150
WHERE variant_id = 170;
-- DisplayPort Cable
-- ============================
-- Summary
-- ============================
-- Inventory has been populated for all variants
-- Stock levels are based on product category:
--   - Smartphones: 20-60 units
--   - Laptops: 12-30 units
--   - Tablets: 18-35 units
--   - Smartwatches: 28-50 units
--   - Gaming Consoles: 30-55 units
--   - Headphones: 35-80 units
--   - Speakers: 38-65 units
--   - Cameras: 10-45 units
--   - Storage: 50-80 units
--   - Accessories: 75-200 units
-- ============================
SELECT 'Inventory population completed!' AS Status;
SELECT COUNT(*) AS Total_Variants_With_Inventory
FROM Inventory;
SELECT SUM(quantity) AS Total_Items_In_Stock
FROM Inventory;
SELECT AVG(quantity) AS Average_Stock_Per_Variant
FROM Inventory;
-- ===================================================================
-- 4c. SEED DATA — product images
-- ===================================================================

-- ============================================
-- Add CDN Image URLs for All Product Variants
-- Generated: October 20, 2025
-- Total: 147 product variants
-- Source: Unsplash CDN (high-quality product images)
-- ============================================


-- Smartphones (42 variants)
-- Galaxy S24 Ultra (8 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=800&q=80' WHERE variant_id = 1;  -- Black 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800&q=80' WHERE variant_id = 2;  -- Gray 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=800&q=80' WHERE variant_id = 3;  -- Black 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800&q=80' WHERE variant_id = 4;  -- Gray 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=800&q=80' WHERE variant_id = 5;  -- Black 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800&q=80' WHERE variant_id = 6;  -- Gray 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1616348436168-de43ad0db179?w=800&q=80' WHERE variant_id = 7;  -- Violet 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1616348436168-de43ad0db179?w=800&q=80' WHERE variant_id = 8;  -- Violet 512GB

-- iPhone 15 Pro Max (8 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&q=80' WHERE variant_id = 9;   -- Blue Titanium 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1696446702163-873f6e7f2ced?w=800&q=80' WHERE variant_id = 10;  -- Natural Titanium 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1697624412990-c2417b7a65c1?w=800&q=80' WHERE variant_id = 11;  -- White Titanium 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1592286927505-e27b9b19e0ed?w=800&q=80' WHERE variant_id = 12;  -- Black Titanium 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&q=80' WHERE variant_id = 13;  -- Blue Titanium 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1696446702163-873f6e7f2ced?w=800&q=80' WHERE variant_id = 14;  -- Natural Titanium 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=800&q=80' WHERE variant_id = 15;  -- Blue Titanium 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1592286927505-e27b9b19e0ed?w=800&q=80' WHERE variant_id = 16;  -- Black Titanium 1TB

-- Pixel 8 Pro (6 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=800&q=80' WHERE variant_id = 17;  -- Obsidian 128GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&q=80' WHERE variant_id = 18;  -- Porcelain 128GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1605236453806-6ff36851218e?w=800&q=80' WHERE variant_id = 19;  -- Bay Blue 128GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=800&q=80' WHERE variant_id = 20;  -- Obsidian 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&q=80' WHERE variant_id = 21;  -- Porcelain 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=800&q=80' WHERE variant_id = 22;  -- Obsidian 512GB

-- OnePlus 12 (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1574755393849-623942496936?w=800&q=80' WHERE variant_id = 23;  -- Flowy Emerald 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&q=80' WHERE variant_id = 24;  -- Silky Black 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1574755393849-623942496936?w=800&q=80' WHERE variant_id = 25;  -- Flowy Emerald 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&q=80' WHERE variant_id = 26;  -- Silky Black 512GB

-- Xiaomi 14 Pro (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&q=80' WHERE variant_id = 27;  -- Black 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1585060544812-6b45742d762f?w=800&q=80' WHERE variant_id = 28;  -- White 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&q=80' WHERE variant_id = 29;  -- Black 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1585060544812-6b45742d762f?w=800&q=80' WHERE variant_id = 30;  -- White 512GB

-- Laptops (21 variants)
-- MacBook Pro 16" (6 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80' WHERE variant_id = 31;  -- Space Gray 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?w=800&q=80' WHERE variant_id = 32;  -- Silver 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80' WHERE variant_id = 33;  -- Space Gray 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?w=800&q=80' WHERE variant_id = 34;  -- Silver 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80' WHERE variant_id = 35;  -- Space Gray 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80' WHERE variant_id = 36;  -- Space Gray 2TB

-- ThinkPad X1 Carbon (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&q=80' WHERE variant_id = 37;  -- Black 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&q=80' WHERE variant_id = 38;  -- Black 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&q=80' WHERE variant_id = 39;  -- Black 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&q=80' WHERE variant_id = 40;  -- Black 1TB

-- XPS 15 (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=800&q=80' WHERE variant_id = 41;  -- Platinum Silver 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=800&q=80' WHERE variant_id = 42;  -- Platinum Silver 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=800&q=80' WHERE variant_id = 43;  -- Graphite 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=800&q=80' WHERE variant_id = 44;  -- Graphite 2TB

-- ZenBook Pro (3 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800&q=80' WHERE variant_id = 45;  -- Pine Gray 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800&q=80' WHERE variant_id = 46;  -- Pine Gray 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=800&q=80' WHERE variant_id = 47;  -- Deep Blue 1TB

-- Surface Laptop 5 (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1617826964551-6a8b9f7d7a34?w=800&q=80' WHERE variant_id = 48;  -- Platinum 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1617826964551-6a8b9f7d7a34?w=800&q=80' WHERE variant_id = 49;  -- Platinum 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=800&q=80' WHERE variant_id = 50;  -- Matte Black 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=800&q=80' WHERE variant_id = 51;  -- Matte Black 1TB

-- Tablets (13 variants)
-- iPad Pro 12.9" (6 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1585790050230-5dd28404f905?w=800&q=80' WHERE variant_id = 52;  -- Space Gray 128GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1561154464-82e9adf32764?w=800&q=80' WHERE variant_id = 53;  -- Silver 128GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1585790050230-5dd28404f905?w=800&q=80' WHERE variant_id = 54;  -- Space Gray 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1561154464-82e9adf32764?w=800&q=80' WHERE variant_id = 55;  -- Silver 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1585790050230-5dd28404f905?w=800&q=80' WHERE variant_id = 56;  -- Space Gray 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1585790050230-5dd28404f905?w=800&q=80' WHERE variant_id = 57;  -- Space Gray 1TB

-- Galaxy Tab S9 (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800&q=80' WHERE variant_id = 58;  -- Graphite 128GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1561154464-82e9adf32764?w=800&q=80' WHERE variant_id = 59;  -- Beige 128GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800&q=80' WHERE variant_id = 60;  -- Graphite 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1561154464-82e9adf32764?w=800&q=80' WHERE variant_id = 61;  -- Beige 256GB

-- Surface Pro 9 (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1617826964551-6a8b9f7d7a34?w=800&q=80' WHERE variant_id = 62;  -- Platinum 256GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=800&q=80' WHERE variant_id = 63;  -- Graphite 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1617826964551-6a8b9f7d7a34?w=800&q=80' WHERE variant_id = 64;  -- Platinum 512GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1593642702821-c8da6771f0c6?w=800&q=80' WHERE variant_id = 65;  -- Graphite 1TB

-- Smartwatches (13 variants)
-- Apple Watch Series 9 (6 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=800&q=80' WHERE variant_id = 66;  -- Midnight 41mm
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=800&q=80' WHERE variant_id = 67;  -- Starlight 41mm
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1510017803434-a899398421b3?w=800&q=80' WHERE variant_id = 68;  -- Red 41mm
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=800&q=80' WHERE variant_id = 69;  -- Midnight 45mm
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=800&q=80' WHERE variant_id = 70;  -- Starlight 45mm
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1510017803434-a899398421b3?w=800&q=80' WHERE variant_id = 71;  -- Red 45mm

-- Galaxy Watch 6 (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=800&q=80' WHERE variant_id = 72;  -- Graphite 40mm
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1523170335258-f5ed11844a49?w=800&q=80' WHERE variant_id = 73;  -- Gold 40mm
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=800&q=80' WHERE variant_id = 74;  -- Graphite 44mm
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1617625802912-cde586faf331?w=800&q=80' WHERE variant_id = 75;  -- Silver 44mm

-- Pixel Watch 2 (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=800&q=80' WHERE variant_id = 76;  -- Matte Black WiFi
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1617625802912-cde586faf331?w=800&q=80' WHERE variant_id = 77;  -- Polished Silver WiFi
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=800&q=80' WHERE variant_id = 78;  -- Matte Black LTE
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1617625802912-cde586faf331?w=800&q=80' WHERE variant_id = 79;  -- Polished Silver LTE

-- Gaming Consoles (6 variants)
-- PlayStation 5 (3 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800&q=80' WHERE variant_id = 80;  -- White Standard
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800&q=80' WHERE variant_id = 81;  -- White Digital
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800&q=80' WHERE variant_id = 82;  -- White Slim

-- Xbox Series X (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1621259182978-fbf93132d53d?w=800&q=80' WHERE variant_id = 83;  -- Black 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1622297845775-5ff3fef71d13?w=800&q=80' WHERE variant_id = 84;  -- White 512GB

-- Nintendo Switch OLED (3 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1578303512597-81e6cc155b3e?w=800&q=80' WHERE variant_id = 85;  -- White OLED
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1592840496694-26d035b52b48?w=800&q=80' WHERE variant_id = 86;  -- Neon OLED
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1592840496694-26d035b52b48?w=800&q=80' WHERE variant_id = 87;  -- Neon Standard

-- Audio (16 variants)
-- AirPods Pro (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=800&q=80' WHERE variant_id = 88;  -- White Gen 2
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=800&q=80' WHERE variant_id = 89;  -- White Gen 2

-- WH-1000XM5 (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=800&q=80' WHERE variant_id = 90;  -- Black
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1545127398-14699f92334b?w=800&q=80' WHERE variant_id = 91;  -- Silver

-- QuietComfort Ultra (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=800&q=80' WHERE variant_id = 92;  -- Black
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1577174881658-0f30157f72db?w=800&q=80' WHERE variant_id = 93;  -- White Smoke

-- Momentum 4 (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=800&q=80' WHERE variant_id = 94;  -- Black
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1545127398-14699f92334b?w=800&q=80' WHERE variant_id = 95;  -- White

-- HomePod (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1589492477829-5e65395b66cc?w=800&q=80' WHERE variant_id = 96;  -- White 2nd Gen
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=800&q=80' WHERE variant_id = 97;  -- Midnight 2nd Gen

-- Echo Studio (1 variant)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1543512214-318c7553f230?w=800&q=80' WHERE variant_id = 98;  -- Charcoal

-- Sonos One (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=800&q=80' WHERE variant_id = 99;   -- Black Gen 2
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1589492477829-5e65395b66cc?w=800&q=80' WHERE variant_id = 100;  -- White Gen 2

-- Cameras (6 variants)
-- EOS R6 Mark II (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=800&q=80' WHERE variant_id = 101;  -- Body Only
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=800&q=80' WHERE variant_id = 102;  -- Kit

-- Alpha A7 IV (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1606980702954-79b7ecaa7ab2?w=800&q=80' WHERE variant_id = 103;  -- Body Only
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1606980702954-79b7ecaa7ab2?w=800&q=80' WHERE variant_id = 104;  -- Kit

-- Z6 III (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1617005082133-548c4dd27f35?w=800&q=80' WHERE variant_id = 105;  -- Body Only
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1617005082133-548c4dd27f35?w=800&q=80' WHERE variant_id = 106;  -- Kit

-- Storage (21 variants)
-- Samsung Portable SSD T7 (6 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800&q=80' WHERE variant_id = 107;  -- Gray 500GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800&q=80' WHERE variant_id = 108;  -- Gray 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1624823183493-ed5832f48f18?w=800&q=80' WHERE variant_id = 109;  -- Blue 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800&q=80' WHERE variant_id = 110;  -- Gray 2TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1531492746076-161ca9bcad58?w=800&q=80' WHERE variant_id = 111;  -- Red 2TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800&q=80' WHERE variant_id = 112;  -- Gray 4TB

-- WD My Passport (5 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800&q=80' WHERE variant_id = 113;  -- Black 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800&q=80' WHERE variant_id = 114;  -- Black 2TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800&q=80' WHERE variant_id = 115;  -- Black 4TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=800&q=80' WHERE variant_id = 116;  -- Black 5TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1624823183493-ed5832f48f18?w=800&q=80' WHERE variant_id = 117;  -- Blue 2TB

-- SanDisk Extreme Pro SSD (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1624823183493-ed5832f48f18?w=800&q=80' WHERE variant_id = 118;  -- Black 500GB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1624823183493-ed5832f48f18?w=800&q=80' WHERE variant_id = 119;  -- Black 1TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1624823183493-ed5832f48f18?w=800&q=80' WHERE variant_id = 120;  -- Black 2TB
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1624823183493-ed5832f48f18?w=800&q=80' WHERE variant_id = 121;  -- Black 4TB

-- Accessories (26 variants)
-- Magic Keyboard (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800&q=80' WHERE variant_id = 122;  -- White USB-C
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1595225476474-87563907a212?w=800&q=80' WHERE variant_id = 123;  -- Black USB-C

-- MX Master 3S (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=800&q=80' WHERE variant_id = 124;  -- Black
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=800&q=80' WHERE variant_id = 125;  -- Pale Grey

-- PowerCore 20000 (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=800&q=80' WHERE variant_id = 126;  -- Black 20000mAh
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1626976169545-1f86c8b15a5d?w=800&q=80' WHERE variant_id = 127;  -- White 20000mAh

-- USB-C Hub (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1625948515291-69613efd103f?w=800&q=80' WHERE variant_id = 128;  -- Gray 7-in-1
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1625948515291-69613efd103f?w=800&q=80' WHERE variant_id = 129;  -- Gray 10-in-1

-- Phone Case Pro (4 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=800&q=80' WHERE variant_id = 130;  -- Black iPhone 15 Pro Max
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1556656793-08538906a9f8?w=800&q=80' WHERE variant_id = 131;  -- Clear iPhone 15 Pro Max
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=800&q=80' WHERE variant_id = 132;  -- Black Galaxy S24 Ultra
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1556656793-08538906a9f8?w=800&q=80' WHERE variant_id = 133;  -- Clear Galaxy S24 Ultra

-- Screen Protector (3 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=800&q=80' WHERE variant_id = 134;  -- Clear iPhone 15 Pro Max
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=800&q=80' WHERE variant_id = 135;  -- Clear Galaxy S24 Ultra
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=800&q=80' WHERE variant_id = 136;  -- Clear iPad Pro 12.9"

-- Wireless Charger (3 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1591290619762-c588073c8891?w=800&q=80' WHERE variant_id = 137;  -- White 15W
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1591290619762-c588073c8891?w=800&q=80' WHERE variant_id = 138;  -- Black 15W
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1591290619762-c588073c8891?w=800&q=80' WHERE variant_id = 139;  -- White 3-in-1

-- HDMI Cable (3 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80' WHERE variant_id = 140;  -- Black 6ft
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80' WHERE variant_id = 141;  -- Black 10ft
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80' WHERE variant_id = 142;  -- Black 15ft

-- Lightning Cable (2 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1591290619762-c588073c8891?w=800&q=80' WHERE variant_id = 143;  -- White 1m
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1591290619762-c588073c8891?w=800&q=80' WHERE variant_id = 144;  -- White 2m

-- USB-C Cable (3 variants)
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80' WHERE variant_id = 145;  -- Black 3ft
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80' WHERE variant_id = 146;  -- Black 6ft
UPDATE ProductVariant SET image_url = 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80' WHERE variant_id = 147;  -- Black 10ft

-- ============================================
-- Verification Query
-- ============================================
SELECT 
    COUNT(*) as total_variants,
    SUM(CASE WHEN image_url IS NOT NULL THEN 1 ELSE 0 END) as with_images,
    SUM(CASE WHEN image_url IS NULL THEN 1 ELSE 0 END) as without_images
FROM ProductVariant;

-- Sample Check
SELECT 
    pv.variant_id,
    p.name,
    p.brand,
    pv.color,
    pv.image_url
FROM ProductVariant pv
JOIN Product p ON pv.product_id = p.product_id
ORDER BY pv.variant_id
LIMIT 10;

-- ===================================================================
-- 5. CART STORED PROCEDURES
-- ===================================================================

-- ============================
-- BrightBuy Cart Management Procedures
-- Using customer_id approach (direct customer-to-cart-item relationship)
-- Date: October 17, 2025
-- ============================


-- ============================
-- 1. Add Item to Customer's Cart
-- ============================
DROP PROCEDURE IF EXISTS AddToCart;

DELIMITER //
CREATE PROCEDURE AddToCart(
    IN p_customer_id INT,
    IN p_variant_id INT,
    IN p_quantity INT
) 
BEGIN 
    -- Check if customer exists
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer does not exist';
    END IF;

    -- Check if variant exists
    IF NOT EXISTS (SELECT 1 FROM ProductVariant WHERE variant_id = p_variant_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Product variant does not exist';
    END IF;

    -- Validate quantity
    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity must be greater than 0';
    END IF;

    -- Upsert cart item
    INSERT INTO Cart_item(customer_id, variant_id, quantity)
    VALUES(p_customer_id, p_variant_id, p_quantity)
    ON DUPLICATE KEY UPDATE 
        quantity = quantity + p_quantity;
END//
DELIMITER ;

-- ============================
-- 2. Get Customer's Cart Items
-- ============================
DROP PROCEDURE IF EXISTS GetCustomerCart;

DELIMITER //
CREATE PROCEDURE GetCustomerCart(IN p_customer_id INT) 
BEGIN
    SELECT 
        ci.cart_item_id,
        ci.customer_id,
        ci.variant_id,
        ci.quantity,
        pv.sku,
        pv.price,
        pv.size,
        pv.color,
        pv.image_url,
        pv.description as variant_description,
        p.product_id,
        p.name as product_name,
        p.brand,
        COALESCE(i.quantity, 0) as stock_quantity,
        CASE
            WHEN i.quantity >= ci.quantity THEN 'Available'
            WHEN i.quantity > 0 THEN 'Partially Available'
            ELSE 'Out of Stock'
        END as availability_status,
        (pv.price * ci.quantity) as item_total
    FROM Cart_item ci
        INNER JOIN ProductVariant pv ON ci.variant_id = pv.variant_id
        INNER JOIN Product p ON pv.product_id = p.product_id
        LEFT JOIN Inventory i ON pv.variant_id = i.variant_id
    WHERE ci.customer_id = p_customer_id
    ORDER BY ci.cart_item_id DESC;
END//
DELIMITER ;

-- ============================
-- 3. Get Customer's Cart Summary
-- ============================
DROP PROCEDURE IF EXISTS GetCustomerCartSummary;

DELIMITER //
CREATE PROCEDURE GetCustomerCartSummary(IN p_customer_id INT) 
BEGIN
    SELECT 
        p_customer_id as customer_id,
        COUNT(ci.cart_item_id) as total_items,
        COALESCE(SUM(ci.quantity), 0) as total_quantity,
        COALESCE(SUM(pv.price * ci.quantity), 0) as subtotal,
        SUM(
            CASE
                WHEN i.quantity < ci.quantity THEN 1
                ELSE 0
            END
        ) as out_of_stock_items
    FROM Cart_item ci
        INNER JOIN ProductVariant pv ON ci.variant_id = pv.variant_id
        LEFT JOIN Inventory i ON pv.variant_id = i.variant_id
    WHERE ci.customer_id = p_customer_id;
END//
DELIMITER ;

-- ============================
-- 4. Update Cart Item Quantity
-- ============================
DROP PROCEDURE IF EXISTS UpdateCartItemQuantity;

DELIMITER //
CREATE PROCEDURE UpdateCartItemQuantity(
    IN p_customer_id INT,
    IN p_variant_id INT,
    IN p_new_quantity INT
) 
BEGIN
    -- Validate quantity
    IF p_new_quantity <= 0 THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity must be greater than 0';
    END IF;
    
    -- Update quantity
    UPDATE Cart_item
    SET quantity = p_new_quantity
    WHERE customer_id = p_customer_id
        AND variant_id = p_variant_id;
    
    IF ROW_COUNT() = 0 THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Item not found in cart';
    END IF;
END//
DELIMITER ;

-- ============================
-- 5. Remove Item from Customer's Cart
-- ============================
DROP PROCEDURE IF EXISTS RemoveFromCart;

DELIMITER //
CREATE PROCEDURE RemoveFromCart(
    IN p_customer_id INT,
    IN p_variant_id INT
) 
BEGIN
    DELETE FROM Cart_item
    WHERE customer_id = p_customer_id
        AND variant_id = p_variant_id;
    
    IF ROW_COUNT() = 0 THEN 
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Item not found in cart';
    END IF;
END//
DELIMITER ;

-- ============================
-- 6. Clear Customer's Cart
-- ============================
DROP PROCEDURE IF EXISTS ClearCustomerCart;

DELIMITER //
CREATE PROCEDURE ClearCustomerCart(IN p_customer_id INT) 
BEGIN
    DELETE FROM Cart_item
    WHERE customer_id = p_customer_id;
    
    SELECT ROW_COUNT() as items_removed;
END//
DELIMITER ;

-- ============================
-- 7. Get Cart Item Count for Customer
-- ============================
DROP PROCEDURE IF EXISTS GetCustomerCartCount;

DELIMITER //
CREATE PROCEDURE GetCustomerCartCount(IN p_customer_id INT) 
BEGIN
    SELECT 
        COUNT(cart_item_id) as total_items,
        COALESCE(SUM(quantity), 0) as total_quantity
    FROM Cart_item
    WHERE customer_id = p_customer_id;
END//
DELIMITER ;

-- ============================
-- Usage Examples
-- ============================
/*
-- Add item to cart
CALL AddToCart(1, 5, 2);

-- Get all cart items for customer
CALL GetCustomerCart(1);

-- Get cart summary
CALL GetCustomerCartSummary(1);

-- Update quantity
CALL UpdateCartItemQuantity(1, 5, 3);

-- Remove specific item
CALL RemoveFromCart(1, 5);

-- Clear entire cart
CALL ClearCustomerCart(1);

-- Get cart count
CALL GetCustomerCartCount(1);
*/

SELECT 'Cart procedures created successfully!' AS Status;

-- ===================================================================
-- 6a. ADMIN ACCOUNT (Level01 staff)
-- ===================================================================

-- ============================
-- Create Level01 Staff Account
-- Admin: admin_jvishula@brightbuy.com
-- Password: 123456 (bcrypt hashed)
-- ============================


-- Insert Level01 Staff Account
INSERT INTO Staff (user_name, email, password_hash, phone, role)
VALUES (
    'admin_jvishula',
    'admin_jvishula@brightbuy.com',
    '$2b$10$FVKavkRNr22xFXs0wlrz1eGlUE.Vp1uQOydSoT/cotUwD8sKY1Jx.',
    NULL,
    'Level01'
);

-- Verify the account was created
SELECT 
    staff_id,
    user_name,
    email,
    role,
    created_at
FROM Staff
WHERE email = 'admin_jvishula@brightbuy.com';

SELECT 'Level01 staff account created successfully!' AS Status;
SELECT 'Username: admin_jvishula' AS Username;
SELECT 'Email: admin_jvishula@brightbuy.com' AS Email;
SELECT 'Password: 123456' AS Password;
SELECT 'Role: Level01 (Full Admin Access)' AS Role;

-- ===================================================================
-- 6b. STAFF ACCOUNT
-- ===================================================================

-- ============================
-- Create Staff Account: admin_brightbuy
-- ============================
-- This script creates a staff member and associated user account
-- Username: admin_brightbuy
-- Password: 123456 (will be hashed by bcrypt in application)
-- Role: staff


-- Delete existing staff account if it exists (CASCADE will delete from users table too)
DELETE FROM Staff WHERE email = 'admin@brightbuy.com';

-- Insert into Staff table
INSERT INTO Staff (user_name, email, password_hash, phone, role)
VALUES (
    'admin_brightbuy',
    'admin@brightbuy.com',
    '$2b$10$45/QFPHQShGN9eNfqfkeUeTAwjaPoivJjVRuaOtDc9Hb2aiDvQVvu', -- bcrypt hash for '123456'
    '1234567890',
    'Level01'
);

-- Get the staff_id that was just created
SET @staff_id = LAST_INSERT_ID();

-- Now insert into users table
INSERT INTO users (email, password_hash, role, is_active, staff_id)
VALUES (
    'admin@brightbuy.com',
    '$2b$10$45/QFPHQShGN9eNfqfkeUeTAwjaPoivJjVRuaOtDc9Hb2aiDvQVvu', -- bcrypt hash for '123456'
    'staff',
    1,
    @staff_id
);

-- Verify the insertion
SELECT 
    u.user_id,
    u.email,
    u.role,
    u.is_active,
    s.staff_id,
    s.user_name,
    s.role AS staff_role
FROM users u
JOIN Staff s ON u.staff_id = s.staff_id
WHERE u.email = 'admin@brightbuy.com';

-- ===================================================================
-- 6c. LINK ADMIN/STAFF TO users
-- ===================================================================

-- ============================
-- Link Staff Account to users Table
-- This allows admin_jvishula to login via /api/auth/login
-- ============================


-- Get the staff_id for admin_jvishula
SET @staff_id = (SELECT staff_id FROM Staff WHERE email = 'admin_jvishula@brightbuy.com');

-- Get the password hash from Staff table
SET @password_hash = (SELECT password_hash FROM Staff WHERE email = 'admin_jvishula@brightbuy.com');

-- Check if user entry already exists
SELECT 'Checking for existing user entry...' AS Status;
SELECT user_id, email, role, staff_id FROM users WHERE email = 'admin_jvishula@brightbuy.com';

-- Insert into users table linking to staff
INSERT INTO users (email, password_hash, role, customer_id, staff_id, is_active)
VALUES (
    'admin_jvishula@brightbuy.com',
    @password_hash,
    'staff',
    NULL,
    @staff_id,
    1
)
ON DUPLICATE KEY UPDATE 
    staff_id = @staff_id,
    password_hash = @password_hash,
    is_active = 1;

-- Verify the complete setup
SELECT 'Verification: Staff Table' AS Check_Type;
SELECT 
    staff_id,
    user_name,
    email,
    role,
    LEFT(password_hash, 30) as password_preview
FROM Staff 
WHERE email = 'admin_jvishula@brightbuy.com';

SELECT 'Verification: users Table' AS Check_Type;
SELECT 
    user_id,
    email,
    role,
    staff_id,
    customer_id,
    is_active,
    LEFT(password_hash, 30) as password_preview
FROM users 
WHERE email = 'admin_jvishula@brightbuy.com';

SELECT 'Account is now ready for login!' AS Status;
SELECT 'Email: admin_jvishula@brightbuy.com' AS Login_Email;
SELECT 'Password: 123456' AS Login_Password;
SELECT 'Endpoint: POST /api/auth/login' AS Login_Endpoint;

SELECT 'BrightBuy bootstrap on defaultdb complete.' AS Status;
SHOW TABLES;
