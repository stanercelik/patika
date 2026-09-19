import { crisisSignalForText } from "./crisis.ts";
import { encryptSensitiveText } from "./encryption.ts";

// Defter notları — docs/profile-v2-plan.md Aşama 1.
//
// Kural mantığı burada, veritabanı erişimi `NoteStore` arkasında: sahiplik ve
// kriz kuralları gerçek bir veritabanı olmadan sınanabilsin diye. `save-note`
// yalnızca bu modülü Supabase'e bağlar.

export const maxNoteLength = 4_000;

export type NoteRow = { id: string; created_at: string; updated_at: string };

/// Bütün yöntemler `userId`yi **zorunlu** alır: sahiplik denetimi çağıranın
/// hatırlamasına bırakılmaz, depo arayüzünün parçasıdır. Sahibi olmayan satır
/// için `update` `null`, `remove` `false` döner.
export type NoteStore = {
  insert(userId: string, ciphertext: string): Promise<NoteRow>;
  update(userId: string, id: string, ciphertext: string): Promise<NoteRow | null>;
  remove(userId: string, id: string): Promise<boolean>;
};

export type NoteRequest =
  | { action: "create"; body: string }
  | { action: "update"; id: string; body: string }
  | { action: "delete"; id: string };

export type NoteOutcome =
  | { http: 200; body: { status: "saved"; note: { id: string; createdAt: string; updatedAt: string } } }
  | { http: 200; body: { status: "deleted" } }
  | { http: 200; body: { status: "crisis" } }
  | { http: 400; body: { code: "invalid_request" } }
  // Başkasının ya da var olmayan notu ayırt ettirmez: varlık bilgisi sızmaz.
  | { http: 403; body: { code: "forbidden" } };

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function parseNoteRequest(raw: unknown): NoteRequest | null {
  if (typeof raw !== "object" || raw === null) return null;
  const input = raw as Record<string, unknown>;

  const body = typeof input.body === "string" ? input.body.trim() : null;
  const id = typeof input.id === "string" && uuidPattern.test(input.id) ? input.id : null;
  const bodyIsValid = body !== null && body.length > 0 && body.length <= maxNoteLength;

  switch (input.action) {
    case "create":
      return bodyIsValid ? { action: "create", body } : null;
    case "update":
      return bodyIsValid && id ? { action: "update", id, body } : null;
    case "delete":
      return id ? { action: "delete", id } : null;
    default:
      return null;
  }
}

export async function handleNoteRequest(
  userId: string,
  raw: unknown,
  store: NoteStore,
): Promise<NoteOutcome> {
  const request = parseNoteRequest(raw);
  if (!request) return { http: 400, body: { code: "invalid_request" } };

  if (request.action === "delete") {
    const removed = await store.remove(userId, request.id);
    return removed
      ? { http: 200, body: { status: "deleted" } }
      : { http: 403, body: { code: "forbidden" } };
  }

  // İstemci ön filtresi sinyal verdiyse bile sunucu kendi taramasını yapar; not
  // yazılmadan önce. Sinyalde satır hiç oluşmaz ve şifreleme bile çağrılmaz.
  if (crisisSignalForText(request.body)) return { http: 200, body: { status: "crisis" } };

  const ciphertext = await encryptSensitiveText(request.body);
  const row = request.action === "create"
    ? await store.insert(userId, ciphertext)
    : await store.update(userId, request.id, ciphertext);
  if (!row) return { http: 403, body: { code: "forbidden" } };

  return {
    http: 200,
    body: {
      status: "saved",
      note: { id: row.id, createdAt: row.created_at, updatedAt: row.updated_at },
    },
  };
}
