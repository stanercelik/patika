// TTS sağlayıcısı — PRD-Ek Oturum Motoru §3.2, §3.3.
//
// ## Aracısız
//
// Önceki hâl fal.ai üzerinden ElevenLabs'e gidiyordu: **iki** veri işleyici,
// iki DPA, iki aktarım analizi. TTS'e giden metin kullanıcının kendi cümlesini
// içeriyor (aha momenti tam olarak bu) ve bu GDPR Madde 9 anlamında sağlık
// verisi. Zinciri kısaltmak hem hukuki hem teknik hata yüzeyini yarıya indirdi.
//
// Ayrıca kuyruk + webhook mimarisi de gitti: doğrudan çağrı senkron, ses
// gövdede dönüyor. Webhook imza doğrulaması, yarış durumları ve "üretiliyor"
// yoklaması olmadan aynı iş yapılıyor.
//
// ## AB uç noktası
//
// `api.eu.residency.elevenlabs.io` — istek AB'den hiç çıkmıyor. Varsayılan bu;
// hesap bu uç noktayı desteklemiyorsa `ELEVENLABS_BASE_URL` ile geçilebilir,
// ama o zaman aktarım için ayrı bir hukuki dayanak gerekir.

export type VoicePreference = "feminine" | "masculine";
export type SpeechProsody = "neutral" | "soft" | "whisper";

export type SpeechRequest = {
  text: string;
  locale: string;
  voice: VoicePreference;
  /// Bloğun isteğe bağlı ses yönergesi, ör. "[whispers]". Varsayılan yok.
  audioTag?: string | null;
  prosody?: SpeechProsody;
  /// Dikiş yeri düzeltme (request stitching): önceki ve sonraki metin verilirse
  /// sağlayıcı parçanın tonunu komşularına göre ayarlıyor. Bir oturum onlarca
  /// parçadan oluştuğu için bu, parça sınırlarındaki ton sıçramasını engelliyor.
  previousText?: string | null;
  nextText?: string | null;
};

export type SpeechResult = {
  bytes: ArrayBuffer;
  contentType: string;
  modelId: string;
  durationMs: number;
};

const DEFAULT_BASE_URL = "https://api.eu.residency.elevenlabs.io";
// v3: v2 multilingual ile aynı fiyat, belirgin şekilde daha iyi ve
// `language_code` destekliyor (multilingual_v2 desteklemiyor).
export const DEFAULT_TTS_MODEL = "eleven_v3";
export const TTS_POLICY_VERSION = "patika-v3-natural-2026-09-09";

const PROSODY_TAGS: Readonly<Record<SpeechProsody, string | null>> = {
  neutral: null,
  // “Soft” is intentionally achieved through voice choice, punctuation and
  // Natural stability. ElevenLabs does not document a reliable [soft] tag.
  soft: null,
  whisper: "[whispers]",
};

export function sanitizeSpeechText(value: string): string {
  return value
    .replace(/[\[\]{}<>]/g, "")
    .replace(/[\u0000-\u001F\u007F]/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 800);
}

export function audioTagForProsody(value: unknown): string | null {
  if (typeof value !== "string" || !(value in PROSODY_TAGS)) return null;
  return PROSODY_TAGS[value as SpeechProsody];
}

function reviewedAudioTag(value: unknown): string | null {
  return value === "[whispers]" ? value : null;
}

export async function renditionHash(input: {
  text: string;
  locale: string;
  voice: VoicePreference;
  modelId: string;
  prosody?: string | null;
  previousText?: string | null;
  nextText?: string | null;
}): Promise<string> {
  const canonical = JSON.stringify({
    policy: TTS_POLICY_VERSION,
    text: sanitizeSpeechText(input.text),
    locale: languageCode(input.locale),
    voice: input.voice,
    model: input.modelId,
    prosody: input.prosody ?? "neutral",
    previous: sanitizeSpeechText(input.previousText ?? ""),
    next: sanitizeSpeechText(input.nextText ?? ""),
  });
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(canonical));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export function ttsConfigured(): boolean {
  return Deno.env.get("PATIKA_TTS_LIVE_ENABLED") === "true" &&
    !!Deno.env.get("ELEVENLABS_API_KEY");
}

