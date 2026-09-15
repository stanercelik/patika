import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";

// Hesabı ve bütün verileri sil — App Store 5.1.1(v), KVKK Madde 7 / GDPR Madde 17.
//
// Önce kişisel ses dosyaları (`private_audio/<user_id>/...`) silinir; ardından
// kullanıcı. Bütün tablolar `auth.users` üzerinde `on delete cascade` ile bağlı:
// profil, cümleler, ölçümler, path'ler, cevaplar, işler ve manifestler birlikte
// gider. Paylaşılan blok sesleri kişisel veri taşımadığı için kalır.

const bucket = "private_audio";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  try {
    const { user, adminClient } = await authenticate(req);
    const storage = adminClient.storage.from(bucket);

    const { data: folders, error: listError } = await storage.list(user.id, { limit: 1000 });
    if (listError) throw new Error("storage_read_failed");
    for (const folder of folders ?? []) {
      const prefix = `${user.id}/${folder.name}`;
      const { data: files, error: filesError } = await storage.list(prefix, { limit: 1000 });
      if (filesError) throw new Error("storage_read_failed");
      const paths = (files ?? []).map((file) => `${prefix}/${file.name}`);
      if (paths.length > 0) {
        const { error: removeError } = await storage.remove(paths);
        if (removeError) throw new Error("storage_write_failed");
      }
    }

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id);
    if (deleteError) throw new Error("account_delete_failed");

    return json({ status: "deleted" });
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    return json({ code: "server_error" }, 500);
  }
});
