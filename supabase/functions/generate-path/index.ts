import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { fallbackPlan, generateWithGemini, ruleBasedCrisisCheck } from "../_shared/providers.ts";
import { normalize } from "../_shared/measurement.ts";
import { parseGeneratePathRequest, type PathPlanDTO } from "../_shared/schema.ts";
import { encryptSensitiveText } from "../_shared/encryption.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  try {
    const { user, adminClient } = await authenticate(req);
    const idempotencyKey = req.headers.get("Idempotency-Key")?.trim();
    if (!idempotencyKey || idempotencyKey.length < 16 || idempotencyKey.length > 200) {
      return json({ code: "invalid_idempotency_key" }, 400);
    }
    const input = parseGeneratePathRequest(await req.json());

    if (input.clientCrisisSignal || ruleBasedCrisisCheck(input).signal) {
      return json({ status: "crisis" });
    }

    const { data: existing } = await adminClient
      .from("generation_jobs")
      .select("path_id,status")
      .eq("idempotency_key", idempotencyKey)
      .eq("user_id", user.id)
      .maybeSingle();
    if (existing?.path_id) return pathResponse(adminClient, user.id, existing.path_id);

    let plan: PathPlanDTO;
    let provider = "fallback";
    try {
      const generated = await generateWithGemini(input);
      plan = generated ?? fallbackPlan(input);
      provider = generated ? "gemini" : "fallback";
    } catch (error) {
      if (error instanceof Error && error.message === "gemini_refusal") {
        return json({ status: "crisis" });
      }
      plan = fallbackPlan(input);
    }

    const { data: path, error: pathError } = await adminClient
      .from("program_paths")
      .insert({
        user_id: user.id,
        length_days: plan.lengthDays,
        status: "active",
        kind: plan.kind,
        template_id: plan.templateId,
        title: plan.title,
        personalization_context: {
          categories: input.categories,
          duration: input.duration,
          timing: input.timing,
          tone: input.tone,
          session_minutes: input.sessionMinutes,
        },
      })
      .select("id")
      .single();
    if (pathError || !path) throw new Error("database_write_failed");

    const { error: stepsError } = await adminClient.from("path_steps").insert(
      plan.steps.map((step) => ({
        path_id: path.id,
        user_id: user.id,
        day: step.day,
        title: step.title,
        block_ids: step.blockIds,
        slot_copy: step.slotCopy,
        step_question: step.question,
      })),
    );
    if (stepsError) throw new Error("database_write_failed");

    const scores = calculateScores(input.measurementResponses);
    const rawProblemCiphertext = input.problemText || input.avoidanceText
      ? await encryptSensitiveText(JSON.stringify({ problem: input.problemText, avoidance: input.avoidanceText }))
      : null;
    const writes = await Promise.all([
      adminClient.from("profiles").upsert({
        user_id: user.id,
        locale: input.locale,
        gender: input.gender,
        age_range: input.ageRange,
        // `generate-audio` sesi buradan okuyor. Profilde durması bilinçli:
        // ses tercihi path'e değil kullanıcıya ait, ikinci bir path açıldığında
        // yeniden sorulmamalı.
        voice_preference: input.voicePreference,
      }),
      adminClient.from("problem_statements").insert({
        user_id: user.id,
        raw_text_ciphertext: rawProblemCiphertext,
        generation_summary: plan.summary,
      }),
      // Baseline mükerrer yazılmasın: aynı kullanıcı için ikinci bir path
      // üretimi ilk ölçümü değiştirmemeli (tekil dizin 20260909130000).
      adminClient.from("measurements").upsert({
        user_id: user.id,
        variant: input.measurementVariant,
        measurement_day: 0,
        raw_responses: input.measurementResponses,
        emotion_score: scores.emotion,
        behavior_score: scores.behavior,
        self_efficacy_score: scores.selfEfficacy,
      }, { onConflict: "user_id,measurement_day", ignoreDuplicates: true }),
      adminClient.from("generation_jobs").insert({
        user_id: user.id,
        path_id: path.id,
        kind: "path",
        provider,
        status: "succeeded",
        idempotency_key: idempotencyKey,
        completed_at: new Date().toISOString(),
      }),
    ]);
    if (writes.some(({ error }) => error)) throw new Error("database_write_failed");
    return json({ status: "ready", pathId: path.id, kind: plan.kind, title: plan.title, steps: plan.steps });
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    if (code === "invalid_request") return json({ code }, 400);
    return json({ code: "server_error" }, 500);
  }
});

async function pathResponse(adminClient: any, userId: string, pathId: string): Promise<Response> {
  const [{ data: path }, { data: steps }] = await Promise.all([
    adminClient.from("program_paths").select("id,kind,title").eq("id", pathId).eq("user_id", userId).single(),
    adminClient.from("path_steps").select("day,title,block_ids,slot_copy,step_question").eq("path_id", pathId).eq("user_id", userId).order("day"),
  ]);
  if (!path) return json({ code: "not_found" }, 404);
  return json({
    status: "ready",
    pathId: path.id,
    kind: path.kind,
    title: path.title,
    steps: (steps ?? []).map((step: any) => ({ day: step.day, title: step.title, blockIds: step.block_ids, slotCopy: step.slot_copy, question: step.step_question })),
  });
}

// Skorlama deterministik: PRD-Ek Path Uretimi'ndeki sekiz adimin ucunde model
// yok ve bu bilincli — "Kova C'de satis yok" taahhudu, kovayi bir modelin
// belirledigi uründe anlamsiz olurdu.
//
// Tavanlar ve yön `_shared/measurement.ts`ten geliyor; burada elle yazilmiyor.
function calculateScores(responses: Record<string, number>) {
  const groups = { emotion: [] as number[], behavior: [] as number[], selfEfficacy: [] as number[] };
  for (const [key, raw] of Object.entries(responses)) {
    const normalized = normalize(key, raw);
    if (key.startsWith("emotion.")) groups.emotion.push(normalized);
    else if (key.startsWith("selfEfficacy.")) groups.selfEfficacy.push(normalized);
    else groups.behavior.push(normalized);
  }
  const average = (values: number[]) => values.length ? Math.round(values.reduce((a, b) => a + b, 0) / values.length * 100) / 100 : null;
  return { emotion: average(groups.emotion), behavior: average(groups.behavior), selfEfficacy: average(groups.selfEfficacy) };
}
