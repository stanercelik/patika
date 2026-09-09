import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { DEFAULT_TTS_MODEL, renditionHash, synthesize, type VoicePreference } from "../_shared/tts.ts";

const PREVIEW_COPY = {
  tr: "Burada acele etmene gerek yok. Bir nefes al ve sesin sana nasıl eşlik ettiğini fark et.",
  en: "There is no need to hurry here. Take one breath and notice how this voice stays with you.",
} as const;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);
  try {
    const { adminClient } = await authenticate(req);
    const body = await req.json();
    const locale = body?.locale === "tr" ? "tr" : body?.locale === "en" ? "en" : null;
    const voice: VoicePreference | null = body?.voice === "feminine" || body?.voice === "masculine" ? body.voice : null;
    if (!locale || !voice || body?.kind !== "preview") return json({ code: "invalid_request" }, 400);

    const text = PREVIEW_COPY[locale];
    const digest = await renditionHash({ text, locale, voice, modelId: DEFAULT_TTS_MODEL, prosody: "soft" });
    const { data: existing } = await adminClient.from("voice_previews")
      .select("id,storage_path,duration_ms").eq("rendition_hash", digest).maybeSingle();
    if (existing) return previewResponse(adminClient, existing);

    const speech = await synthesize({ text, locale, voice, prosody: "soft" });
    const storagePath = `${locale}/${voice}/${digest}.mp3`;
    const { error: uploadError } = await adminClient.storage.from("voice_previews")
      .upload(storagePath, speech.bytes, { contentType: speech.contentType, upsert: false });
    if (uploadError && !String(uploadError.message).toLowerCase().includes("already exists")) throw new Error("storage_write_failed");
    const { data: stored, error: storeError } = await adminClient.from("voice_previews").upsert({
      locale,
      voice_preference: voice,
      storage_path: storagePath,
      content_type: speech.contentType,
      duration_ms: speech.durationMs,
      model_id: speech.modelId,
      rendition_hash: digest,
    }, { onConflict: "locale,voice_preference" }).select("id,storage_path,duration_ms").single();
    if (storeError || !stored) throw new Error("database_write_failed");
    return previewResponse(adminClient, stored);
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    if (code === "provider_configuration_required") return json({ code }, 503);
    if (code.startsWith("tts_request_failed_")) return json({ code }, 502);
    return json({ code: "server_error" }, 500);
  }
});

function previewResponse(adminClient: Awaited<ReturnType<typeof authenticate>>["adminClient"], row: { id: string; storage_path: string; duration_ms: number }) {
  const { data } = adminClient.storage.from("voice_previews").getPublicUrl(row.storage_path);
  return json({ status: "ready", assetId: row.id, url: data.publicUrl, durationMs: row.duration_ms });
}
