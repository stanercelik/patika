import {
  assert,
  assertEquals,
  assertMatch,
  assertNotEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Defter notları ve rozetler — docs/profile-v2-plan.md Aşama 1 sözleşmesi:
// şifreleme gidiş-dönüşü, kriz reddi, başka kullanıcının notuna erişimin reddi,
// rozet tekilliği.

Deno.env.set("PATIKA_DATA_ENCRYPTION_KEY", btoa(String.fromCharCode(...new Uint8Array(32).fill(9))));
const { decryptSensitiveText } = await import("../_shared/encryption.ts");
const { handleNoteRequest, maxNoteLength, parseNoteRequest } = await import("../_shared/notes.ts");
type NoteStore = import("../_shared/notes.ts").NoteStore;

const alice = "00000000-0000-4000-8000-00000000000a";
const bob = "00000000-0000-4000-8000-00000000000b";

/// Bellek içi depo: sahiplik denetimi gerçek `save-note` deposuyla aynı sözleşmeyi
/// izler (yöntemler `userId` alır, sahibi olmayan satır için null/false döner).
function memoryStore() {
  const rows = new Map<string, { userId: string; ciphertext: string; created: string; updated: string }>();
  let counter = 0;
  let writes = 0;
  const store: NoteStore = {
    insert(userId, ciphertext) {
      writes += 1;
      counter += 1;
      const id = `10000000-0000-4000-8000-${String(counter).padStart(12, "0")}`;
      const now = new Date(1_700_000_000_000 + counter * 1000).toISOString();
      rows.set(id, { userId, ciphertext, created: now, updated: now });
      return Promise.resolve({ id, created_at: now, updated_at: now });
    },
    update(userId, id, ciphertext) {
      const row = rows.get(id);
      if (!row || row.userId !== userId) return Promise.resolve(null);
      writes += 1;
      row.ciphertext = ciphertext;
      row.updated = new Date(1_700_000_100_000).toISOString();
      return Promise.resolve({ id, created_at: row.created, updated_at: row.updated });
    },
    remove(userId, id) {
      const row = rows.get(id);
      if (!row || row.userId !== userId) return Promise.resolve(false);
      writes += 1;
      rows.delete(id);
      return Promise.resolve(true);
    },
  };
  return { store, rows, writeCount: () => writes };
}

async function createNote(store: NoteStore, userId: string, body: string): Promise<string> {
  const outcome = await handleNoteRequest(userId, { action: "create", body }, store);
  assert(outcome.body && "status" in outcome.body && outcome.body.status === "saved");
  return outcome.body.note.id;
}

Deno.test("note is stored encrypted and decrypts back for the owner", async () => {
  const { store, rows } = memoryStore();
  const text = "  Bugün yürüyüşten sonra omuzlarım gevşedi.  ";
  const id = await createNote(store, alice, text);

  const stored = rows.get(id)!.ciphertext;
  assertMatch(stored, /^v1\./);
  assertFalse(stored.includes("omuzlarım"), "plaintext must never reach the store");
  assertEquals(await decryptSensitiveText(stored), text.trim());

  const update = await handleNoteRequest(alice, { action: "update", id, body: "Değişti." }, store);
  assertEquals(update.http, 200);
  assertEquals(await decryptSensitiveText(rows.get(id)!.ciphertext), "Değişti.");
});

Deno.test("crisis text is rejected before anything is encrypted or written", async () => {
  const { store, rows, writeCount } = memoryStore();

  const created = await handleNoteRequest(alice, { action: "create", body: "Artık yaşamak istemiyorum" }, store);
  assertEquals(created, { http: 200, body: { status: "crisis" } });
  assertEquals(writeCount(), 0);
  assertEquals(rows.size, 0);

  // Güncelleme yolu da aynı taramadan geçer; eski not olduğu gibi kalır.
  const id = await createNote(store, alice, "Sakin bir gündü.");
  const before = rows.get(id)!.ciphertext;
  const updated = await handleNoteRequest(alice, { action: "update", id, body: "I want to kill myself" }, store);
  assertEquals(updated, { http: 200, body: { status: "crisis" } });
  assertEquals(rows.get(id)!.ciphertext, before);
});

Deno.test("another user's note cannot be updated or deleted", async () => {
  const { store, rows } = memoryStore();
  const id = await createNote(store, alice, "Sadece benim.");
  const original = rows.get(id)!.ciphertext;

  const update = await handleNoteRequest(bob, { action: "update", id, body: "Ele geçirildi." }, store);
  assertEquals(update, { http: 403, body: { code: "forbidden" } });
  const remove = await handleNoteRequest(bob, { action: "delete", id }, store);
  assertEquals(remove, { http: 403, body: { code: "forbidden" } });
  assertEquals(rows.get(id)?.ciphertext, original);

  // Var olmayan not ile başkasının notu ayırt edilemez: varlık bilgisi sızmaz.
  const missing = await handleNoteRequest(
    bob,
    { action: "delete", id: "20000000-0000-4000-8000-000000000000" },
    store,
  );
  assertEquals(missing, remove);

  assertEquals((await handleNoteRequest(alice, { action: "delete", id }, store)).body, { status: "deleted" });
  assertEquals(rows.size, 0);
});

Deno.test("note requests are validated", () => {
  assertEquals(parseNoteRequest(null), null);
  assertEquals(parseNoteRequest({ action: "create", body: "   " }), null);
  assertEquals(parseNoteRequest({ action: "create", body: "x".repeat(maxNoteLength + 1) }), null);
  assertNotEquals(parseNoteRequest({ action: "create", body: "x".repeat(maxNoteLength) }), null);
  assertEquals(parseNoteRequest({ action: "update", id: "not-a-uuid", body: "Merhaba" }), null);
  assertEquals(parseNoteRequest({ action: "delete" }), null);
  assertEquals(parseNoteRequest({ action: "archive", id: alice }), null);
});

Deno.test("every free-text path shares one crisis source", async () => {
  const providers = await Deno.readTextFile(new URL("../_shared/providers.ts", import.meta.url));
  assertFalse(/const crisisPatterns/.test(providers), "providers.ts must not keep its own pattern list");
  for (const name of ["complete-step", "update-profile"]) {
    const source = await Deno.readTextFile(new URL(`../${name}/index.ts`, import.meta.url));
    assertMatch(source, /_shared\/crisis\.ts/);
  }
});

const migrationUrl = new URL(
  "../../migrations/20260919120000_ben_v2_notes_badges_avatars.sql",
  import.meta.url,
);

/// Yorum satırlarındaki "grant"/"policy" sözcükleri deyim sayılmasın.
async function migrationStatements(): Promise<string> {
  const sql = await Deno.readTextFile(migrationUrl);
  return sql.split("\n").filter((line) => !line.trimStart().startsWith("--")).join("\n");
}

Deno.test("journal notes are unreachable from the client", async () => {
  const sql = await migrationStatements();
  assertMatch(sql, /alter table public\.journal_notes enable row level security/i);
  assertMatch(sql, /revoke all on public\.journal_notes from anon, authenticated/i);
  assertFalse(/create policy \w+ on public\.journal_notes/i.test(sql), "no client policy on journal_notes");
  assertFalse(/grant [^;]+ on public\.journal_notes/i.test(sql), "no client grant on journal_notes");
});

Deno.test("badges are unique per user and can never be taken back", async () => {
  const sql = await migrationStatements();
  assertMatch(sql, /unique \(user_id, badge_id\)/i);
  assertMatch(sql, /grant select, insert on public\.earned_badges to authenticated/i);
  assertFalse(/for (update|delete|all) to authenticated[^;]*earned_badges|on public\.earned_badges\s+for (update|delete|all)/i.test(sql));
  assertFalse(/grant [^;]*(update|delete)[^;]* on public\.earned_badges/i.test(sql));
});

Deno.test("avatar bucket is private, jpeg only and owner scoped", async () => {
  const sql = await migrationStatements();
  assertMatch(sql, /values \('avatars', 'avatars', false,/i);
  assertMatch(sql, /array\['image\/jpeg'\]/i);
  for (const action of ["select", "insert", "update", "delete"]) {
    assertMatch(sql, new RegExp(`avatars_${action}_own on storage\\.objects`, "i"));
  }
  assert((sql.match(/storage\.foldername\(name\)\)\[1\] = \(select auth\.uid\(\)\)::text/g) ?? []).length >= 5);
});
