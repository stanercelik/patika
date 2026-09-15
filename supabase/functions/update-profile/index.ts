import { authenticate } from "../_shared/auth.ts";
import { corsHeaders, json } from "../_shared/cors.ts";
import { encryptSensitiveText } from "../_shared/encryption.ts";
import { crisisSignalForText } from "../_shared/providers.ts";

// Hitap adı. Ad serbest metin: kriz taramasından geçer ve şifreli saklanır
// (`profiles.name_ciphertext`). Boş ad gerçek bir seçenek — sütun temizlenir.

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ code: "method_not_allowed" }, 405);

  try {
    const { user, adminClient } = await authenticate(req);
    const body = await req.json();
    if (!("displayName" in (body ?? {}))) return json({ code: "invalid_request" }, 400);

    const raw = body.displayName;
    if (raw !== null && typeof raw !== "string") return json({ code: "invalid_request" }, 400);
    const name = typeof raw === "string" ? raw.trim() : "";
    if (name.length > 60) return json({ code: "invalid_request" }, 400);
    if (name && crisisSignalForText(name)) return json({ status: "crisis" });

    const { error } = await adminClient.from("profiles").upsert({
      user_id: user.id,
      name_ciphertext: name ? await encryptSensitiveText(name) : null,
    }, { onConflict: "user_id" });
    if (error) throw new Error("database_write_failed");

    return json({ status: "updated" });
  } catch (error) {
    const code = error instanceof Error ? error.message : "server_error";
    if (code === "unauthorized") return json({ code }, 401);
    return json({ code: "server_error" }, 500);
  }
});
