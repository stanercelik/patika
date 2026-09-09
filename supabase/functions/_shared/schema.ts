import { maximumFor } from "./measurement.ts";
export type GeneratePathRequest = {
  clientCrisisSignal: boolean;
  locale: string;
  name?: string | null;
  gender?: string | null;
  ageRange?: string | null;
  categories: string[];
  problemText: string;
  duration?: string | null;
  timing?: string | null;
  avoidanceText?: string | null;
  previousAttempts: string[];
  currentMood?: string | null;
  measurementVariant: "a" | "b" | "c";
  measurementResponses: Record<string, number>;
  sessionMinutes: 5 | 10 | 15;
  tone: string;
  voicePreference: "feminine" | "masculine";
};

export type PathKind = "personalized" | "prepared";

export type PathStepDTO = {
  day: number;
  title: string;
  blockIds: string[];
  slotCopy: Record<string, string>;
  question: string | null;
};

export type PathPlanDTO = {
  kind: PathKind;
  title: string;
  templateId: string;
  lengthDays: 7 | 14 | 21 | 28;
  summary: string;
  steps: PathStepDTO[];
};

export const approvedBlockIds = [
  "breath.awareness.v1",
  "body.grounding.v1",
  "reflection.notice.v1",
] as const;

export const approvedEnglishBlockIds = [
  "breath.awareness.en.v1",
  "body.grounding.en.v1",
  "reflection.notice.en.v1",
] as const;

export function approvedBlockIdsFor(locale: string): readonly string[] {
  return locale.toLowerCase().startsWith("tr") ? approvedBlockIds : approvedEnglishBlockIds;
}

const allowedCategories = new Set([
  "anxiety", "sleep", "burnout", "focus", "anger", "selfcrit", "social",
  "exam", "grief", "unnamed",
]);

export function parseGeneratePathRequest(value: unknown): GeneratePathRequest {
  if (!value || typeof value !== "object") throw new Error("invalid_request");
  const body = value as Record<string, unknown>;
  const categories = stringArray(body.categories, 1, 2);
  if (categories.some((item) => !allowedCategories.has(item))) throw new Error("invalid_request");
  const problemText = boundedString(body.problemText, 0, 4000);
  const avoidanceText = nullableBoundedString(body.avoidanceText, 2000);
  const measurementVariant = body.measurementVariant;
  if (measurementVariant !== "a" && measurementVariant !== "b" && measurementVariant !== "c") {
    throw new Error("invalid_request");
  }
  const sessionMinutes = body.sessionMinutes;
  if (sessionMinutes !== 5 && sessionMinutes !== 10 && sessionMinutes !== 15) throw new Error("invalid_request");
  const responses = body.measurementResponses;
  if (!responses || typeof responses !== "object" || Array.isArray(responses)) throw new Error("invalid_request");
  const measurementResponses: Record<string, number> = {};
  for (const [key, raw] of Object.entries(responses)) {
    const maximum = maximumFor(key);
    if (!/^[a-z0-9._-]{1,80}$/i.test(key) || typeof raw !== "number" || raw < 0 || raw > maximum) {
      throw new Error("invalid_request");
    }
    measurementResponses[key] = raw;
  }
  if (Object.keys(measurementResponses).length !== 8) throw new Error("invalid_request");

  return {
    clientCrisisSignal: body.clientCrisisSignal === true,
    locale: boundedString(body.locale, 2, 35),
    name: nullableBoundedString(body.name, 80),
    gender: nullableEnum(body.gender, ["woman", "man", "other", "undisclosed"]),
    ageRange: nullableEnum(body.ageRange, ["eighteenToTwentyFour", "twentyFiveToThirtyFour", "thirtyFiveToFortyFour", "fortyFiveToFiftyFour", "fiftyFivePlus", "undisclosed"]),
    categories,
    problemText,
    duration: nullableBoundedString(body.duration, 50),
    timing: nullableBoundedString(body.timing, 50),
    avoidanceText,
    previousAttempts: stringArray(body.previousAttempts, 0, 10),
    currentMood: nullableBoundedString(body.currentMood, 50),
    measurementVariant,
    measurementResponses,
    sessionMinutes,
    tone: boundedString(body.tone, 1, 50),
    // Tanınmayan bir değer kadın sesine düşer; ses tercihinin geçersizliği
    // path üretimini durduracak bir hata değil.
    voicePreference: body.voicePreference === "masculine" ? "masculine" : "feminine",
  };
}

function nullableEnum(value: unknown, allowed: string[]): string | null {
  if (value === undefined || value === null || value === "") return null;
  const result = boundedString(value, 1, 50);
  if (!allowed.includes(result)) throw new Error("invalid_request");
  return result;
}

export function validatePlan(plan: PathPlanDTO): PathPlanDTO {
  if (plan.kind !== "personalized" && plan.kind !== "prepared") {
    throw new Error("invalid_provider_response");
  }
  if (![7, 14, 21, 28].includes(plan.lengthDays) || plan.steps.length !== plan.lengthDays) {
    throw new Error("invalid_provider_response");
  }
  const approved = new Set<string>([...approvedBlockIds, ...approvedEnglishBlockIds]);
  plan.steps.forEach((step, index) => {
    if (step.day !== index + 1 || step.title.length < 1 || step.title.length > 120) {
      throw new Error("invalid_provider_response");
    }
    if (step.blockIds.length < 1 || step.blockIds.some((id) => !approved.has(id))) {
      throw new Error("invalid_provider_response");
    }
    for (const [slot, copy] of Object.entries(step.slotCopy)) {
      if (!["step_opening", "technique_bridge", "mid_bridge", "step_closing"].includes(slot) || copy.length > 520) {
        throw new Error("invalid_provider_response");
      }
    }
    if (step.question !== null && (step.question.length < 1 || step.question.length > 120)) {
      throw new Error("invalid_provider_response");
    }
    if (plan.kind === "prepared" && (step.question !== null || Object.keys(step.slotCopy).length > 0)) {
      throw new Error("invalid_provider_response");
    }
  });
  return plan;
}

function boundedString(value: unknown, minimum: number, maximum: number): string {
  if (typeof value !== "string") throw new Error("invalid_request");
  const result = value.trim();
  if (result.length < minimum || result.length > maximum) throw new Error("invalid_request");
  return result;
}

function nullableBoundedString(value: unknown, maximum: number): string | null {
  if (value === undefined || value === null || value === "") return null;
  return boundedString(value, 1, maximum);
}

function stringArray(value: unknown, minimum: number, maximum: number): string[] {
  if (!Array.isArray(value) || value.length < minimum || value.length > maximum) throw new Error("invalid_request");
  return value.map((item) => boundedString(item, 1, 100));
}
