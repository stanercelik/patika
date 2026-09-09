import { approvedBlockIds, type GeneratePathRequest, type PathPlanDTO, validatePlan } from "./schema.ts";

const crisisPatterns = [
  /intihar/i, /kendimi oldur/i, /kendimi öldür/i, /yasamak istemiyorum/i,
  /yaşamak istemiyorum/i, /canima kiymak/i, /canıma kıymak/i, /self[ -]?harm/i,
  /kill myself/i, /suicide/i,
];

export type CrisisResult = { signal: boolean; source: "rule" | "gemini" | "none" };

export function ruleBasedCrisisCheck(input: GeneratePathRequest): CrisisResult {
  const text = `${input.problemText}\n${input.avoidanceText ?? ""}`;
  return crisisPatterns.some((pattern) => pattern.test(text))
    ? { signal: true, source: "rule" }
    : { signal: false, source: "none" };
}

export function fallbackPlan(input: GeneratePathRequest): PathPlanDTO {
  const primary = input.categories[0] ?? "unnamed";
  const titleByCategory: Record<string, string> = {
    sleep: "Akşamı yavaşlatma yolu",
    anxiety: "Gerginliği fark etme yolu",
    burnout: "Yükü sadeleştirme yolu",
    focus: "Dikkati toplama yolu",
    social: "Sınırları fark etme yolu",
    selfcrit: "Kendi sesini duyma yolu",
    grief: "Yasa alan açma yolu",
    anger: "Yoğunluğu düzenleme yolu",
    exam: "Baskı altında durma yolu",
    unnamed: "Durup fark etme yolu",
  };
  const opening = input.problemText
    ? "Yazdığın duruma bugün kısa ve sakin bir yerden yaklaşacağız."
    : "Bugün kısa ve sakin bir başlangıç yapacağız.";
  const steps = Array.from({ length: 21 }, (_, index) => ({
    day: index + 1,
    title: index < 3 ? "Nefesi fark etmek" : index < 7 ? "Bedene dönmek" : index < 14 ? "Örüntüyü görmek" : "Küçük bir adım seçmek",
    blockIds: [approvedBlockIds[index % approvedBlockIds.length]],
    slotCopy: index === 0 ? { step_opening: opening } : {},
  }));
  return validatePlan({
    title: titleByCategory[primary] ?? titleByCategory.unnamed,
    templateId: `${primary}.three_weeks.v1`,
    lengthDays: 21,
    summary: `${primary}; ${input.duration ?? "unspecified"}; ${input.timing ?? "unspecified"}`.slice(0, 400),
    steps,
  });
}

export async function generateWithGemini(input: GeneratePathRequest): Promise<PathPlanDTO | null> {
  if (Deno.env.get("PATIKA_AI_LIVE_ENABLED") !== "true") return null;
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new Error("gemini_configuration_missing");
  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.6-flash";
  const fallback = fallbackPlan(input);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20_000);
  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
      method: "POST",
      signal: controller.signal,
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: "Select only approved block IDs. Do not diagnose, promise outcomes, recommend medication, or add therapeutic exposure. Return JSON only." }] },
        contents: [{ role: "user", parts: [{ text: JSON.stringify({ safeSummary: fallback.summary, categories: input.categories, duration: input.duration, timing: input.timing, sessionMinutes: input.sessionMinutes, tone: input.tone, approvedBlockIds }) }] }],
        generationConfig: {
          responseMimeType: "application/json",
          responseJsonSchema: planJsonSchema,
          temperature: 0.2,
        },
      }),
    });
    if (!response.ok) throw new Error("gemini_request_failed");
    const payload = await response.json();
    const candidate = payload?.candidates?.[0];
    if (!candidate || candidate.finishReason === "SAFETY" || candidate.finishReason === "RECITATION") {
      throw new Error("gemini_refusal");
    }
    const text = candidate.content?.parts?.map((part: { text?: string }) => part.text ?? "").join("");
    if (!text) throw new Error("invalid_provider_response");
    return validatePlan(JSON.parse(text));
  } finally {
    clearTimeout(timeout);
  }
}

// TTS artık burada değil: `_shared/tts.ts`, aracısız ElevenLabs v3.
// fal.ai kuyruğu ve webhook imza doğrulaması kaldırıldı — doğrudan çağrı
// senkron ve zincirde bir veri işleyici daha az (PRD-Ek Oturum Motoru §3.3).

const planJsonSchema = {
  type: "object",
  additionalProperties: false,
  required: ["title", "templateId", "lengthDays", "summary", "steps"],
  properties: {
    title: { type: "string", maxLength: 120 },
    templateId: { type: "string", maxLength: 100 },
    lengthDays: { type: "integer", enum: [7, 14, 21, 28] },
    summary: { type: "string", maxLength: 400 },
    steps: {
      type: "array",
      minItems: 7,
      maxItems: 28,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["day", "title", "blockIds", "slotCopy"],
        properties: {
          day: { type: "integer", minimum: 1, maximum: 28 },
          title: { type: "string", maxLength: 120 },
          blockIds: { type: "array", minItems: 1, maxItems: 12, items: { type: "string", enum: approvedBlockIds } },
          slotCopy: { type: "object", additionalProperties: { type: "string", maxLength: 520 } },
        },
      },
    },
  },
};
