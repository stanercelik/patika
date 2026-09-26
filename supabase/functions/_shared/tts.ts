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
// ## Uç nokta: standart (ABD) — AB ikametgahı ertelendi
//
// Tasarım AB uç noktasını (`api.eu.residency.elevenlabs.io`) varsayıyordu.
// **Ölçüldü (2026-09-09): veri ikametgahı ElevenLabs'te Enterprise özelliği** ve
// ürün sahibi kararı kullandığın kadar öde modeliyle ilerlemek. Bu yüzden
// varsayılan standart uç nokta.
//
// Bunun bedeli açıkça yazılsın: TTS'e giden metin kullanıcının kendi cümlesini
// içeriyor ve bu GDPR Madde 9 anlamında sağlık verisi. Standart uç noktada bu
// veri AB dışına çıkıyor; aktarım için ayrı bir hukuki dayanak (ElevenLabs DPA +
// SCC) ve gizlilik metninde açık bir satır gerekiyor. Zincirde hâlâ tek işleyici
// var — aracı kaldırıldı, değişen yalnızca bölge.
//
// `ELEVENLABS_BASE_URL` ile AB uç noktasına dönmek tek secret'lık iş; plan
// yükseldiğinde kod değişmiyor.

import { mp3DurationMs } from "./mp3.ts";

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
  /// Dosyanın gerçek çözülmüş uzunluğu (`mp3DurationMs`). Bir **planlama** değeri:
  /// istemci zamanlamayı yüklediği dosyanın kendi ölçümüne göre yapar.
  durationMs: number;
  /// Sağlayıcının konuşmadan önce bıraktığı sessizlik. Hizalamanın ilk karakter
  /// başlangıcından. Oturum motoru bunu bağlantı boşluğundan düşer: dolgu
  /// planlanan boşluğun **üstüne binmek** yerine içinde soğurulur.
  leadSilenceMs: number;
  /// Son karakterden dosyanın sonuna kadar olan sessizlik.
  tailSilenceMs: number;
};

const DEFAULT_BASE_URL = "https://api.elevenlabs.io";
// v3: v2 multilingual ile aynı fiyat, belirgin şekilde daha iyi ve
// `language_code` destekliyor (multilingual_v2 desteklemiyor).
export const DEFAULT_TTS_MODEL = "eleven_v3";
// Baytları değiştirebilecek her karar burada sürümlenir; rendition anahtarı bunu
// içeriyor, yani sürüm artınca önbelleğin tamamı doğru şekilde ıskalar.
// v3-paced: yerel son işlem (kırpma + -16 LUFS + 15 ms declick) ve gerçek süre.
export const TTS_POLICY_VERSION = "patika-v3-paced-2026-09-21";

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

/// Sağlayıcıya giden gövde. `eleven_v3` istek dikişini (`previous_text` / `next_text`)
/// **desteklemiyor** ve `400 unsupported_model` dönüyor (canlıda ölçüldü, 2026-09-21):
/// kişisel slot sesi bu yüzden hiç üretilemiyordu. v3'te komşu bağlam gönderilmez;
/// parça sınırındaki ton tutarlılığı ses kimliği + sabit ayarlarla sağlanıyor.
/// Desteklemeyen bir model (ör. `eleven_multilingual_v2`) seçilirse bağlam gider.
export function speechRequestBody(input: {
  text: string;
  modelId: string;
  locale: string;
  previousText?: string | null;
  nextText?: string | null;
}) {
  const stitching = !input.modelId.startsWith("eleven_v3");
  return {
    text: input.text,
    model_id: input.modelId,
    language_code: languageCode(input.locale),
    previous_text: stitching ? sanitizeSpeechText(input.previousText ?? "") || undefined : undefined,
    next_text: stitching ? sanitizeSpeechText(input.nextText ?? "") || undefined : undefined,
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
  };
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
        body: JSON.stringify(speechRequestBody({
          text,
          modelId,
          locale: request.locale,
          previousText: request.previousText,
          nextText: request.nextText,
        })),
      },
    );

    if (response.status === 401) throw new Error("provider_configuration_required");
    if (!response.ok) {
      const errorPayload = await response.json().catch(() => null) as { detail?: { status?: string } } | null;
      const providerStatus = errorPayload?.detail?.status?.replace(/[^a-z0-9_]/gi, "_").slice(0, 80);
      throw new Error(`tts_request_failed_${response.status}${providerStatus ? `_${providerStatus}` : ""}`);
    }
    type Alignment = { character_start_times_seconds?: number[]; character_end_times_seconds?: number[] };
    const payload = await response.json() as {
      audio_base64?: string;
      alignment?: Alignment;
      normalized_alignment?: Alignment;
    };
    if (!payload.audio_base64) throw new Error("tts_request_failed");
    const bytes = decodeBase64(payload.audio_base64);
    if (bytes.byteLength === 0) throw new Error("tts_request_failed");
    const alignment = payload.normalized_alignment ?? payload.alignment;
    const startTimes = alignment?.character_start_times_seconds ?? [];
    const endTimes = alignment?.character_end_times_seconds ?? [];
    const spokenEndMs = Math.round((endTimes.at(-1) ?? 0.001) * 1_000);
    // Gerçek uzunluk dosyadan; hizalama yalnızca çözülemeyen dosya için yedek.
    const durationMs = Math.max(1, mp3DurationMs(bytes) || spokenEndMs);
    return {
      bytes,
      contentType: "audio/mpeg",
      modelId,
      durationMs,
      leadSilenceMs: Math.max(0, Math.round((startTimes[0] ?? 0) * 1_000)),
      tailSilenceMs: Math.max(0, durationMs - spokenEndMs),
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
