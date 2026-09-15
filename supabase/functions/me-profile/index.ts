import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { decryptSensitiveText } from "../_shared/encryption.ts";

// "Ben" sekmesinin kaynağı: kullanıcının kendi verisi, kendi oturumuyla.
//
// Şifreli alanlar (ad, ilk cümle, kaçınma cümlesi, oturum cevapları) yalnızca
// burada ve yalnızca sahibine çözülür. Yanıt loglanmaz. Çözülemeyen tek bir satır
// bütün sayfayı düşürmez; o satır yanıtta hiç yer almaz.

type PersonalizationContext = {
  categories?: unknown;
  timing?: unknown;
  tone?: unknown;
  session_minutes?: unknown;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  try {
    const { user, adminClient } = await authenticate(req);

    const [profile, statement, measurements, paths, completedSteps, answers] = await Promise.all([
      adminClient.from("profiles")
        .select("name_ciphertext,locale,voice_preference,created_at")
        .eq("user_id", user.id).maybeSingle(),
      // İlk cümle: kullanıcının yola hangi cümleyle çıktığı. Sonradan üretilen
      // path'ler başlangıcı değiştirmez.
      adminClient.from("problem_statements")
        .select("raw_text_ciphertext,created_at")
        .eq("user_id", user.id).not("raw_text_ciphertext", "is", null)
        .order("created_at", { ascending: true }).limit(1).maybeSingle(),
      adminClient.from("measurements")
        .select("id,measurement_day,variant,raw_responses,path_id,created_at")
        .eq("user_id", user.id).order("created_at", { ascending: true }),
      adminClient.from("program_paths")
        .select("id,kind,title,status,length_days,personalization_context,created_at,completed_at")
        .eq("user_id", user.id).in("status", ["active", "completed", "cancelled"])
        .order("created_at", { ascending: false }),
      adminClient.from("path_steps")
        .select("path_id")
        .eq("user_id", user.id).not("completed_at", "is", null),
      adminClient.from("path_step_answers")
        .select("id,question,answer_ciphertext,created_at,path_steps!inner(day,title,path_id)")
        .eq("user_id", user.id).eq("skipped", false).not("answer_ciphertext", "is", null)
        .order("created_at", { ascending: true }),
    ]);

    for (const result of [profile, statement, measurements, paths, completedSteps, answers]) {
      if (result.error) throw new Error("database_read_failed");
    }

    const completedByPath = new Map<string, number>();
    for (const row of completedSteps.data ?? []) {
      completedByPath.set(row.path_id, (completedByPath.get(row.path_id) ?? 0) + 1);
    }

    const origin = statement.data?.raw_text_ciphertext
      ? await decryptJSON(statement.data.raw_text_ciphertext)
      : null;

    const decryptedAnswers = await Promise.all((answers.data ?? []).map(async (row) => {
      const text = await safeDecrypt(row.answer_ciphertext);
      const step = Array.isArray(row.path_steps) ? row.path_steps[0] : row.path_steps;
      if (!text || !step) return null;
      return {
        id: row.id,
        pathId: step.path_id,
        stepDay: step.day,
        stepTitle: step.title,
        question: row.question,
        answer: text,
        createdAt: row.created_at,
      };
    }));

    return json({
      profile: profile.data
        ? {
          displayName: profile.data.name_ciphertext ? await safeDecrypt(profile.data.name_ciphertext) : null,
          locale: profile.data.locale,
          voicePreference: profile.data.voice_preference,
          createdAt: profile.data.created_at,
        }
        : null,
      origin: origin && (origin.problem || origin.avoidance)
        ? { problemText: origin.problem, avoidanceText: origin.avoidance, createdAt: statement.data!.created_at }
        : null,
      measurements: (measurements.data ?? []).map((row) => ({
        id: row.id,
        day: row.measurement_day,
        variant: row.variant,
        responses: row.raw_responses,
        pathId: row.path_id,
        createdAt: row.created_at,
      })),
      paths: (paths.data ?? []).map((row) => {
        const context = (row.personalization_context ?? {}) as PersonalizationContext;
        return {
          id: row.id,
          kind: row.kind,
          title: row.title,
          status: row.status,
          lengthDays: row.length_days,
          completedSteps: completedByPath.get(row.id) ?? 0,
          categories: Array.isArray(context.categories)
            ? context.categories.filter((item): item is string => typeof item === "string")
            : [],
          timing: typeof context.timing === "string" ? context.timing : null,
          tone: typeof context.tone === "string" ? context.tone : null,
          sessionMinutes: typeof context.session_minutes === "number" ? context.session_minutes : null,
          createdAt: row.created_at,
          completedAt: row.completed_at,
        };
      }),
      answers: decryptedAnswers.filter((item) => item !== null),
    });
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    return json({ code: "server_error" }, 500);
  }
});

async function safeDecrypt(value: string | null): Promise<string | null> {
  if (!value) return null;
  try {
    const text = (await decryptSensitiveText(value)).trim();
    return text.length > 0 ? text : null;
  } catch {
    return null;
  }
}

async function decryptJSON(value: string): Promise<{ problem: string | null; avoidance: string | null } | null> {
  const text = await safeDecrypt(value);
  if (!text) return null;
  try {
    const parsed = JSON.parse(text);
    const clean = (item: unknown) =>
      typeof item === "string" && item.trim().length > 0 ? item.trim() : null;
    return { problem: clean(parsed?.problem), avoidance: clean(parsed?.avoidance) };
  } catch {
    return null;
  }
}
