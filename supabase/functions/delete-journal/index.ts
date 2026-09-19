import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";

// Defterden silme (KVKK Madde 11 / GDPR Madde 17).
//
// - `answerId`: tek bir oturum cevabı. Satır kalır ve `skipped` olur: adımın
//   tamamlanma kaydı ve sonraki adımın üretimi bu satıra dayanıyor. Ham metin ve
//   özet kalıcı olarak silinir.
// - `origin`: ilk cümle ve kaçınma cümlesi. Path'in kısa üretim özeti kalır;
//   ham metin silinir.
// - `noteId`: kullanıcının kendi notu. Adım cevabının aksine satır **kaldırılır**:
//   hiçbir şey ona dayanmıyor, boş bir kabuk tutmanın anlamı yok.
// - `allNotes`: kullanıcının bütün notları.
// - `all`: hepsi birden — cevaplar, ilk cümleler ve notlar.
//
// Yol değişmez: zaten üretilmiş adımlar geri alınmaz. Kazanılmış rozetler de
// silinmez; rozet geri alınmaz (docs/profile-v2-plan.md).

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  try {
    const { user, adminClient } = await authenticate(req);
    const body = await req.json();
    const answerId = typeof body?.answerId === "string" ? body.answerId : null;
    const noteId = typeof body?.noteId === "string" ? body.noteId : null;
    const origin = body?.origin === true;
    const allNotes = body?.allNotes === true;
    const all = body?.all === true;
    if (!answerId && !noteId && !origin && !allNotes && !all) return json({ code: "invalid_request" }, 400);
    if (noteId && !uuidPattern.test(noteId)) return json({ code: "invalid_request" }, 400);

    if (noteId || allNotes || all) {
      let query = adminClient.from("journal_notes").delete().eq("user_id", user.id);
      if (noteId && !allNotes && !all) query = query.eq("id", noteId);
      const { error } = await query;
      if (error) throw new Error("database_write_failed");
    }

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
