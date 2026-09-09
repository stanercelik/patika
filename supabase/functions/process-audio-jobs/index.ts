import { createClient } from "npm:@supabase/supabase-js@2.116.0";
import { requireEnv } from "../_shared/auth.ts";
import { processAudioJob } from "../_shared/audio-worker.ts";
import { corsHeaders, json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);
  const serviceKey = Deno.env.get("SUPABASE_SECRET_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceKey || req.headers.get("Authorization") !== `Bearer ${serviceKey}`) return json({ code: "unauthorized" }, 401);

  const adminClient = createClient(requireEnv("SUPABASE_URL"), serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const task = drain(adminClient);
  const runtime = (globalThis as unknown as { EdgeRuntime?: { waitUntil(promise: Promise<unknown>): void } }).EdgeRuntime;
  if (runtime) runtime.waitUntil(task);
  else await task;
  return json({ status: "accepted" }, 202);
});

async function drain(adminClient: any) {
  const { data: messages, error } = await adminClient.rpc("read_audio_jobs", {
    visibility_timeout_seconds: 300,
    quantity: 1,
  });
  if (error) throw new Error("queue_read_failed");
  for (const message of messages ?? []) {
    try {
      const jobId = message?.message?.job_id;
      if (typeof jobId !== "string") throw new Error("invalid_queue_message");
      await processAudioJob(adminClient, jobId);
    } finally {
      await adminClient.rpc("archive_audio_job", { message_id: message.msg_id });
    }
  }
}
