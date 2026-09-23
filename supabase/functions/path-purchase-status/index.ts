import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";

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
    const { data: grant, error } = await adminClient.from("path_purchase_grants")
      .select("path_id").eq("path_id", path.id).eq("user_id", user.id)
      .is("revoked_at", null).maybeSingle();
    if (error) throw new Error("grant_read_failed");
    return json({ status: grant ? "unlocked" : "locked" });
  } catch (error) {
    if (error instanceof Error && error.message === "unauthorized") return json({ code: "unauthorized" }, 401);
    return json({ code: "server_error" }, 500);
  }
});
