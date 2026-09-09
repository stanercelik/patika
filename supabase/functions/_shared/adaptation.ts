import type { PathKind } from "./schema.ts";
import { sanitizeSpeechText } from "./tts.ts";

export type AdaptiveFrame = {
  step_opening: string;
  technique_bridge: string;
  mid_bridge?: string;
  step_closing: string;
};

const UNSAFE_COPY = [
  /\bterapi\b/i, /\btedavi/i, /iyileştir/i, /klinik olarak/i, /\bila[çc]/i,
  /travma.{0,20}(ayrınt|detay)/i, /maruz bırak/i, /\bteşhis/i,
  /\btherapy\b/i, /\btreatment\b/i, /\bcure[sd]?\b/i, /clinically proven/i,
  /\bmedication\b/i, /trauma.{0,20}detail/i, /\bdiagnos/i, /\bexposure\b/i,
  /harika iş/i, /tebrikler/i, /endişelenme/i, /sakin ol/i, /bunu aşacaksın/i,
];

export function completionPolicy(input: {
  pathKind: PathKind;
  answer: string | null;
  skipped: boolean;
  hasNextStep: boolean;
}) {
  const hasAnswer = typeof input.answer === "string" && input.answer.trim().length > 0;
  if (input.pathKind === "prepared" && hasAnswer) throw new Error("prepared_path_does_not_accept_answers");
  if (hasAnswer && input.skipped) throw new Error("invalid_completion_request");
  return {
    acceptsAnswer: input.pathKind === "personalized",
    shouldPersonalize: input.pathKind === "personalized" && hasAnswer && !input.skipped && input.hasNextStep,
    shouldQueueNext: input.hasNextStep,
  };
}

export function safeAnswerSummary(value: string): string {
  return sanitizeSpeechText(value).slice(0, 280);
}

export function validateAdaptiveFrame(value: unknown): AdaptiveFrame {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("invalid_adaptive_copy");
  const frame = value as Record<string, unknown>;
  const allowed = new Set(["step_opening", "technique_bridge", "mid_bridge", "step_closing"]);
  if (Object.keys(frame).some((key) => !allowed.has(key))) throw new Error("invalid_adaptive_copy");
  const required = ["step_opening", "technique_bridge", "step_closing"];
  if (required.some((key) => typeof frame[key] !== "string")) throw new Error("invalid_adaptive_copy");

  const normalized: Record<string, string> = {};
  for (const [key, raw] of Object.entries(frame)) {
    if (typeof raw !== "string") throw new Error("invalid_adaptive_copy");
    const copy = sanitizeSpeechText(raw);
    if (!copy || copy.length > 520) throw new Error("invalid_adaptive_copy");
    if (UNSAFE_COPY.some((pattern) => pattern.test(copy))) throw new Error("unsafe_adaptive_copy");
    normalized[key] = copy;
  }
  if (Object.values(normalized).join(" ").length > 1_200) throw new Error("invalid_adaptive_copy");
  return normalized as AdaptiveFrame;
}

export async function personalizeNextFrame(input: {
  locale: string;
  answerSummary: string;
  nextStepTitle: string;
  priorFrame: Record<string, string>;
}): Promise<AdaptiveFrame> {
  const fallback = fallbackFrame(input.locale, input.answerSummary);
  if (Deno.env.get("PATIKA_AI_LIVE_ENABLED") !== "true") return fallback;
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) return fallback;
  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.6-flash";
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20_000);
  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
      method: "POST",
      signal: controller.signal,
      headers: { "Content-Type": "application/json", "x-goog-api-key": key },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: [
          "Write a calm, natural frame for one non-clinical wellbeing exercise.",
          "Reflect the supplied safe summary without quoting it verbatim.",
          "Do not diagnose, promise outcomes, mention therapy or treatment, recommend medication, request trauma details, or add techniques.",
          "Do not use bracketed audio directions. Return JSON only.",
        ].join(" ") }] },
        contents: [{ role: "user", parts: [{ text: JSON.stringify(input) }] }],
        generationConfig: {
          responseMimeType: "application/json",
          responseJsonSchema: ADAPTIVE_FRAME_SCHEMA,
          temperature: 0.25,
        },
      }),
    });
    if (!response.ok) return fallback;
    const payload = await response.json();
    const candidate = payload?.candidates?.[0];
    if (!candidate || candidate.finishReason === "SAFETY" || candidate.finishReason === "RECITATION") return fallback;
    const text = candidate.content?.parts?.map((part: { text?: string }) => part.text ?? "").join("");
    return text ? validateAdaptiveFrame(JSON.parse(text)) : fallback;
  } catch {
    return fallback;
  } finally {
    clearTimeout(timeout);
  }
}

function fallbackFrame(locale: string, answerSummary: string): AdaptiveFrame {
  const hasContext = answerSummary.length > 0;
  return validateAdaptiveFrame(locale.toLowerCase().startsWith("tr") ? {
    step_opening: hasContext
      ? "Dün fark ettiğin anı akılda tutarak bugün biraz daha küçük bir yerden başlayacağız."
      : "Bugün kısa ve sakin bir yerden başlayacağız.",
    technique_bridge: "Şimdi dikkati zorlamadan bu adıma getirebilirsin.",
    step_closing: "Bugünlük burada durabiliriz.",
  } : {
    step_opening: hasContext
      ? "Keeping yesterday's observation in mind, we will begin from a smaller place today."
      : "Today, we will begin from a quiet and manageable place.",
    technique_bridge: "You can bring your attention to this step without forcing it.",
    step_closing: "We can stop here for today.",
  });
}

const ADAPTIVE_FRAME_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["step_opening", "technique_bridge", "step_closing"],
  properties: {
    step_opening: { type: "string", minLength: 1, maxLength: 520 },
    technique_bridge: { type: "string", minLength: 1, maxLength: 520 },
    mid_bridge: { type: "string", minLength: 1, maxLength: 520 },
    step_closing: { type: "string", minLength: 1, maxLength: 520 },
  },
};

