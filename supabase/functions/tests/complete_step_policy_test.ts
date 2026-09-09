import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  completionPolicy,
  safeAnswerSummary,
  validateAdaptiveFrame,
} from "../_shared/adaptation.ts";

Deno.test("prepared paths complete without accepting personalization", () => {
  assertEquals(completionPolicy({ pathKind: "prepared", answer: null, skipped: true, hasNextStep: true }), {
    acceptsAnswer: false,
    shouldPersonalize: false,
    shouldQueueNext: true,
  });
  assertThrows(
    () => completionPolicy({ pathKind: "prepared", answer: "Bugün ağırdı", skipped: false, hasNextStep: true }),
    Error,
    "prepared_path_does_not_accept_answers",
  );
});

Deno.test("personalized answers affect only the next step and skip still queues it", () => {
  assertEquals(completionPolicy({ pathKind: "personalized", answer: "Akşam zorlandı", skipped: false, hasNextStep: true }), {
    acceptsAnswer: true,
    shouldPersonalize: true,
    shouldQueueNext: true,
  });
  assertEquals(completionPolicy({ pathKind: "personalized", answer: null, skipped: true, hasNextStep: true }), {
    acceptsAnswer: true,
    shouldPersonalize: false,
    shouldQueueNext: true,
  });
});

Deno.test("answer summaries and generated frames stay bounded and non-clinical", () => {
  assertEquals(safeAnswerSummary("  Akşam   toplantısından sonra. [shouts]  "), "Akşam toplantısından sonra. shouts");
  assertThrows(() => validateAdaptiveFrame({
    step_opening: "Bu tedavi seni iyileştirecek.",
    technique_bridge: "Nefese dön.",
    step_closing: "Burada bitirelim.",
  }), Error, "unsafe_adaptive_copy");
  assertThrows(() => validateAdaptiveFrame({
    step_opening: "Travmanın ayrıntılarını düşün.",
    technique_bridge: "Nefese dön.",
    step_closing: "Burada bitirelim.",
  }), Error, "unsafe_adaptive_copy");
});

