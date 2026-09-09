import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { fallbackPlan, generateWithGemini, ruleBasedCrisisCheck } from "../_shared/providers.ts";
import { parseGeneratePathRequest, type PathPlanDTO } from "../_shared/schema.ts";

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
      })),
    );
    if (stepsError) throw new Error("database_write_failed");

    const scores = calculateScores(input.measurementResponses);
    const writes = await Promise.all([
      adminClient.from("profiles").upsert({
        user_id: user.id,
        locale: input.locale,
        gender: input.gender,
        age_range: input.ageRange,
      }),
      adminClient.from("problem_statements").insert({
        user_id: user.id,
        raw_text_ciphertext: null,
        generation_summary: plan.summary,
      }),
      adminClient.from("measurements").insert({
        user_id: user.id,
        variant: input.measurementVariant,
        measurement_day: 0,
        raw_responses: input.measurementResponses,
        emotion_score: scores.emotion,
        behavior_score: scores.behavior,
        self_efficacy_score: scores.selfEfficacy,
      }),
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
    return json({ status: "ready", pathId: path.id, title: plan.title, steps: plan.steps });
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    if (code === "invalid_request") return json({ code }, 400);
    return json({ code: "server_error" }, 500);
  }
});

async function pathResponse(adminClient: any, userId: string, pathId: string): Promise<Response> {
  const [{ data: path }, { data: steps }] = await Promise.all([
    adminClient.from("program_paths").select("id,title").eq("id", pathId).eq("user_id", userId).single(),
    adminClient.from("path_steps").select("day,title,block_ids,slot_copy").eq("path_id", pathId).eq("user_id", userId).order("day"),
  ]);
  if (!path) return json({ code: "not_found" }, 404);
  return json({
    status: "ready",
    pathId: path.id,
    title: path.title,
    steps: (steps ?? []).map((step: any) => ({ day: step.day, title: step.title, blockIds: step.block_ids, slotCopy: step.slot_copy })),
  });
}

function calculateScores(responses: Record<string, number>) {
  const groups = { emotion: [] as number[], behavior: [] as number[], selfEfficacy: [] as number[] };
  for (const [key, raw] of Object.entries(responses)) {
    const maximum = key === "emotion.intensity" ? 10 : 4;
    let normalized = Math.min(100, Math.max(0, raw / maximum * 100));
    if (key.startsWith("selfEfficacy.") || key === "behavior.breaksTaken") normalized = 100 - normalized;
    if (key.startsWith("emotion.")) groups.emotion.push(normalized);
    else if (key.startsWith("selfEfficacy.")) groups.selfEfficacy.push(normalized);
    else groups.behavior.push(normalized);
  }
  const average = (values: number[]) => values.length ? Math.round(values.reduce((a, b) => a + b, 0) / values.length * 100) / 100 : null;
  return { emotion: average(groups.emotion), behavior: average(groups.behavior), selfEfficacy: average(groups.selfEfficacy) };
}
