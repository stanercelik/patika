import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { synthesize, renditionHash, DEFAULT_TTS_MODEL } from "../_shared/tts.ts";
import catalog from "./catalog.json" with { type: "json" };

// Publishing tool only. The shipped app never triggers paid synthesis.
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);
  try {
    const { user, adminClient } = await authenticate(req);
    const publisherID = Deno.env.get("PATIKA_CONTENT_PUBLISHER_ID");
    if (!publisherID || user.id !== publisherID) return json({ code: "forbidden" }, 403);
    const { stepID, voice, part } = await req.json();
    if (!["feminine", "masculine"].includes(voice) || !["guidance", "closing"].includes(part)) return json({ code: "invalid_request" }, 400);
    const step = catalog.paths.flatMap(p => p.steps).find(s => s.id === stepID);
    if (!step) return json({ code: "not_found" }, 404);
    const text = part === "closing" ? step.closing.en : step.guidance.en;
    const hash = await renditionHash({ text, locale: "en", voice, modelId: DEFAULT_TTS_MODEL, prosody: "soft" });
    const base = `discover/v1/${hash}`;
    const bucket = adminClient.storage.from("block_audio");
    const { data: cached } = await bucket.download(`${base}.json`);
    if (cached) return json(JSON.parse(await cached.text()));
    const speech = await synthesize({ text, locale: "en", voice, prosody: "soft" });
    const { error } = await bucket.upload(`${base}.mp3`, speech.bytes, { contentType: "audio/mpeg", upsert: true });
    if (error) throw new Error("storage_write_failed");
    const result = { url: bucket.getPublicUrl(`${base}.mp3`).data.publicUrl, durationMs: speech.durationMs, hash, voice, part, locale: "en", model: speech.modelId };
    const { error: metadataError } = await bucket.upload(`${base}.json`, JSON.stringify(result), { contentType: "application/json", upsert: true });
    if (metadataError) throw new Error("metadata_write_failed");
    return json(result);
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    return json({ code }, code === "unauthorized" ? 401 : 502);
  }
});
