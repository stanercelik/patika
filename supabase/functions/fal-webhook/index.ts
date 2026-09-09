import { createClient } from "npm:@supabase/supabase-js@2.116.0";
import { json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);
  const raw = new Uint8Array(await req.arrayBuffer());
  if (!(await verifyFalSignature(req.headers, raw))) return json({ code: "invalid_signature" }, 401);
  try {
    const event = JSON.parse(new TextDecoder().decode(raw));
    if (typeof event.request_id !== "string") return json({ code: "invalid_request" }, 400);
    const url = Deno.env.get("SUPABASE_URL") ?? "";
    const key = Deno.env.get("SUPABASE_SECRET_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!url || !key) throw new Error("server_configuration_missing");
    const admin = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: job } = await admin.from("generation_jobs").select("id,user_id,last_error_code").eq("provider_request_id", event.request_id).single();
    if (!job) return json({ code: "not_found" }, 404);
    const stepId = typeof job.last_error_code === "string" && job.last_error_code.startsWith("step:")
      ? job.last_error_code.slice(5) : null;
    const audioUrl = event.status === "OK" ? event.payload?.audio?.url : null;
    if (!stepId || typeof audioUrl !== "string") {
      await admin.from("generation_jobs").update({ status: "failed", last_error_code: "provider_failed", completed_at: new Date().toISOString() }).eq("id", job.id);
      if (stepId) await admin.from("path_steps").update({ audio_status: "failed" }).eq("id", stepId);
      return json({ ok: true });
    }
    const download = await fetch(audioUrl, { redirect: "follow" });
    const contentType = download.headers.get("content-type")?.split(";")[0] ?? "audio/mpeg";
    const length = Number(download.headers.get("content-length") ?? 0);
    if (!download.ok || !["audio/mpeg", "audio/wav", "audio/mp4"].includes(contentType) || length > 50 * 1024 * 1024) {
      throw new Error("invalid_audio_response");
    }
    const bytes = await download.arrayBuffer();
    if (bytes.byteLength > 50 * 1024 * 1024) throw new Error("invalid_audio_response");
    const extension = contentType === "audio/wav" ? "wav" : contentType === "audio/mp4" ? "m4a" : "mp3";
    const storagePath = `${job.user_id}/${stepId}/${crypto.randomUUID()}.${extension}`;
    const { error: uploadError } = await admin.storage.from("private_audio").upload(storagePath, bytes, { contentType, upsert: false });
    if (uploadError) throw new Error("storage_write_failed");
    await Promise.all([
      admin.from("audio_assets").insert({ user_id: job.user_id, path_step_id: stepId, storage_path: storagePath, content_type: contentType }),
      admin.from("path_steps").update({ audio_status: "ready" }).eq("id", stepId),
      admin.from("generation_jobs").update({ status: "succeeded", last_error_code: null, completed_at: new Date().toISOString() }).eq("id", job.id),
    ]);
    return json({ ok: true });
  } catch {
    return json({ code: "server_error" }, 500);
  }
});

async function verifyFalSignature(headers: Headers, body: Uint8Array): Promise<boolean> {
  const requestId = headers.get("X-Fal-Webhook-Request-Id");
  const userId = headers.get("X-Fal-Webhook-User-Id");
  const timestamp = headers.get("X-Fal-Webhook-Timestamp");
  const signatureHex = headers.get("X-Fal-Webhook-Signature");
  if (!requestId || !userId || !timestamp || !signatureHex || !/^\d+$/.test(timestamp) || !/^[0-9a-f]+$/i.test(signatureHex)) return false;
  if (Math.abs(Date.now() / 1000 - Number(timestamp)) > 300) return false;
  const digest = [...new Uint8Array(await crypto.subtle.digest("SHA-256", body))]
    .map((byte) => byte.toString(16).padStart(2, "0")).join("");
  const message = new TextEncoder().encode([requestId, userId, timestamp, digest].join("\n"));
  const signature = new Uint8Array(signatureHex.match(/.{2}/g)!.map((byte) => parseInt(byte, 16)));
  const response = await fetch("https://rest.fal.ai/.well-known/jwks.json");
  if (!response.ok) return false;
  const jwks = await response.json();
  for (const jwk of jwks.keys ?? []) {
    try {
      const key = await crypto.subtle.importKey("jwk", jwk, { name: "Ed25519" }, false, ["verify"]);
      if (await crypto.subtle.verify({ name: "Ed25519" }, key, signature, message)) return true;
    } catch { /* try the next advertised key */ }
  }
  return false;
}
