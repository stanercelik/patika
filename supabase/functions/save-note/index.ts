import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { handleNoteRequest, type NoteStore } from "../_shared/notes.ts";

// Defter notunu oluştur, güncelle, sil. Ham metin sunucuda şifrelenir ve yalnızca
// `me-profile` ile sahibine çözülür. Kural mantığı `_shared/notes.ts`te.

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  try {
    const { user, adminClient } = await authenticate(req);
    let payload: unknown;
    try {
      payload = await req.json();
    } catch {
      return json({ code: "invalid_request" }, 400);
    }

    const select = "id,created_at,updated_at";
    const store: NoteStore = {
      async insert(userId, ciphertext) {
        const { data, error } = await adminClient.from("journal_notes")
          .insert({ user_id: userId, body_ciphertext: ciphertext }).select(select).single();
        if (error || !data) throw new Error("database_write_failed");
        return data;
      },
      async update(userId, id, ciphertext) {
        const { data, error } = await adminClient.from("journal_notes")
          .update({ body_ciphertext: ciphertext }).eq("id", id).eq("user_id", userId)
          .select(select).maybeSingle();
        if (error) throw new Error("database_write_failed");
        return data;
      },
      async remove(userId, id) {
        const { data, error } = await adminClient.from("journal_notes")
          .delete().eq("id", id).eq("user_id", userId).select("id");
        if (error) throw new Error("database_write_failed");
        return (data?.length ?? 0) > 0;
      },
    };

    const outcome = await handleNoteRequest(user.id, payload, store);
    return json(outcome.body, outcome.http);
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    return json({ code: "server_error" }, 500);
  }
});
