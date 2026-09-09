import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { DEFAULT_TTS_MODEL, renditionHash, ttsConfigured } from "../_shared/tts.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  try {
    const { user, adminClient } = await authenticate(req);
    const body = await req.json();
    if (typeof body?.pathStepId !== "string") return json({ code: "invalid_request" }, 400);
    const idempotencyKey = req.headers.get("Idempotency-Key")?.trim();
    if (!idempotencyKey || idempotencyKey.length < 16 || idempotencyKey.length > 200) {
      return json({ code: "invalid_idempotency_key" }, 400);
    }
    if (!ttsConfigured()) return json({ code: "provider_configuration_required" }, 503);

    const { data: step } = await adminClient.from("path_steps")
      .select("id,path_id,block_ids,slot_copy")
      .eq("id", body.pathStepId).eq("user_id", user.id).maybeSingle();
    if (!step) return json({ code: "not_found" }, 404);
    const [{ data: path }, { data: profile }] = await Promise.all([
      adminClient.from("program_paths").select("id,kind").eq("id", step.path_id).eq("user_id", user.id).single(),
      adminClient.from("profiles").select("locale,voice_preference").eq("user_id", user.id).maybeSingle(),
    ]);
    if (!path) return json({ code: "not_found" }, 404);

    const locale = typeof profile?.locale === "string" && profile.locale.toLowerCase().startsWith("tr") ? "tr" : "en";
    const voice = profile?.voice_preference === "masculine" ? "masculine" : "feminine";
    const digest = await renditionHash({
      text: JSON.stringify({ kind: path.kind, blocks: step.block_ids, slots: path.kind === "prepared" ? {} : step.slot_copy }),
      locale,
      voice,
      modelId: DEFAULT_TTS_MODEL,
      prosody: "manifest-v1",
    });
    const { data: readyManifest } = await adminClient.from("session_manifests")
      .select("id").eq("path_step_id", step.id).eq("rendition_hash", digest).maybeSingle();
    if (readyManifest) return json({ status: "ready", manifestId: readyManifest.id });

    const { data: prior } = await adminClient.from("generation_jobs")
      .select("id,path_step_id,status")
      .eq("user_id", user.id).eq("idempotency_key", idempotencyKey).maybeSingle();
    if (prior && prior.path_step_id !== step.id) return json({ code: "idempotency_conflict" }, 409);

    let jobId = prior?.id as string | undefined;
    if (prior) {
      if (prior.status === "blocked") return json({ code: "content_review_required" }, 503);
      if (prior.status === "failed" || prior.status === "succeeded") {
        await adminClient.from("generation_jobs").update({
          status: "queued", rendition_hash: digest, completed_at: null, last_error_code: null,
        }).eq("id", prior.id);
      }
    } else {
      const { data: job, error: jobError } = await adminClient.from("generation_jobs").insert({
        user_id: user.id,
        path_id: path.id,
        path_step_id: step.id,
        kind: "audio",
        provider: "elevenlabs",
        status: "queued",
        rendition_hash: digest,
        idempotency_key: idempotencyKey,
      }).select("id").single();
      if (jobError || !job) throw new Error("database_write_failed");
      jobId = job.id;
    }

    await adminClient.from("path_steps").update({ audio_status: "processing" }).eq("id", step.id);
    const { error: queueError } = await adminClient.rpc("enqueue_audio_job", { job_id: jobId });
    if (queueError) throw new Error("queue_write_failed");
    wakeWorker();
    return json({ status: "queued", jobId }, 202);
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    if (code === "provider_configuration_required") return json({ code }, 503);
    return json({ code: "server_error" }, 500);
  }
});

function wakeWorker() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SECRET_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return;
  const task = fetch(`${url}/functions/v1/process-audio-jobs`, {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: "{}",
  }).catch(() => undefined);
  (globalThis as unknown as { EdgeRuntime?: { waitUntil(promise: Promise<unknown>): void } })
    .EdgeRuntime?.waitUntil(task);
}
