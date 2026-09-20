#!/usr/bin/env python3
"""Ben v2 canlı duman testi (docs/profile-v2-plan.md Doğrulama 3).

Uzak projede iki anonim kullanıcı açar; not, kriz, başka kullanıcının notu, rozet
tekilliği, avatar ve hesap silme akışlarını dener; sonunda ikisini de siler.
Yayımlanabilir anahtar zaten istemcide (AppConfiguration.live); sır yok.

Kullanım: python3 scripts/live-smoke-ben-v2.py
"""
import json, urllib.request, urllib.error, uuid, struct, zlib, sys

URL = "https://aapxqeqduphafisyaadk.supabase.co"
KEY = "sb_publishable_JjMT_0utI6qsAUAWMjW3Sw_RlKvNIZc"
results = []

def req(method, path, token=None, body=None, headers=None, raw=None):
    h = {"apikey": KEY, "Content-Type": "application/json"}
    if token: h["Authorization"] = f"Bearer {token}"
    if headers: h.update(headers)
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    r = urllib.request.Request(URL + path, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            b = resp.read()
            return resp.status, (json.loads(b) if b and b[:1] in b"[{" else b)
    except urllib.error.HTTPError as e:
        b = e.read()
        try: return e.code, json.loads(b)
        except Exception: return e.code, b

def check(name, cond, detail=""):
    results.append((name, bool(cond)))
    print(("PASS " if cond else "FAIL ") + name + (f"  [{detail}]" if not cond else ""))

def anon():
    s, b = req("POST", "/auth/v1/signup", body={})
    assert s == 200, (s, b)
    return b["access_token"], b["user"]["id"]

def jpeg():
    # smallest valid JPEG (1x1)
    return bytes.fromhex("ffd8ffe000104a46494600010100000100010000ffdb004300080606070605080707070909080a0c140d0c0b0b0c1912130f141d1a1f1e1d1a1c1c20242e2720222c231c1c2837292c30313434341f27393d38323c2e333432ffc0000b080001000101011100ffc4001f0000010501010101010100000000000000000102030405060708090a0bffc400b5100002010303020403050504040000017d01020300041105122131410613516107227114328191a1082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aab2b3b4b5b6b7b8b9bac2c3c4c5c6c7c8c9cad2d3d4d5d6d7d8d9dae1e2e3e4e5e6e7e8e9eaf1f2f3f4f5f6f7f8f9faffda0008010100003f00fbfcffd9")

A, aid = anon()
B, bid = anon()
print("users:", aid[:8], bid[:8])

# 1. create note, decrypted through me-profile
s, b = req("POST", "/functions/v1/save-note", A, {"action": "create", "body": "Bugün yürüyüşten sonra omuzlarım gevşedi."})
check("save-note create -> saved", s == 200 and b.get("status") == "saved", (s, b))
note_id = b["note"]["id"] if s == 200 and "note" in b else None

s, b = req("POST", "/functions/v1/me-profile", A, {})
notes = b.get("notes", []) if s == 200 else []
check("me-profile returns decrypted note", any(n["id"] == note_id and n["body"].startswith("Bugün yürüyüşten") for n in notes), (s, str(b)[:200]))
check("me-profile has new fields", s == 200 and all(k in b for k in ["earnedBadges", "completedStepDates", "avatarURL"]), list(b.keys()) if isinstance(b, dict) else b)

# 2. update own note
s, b = req("POST", "/functions/v1/save-note", A, {"action": "update", "id": note_id, "body": "Değişti."})
check("save-note update own -> saved", s == 200 and b.get("status") == "saved", (s, b))

# 3. crisis
s, b = req("POST", "/functions/v1/save-note", A, {"action": "create", "body": "Artık yaşamak istemiyorum"})
check("save-note crisis -> status crisis", s == 200 and b.get("status") == "crisis", (s, b))
s, b = req("POST", "/functions/v1/me-profile", A, {})
check("crisis text was NOT stored", all("yaşamak" not in n["body"] for n in b.get("notes", [])) and len(b.get("notes", [])) == 1, b.get("notes"))
s, b = req("POST", "/functions/v1/save-note", A, {"action": "update", "id": note_id, "body": "I want to kill myself"})
check("crisis on update -> crisis, note unchanged", s == 200 and b.get("status") == "crisis")
s, b = req("POST", "/functions/v1/me-profile", A, {})
check("note text unchanged after crisis update", b["notes"][0]["body"] == "Değişti.", b.get("notes"))

# 4. cross-user
s, b = req("POST", "/functions/v1/save-note", B, {"action": "update", "id": note_id, "body": "Ele geçirildi"})
check("other user update -> 403", s == 403, (s, b))
s, b = req("POST", "/functions/v1/save-note", B, {"action": "delete", "id": note_id})
check("other user delete -> 403", s == 403, (s, b))
s, b = req("POST", "/functions/v1/me-profile", B, {})
check("other user cannot see the note", b.get("notes") == [], b.get("notes"))
s, b = req("GET", "/rest/v1/journal_notes?select=*", B)
check("journal_notes not readable via REST (anon/authenticated)", s in (401, 403, 404) or b == [], (s, b))
s, b = req("GET", "/rest/v1/journal_notes?select=*", A)
check("journal_notes not readable by owner via REST either", s in (401, 403, 404) or b == [], (s, b))

# 5. validation
s, b = req("POST", "/functions/v1/save-note", A, {"action": "create", "body": "   "})
check("empty note -> 400", s == 400, (s, b))
# Sınır sunucudaki maxNoteLength ve istemcideki JournalNote.maxLength ile aynı: 1000.
s, b = req("POST", "/functions/v1/save-note", A, {"action": "create", "body": "x" * 1001})
check("1001 chars -> 400", s == 400, (s, b))
s, b = req("POST", "/functions/v1/save-note", A, {"action": "create", "body": "x" * 1000})
check("exactly 1000 chars -> saved", s == 200 and b.get("status") == "saved", (s, b))
if s == 200 and "note" in b:
    req("POST", "/functions/v1/save-note", A, {"action": "delete", "id": b["note"]["id"]})

# 6. badges: unique, no update/delete
body = [{"user_id": aid, "badge_id": "first-step"}]
h = {"Prefer": "resolution=ignore-duplicates,return=minimal"}
s1, _ = req("POST", "/rest/v1/earned_badges?on_conflict=user_id,badge_id", A, body, h)
s2, _ = req("POST", "/rest/v1/earned_badges?on_conflict=user_id,badge_id", A, body, h)
check("badge insert twice OK (ignore-duplicates)", s1 in (200, 201, 204) and s2 in (200, 201, 204), (s1, s2))
s, b = req("GET", "/rest/v1/earned_badges?select=badge_id", A)
check("exactly one badge row", s == 200 and len(b) == 1, (s, b))
s, b = req("PATCH", "/rest/v1/earned_badges?badge_id=eq.first-step", A, {"badge_id": "week-7"})
s, b2 = req("GET", "/rest/v1/earned_badges?select=badge_id", A)
check("badge update denied / no effect", [r["badge_id"] for r in b2] == ["first-step"], (s, b2))
s, b = req("DELETE", "/rest/v1/earned_badges?badge_id=eq.first-step", A)
s, b2 = req("GET", "/rest/v1/earned_badges?select=badge_id", A)
check("badge delete denied / no effect", len(b2) == 1, (s, b2))
s, b = req("POST", "/rest/v1/earned_badges", A, [{"user_id": bid, "badge_id": "week-3"}])
check("cannot insert badge for another user", s in (401, 403), (s, b))
s, b = req("POST", "/rest/v1/earned_badges", A, [{"user_id": aid, "badge_id": "Bad Id!"}])
check("badge id format enforced", s in (400, 422) or s >= 400, (s, b))
s, b = req("POST", "/functions/v1/me-profile", A, {})
check("me-profile returns earned badge", [x["id"] for x in b.get("earnedBadges", [])] == ["first-step"], b.get("earnedBadges"))

# 7. avatar
img = jpeg()
s, b = req("POST", f"/storage/v1/object/avatars/{aid}/avatar.jpg", A, headers={"Content-Type": "image/jpeg", "x-upsert": "true"}, raw=img)
check("avatar upload own folder", s in (200, 201), (s, b))
s, b = req("POST", f"/storage/v1/object/avatars/{bid}/avatar.jpg", A, headers={"Content-Type": "image/jpeg", "x-upsert": "true"}, raw=img)
check("avatar upload to another user's folder denied", s in (400, 401, 403), (s, b))
s, b = req("POST", f"/storage/v1/object/avatars/{aid}/x.png", A, headers={"Content-Type": "image/png"}, raw=b"\x89PNG\r\n")
check("non-jpeg upload rejected", s >= 400, (s, b))
s, b = req("POST", "/functions/v1/me-profile", A, {})
url = b.get("avatarURL")
check("me-profile returns signed avatarURL", isinstance(url, str) and "token=" in url, url)
stamp = b.get("avatarUpdatedAt")
check("me-profile returns avatarUpdatedAt (ISO timestamp)", isinstance(stamp, str) and "T" in stamp, stamp)

# replacing the photo moves avatarUpdatedAt forward (cross-device cache refresh relies on it)
import time; time.sleep(1.2)
s_up, _ = req("POST", f"/storage/v1/object/avatars/{aid}/avatar.jpg", A, headers={"Content-Type": "image/jpeg", "x-upsert": "true"}, raw=img)
s_pf, b_pf = req("POST", "/functions/v1/me-profile", A, {})
check("replacing the photo advances avatarUpdatedAt", s_up in (200, 201) and b_pf.get("avatarUpdatedAt") and b_pf["avatarUpdatedAt"] > stamp, (stamp, b_pf.get("avatarUpdatedAt")))
if url:
    try:
        with urllib.request.urlopen(url, timeout=30) as r: got = r.read()
        check("signed URL serves the file", got == img)
    except Exception as e:
        check("signed URL serves the file", False, e)
s, b = req("GET", f"/storage/v1/object/authenticated/avatars/{aid}/avatar.jpg", B)
check("other user cannot read the avatar", s >= 400, s)
s, b = req("GET", f"/storage/v1/object/public/avatars/{aid}/avatar.jpg")
check("bucket is not public", s >= 400, s)

# 8. delete note via delete-journal + save-note delete
s, b = req("POST", "/functions/v1/save-note", A, {"action": "create", "body": "ikinci"})
n2 = b["note"]["id"]
s, b = req("POST", "/functions/v1/delete-journal", A, {"noteId": n2})
check("delete-journal noteId", s == 200, (s, b))
s, b = req("POST", "/functions/v1/save-note", A, {"action": "delete", "id": note_id})
check("save-note delete own", s == 200 and b.get("status") == "deleted", (s, b))
s, b = req("POST", "/functions/v1/me-profile", A, {})
check("no notes left", b.get("notes") == [], b.get("notes"))
req("POST", "/functions/v1/save-note", A, {"action": "create", "body": "bir"})
req("POST", "/functions/v1/save-note", A, {"action": "create", "body": "iki"})
s, b = req("POST", "/functions/v1/delete-journal", A, {"allNotes": True})
s, b = req("POST", "/functions/v1/me-profile", A, {})
check("delete-journal allNotes", b.get("notes") == [], b.get("notes"))
req("POST", "/functions/v1/save-note", A, {"action": "create", "body": "uc"})
s, b = req("POST", "/functions/v1/delete-journal", A, {"all": True})
s, b = req("POST", "/functions/v1/me-profile", A, {})
check("delete-journal all also removes notes", b.get("notes") == [], b.get("notes"))
check("badges survive delete-journal all", [x["id"] for x in b.get("earnedBadges", [])] == ["first-step"])

# 9. account deletion
s, b = req("POST", "/functions/v1/delete-account", A, {})
check("delete-account", s == 200 and b.get("status") == "deleted", (s, b))
s, b = req("POST", "/functions/v1/me-profile", A, {})
check("deleted user's token no longer works", s in (401, 403), (s, b))
open("/tmp/patika-smoke-ids.json", "w").write(json.dumps({"a": aid, "b": bid}))

# cleanup B
req("POST", "/functions/v1/delete-account", B, {})
fails = [n for n, ok in results if not ok]
print(f"\n{len(results)-len(fails)}/{len(results)} passed")
sys.exit(1 if fails else 0)
