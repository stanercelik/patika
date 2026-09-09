import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { synthesize, ttsConfigured, type VoicePreference } from "../_shared/tts.ts";

// Bir adımın **kişisel** seslerini üretir: yalnızca slot metinleri.
//
// Blokların sabit metinleri buraya hiç gelmez — onlar paylaşılan `block_audio`
// deposunda, bir kez render edilmiş hâlde duruyor (PRD-Ek Oturum Motoru §5.2).
// Burada üretilen, oturumun ~%53'ü olan çerçeve.
//
// **Senkron.** Eski hâl kuyruk + webhook'tu; doğrudan çağrıda ses gövdede
// dönüyor ve imza doğrulama, yarış durumu, yoklama katmanları gereksiz kaldı.

const SLOT_ORDER = ["step_opening", "technique_bridge", "mid_bridge", "step_closing"] as const;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  try {
    const { user, adminClient } = await authenticate(req);
    const body = await req.json();
    if (typeof body?.pathStepId !== "string") return json({ code: "invalid_request" }, 400);
    const idempotencyKey = req.headers.get("Idempotency-Key")?.trim();
    if (!idempotencyKey || idempotencyKey.length < 16) return json({ code: "invalid_idempotency_key" }, 400);

    // Sağlayıcı yapılandırılmamışsa **oturum durmaz**: istemci sessiz sürüme
    // düşer. Ses ek, oturumun kendisi değil.
    if (!ttsConfigured()) return json({ code: "provider_configuration_required" }, 503);

    const { data: step } = await adminClient
      .from("path_steps")
      .select("id,slot_copy,audio_status")
      .eq("id", body.pathStepId)
      .eq("user_id", user.id)
      .maybeSingle();
    if (!step) return json({ code: "not_found" }, 404);
    if (step.audio_status === "ready") return json({ status: "ready" });

    const { data: profile } = await adminClient
      .from("profiles")
      .select("locale,voice_preference")
      .eq("user_id", user.id)
      .maybeSingle();
    const locale: string = profile?.locale ?? "tr-TR";
    const voice: VoicePreference = profile?.voice_preference === "masculine" ? "masculine" : "feminine";

    // Yalnızca dolu slotlar, şemadaki sırayla. Sıra önemli: dikiş yeri
    // düzeltmesi (previous/next) komşu metinleri istiyor.
    const slots = SLOT_ORDER
      .map((name) => ({ name, text: (step.slot_copy ?? {})[name] }))
      .filter((slot): slot is { name: string; text: string } =>
        typeof slot.text === "string" && slot.text.trim().length > 0
      );
    if (slots.length === 0) return json({ code: "audio_copy_unavailable" }, 422);
    const totalChars = slots.reduce((sum, slot) => sum + slot.text.length, 0);
    if (totalChars > 2400) return json({ code: "audio_copy_unavailable" }, 422);

    await adminClient.from("path_steps")
      .update({ audio_status: "processing" }).eq("id", step.id).eq("user_id", user.id);

    try {
      for (const [index, slot] of slots.entries()) {
        // Zaten üretilmişse atla — kısmi başarısızlıktan sonra tekrar
        // çağrıldığında baştan ödeme yapmamak için.
        const { data: existing } = await adminClient
          .from("audio_assets")
          .select("id")
          .eq("path_step_id", step.id)
          .eq("slot_name", slot.name)
          .maybeSingle();
        if (existing) continue;

        const speech = await synthesize({
          text: slot.text,
          locale,
          voice,
          previousText: slots[index - 1]?.text ?? null,
          nextText: slots[index + 1]?.text ?? null,
        });

        const storagePath = `${user.id}/${step.id}/${slot.name}.mp3`;
        const { error: uploadError } = await adminClient.storage
          .from("private_audio")
          .upload(storagePath, speech.bytes, { contentType: speech.contentType, upsert: true });
        if (uploadError) throw new Error("storage_write_failed");

        const { error: insertError } = await adminClient.from("audio_assets").insert({
          user_id: user.id,
          path_step_id: step.id,
          slot_name: slot.name,
          storage_path: storagePath,
          content_type: speech.contentType,
          model_id: speech.modelId,
          voice_preference: voice,
          locale,
        });
        if (insertError) throw new Error("database_write_failed");
      }
    } catch (error) {
      await adminClient.from("path_steps")
        .update({ audio_status: "failed" }).eq("id", step.id).eq("user_id", user.id);
      throw error;
    }

    await adminClient.from("path_steps")
      .update({ audio_status: "ready" }).eq("id", step.id).eq("user_id", user.id);
    await adminClient.from("generation_jobs").insert({
      user_id: user.id,
      path_id: null,
      kind: "audio",
      provider: "elevenlabs",
      status: "succeeded",
      idempotency_key: idempotencyKey,
      completed_at: new Date().toISOString(),
    });

    return json({ status: "ready" });
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    if (code === "provider_configuration_required") return json({ code }, 503);
    if (code === "tts_request_failed") return json({ code }, 502);
    return json({ code: "server_error" }, 500);
  }
});
