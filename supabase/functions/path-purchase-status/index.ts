import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { ownedPurchases } from "../_shared/revenuecat.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);
  try {
    const { user, adminClient } = await authenticate(req);
    const body = await req.json();
    if (typeof body?.pathId !== "string" || !/^[0-9a-f-]{36}$/i.test(body.pathId)) {
      return json({ code: "invalid_request" }, 400);
    }
    const { data: path } = await adminClient.from("program_paths")
      .select("id,kind,length_days").eq("id", body.pathId).eq("user_id", user.id).maybeSingle();
    if (!path) return json({ code: "not_found" }, 404);
    if (path.kind === "prepared") return json({ status: "unlocked" });
    if (await hasActiveGrant(adminClient, path.id, user.id)) return json({ status: "unlocked" });
    // The webhook can lag by minutes. If this path has an open purchase intent,
    // confirm the owned transaction with RevenueCat now and apply it; the later
    // webhook for the same transaction is recorded as already applied.
    if (await applyOwnedPurchase(adminClient, path.id, user.id)) {
      return json({ status: (await hasActiveGrant(adminClient, path.id, user.id)) ? "unlocked" : "locked" });
    }
    return json({ status: "locked" });
  } catch (error) {
    if (error instanceof Error && error.message === "unauthorized") return json({ code: "unauthorized" }, 401);
    return json({ code: "server_error" }, 500);
  }
});

// deno-lint-ignore no-explicit-any
type Admin = any;

async function hasActiveGrant(adminClient: Admin, pathId: string, userId: string): Promise<boolean> {
  const { data: grant, error } = await adminClient.from("path_purchase_grants")
    .select("path_id,expires_at").eq("path_id", pathId).eq("user_id", userId)
    .is("revoked_at", null).maybeSingle();
  if (error) throw new Error("grant_read_failed");
  return !!grant && (!grant.expires_at || new Date(grant.expires_at).getTime() > Date.now());
}

async function applyOwnedPurchase(adminClient: Admin, pathId: string, userId: string): Promise<boolean> {
  const { data: intent } = await adminClient.from("path_purchase_intents")
    .select("product_id,created_at,expires_at").eq("path_id", pathId).eq("user_id", userId)
    .is("fulfilled_at", null).is("cancelled_at", null)
    .order("created_at", { ascending: false }).limit(1).maybeSingle();
  if (!intent) return false;
  const earliest = new Date(new Date(intent.created_at).getTime() - 2 * 60_000).toISOString();
  const candidates = (await ownedPurchases(userId, intent.product_id))
    .filter((purchase) => purchase.purchasedAt >= earliest && purchase.purchasedAt <= intent.expires_at);
  for (const purchase of candidates) {
    const { data, error } = await adminClient.rpc("apply_path_purchase_event", {
      p_event_id: `status:${purchase.transactionId}`,
      p_event_type: "NON_RENEWING_PURCHASE",
      p_user_id: userId,
      p_product_id: purchase.storeProductId,
      p_transaction_id: purchase.transactionId,
      p_purchased_at: purchase.purchasedAt,
      p_expiration_at: null,
    });
    if (error) {
      console.error("status_purchase_apply_failed", error.message);
      continue;
    }
    if (data === "processed" || data === "duplicate" || data === "already_applied") return true;
  }
  return false;
}
