-- ============================================================
--  HORTZMAN GAS — POS SYSTEM DATABASE
--  Supabase / PostgreSQL Compatible
--  Generated for: Hortzman Gas, Nairobi, Kenya
-- ============================================================

-- ============================================================
-- 1. SYSTEM SETTINGS
--    Stores global config like refill buying price (170 KES)
--    Admin can change these values at any time.
-- ============================================================
CREATE TABLE settings (
  key         TEXT PRIMARY KEY,
  value       TEXT NOT NULL,
  description TEXT,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Default refill cost per kg (used for buying price of all refills)
INSERT INTO settings (key, value, description) VALUES
  ('refill_bp_per_kg',     '170',        'Buying price (KES) for refilling per kg — change this to update all refill costs'),
  ('cashier_password',     '1234',       'Cashier login password'),
  ('admin_password',       'admin123',   'Admin login password'),
  ('business_name',        'Hortzman Gas', 'Business display name'),
  ('business_location',    'Nairobi, Kenya', 'Business location'),
  ('currency',             'KES',        'Currency code'),
  ('low_stock_notify',     'true',       'Whether to show low stock alerts');


-- ============================================================
-- 2. BRANDS
--    Each brand (K-Gas, TotalGaz, Shell Afrigas, etc.)
-- ============================================================
CREATE TABLE brands (
  id         SERIAL PRIMARY KEY,
  name       TEXT NOT NULL UNIQUE,    -- e.g. 'K-Gas', 'TotalGaz', 'Shell Afrigas'
  icon       TEXT DEFAULT '🔵',
  is_active  BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO brands (name, icon) VALUES
  ('K-Gas',        '🔵'),
  ('TotalGaz',     '🔵'),
  ('Shell Afrigas','🔵'),
  ('Oilibya',      '🔵'),
  ('ProGas',       '🔵'),
  ('Mix',          '🔃'),
  ('Any',          '🔄'),
  ('Meko',         '🍳'),
  ('Meko Plus',    '🍳'),
  ('Various',      '⚙️'),
  ('Generic',      '🔧'),
  ('Safety Cert.', '🌀'),
  ('Safety Pro',   '🚨'),
  ('Pro',          '🔍'),
  ('Licensed',     '🧯');


-- ============================================================
-- 3. PRODUCT CATEGORIES
-- ============================================================
CREATE TABLE categories (
  id   SERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,  -- 'lpg', 'appliance', 'accessory', 'safety'
  name TEXT NOT NULL          -- 'LPG Gas', 'Appliances', 'Accessories', 'Safety'
);

INSERT INTO categories (code, name) VALUES
  ('lpg',       'LPG Gas'),
  ('appliance', 'Appliances'),
  ('accessory', 'Accessories'),
  ('safety',    'Safety');


-- ============================================================
-- 4. CYLINDER SIZES
--    Shared across all brands: 3kg, 6kg, 13kg, 50kg
-- ============================================================
CREATE TABLE cylinder_sizes (
  id        SERIAL PRIMARY KEY,
  size_label TEXT NOT NULL UNIQUE,  -- '3kg', '6kg', '13kg', '50kg'
  weight_kg  NUMERIC(6,2) NOT NULL  -- 3, 6, 13, 50
);

INSERT INTO cylinder_sizes (size_label, weight_kg) VALUES
  ('3kg',  3),
  ('6kg',  6),
  ('13kg', 13),
  ('50kg', 50);


-- ============================================================
-- 5. PRODUCTS
--    LPG cylinders are grouped by: brand + size + type (new/refill/exchange)
--    Refill buying price = refill_bp_per_kg × weight_kg (from settings × cylinder_sizes)
--    Non-LPG products (appliances, accessories, safety) have direct prices.
-- ============================================================
CREATE TABLE products (
  id              SERIAL PRIMARY KEY,
  name            TEXT NOT NULL,          -- e.g. 'K-Gas 3kg (New)'
  brand_id        INT REFERENCES brands(id),
  category_id     INT NOT NULL REFERENCES categories(id),
  cylinder_size_id INT REFERENCES cylinder_sizes(id),  -- NULL for non-LPG
  product_type    TEXT CHECK (product_type IN ('new','refill','exchange', NULL)),
  icon            TEXT DEFAULT '🔵',

  -- Prices
  buying_price    NUMERIC(10,2) NOT NULL DEFAULT 0,
  selling_price   NUMERIC(10,2) NOT NULL DEFAULT 0,
  -- For refills, buying_price is calculated as: refill_bp_per_kg × weight_kg
  -- The app should recalculate this whenever the refill_bp_per_kg setting changes.
  is_refill       BOOLEAN DEFAULT FALSE,   -- TRUE for refill products (bp is auto-calculated)
  exchange_only   BOOLEAN DEFAULT FALSE,   -- TRUE for exchange/mix products

  -- Stock
  stock_qty       INT NOT NULL DEFAULT 0,
  low_stock_alert INT NOT NULL DEFAULT 3,

  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- -------------------------------------------------------
-- LPG — NEW CYLINDERS
-- Each brand gets 3kg, 6kg, 13kg, 50kg where applicable
-- -------------------------------------------------------
INSERT INTO products (name, brand_id, category_id, cylinder_size_id, product_type, icon, buying_price, selling_price, stock_qty, low_stock_alert, is_refill) VALUES
  -- K-Gas (full range)
  ('K-Gas 3kg (New)',          1, 1, 1, 'new', '🔵', 900,   1200,  8,  3, FALSE),
  ('K-Gas 6kg (New)',          1, 1, 2, 'new', '🔵', 2200,  2800,  10, 3, FALSE),
  ('K-Gas 13kg (New)',         1, 1, 3, 'new', '🔵', 4800,  5500,  6,  2, FALSE),
  ('K-Gas 50kg (New)',         1, 1, 4, 'new', '🔵', 18000, 21000, 3,  1, FALSE),
  -- TotalGaz
  ('TotalGaz 3kg (New)',       2, 1, 1, 'new', '🔵', 950,   1250,  5,  2, FALSE),
  ('TotalGaz 6kg (New)',       2, 1, 2, 'new', '🔵', 2300,  2900,  8,  2, FALSE),
  ('TotalGaz 13kg (New)',      2, 1, 3, 'new', '🔵', 5000,  5700,  5,  2, FALSE),
  ('TotalGaz 50kg (New)',      2, 1, 4, 'new', '🔵', 18500, 22000, 2,  1, FALSE),
  -- Shell Afrigas
  ('Shell Afrigas 3kg (New)',  3, 1, 1, 'new', '🔵', 950,   1250,  4,  2, FALSE),
  ('Shell Afrigas 6kg (New)',  3, 1, 2, 'new', '🔵', 2300,  2900,  5,  2, FALSE),
  ('Shell Afrigas 13kg (New)', 3, 1, 3, 'new', '🔵', 5200,  6000,  4,  2, FALSE),
  ('Shell Afrigas 50kg (New)', 3, 1, 4, 'new', '🔵', 18500, 22000, 2,  1, FALSE),
  -- Oilibya
  ('Oilibya 3kg (New)',        4, 1, 1, 'new', '🔵', 900,   1200,  4,  2, FALSE),
  ('Oilibya 6kg (New)',        4, 1, 2, 'new', '🔵', 2250,  2850,  7,  2, FALSE),
  ('Oilibya 13kg (New)',       4, 1, 3, 'new', '🔵', 4900,  5600,  4,  2, FALSE),
  ('Oilibya 50kg (New)',       4, 1, 4, 'new', '🔵', 18000, 21500, 2,  1, FALSE),
  -- ProGas
  ('ProGas 3kg (New)',         5, 1, 1, 'new', '🔵', 900,   1200,  4,  2, FALSE),
  ('ProGas 6kg (New)',         5, 1, 2, 'new', '🔵', 2200,  2800,  5,  2, FALSE),
  ('ProGas 13kg (New)',        5, 1, 3, 'new', '🔵', 4900,  5600,  5,  2, FALSE),
  ('ProGas 50kg (New)',        5, 1, 4, 'new', '🔵', 18000, 21500, 2,  1, FALSE),
  -- Composite (brand-neutral)
  ('Composite Cylinder 13kg', 7, 1, 3, 'new', '🔵', 6500,  7800,  4,  1, FALSE);

-- -------------------------------------------------------
-- LPG — REFILLS  (brand = 'Any', is_refill = TRUE)
-- Buying price = 170 KES/kg × size
--   3kg  → 170 × 3  = 510
--   6kg  → 170 × 6  = 1020
--   13kg → 170 × 13 = 2210
--   50kg → 170 × 50 = 8500
-- NOTE: When refill_bp_per_kg changes in settings, update these
--       buying_price values (or have the app compute them on the fly).
-- -------------------------------------------------------
INSERT INTO products (name, brand_id, category_id, cylinder_size_id, product_type, icon, buying_price, selling_price, stock_qty, low_stock_alert, is_refill) VALUES
  ('Refill 3kg',  7, 1, 1, 'refill', '🔄', 510,  700,  99, 10, TRUE),
  ('Refill 6kg',  7, 1, 2, 'refill', '🔄', 1020, 1400, 99, 10, TRUE),
  ('Refill 13kg', 7, 1, 3, 'refill', '🔄', 2210, 2800, 99, 10, TRUE),
  ('Refill 50kg', 7, 1, 4, 'refill', '🔄', 8500, 9500, 20,  5, TRUE);

-- -------------------------------------------------------
-- LPG — MIX / EXCHANGE
-- -------------------------------------------------------
INSERT INTO products (name, brand_id, category_id, cylinder_size_id, product_type, icon, buying_price, selling_price, stock_qty, low_stock_alert, exchange_only) VALUES
  ('Mix Exchange 6kg',  6, 1, 2, 'exchange', '🔃', 400,  650,  15, 5, TRUE),
  ('Mix Exchange 13kg', 6, 1, 3, 'exchange', '🔃', 800,  1200, 12, 4, TRUE);

-- -------------------------------------------------------
-- APPLIANCES
-- -------------------------------------------------------
INSERT INTO products (name, brand_id, category_id, product_type, icon, buying_price, selling_price, stock_qty, low_stock_alert) VALUES
  ('Single Burner Stove',   8,  2, NULL, '🍳',  650,  950,   10, 3),
  ('Double Burner Stove',   8,  2, NULL, '🍳',  1800, 2500,  8,  2),
  ('4-Burner Cooker',       9,  2, NULL, '🍳',  8500, 11500, 4,  1),
  ('Portable Camping Stove',10, 2, NULL, '🏕️',  800,  1200,  6,  2),
  ('Grill / Multi-Burner',  10, 2, NULL, '🔥',  4500, 6500,  3,  1);

-- -------------------------------------------------------
-- ACCESSORIES
-- -------------------------------------------------------
INSERT INTO products (name, brand_id, category_id, product_type, icon, buying_price, selling_price, stock_qty, low_stock_alert) VALUES
  ('Meko Regulator',          8,  3, NULL, '🔧', 350, 550,  20, 5),
  ('Low-Pressure Regulator',  12, 3, NULL, '🔧', 280, 450,  18, 5),
  ('High-Pressure Regulator', 12, 3, NULL, '🔧', 450, 700,  12, 4),
  ('Unified Regulator',       12, 3, NULL, '🔧', 380, 600,  10, 3),
  ('LP Hose 1.5m',            12, 3, NULL, '🌀', 180, 300,  25, 8),
  ('HP Hose Pipe',            12, 3, NULL, '🌀', 350, 550,  15, 5),
  ('Gas Igniter / Lighter',   10, 3, NULL, '🔦', 80,  150,  30, 10),
  ('Burner Head & Cap',       8,  3, NULL, '⚙️', 120, 220,  20, 6),
  ('Cylinder Trolley',        12, 3, NULL, '🛒', 800, 1300, 5,  2),
  ('Cylinder Stand/Rack',     12, 3, NULL, '🗄️', 500, 850,  8,  3);

-- -------------------------------------------------------
-- SAFETY
-- -------------------------------------------------------
INSERT INTO products (name, brand_id, category_id, product_type, icon, buying_price, selling_price, stock_qty, low_stock_alert) VALUES
  ('LPG Leak Detector (Home)',       12, 4, NULL, '🔍', 1200, 1800, 8, 2),
  ('LPG Leak Detector (Industrial)', 14, 4, NULL, '🔍', 4500, 6500, 3, 1),
  ('Emergency Shut-off Switch',      13, 4, NULL, '🚨', 800,  1300, 6, 2),
  ('Fire Extinguisher 2kg',          15, 4, NULL, '🧯', 1800, 2800, 5, 2),
  ('Fire Extinguisher 5kg',          15, 4, NULL, '🧯', 3200, 4800, 3, 1);


-- ============================================================
-- 6. CUSTOMERS
-- ============================================================
CREATE TABLE customers (
  id           SERIAL PRIMARY KEY,
  name         TEXT NOT NULL,
  phone        TEXT,
  email        TEXT,
  total_bought NUMERIC(12,2) DEFAULT 0,
  visit_count  INT DEFAULT 0,
  last_visit   DATE,
  balance      NUMERIC(10,2) DEFAULT 0,  -- outstanding credit balance
  notes        TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO customers (name, phone, total_bought, visit_count, last_visit, balance) VALUES
  ('Mary Wanjiku',  '0712345678', 18500, 12, '2025-04-05', 0),
  ('James Otieno',  '0723456789', 5200,  4,  '2025-04-03', 1500),
  ('Fatuma Hassan', '0734567890', 32000, 20, '2025-04-06', 0),
  ('Peter Kamau',   '0745678901', 9800,  7,  '2025-04-01', 2800);


-- ============================================================
-- 7. TRANSACTIONS (SALES)
-- ============================================================
CREATE TABLE transactions (
  id             SERIAL PRIMARY KEY,
  customer_id    INT REFERENCES customers(id),
  customer_name  TEXT NOT NULL DEFAULT 'Walk-in',
  payment_method TEXT CHECK (payment_method IN ('cash','mpesa','card','credit')) DEFAULT 'cash',
  subtotal       NUMERIC(10,2) NOT NULL DEFAULT 0,
  delivery_fee   NUMERIC(10,2) DEFAULT 0,
  discount       NUMERIC(10,2) DEFAULT 0,
  total          NUMERIC(10,2) NOT NULL DEFAULT 0,
  cashier_name   TEXT,
  notes          TEXT,
  due_date       DATE,          -- For credit payments
  due_note       TEXT,          -- e.g. 'Pay this evening'
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Line items for each transaction
CREATE TABLE transaction_items (
  id             SERIAL PRIMARY KEY,
  transaction_id INT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  product_id     INT NOT NULL REFERENCES products(id),
  product_name   TEXT NOT NULL,  -- snapshot of name at time of sale
  qty            INT NOT NULL DEFAULT 1,
  unit_price     NUMERIC(10,2) NOT NULL,
  line_total     NUMERIC(10,2) NOT NULL,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Sample transactions
INSERT INTO transactions (customer_id, customer_name, payment_method, subtotal, total, cashier_name, created_at) VALUES
  (1, 'Mary Wanjiku', 'mpesa', 1800, 1800, 'Jane M.', NOW()),
  (NULL, 'Walk-in',   'cash',  2800, 2800, 'Jane M.', NOW() - INTERVAL '1 hour');


-- ============================================================
-- 8. CREDIT BOOK
-- ============================================================
CREATE TABLE credits (
  id             SERIAL PRIMARY KEY,
  transaction_id INT REFERENCES transactions(id),
  customer_id    INT REFERENCES customers(id),
  customer_name  TEXT NOT NULL,
  customer_phone TEXT,
  items_summary  TEXT,           -- human readable, e.g. 'Refill 13kg × 2'
  amount         NUMERIC(10,2) NOT NULL,
  promise_note   TEXT,           -- e.g. 'Pay evening'
  due_date       DATE,
  status         TEXT CHECK (status IN ('pending','paid','partial','written_off')) DEFAULT 'pending',
  paid_amount    NUMERIC(10,2) DEFAULT 0,
  paid_at        TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO credits (customer_id, customer_name, customer_phone, items_summary, amount, promise_note, due_date, status) VALUES
  (2, 'James Otieno', '0723456789', 'Refill 13kg × 2',                         3000, 'Pay evening',   CURRENT_DATE,          'pending'),
  (4, 'Peter Kamau',  '0745678901', 'Double Burner Stove × 1, LP Hose 1.5m × 1', 2800, 'Pay tomorrow', CURRENT_DATE + 1,      'pending');


-- ============================================================
-- 9. REFILL DISPATCH (CYLINDER SEND-OUT FOR REFILLING)
--    Tracks days when empty cylinders are taken out to be
--    refilled by the supplier, and when they come back.
-- ============================================================
CREATE TABLE refill_dispatches (
  id               SERIAL PRIMARY KEY,
  dispatch_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  expected_back    DATE,                   -- estimated return date
  actual_back      DATE,                   -- filled in when cylinders return
  supplier_name    TEXT,                   -- who they were sent to
  notes            TEXT,
  status           TEXT CHECK (status IN ('dispatched','returned','partial')) DEFAULT 'dispatched',
  created_by       TEXT,                   -- cashier or admin name
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Items per dispatch batch
CREATE TABLE refill_dispatch_items (
  id                  SERIAL PRIMARY KEY,
  dispatch_id         INT NOT NULL REFERENCES refill_dispatches(id) ON DELETE CASCADE,
  cylinder_size_id    INT NOT NULL REFERENCES cylinder_sizes(id),
  brand_id            INT REFERENCES brands(id),    -- whose cylinder (if known)
  qty_sent            INT NOT NULL DEFAULT 0,
  qty_returned        INT DEFAULT 0,                -- filled in on return
  buying_price_each   NUMERIC(10,2),                -- refill cost paid per cylinder (snapshot of setting at time of dispatch)
  total_cost          NUMERIC(10,2),                -- qty_sent × buying_price_each
  notes               TEXT
);

-- Sample dispatch
INSERT INTO refill_dispatches (dispatch_date, expected_back, supplier_name, notes, status, created_by) VALUES
  (CURRENT_DATE, CURRENT_DATE + 1, 'K-Gas Depot Nairobi', 'Morning batch — 3kg and 6kg cylinders', 'dispatched', 'Jane M.');

INSERT INTO refill_dispatch_items (dispatch_id, cylinder_size_id, brand_id, qty_sent, buying_price_each, total_cost) VALUES
  (1, 1, 1, 10, 510,  5100),   -- 10 × 3kg K-Gas cylinders @ KES 510 each
  (1, 2, 1, 8,  1020, 8160);   -- 8  × 6kg K-Gas cylinders @ KES 1020 each


-- ============================================================
-- 10. OVERHEADS / FIXED COSTS
-- ============================================================
CREATE TABLE overheads (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  amount      NUMERIC(10,2) NOT NULL DEFAULT 0,
  frequency   TEXT CHECK (frequency IN ('monthly','weekly','annual','one-off')) DEFAULT 'monthly',
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO overheads (name, amount, frequency) VALUES
  ('Shop Rent',               4000, 'monthly'),
  ('Employee Salary (Jane)',  7000, 'monthly'),
  ('Legal / License Fees',    2000, 'monthly'),
  ('Electricity & Water',     1500, 'monthly'),
  ('Internet / Airtime',       500, 'monthly');


-- ============================================================
-- 11. STOCK ADJUSTMENTS (AUDIT LOG)
-- ============================================================
CREATE TABLE stock_adjustments (
  id           SERIAL PRIMARY KEY,
  product_id   INT NOT NULL REFERENCES products(id),
  change_qty   INT NOT NULL,   -- positive = stock in, negative = stock out
  reason       TEXT,           -- 'sale', 'restock', 'damage', 'correction', 'dispatch', 'return'
  reference_id INT,            -- transaction_id or dispatch_id
  adjusted_by  TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================
-- 12. USEFUL VIEWS
-- ============================================================

-- Current stock with product details
CREATE VIEW v_stock AS
SELECT
  p.id,
  p.name,
  b.name              AS brand,
  c.name              AS category,
  cs.size_label       AS cylinder_size,
  p.product_type,
  p.buying_price,
  p.selling_price,
  (p.selling_price - p.buying_price) AS margin,
  ROUND(((p.selling_price - p.buying_price) / NULLIF(p.selling_price,0)) * 100, 1) AS margin_pct,
  p.stock_qty,
  p.low_stock_alert,
  CASE WHEN p.stock_qty <= p.low_stock_alert THEN TRUE ELSE FALSE END AS is_low_stock,
  p.is_refill,
  p.exchange_only
FROM products p
LEFT JOIN brands b         ON b.id = p.brand_id
LEFT JOIN categories c     ON c.id = p.category_id
LEFT JOIN cylinder_sizes cs ON cs.id = p.cylinder_size_id
WHERE p.is_active = TRUE
ORDER BY c.name, cs.weight_kg NULLS LAST, b.name;

-- Daily sales summary
CREATE VIEW v_daily_sales AS
SELECT
  DATE(created_at)              AS sale_date,
  COUNT(*)                      AS transaction_count,
  SUM(total)                    AS total_revenue,
  SUM(CASE WHEN payment_method = 'cash'   THEN total ELSE 0 END) AS cash_revenue,
  SUM(CASE WHEN payment_method = 'mpesa'  THEN total ELSE 0 END) AS mpesa_revenue,
  SUM(CASE WHEN payment_method = 'card'   THEN total ELSE 0 END) AS card_revenue,
  SUM(CASE WHEN payment_method = 'credit' THEN total ELSE 0 END) AS credit_revenue
FROM transactions
GROUP BY DATE(created_at)
ORDER BY sale_date DESC;

-- Outstanding credits summary
CREATE VIEW v_outstanding_credits AS
SELECT
  c.id,
  c.customer_name,
  c.customer_phone,
  c.items_summary,
  c.amount,
  c.paid_amount,
  (c.amount - c.paid_amount) AS balance_due,
  c.due_date,
  c.promise_note,
  c.status,
  CASE WHEN c.due_date < CURRENT_DATE THEN TRUE ELSE FALSE END AS is_overdue
FROM credits c
WHERE c.status IN ('pending','partial')
ORDER BY c.due_date;

-- Refill dispatch tracker
CREATE VIEW v_refill_dispatches AS
SELECT
  d.id,
  d.dispatch_date,
  d.expected_back,
  d.actual_back,
  d.supplier_name,
  d.status,
  cs.size_label,
  b.name            AS brand,
  di.qty_sent,
  di.qty_returned,
  di.buying_price_each,
  di.total_cost,
  d.notes,
  d.created_by
FROM refill_dispatches d
JOIN refill_dispatch_items di ON di.dispatch_id = d.id
LEFT JOIN cylinder_sizes cs   ON cs.id = di.cylinder_size_id
LEFT JOIN brands b             ON b.id = di.brand_id
ORDER BY d.dispatch_date DESC;


-- ============================================================
-- 13. HELPER FUNCTION — Recalculate Refill Buying Prices
--    Run this whenever you change the refill_bp_per_kg setting.
--    Usage: SELECT recalculate_refill_prices(170);
-- ============================================================
CREATE OR REPLACE FUNCTION recalculate_refill_prices(new_bp_per_kg NUMERIC)
RETURNS VOID AS $$
BEGIN
  -- Update the setting
  UPDATE settings SET value = new_bp_per_kg::TEXT, updated_at = NOW()
  WHERE key = 'refill_bp_per_kg';

  -- Recalculate buying_price for all refill products based on cylinder weight
  UPDATE products p
  SET
    buying_price = ROUND(new_bp_per_kg * cs.weight_kg, 2),
    updated_at   = NOW()
  FROM cylinder_sizes cs
  WHERE p.cylinder_size_id = cs.id
    AND p.is_refill = TRUE;
END;
$$ LANGUAGE plpgsql;

-- Example: to change the refill buying price to 200 KES/kg:
-- SELECT recalculate_refill_prices(200);


-- ============================================================
-- END OF SCHEMA
-- ============================================================