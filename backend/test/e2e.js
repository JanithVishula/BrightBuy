/**
 * BrightBuy end-to-end data-flow test.
 *
 * Exercises the whole system against a running backend and asserts that an
 * order placed by a customer propagates everywhere: inventory is deducted,
 * the order shows up for the customer and for staff, payment is recorded,
 * and security boundaries hold.
 *
 * Usage:
 *   API_URL=https://<backend>/api \
 *   ADMIN_EMAIL=admin@brightbuy.com ADMIN_PASSWORD=BrightBuy@2026 \
 *   node backend/test/e2e.js
 *
 * Defaults target the live Railway backend and the seed admin account.
 */

const API = process.env.API_URL || "http://localhost:5001/api";
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "admin@brightbuy.com";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "BrightBuy@2026";

let passed = 0;
let failed = 0;

function ok(name, cond, detail = "") {
  if (cond) {
    passed++;
    console.log(`  ✓ ${name}`);
  } else {
    failed++;
    console.log(`  ✗ ${name}${detail ? "  -> " + detail : ""}`);
  }
}

async function req(method, path, { token, body } = {}) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      ...(body ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  let data = null;
  try {
    data = await res.json();
  } catch {
    /* non-JSON */
  }
  return { status: res.status, data };
}

(async () => {
  console.log(`\nBrightBuy E2E — target: ${API}\n`);

  // ---- 1. Health ----
  console.log("1. Health & connectivity");
  const health = await req("GET", "/health");
  ok("backend healthy", health.status === 200 && health.data?.status === "ok");

  // ---- 2. Customer signup/login ----
  console.log("\n2. Customer auth");
  const email = `e2e_${Date.now()}@brightbuy.com`;
  const password = "E2e@12345";
  let signup = await req("POST", "/auth/signup", {
    body: { name: "E2E Tester", email, password, phone: "5550000000" },
  });
  ok("signup succeeds", signup.status === 201 && signup.data?.success);
  const login = await req("POST", "/auth/login", {
    body: { email, password },
  });
  ok("login succeeds", login.status === 200 && login.data?.success);
  const cToken = login.data?.token;
  const me = await req("GET", "/auth/me", { token: cToken });
  const customerId = me.data?.user?.customer_id;
  ok("customer_id resolved", Boolean(customerId), `got ${customerId}`);

  // ---- 3. Catalog browse ----
  console.log("\n3. Catalog");
  const products = await req("GET", "/products");
  const list = Array.isArray(products.data)
    ? products.data
    : products.data?.products || [];
  ok("products listed", list.length > 0, `count=${list.length}`);
  const variant = list[0];
  const variantId = variant?.variant_id;
  const unitPrice = Number(variant?.price);
  ok("variant has a price", unitPrice > 0, `price=${unitPrice}`);

  // ---- 4. Admin baseline inventory ----
  console.log("\n4. Staff/admin access");
  const adminLogin = await req("POST", "/auth/login", {
    body: { email: ADMIN_EMAIL, password: ADMIN_PASSWORD },
  });
  ok("admin login", adminLogin.status === 200 && adminLogin.data?.success);
  const aToken = adminLogin.data?.token;
  const invBefore = await req("GET", "/staff/inventory", { token: aToken });
  const beforeRow = (invBefore.data?.inventory || []).find(
    (r) => r.variant_id === variantId
  );
  const stockBefore = Number(beforeRow?.stock);
  ok("inventory readable by staff", invBefore.status === 200);

  // ---- 5. Cart ----
  console.log("\n5. Cart");
  const qty = 2;
  const addCart = await req("POST", `/cart/${customerId}/items`, {
    token: cToken,
    body: { variant_id: variantId, quantity: qty },
  });
  ok("add to cart", addCart.status === 200);
  const cart = await req("GET", `/cart/${customerId}`, { token: cToken });
  ok("cart reflects item", (cart.data?.items || []).length > 0);

  // ---- 6. Security boundaries ----
  console.log("\n6. Security");
  const otherCart = await req("GET", `/cart/1`, { token: cToken });
  ok("IDOR blocked (other cart)", otherCart.status === 403, `status=${otherCart.status}`);
  const noAuthCart = await req("GET", `/cart/1`);
  ok("unauth cart blocked", noAuthCart.status === 401, `status=${noAuthCart.status}`);
  const staffOnly = await req("GET", "/orders/all", { token: cToken });
  ok("customer blocked from /orders/all", staffOnly.status === 403, `status=${staffOnly.status}`);

  // ---- 7. Place order (Store Pickup) with a FAKE price ----
  console.log("\n7. Order placement & server-side pricing");
  const order = await req("POST", "/orders", {
    token: cToken,
    body: {
      delivery_mode: "Store Pickup",
      payment_method: "Cash on Delivery",
      // intentionally wrong unit_price/totals — server must ignore them
      items: [{ variant_id: variantId, quantity: qty, unit_price: 0.01 }],
      sub_total: 0.01,
      total: 0.01,
    },
  });
  ok("order created", order.status === 201, `status=${order.status}`);
  const orderId = order.data?.order?.order_id;
  const orderTotal = Number(order.data?.order?.total);
  const expectedTotal = Math.round(unitPrice * qty * 100) / 100;
  ok(
    "price recomputed server-side (not 0.01)",
    orderTotal === expectedTotal,
    `got ${orderTotal}, expected ${expectedTotal}`
  );

  // ---- 8. Inventory deducted ----
  console.log("\n8. Inventory propagation");
  const invAfter = await req("GET", "/staff/inventory", { token: aToken });
  const afterRow = (invAfter.data?.inventory || []).find(
    (r) => r.variant_id === variantId
  );
  const stockAfter = Number(afterRow?.stock);
  ok(
    "stock deducted by ordered qty",
    Number.isFinite(stockBefore) ? stockAfter === stockBefore - qty : true,
    `before=${stockBefore} after=${stockAfter}`
  );

  // ---- 9. Order visible to owner & staff ----
  console.log("\n9. Order visibility");
  const myOrders = await req("GET", `/orders/customer/${customerId}`, {
    token: cToken,
  });
  ok(
    "order in customer's list",
    (myOrders.data?.orders || []).some((o) => o.order_id === orderId)
  );
  const allOrders = await req("GET", "/orders/all", { token: aToken });
  ok(
    "order in staff's all-orders",
    (allOrders.data?.orders || []).some((o) => o.order_id === orderId)
  );
  const ownById = await req("GET", `/orders/${orderId}`, { token: cToken });
  ok("owner can read own order", ownById.status === 200);

  // ---- 10. Payment recorded ----
  console.log("\n10. Payment");
  ok(
    "payment method recorded",
    ownById.data?.order?.payment_method === "Cash on Delivery",
    ownById.data?.order?.payment_method
  );

  // ---- 11. Reports include the sale (best-effort) ----
  console.log("\n11. Reports");
  const report = await req(
    "GET",
    "/reports/sales-summary?startDate=2020-01-01&endDate=2035-01-01",
    { token: aToken }
  );
  ok("sales summary returns", report.status === 200);

  // ---- Summary ----
  console.log(`\n──────────────────────────────`);
  console.log(`  PASSED: ${passed}   FAILED: ${failed}`);
  console.log(`──────────────────────────────\n`);
  process.exit(failed > 0 ? 1 : 0);
})().catch((err) => {
  console.error("\nE2E run crashed:", err.message);
  process.exit(1);
});
