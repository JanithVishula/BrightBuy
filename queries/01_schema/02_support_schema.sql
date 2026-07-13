-- ===================================================================
-- Customer support: tickets + threaded messages
-- ===================================================================
-- Customers raise support tickets (from the contact page or their
-- profile). Staff view, reply to, and change the status of tickets.
-- Replies are stored in support_message and shown to the customer.
-- ===================================================================

USE brightbuy;

-- Support tickets raised by customers, managed by staff.
CREATE TABLE IF NOT EXISTS support_ticket (
  ticket_id     INT AUTO_INCREMENT PRIMARY KEY,
  customer_id   INT NULL,                      -- NULL for guest contact-form messages
  name          VARCHAR(120) NOT NULL,
  email         VARCHAR(160) NOT NULL,
  subject       VARCHAR(200) NOT NULL,
  message       TEXT NOT NULL,
  priority      ENUM('low','medium','high') NOT NULL DEFAULT 'medium',
  status        ENUM('open','in_progress','resolved','closed') NOT NULL DEFAULT 'open',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ticket_customer FOREIGN KEY (customer_id)
    REFERENCES customer(customer_id) ON DELETE SET NULL
);

-- Threaded replies on a ticket (from customer or staff).
CREATE TABLE IF NOT EXISTS support_message (
  message_id    INT AUTO_INCREMENT PRIMARY KEY,
  ticket_id     INT NOT NULL,
  sender_role   ENUM('customer','staff') NOT NULL,
  sender_name   VARCHAR(120) NOT NULL,
  body          TEXT NOT NULL,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_msg_ticket FOREIGN KEY (ticket_id)
    REFERENCES support_ticket(ticket_id) ON DELETE CASCADE
);
