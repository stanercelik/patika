import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { productForLength } from "../_shared/path-access.ts";

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
      .select("id,kind,length_days,status").eq("id", body.pathId)
      .eq("user_id", user.id).maybeSingle();
    if (!path || path.kind !== "personalized" || !["active", "completed"].includes(path.status)) {
      return json({ code: "not_found" }, 404);
    }
    const { data: first } = await adminClient.from("path_steps")
      .select("completed_at").eq("path_id", path.id).eq("day", 1).maybeSingle();
    if (!first?.completed_at) return json({ code: "first_session_incomplete" }, 409);
    const { data: grant } = await adminClient.from("path_purchase_grants")
      .select("path_id").eq("path_id", path.id).eq("user_id", user.id)
      .is("revoked_at", null).maybeSingle();
    if (grant) return json({ status: "already_unlocked" });
    const productId = productForLength(path.length_days);
    if (!productId) return json({ code: "unsupported_path_length" }, 409);

    const { data: previous } = await adminClient.from("path_purchase_intents")
      .select("id,path_id,expires_at").eq("user_id", user.id).eq("product_id", productId)
      .is("fulfilled_at", null).gt("expires_at", new Date().toISOString())
      .order("created_at", { ascending: false }).limit(1).maybeSingle();
    if (previous?.path_id === path.id) {
      return json({ status: "ready", intentId: previous.id, productId });
    }
    if (previous) return json({ code: "another_purchase_pending" }, 409);
    const { data: intent, error } = await adminClient.from("path_purchase_intents")
      .insert({ user_id: user.id, path_id: path.id, product_id: productId })
      .select("id").single();
    if (error || !intent) throw new Error("intent_write_failed");
    return json({ status: "ready", intentId: intent.id, productId });
  } catch (error) {
    if (error instanceof Error && error.message === "unauthorized") return json({ code: "unauthorized" }, 401);
    return json({ code: "server_error" }, 500);
  }
});
