import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";

// Defterden silme (KVKK Madde 11 / GDPR Madde 17).
//
// - `answerId`: tek bir oturum cevabı. Satır kalır ve `skipped` olur: adımın
//   tamamlanma kaydı ve sonraki adımın üretimi bu satıra dayanıyor. Ham metin ve
//   özet kalıcı olarak silinir.
// - `origin`: ilk cümle ve kaçınma cümlesi. Path'in kısa üretim özeti kalır;
//   ham metin silinir.
// - `all`: ikisi birden.
//
// Yol değişmez: zaten üretilmiş adımlar geri alınmaz.

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  try {
    const { user, adminClient } = await authenticate(req);
    const body = await req.json();
    const answerId = typeof body?.answerId === "string" ? body.answerId : null;
    const origin = body?.origin === true;
    const all = body?.all === true;
    if (!answerId && !origin && !all) return json({ code: "invalid_request" }, 400);

    if (answerId || all) {
      let query = adminClient.from("path_step_answers")
        .update({ answer_ciphertext: null, answer_summary: null, skipped: true })
        .eq("user_id", user.id);
      if (answerId && !all) query = query.eq("id", answerId);
      const { error } = await query;
      if (error) throw new Error("database_write_failed");
    }

    if (origin || all) {
      const { error } = await adminClient.from("problem_statements")
        .update({ raw_text_ciphertext: null })
        .eq("user_id", user.id);
      if (error) throw new Error("database_write_failed");
    }

    return json({ status: "deleted" });
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    return json({ code: "server_error" }, 500);
  }
});