export function voiceIdFor(voice: VoicePreference): string {
  const key = voice === "feminine" ? "ELEVENLABS_VOICE_FEMININE" : "ELEVENLABS_VOICE_MASCULINE";
  const id = Deno.env.get(key);
  if (!id) throw new Error("provider_configuration_required");
  return id;
}

/// Dil kodu ISO 639-1. Desteklenmeyen kod sağlayıcı tarafından yok sayılıyor,
/// bu yüzden yalnızca taşıdığımız iki dil gönderiliyor — yanlış bir kod
/// telaffuzu sessizce bozar.
export function languageCode(locale: string): string {
  return locale.toLowerCase().startsWith("tr") ? "tr" : "en";
}

export async function synthesize(request: SpeechRequest): Promise<SpeechResult> {
  if (!ttsConfigured()) throw new Error("provider_configuration_required");
  const key = Deno.env.get("ELEVENLABS_API_KEY")!;
  const baseUrl = Deno.env.get("ELEVENLABS_BASE_URL") ?? DEFAULT_BASE_URL;
  const modelId = Deno.env.get("ELEVENLABS_MODEL") ?? DEFAULT_TTS_MODEL;
  const voiceId = voiceIdFor(request.voice);

  const cleanText = sanitizeSpeechText(request.text);
  if (!cleanText) throw new Error("invalid_speech_text");
  const tag = audioTagForProsody(request.prosody) ?? reviewedAudioTag(request.audioTag);
  const text = tag ? `${tag} ${cleanText}` : cleanText;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 60_000);
  try {
    const response = await fetch(
      `${baseUrl}/v1/text-to-speech/${voiceId}/with-timestamps?output_format=mp3_44100_128`,
      {
        method: "POST",
        signal: controller.signal,
        headers: {
          "xi-api-key": key,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: JSON.stringify({
          text,
          model_id: modelId,
          language_code: languageCode(request.locale),
          previous_text: sanitizeSpeechText(request.previousText ?? "") || undefined,
          next_text: sanitizeSpeechText(request.nextText ?? "") || undefined,
          voice_settings: {
            // v3 kararlılığı üç kademe: 0.0 Creative, 0.5 Natural, 1.0 Robust.
            // Meditasyonda Creative eleniyor (halüsinasyon riski), Robust ise
            // sesi düzleştiriyor. Natural, orijinal kayda en yakın olan.
            stability: 0.5,
            similarity_boost: 0.8,
            // Abartı yok (Ton eki §2). Meditasyonda üslup vurgusu istemiyoruz.
            style: 0.0,
            use_speaker_boost: true,
          },
          // Sayı ve kısaltmalar sesli okunsun: "22:30" ekranda böyle yazılıyor
          // ama kulakta "yirmi iki otuz" olmalı.
          apply_text_normalization: "auto",
        }),
      },
    );

    if (response.status === 401) throw new Error("provider_configuration_required");
    if (!response.ok) {
      const errorPayload = await response.json().catch(() => null) as { detail?: { status?: string } } | null;
      const providerStatus = errorPayload?.detail?.status?.replace(/[^a-z0-9_]/gi, "_").slice(0, 80);
      throw new Error(`tts_request_failed_${response.status}${providerStatus ? `_${providerStatus}` : ""}`);
    }
    const payload = await response.json() as {
      audio_base64?: string;
      alignment?: { character_end_times_seconds?: number[] };
      normalized_alignment?: { character_end_times_seconds?: number[] };
    };
    if (!payload.audio_base64) throw new Error("tts_request_failed");
    const bytes = decodeBase64(payload.audio_base64);
    if (bytes.byteLength === 0) throw new Error("tts_request_failed");
    const endTimes = payload.normalized_alignment?.character_end_times_seconds ??
      payload.alignment?.character_end_times_seconds ?? [];
    const durationMs = Math.max(1, Math.round((endTimes.at(-1) ?? 0.001) * 1_000));
    return {
      bytes,
      contentType: "audio/mpeg",
      modelId,
      durationMs,
    };
  } finally {
    clearTimeout(timeout);
  }
}

function decodeBase64(value: string): ArrayBuffer {
  const decoded = atob(value);
  const bytes = new Uint8Array(decoded.length);
  for (let index = 0; index < decoded.length; index += 1) {
    bytes[index] = decoded.charCodeAt(index);
  }
  return bytes.buffer;
}
