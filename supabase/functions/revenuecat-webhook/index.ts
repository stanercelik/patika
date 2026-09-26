import { createClient } from "npm:@supabase/supabase-js@2.116.0";
import { productForLength } from "../_shared/path-access.ts";
import { requestIsAuthentic } from "../_shared/webhook-auth.ts";

type Event = {
  id?: string;
  type?: string;
  app_user_id?: string;
  product_id?: string;
  transaction_id?: string;
  purchased_at_ms?: number;
  expiration_at_ms?: number | null;
  entitlement_ids?: string[] | null;
  store?: string;
  environment?: string;
  cancel_reason?: string;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method_not_allowed", { status: 405 });
  try {
    const raw = await req.text();
    if (!await requestIsAuthentic(req.headers, raw)) {
      return new Response("unauthorized", { status: 401 });
    }
    const event = (JSON.parse(raw) as { event?: Event }).event;
    if (!event?.id || !event.type) return new Response("invalid_event", { status: 400 });
    if (!["NON_RENEWING_PURCHASE", "CANCELLATION", "REFUND_REVERSED"].includes(event.type)) {
      return new Response("ignored", { status: 200 });
    }
    if (!event.transaction_id || !event.app_user_id || !event.product_id ||
        !event.purchased_at_ms || !/^[0-9a-f-]{36}$/i.test(event.app_user_id)) {
      return new Response("invalid_event", { status: 400 });
    }
    const isPromo = event.type === "NON_RENEWING_PURCHASE" &&
      event.store === "PROMOTIONAL" &&
      event.entitlement_ids?.includes("shipaton_review") === true;
    if (isPromo) {
      const expiresAt = await verifiedPromo(event.app_user_id);
      if (!expiresAt) return new Response("promo_unverified", { status: 503 });
      return await applyEvent(event, "SHIPATON_PROMO", "shipaton_review", expiresAt);
    }
    if (![7, 14, 21, 28].some((n) => productForLength(n) === event.product_id) ||
        !["APP_STORE", "TEST_STORE"].includes(event.store ?? "")) {
      return new Response("invalid_event", { status: 400 });
    }
    // The signed webhook is authenticated, then the transaction is checked
    // against RevenueCat's server API before any path grant is written.
    const purchase = await verifiedPurchase(event.transaction_id);
    if (!purchase) return new Response("purchase_unverified", { status: 503 });
    const refundReason = ["CUSTOMER_SUPPORT", "DEVELOPER_INITIATED", "UNKNOWN"]
      .includes(event.cancel_reason ?? "");
    if (event.type === "CANCELLATION" && !refundReason) {
      return new Response("ignored", { status: 200 });
    }
    if (event.type === "CANCELLATION" && purchase.status === "owned") {
      return new Response("purchase_status_pending", { status: 503 });
    }
    if (event.type === "NON_RENEWING_PURCHASE" && purchase.status !== "owned") {
      return new Response("purchase_not_owned", { status: 409 });
    }
    if (event.type === "REFUND_REVERSED" && purchase.status !== "owned") {
      return new Response("purchase_status_pending", { status: 503 });
    }
    return await applyEvent(event, event.type, event.product_id);
  } catch {
    return new Response("processing_retry", { status: 503 });
  }
});

async function applyEvent(
  event: Event,
  type: string,
  productId: string,
  expiresAt?: string,
): Promise<Response> {
  const url = required("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SECRET_KEY") ?? required("SUPABASE_SERVICE_ROLE_KEY");
  const admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data, error } = await admin.rpc("apply_path_purchase_event", {
    p_event_id: event.id,
    p_event_type: type,
    p_user_id: event.app_user_id,
    p_product_id: productId,
    p_transaction_id: event.transaction_id,
    p_purchased_at: new Date(event.purchased_at_ms!).toISOString(),
    p_expiration_at: expiresAt ?? null,
  });
  if (error) {
    console.error("path_purchase_event_failed", error.code);
    return new Response("processing_retry", { status: 503 });
  }
  return new Response(String(data ?? "processed"), { status: 200 });
}

async function verifiedPromo(userId: string): Promise<string | null> {
  const key = required("REVENUECAT_V1_SECRET_API_KEY");
  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`,
    { headers: { Authorization: `Bearer ${key}` } },
  );
  if (!response.ok) return null;
  const body = await response.json() as {
    subscriber?: { entitlements?: Record<string, { expires_date?: string | null }> };
  };
  const expiration = body.subscriber?.entitlements?.shipaton_review?.expires_date;
  return expiration && new Date(expiration).getTime() > Date.now() ? expiration : null;
}

function required(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error("server_configuration_missing");
  return value;
}
