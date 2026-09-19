import { completionPolicy, personalizeNextFrame, safeAnswerSummary } from "../_shared/adaptation.ts";
import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { encryptSensitiveText } from "../_shared/encryption.ts";
import { crisisSignalForText } from "../_shared/crisis.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);
  try {
    const { user, adminClient } = await authenticate(req);
    const body = await req.json();
    if (typeof body?.pathStepId !== "string" || typeof body?.skipped !== "boolean") {
      return json({ code: "invalid_request" }, 400);
    }
    const answer = body.answer === null || body.answer === undefined
      ? null
      : typeof body.answer === "string" && body.answer.trim().length <= 1_000 ? body.answer.trim() : undefined;
    if (answer === undefined) return json({ code: "invalid_request" }, 400);
    if (answer && crisisSignalForText(answer)) return json({ status: "crisis", crisis: true });

    const { data: current } = await adminClient.from("path_steps")
      .select("id,path_id,day,step_question,completed_at")
      .eq("id", body.pathStepId).eq("user_id", user.id).maybeSingle();
    if (!current) return json({ code: "not_found" }, 404);
    const [{ data: path }, { data: next }, { data: profile }] = await Promise.all([
      adminClient.from("program_paths").select("id,kind").eq("id", current.path_id).eq("user_id", user.id).single(),
      adminClient.from("path_steps").select("id,title,slot_copy")
        .eq("path_id", current.path_id).eq("user_id", user.id).eq("day", current.day + 1).maybeSingle(),
      adminClient.from("profiles").select("locale").eq("user_id", user.id).maybeSingle(),
    ]);
    if (!path) return json({ code: "not_found" }, 404);
    const policy = completionPolicy({
      pathKind: path.kind === "prepared" ? "prepared" : "personalized",
      answer,
      skipped: body.skipped,
      hasNextStep: !!next,
    });
    if (answer && !current.step_question) return json({ code: "question_unavailable" }, 409);

    if (policy.acceptsAnswer && current.step_question) {
      const summary = answer ? safeAnswerSummary(answer) : null;
      const ciphertext = answer ? await encryptSensitiveText(answer) : null;
      const { error: answerError } = await adminClient.from("path_step_answers").upsert({
        user_id: user.id,
        path_step_id: current.id,
        question: current.step_question,
        answer_ciphertext: ciphertext,
        answer_summary: summary,
        skipped: body.skipped,
      }, { onConflict: "path_step_id" });
      if (answerError) throw new Error("database_write_failed");
    }

    if (policy.shouldPersonalize && next && answer) {
      const frame = await personalizeNextFrame({
        locale: profile?.locale ?? "en",
        answerSummary: safeAnswerSummary(answer),
        nextStepTitle: next.title,
        priorFrame: next.slot_copy ?? {},
      });
      const { error: updateError } = await adminClient.from("path_steps")
        .update({ slot_copy: frame, audio_status: "pending" }).eq("id", next.id).eq("user_id", user.id);
      if (updateError) throw new Error("database_write_failed");
    }

    if (!current.completed_at) {
      const { error: completionError } = await adminClient.from("path_steps")
        .update({ completed_at: new Date().toISOString() }).eq("id", current.id).eq("user_id", user.id);
      if (completionError) throw new Error("database_write_failed");
    }

    // Yolun sonu: tamamlanmamış adım kalmadıysa yol tamamlanır. "Yolum" bitmiş
    // yolu göstermeye devam eder; "Ben" onu arşive alır ve son ölçümle kovasını
    // hesaplar.
    let pathStatus: "active" | "completed" = "active";
    const { count: remaining, error: remainingError } = await adminClient.from("path_steps")
      .select("id", { count: "exact", head: true })
      .eq("path_id", current.path_id).eq("user_id", user.id).is("completed_at", null);
    if (remainingError) throw new Error("database_read_failed");
    if (remaining === 0) {
      const { error: pathError } = await adminClient.from("program_paths")
        .update({ status: "completed", completed_at: new Date().toISOString() })
        .eq("id", path.id).eq("user_id", user.id).eq("status", "active");
      if (pathError) throw new Error("database_write_failed");
      pathStatus = "completed";
    }

    let nextStepStatus: "none" | "queued" = "none";
    if (policy.shouldQueueNext && next) {
      const response = await fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/generate-audio`, {
        method: "POST",
        headers: {
          Authorization: req.headers.get("Authorization")!,
          "Content-Type": "application/json",
          "Idempotency-Key": `next-step-${path.id}-${next.id}`,
        },
        body: JSON.stringify({ pathStepId: next.id }),
      });
      if (response.ok || response.status === 202) nextStepStatus = "queued";
    }
    return json({ status: "completed", nextStepStatus, pathStatus, crisis: false });
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    if (code === "prepared_path_does_not_accept_answers" || code === "invalid_completion_request") return json({ code }, 400);
    return json({ code: "server_error" }, 500);
  }
});

