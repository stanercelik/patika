import { assertEquals, assertThrows } from "jsr:@std/assert@1.0.14";
import { fallbackPlan, ruleBasedCrisisCheck } from "../_shared/providers.ts";
import { parseGeneratePathRequest, validatePlan } from "../_shared/schema.ts";

const request = parseGeneratePathRequest({
  clientCrisisSignal: false, locale: "tr-TR", categories: ["sleep"], problemText: "Akşam zihnim hızlanıyor",
  previousAttempts: [], measurementVariant: "a",
  measurementResponses: { "emotion.intensity": 4, "emotion.frequency": 2, "behavior.sleepLatency": 2, "behavior.avoidanceCount": 1, "behavior.nightWakings": 1, "selfEfficacy.knowsWhatToDo": 2, "selfEfficacy.believesChangePossible": 2, "behavior.dailyImpact": 2 },
  sessionMinutes: 10, tone: "calmAndShort",
});

Deno.test("fallback returns an approved 21 day plan", () => {
  const plan = fallbackPlan(request);
  assertEquals(plan.steps.length, 21);
  assertEquals(validatePlan(plan).templateId, "sleep.three_weeks.v1");
});

Deno.test("rule-based crisis signal is one-way", () => {
  assertEquals(ruleBasedCrisisCheck({ ...request, problemText: "Yaşamak istemiyorum" }).signal, true);
});

Deno.test("unknown blocks are rejected", () => {
  const plan = fallbackPlan(request);
  plan.steps[0].blockIds = ["invented.block"];
  assertThrows(() => validatePlan(plan), Error, "invalid_provider_response");
});
