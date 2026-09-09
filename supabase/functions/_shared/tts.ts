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

export type SpeechRequest = {
  text: string;
  locale: string;
  voice: VoicePreference;
  /// Bloğun isteğe bağlı ses yönergesi, ör. "[whispers]". Varsayılan yok.
  audioTag?: string | null;
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
};

const DEFAULT_BASE_URL = "https://api.eu.residency.elevenlabs.io";
// v3: v2 multilingual ile aynı fiyat, belirgin şekilde daha iyi ve
// `language_code` destekliyor (multilingual_v2 desteklemiyor).
const DEFAULT_MODEL = "eleven_v3";

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
  const modelId = Deno.env.get("ELEVENLABS_MODEL") ?? DEFAULT_MODEL;
  const voiceId = voiceIdFor(request.voice);

  const text = request.audioTag ? `${request.audioTag} ${request.text}` : request.text;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 60_000);
  try {
    const response = await fetch(
      `${baseUrl}/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128`,
      {
        method: "POST",
        signal: controller.signal,
        headers: {
          "xi-api-key": key,
          "Content-Type": "application/json",
          "Accept": "audio/mpeg",
        },
        body: JSON.stringify({
          text,
          model_id: modelId,
          language_code: languageCode(request.locale),
          previous_text: request.previousText ?? undefined,
          next_text: request.nextText ?? undefined,
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
    if (!response.ok) throw new Error("tts_request_failed");
    const bytes = await response.arrayBuffer();
    if (bytes.byteLength === 0) throw new Error("tts_request_failed");
    return {
      bytes,
      contentType: response.headers.get("content-type")?.split(";")[0] ?? "audio/mpeg",
      modelId,
    };
  } finally {
    clearTimeout(timeout);
  }
}
