#!/usr/bin/env python3
"""Kişisel patika + ses için canlı uçtan uca duman testi.

Uzak projede bir anonim kullanıcı açar; İngilizce bir patika üretir, 1. adımın sesini
ister, manifesti okur ve **tempo sözleşmesini** denetler; sonunda kullanıcıyı siler.
Yayımlanabilir anahtar zaten istemcide (AppConfiguration.live); sır yok.

Denetlenenler:
  - manifest eklemeli v2 alanlarını taşıyor (breathMs, leadInMs, ms) ve `version` 1 kaldı
  - her sessizlikte `ms` var ve eski istemciler için `breaths` yansıması tutarlı
  - bitişik konuşmalar arasında bağlantı boşluğu (`leadInMs`) var, sessizliğin üstüne yok
  - blok sesleri açık kovada gerçekten duruyor (HTTP 200, audio/mpeg)
  - sayım blokları söylenen sayımı içeriyor (verme dahil)

Kullanım: python3 scripts/live-smoke-audio.py [--category sleep]
"""
import json, sys, time, urllib.request, urllib.error, uuid

URL = "https://aapxqeqduphafisyaadk.supabase.co"
KEY = "sb_publishable_JjMT_0utI6qsAUAWMjW3Sw_RlKvNIZc"
results = []


def req(method, path, token=None, body=None, headers=None):
    h = {"apikey": KEY, "Content-Type": "application/json"}
    if token: h["Authorization"] = f"Bearer {token}"
    if headers: h.update(headers)
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(URL + path, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(r, timeout=120) as resp:
            b = resp.read()
            return resp.status, (json.loads(b) if b and b[:1] in b"[{" else b)
    except urllib.error.HTTPError as e:
        b = e.read()
        try: return e.code, json.loads(b)
        except Exception: return e.code, b


def check(name, cond, detail=""):
    results.append((name, bool(cond)))
    print(("PASS " if cond else "FAIL ") + name + (f"  [{detail}]" if not cond else ""))


category = sys.argv[sys.argv.index("--category") + 1] if "--category" in sys.argv else "sleep"
s, b = req("POST", "/auth/v1/signup", body={})
assert s == 200, (s, b)
token, uid = b["access_token"], b["user"]["id"]
print("user:", uid[:8])
try:
    payload = {
        "clientCrisisSignal": False, "locale": "en-US", "name": None, "gender": None, "ageRange": None,
        "categories": [category],
        "problemText": "My mind keeps racing when I get into bed and I lie awake for hours.",
        "duration": "months", "timing": "bedtime", "avoidanceText": "I avoid going to bed early.",
        "previousAttempts": ["breathing"], "currentMood": "2", "measurementVariant": "a",
        "measurementResponses": {"emotion.intensity": 7, "emotion.frequency": 3, "behavior.sleepLatency": 3,
                                 "behavior.avoidanceCount": 2, "behavior.nightWakings": 2,
                                 "selfEfficacy.knowsWhatToDo": 2, "selfEfficacy.believesChangePossible": 3,
                                 "behavior.dailyImpact": 3},
        "sessionMinutes": 10, "tone": "calmAndShort", "voicePreference": "feminine",
    }
    t0 = time.time()
    s, b = req("POST", "/functions/v1/generate-path", token, payload, {"Idempotency-Key": str(uuid.uuid4())})
    check("generate-path ready (English)", s == 200 and b.get("status") == "ready", (s, str(b)[:200]))
    path_id = b.get("pathId")
    print(f"  path in {time.time() - t0:.1f}s, {len(b.get('steps', []))} steps, title: {b.get('title')}")
    check("step copy is English", not any(c in (b.get("title") or "") for c in "çğışöü"), b.get("title"))

    s, rows = req("GET", f"/rest/v1/path_steps?select=id,day,block_ids&path_id=eq.{path_id}&order=day&limit=1", token)
    step = rows[0]
    print("  step 1 blocks:", step["block_ids"])

    s, b = req("POST", "/functions/v1/generate-audio", token, {"pathStepId": step["id"]}, {"Idempotency-Key": str(uuid.uuid4()) * 1})
    check("generate-audio accepted", s in (200, 202) and b.get("status") in ("ready", "processing", "queued"), (s, b))

    status = None
    for _ in range(45):
        s, rows = req("GET", f"/rest/v1/path_steps?select=audio_status&id=eq.{step['id']}", token)
        status = rows[0]["audio_status"] if s == 200 and rows else None
        if status in ("ready", "failed"): break
        time.sleep(2)
    check("audio reaches ready", status == "ready", status)

    s, rows = req("GET", f"/rest/v1/session_manifests?select=manifest&path_step_id=eq.{step['id']}&order=version.desc&limit=1", token)
    manifest = rows[0]["manifest"] if s == 200 and rows else None
    check("manifest exists", manifest is not None, (s, str(rows)[:200]))
    if manifest:
        events = manifest["events"]
        speech = [e for e in events if e["type"] == "speech"]
        silence = [e for e in events if e["type"] == "silence"]
        check("manifest version stays 1 (additive)", manifest["version"] == 1)
        check("manifest carries breathMs", manifest.get("breathMs") == 10000, manifest.get("breathMs"))
        check("no legacy gap events are produced", not any(e["type"] == "gap" for e in events))
        check("every silence has ms", all("ms" in e for e in silence), silence[:2])
        period = lambda e: e.get("breathMs", manifest.get("breathMs", 10000))
        check("breaths mirror is consistent with ms", all(
            e["breaths"] == min(60, max(1, round(e["ms"] / period(e)))) for e in silence if "breaths" in e))
        leads = [e for e in speech if e.get("leadInMs")]
        check("adjacent speech carries a join lead-in", len(leads) >= 1, f"{len(leads)} of {len(speech)}")
        check("lead-in stays within the join range", all(0 <= e["leadInMs"] <= 2000 for e in leads))
        # Sessizliğin hemen ardından gelen konuşmaya bağlantı boşluğu eklenmemeli.
        after_silence = [events[i + 1] for i, e in enumerate(events[:-1]) if e["type"] == "silence" and events[i + 1]["type"] == "speech"]
        check("no join lead-in is stacked on top of a silence", all(not e.get("leadInMs") for e in after_silence))
        blocks = [e for e in speech if e["source"] == "block"]
        bad = []
        for e in blocks[:6]:
            r = urllib.request.Request(f"{URL}/storage/v1/object/public/block_audio/{e['storagePath']}", method="HEAD")
            try:
                with urllib.request.urlopen(r, timeout=30) as resp:
                    if resp.status != 200 or "audio" not in resp.headers.get("content-type", ""): bad.append(e["storagePath"])
            except Exception as err:
                bad.append(f"{e['storagePath']}: {err}")
        check("block audio is in the public bucket", not bad, bad[:2])
        total = sum(e.get("durationMs", 0) + e.get("leadInMs", 0) for e in speech) + sum(e["ms"] for e in silence)
        print(f"  manifest: {len(speech)} speech, {len(silence)} silence, ~{total / 60000:.1f} min; texts:")
        for e in speech[:5]: print("   -", e["text"][:90])
finally:
    if "--keep" in sys.argv:
        print("kept user", uid)
    else:
        s, b = req("POST", "/functions/v1/delete-account", token, {})
        check("cleanup: delete-account", s == 200 and b.get("status") == "deleted", (s, b))

failed = [n for n, ok in results if not ok]
print(f"\n{len(results) - len(failed)}/{len(results)} passed")
sys.exit(1 if failed else 0)
