import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { submitFalTTS } from "../_shared/providers.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);
  try {
    const { user, adminClient } = await authenticate(req);
    const body = await req.json();
    if (typeof body?.pathStepId !== "string") return json({ code: "invalid_request" }, 400);
    const idempotencyKey = req.headers.get("Idempotency-Key")?.trim();
    if (!idempotencyKey || idempotencyKey.length < 16) return json({ code: "invalid_idempotency_key" }, 400);

    const { data: step } = await adminClient
      .from("path_steps")
      .select("id,slot_copy,audio_status")
      .eq("id", body.pathStepId)
      .eq("user_id", user.id)
      .single();
    if (!step) return json({ code: "not_found" }, 404);
    if (step.audio_status === "ready") return json({ status: "ready" });
    const text = ["step_opening", "technique_bridge", "mid_bridge", "step_closing"]
      .map((key) => step.slot_copy?.[key])
      .filter((value) => typeof value === "string")
      .join("\n");
    if (!text || text.length > 1800) return json({ code: "audio_copy_unavailable" }, 422);

    const webhookUrl = `${Deno.env.get("SUPABASE_URL")}/functions/v1/fal-webhook`;
    const requestId = await submitFalTTS(text, webhookUrl);
    const { error } = await adminClient.from("generation_jobs").insert({
      user_id: user.id,
      path_id: null,
      kind: "audio",
      provider: "fal",
      provider_request_id: requestId,
      status: "processing",
      idempotency_key: idempotencyKey,
      last_error_code: `step:${step.id}`,
    });
    if (error) throw new Error("database_write_failed");
    await adminClient.from("path_steps").update({ audio_status: "processing" }).eq("id", step.id).eq("user_id", user.id);
    return json({ status: "processing" }, 202);
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    if (["provider_configuration_required", "fal_configuration_missing"].includes(code)) return json({ code: "provider_configuration_required" }, 503);
    return json({ code: "server_error" }, 500);
  }
});
