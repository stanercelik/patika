#!/usr/bin/env python3
"""Blok kütüphanesinin sabit (`fixed`) metinlerini yerelde render eder.

    ELEVENLABS_API_KEY=... python3 scripts/render-block-audio.py [seçenekler]

    --locale en|tr          varsayılan en (MVP yalnızca İngilizce)
    --voice feminine        varsayılan feminine (MVP tek ses: kadın)
    --block id[,id]         yalnızca bu bloklar
    --dry-run               üretme; karakter ve kalan kotayı yaz
    --listening-test        "bekleme" dinleme dosyalarını kur (bkz. aşağı)
    --upload                üretilenleri Supabase'e yükle (depolama + satırlar)

## Neden var

Kişisel oturumun ~%70'i bu bloklardan geliyor. Blok sesi kişi başına değil **bir kez**
üretiliyor; bu yüzden sunucudaki edge fonksiyonunun ffmpeg'i olmadan (Deno'da yok)
yapamadığı kırpma, -16 LUFS ve tıklama önleyiciyi burada uyguluyoruz. Yoksa farklı
günlerde render edilmiş iki parça farklı seviyede duyulur ve dikiş tam aha
momentinde ortaya çıkar. Kişisel slot sesi canlıda üretilmeye devam ediyor.

Sunucunun `renditionHash`i ile **aynı** özet hesaplanır (`patika_tts.edge_rendition_hash`,
`supabase/functions/tests/fixtures/rendition-vectors.json` ile sınanır): worker
`block_audio`da bu özeti bulur ve sabit metin için TTS'i hiç çağırmaz.

## Yükleme anahtarsız

`--upload` hizmet anahtarı istemez: Supabase CLI oturumunu kullanır
(`supabase storage cp --linked`, `supabase db query --linked`). Yüklemeden önce
`20260921090000_audio_silence_metrics.sql` uygulanmış olmalı (lead/tail sütunları).

## Dinleme testi

`--listening-test`: `breath.extendedExhale` bloğunun açıklama -> yönerge sınırındaki
beklemeyi 800 / 1500 / 2500 ms ve **eski** 10 sn ile birleştirip `build/listening-test/`
altına yazar. Bir beklemenin doğal olup olmadığı yalnızca kulakla anlaşılır.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import patika_tts as tts  # noqa: E402

ROOT = tts.ROOT
SEEDS = [ROOT / "supabase/migrations/20260909130100_seed_blocks_tr.sql",
         ROOT / "supabase/migrations/20260909150100_seed_blocks_en.sql"]
OUT = ROOT / "build/block-audio"
LISTEN = ROOT / "build/listening-test"
BUCKET = "block_audio"


def load_blocks(locale: str) -> list[dict]:
    """Seed migrasyonlarındaki bloklar + sonraki migrasyonların `update public.blocks` düzeltmeleri.
    Canlıda hangi metin varsa o render edilir: bekleme düzeltmesi yalnızca `silence` girdilerine,
    yeniden yazımlar ise `script` ve `version`a dokunuyor."""
    blocks: dict[str, dict] = {}
    for path in SEEDS:
        sql = path.read_text()
        for m in re.finditer(r"\('([A-Za-z0-9._]+)',\s*(\d+),\s*'(tr|en)'(.*?)\$json\$(\[.*?\])\$json\$", sql, re.S):
            bid, version, loc, _, script = m.groups()
            blocks[bid] = {"id": bid, "version": int(version), "locale": loc, "script": json.loads(script)}
    for path in sorted((ROOT / "supabase/migrations").glob("2026092*_block_script_*.sql")):
        for m in re.finditer(r"update public\.blocks set (?P<set>.*?)script = \$json\$(?P<script>\[.*?\])\$json\$\s*where id = '(?P<id>[^']+)'", path.read_text(), re.S):
            block = blocks[m["id"]]
            block["script"] = json.loads(m["script"])
            version = re.search(r"version = (\d+)", m["set"])
            if version:
                block["version"] = int(version.group(1))
    return [b for b in blocks.values() if b["locale"] == locale]


def jobs_for(blocks: list[dict], voice: str) -> dict[str, dict]:
    """edge özeti -> iş. Aynı metin iki blokta geçerse tek kayda çöker (worker özetle arıyor)."""
    jobs: dict[str, dict] = {}
    for block in blocks:
        for index, entry in enumerate(block["script"]):
            if entry["type"] != "fixed":
                continue
            digest = tts.edge_rendition_hash(text=entry["text"], locale=block["locale"], voice=voice)
            job = jobs.setdefault(digest, {
                "hash": digest, "text": entry["text"], "locale": block["locale"], "voice": voice,
                "voice_id": tts.voice_id_for(voice), "usages": [],
            })
            job["usages"].append((block["id"], block["version"], index))
    return jobs


def render(job: dict) -> dict:
    audio, alignment = tts.synthesize_raw(text=job["text"], locale=job["locale"], voice_id=job["voice_id"])
    path = OUT / job["locale"] / job["voice"] / f"{job['hash']}.mp3"
    result = tts.post_process(audio, alignment, path)
    starts = alignment.get("character_start_times_seconds") or [0.0]
    lead_ms = round(min(float(starts[0]), tts.POST["trim_pad_head_s"]) * 1000)
    tail_ms = round(tts.POST["trim_pad_tail_s"] * 1000)
    meta = {"hash": job["hash"], "path": str(path.relative_to(ROOT)), "duration_ms": result["measured_ms"],
            "lead_silence_ms": lead_ms, "tail_silence_ms": tail_ms, "suspicious": result["suspicious"],
            "usages": job["usages"], "locale": job["locale"], "voice": job["voice"]}
    path.with_suffix(".json").write_text(json.dumps(meta))
    return meta


def is_rendered(job: dict) -> bool:
    base = OUT / job["locale"] / job["voice"] / job["hash"]
    return base.with_suffix(".mp3").exists() and base.with_suffix(".json").exists()


def cli(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["supabase", *args], capture_output=True, text=True)


def sql_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def upload(metas: list[dict]) -> None:
    check = cli("db", "query", "--linked",
                "select column_name from information_schema.columns where table_name='block_audio' and column_name in ('lead_silence_ms','tail_silence_ms')")
    if check.returncode != 0 or check.stdout.count("_silence_ms") < 2:
        raise tts.RenderError("block_audio'da lead/tail sütunları yok. Önce uygula: "
                              "supabase/migrations/20260921090000_audio_silence_metrics.sql")
    rows = []
    for meta in metas:
        storage_path = f"{meta['locale']}/{meta['voice']}/{meta['hash']}.mp3"
        done = cli("--experimental", "storage", "cp", "--linked", "--content-type", "audio/mpeg",
                   str(ROOT / meta["path"]), f"ss:///{BUCKET}/{storage_path}")
        if done.returncode != 0 and "already exists" not in (done.stderr + done.stdout).lower():
            raise tts.RenderError(f"yükleme başarısız {storage_path}: {(done.stderr or done.stdout)[:200]}")
        # Özet başına tek satır: `block_audio_rendition_hash_idx` özeti tekil tutuyor ve
        # worker özetle arıyor, aynı metni kullanan ikinci blok için satır gerekmiyor.
        block_id, block_version, segment_index = meta["usages"][0]
        rows.append("(" + ", ".join([
            sql_quote(block_id), str(block_version), str(segment_index), sql_quote(meta["locale"]),
            sql_quote(meta["voice"]), sql_quote(storage_path), "'audio/mpeg'", str(meta["duration_ms"]),
            str(meta["lead_silence_ms"]), str(meta["tail_silence_ms"]), sql_quote(tts.MODEL_ID), sql_quote(meta["hash"]),
        ]) + ")")
    sql = ("insert into public.block_audio (block_id, block_version, segment_index, locale, voice_preference, storage_path, "
           "content_type, duration_ms, lead_silence_ms, tail_silence_ms, model_id, rendition_hash) values\n" + ",\n".join(rows) +
           "\non conflict (block_id, block_version, segment_index, locale, voice_preference) do update set "
           "storage_path = excluded.storage_path, content_type = excluded.content_type, duration_ms = excluded.duration_ms, "
           "lead_silence_ms = excluded.lead_silence_ms, tail_silence_ms = excluded.tail_silence_ms, "
           "model_id = excluded.model_id, rendition_hash = excluded.rendition_hash;")
    result = cli("db", "query", "--linked", sql)
    if result.returncode != 0:
        raise tts.RenderError(f"satırlar yazılamadı: {(result.stderr or result.stdout)[:300]}")
    print(f"{len(rows)} satır yazıldı, {len(metas)} dosya yüklendi.")


# --- Dinleme testi ----------------------------------------------------------------

def listening_test(locale: str, voice: str) -> None:
    block = next(b for b in load_blocks(locale) if b["id"].startswith("breath.extendedExhale"))
    LISTEN.mkdir(parents=True, exist_ok=True)
    pieces: list[tuple[str, object]] = []   # ("speech", path) | ("silence", seconds) | ("beat", None)
    spoken = 0
    for entry in block["script"]:
        if entry["type"] == "fixed" and spoken < 3:
            digest = tts.edge_rendition_hash(text=entry["text"], locale=locale, voice=voice)
            job = {"hash": digest, "text": entry["text"], "locale": locale, "voice": voice,
                   "voice_id": tts.voice_id_for(voice), "usages": [(block["id"], block["version"], 0)]}
            meta = json.loads((OUT / locale / voice / f"{digest}.json").read_text()) if is_rendered(job) else render(job)
            pieces.append(("speech", ROOT / meta["path"]))
            spoken += 1
        elif entry["type"] == "silence" and spoken:
            if entry.get("breaths") == 1 and not entry.get("landOn"):
                pieces.append(("beat", None))            # açıklama -> yönerge sınırı
            elif spoken < 3:
                pieces.append(("silence", 5.0))          # pratik bekleme: dinleme için kısaltıldı
    for label, beat in (("old-10s", 10.0), ("beat-800ms", 0.8), ("beat-1500ms", 1.5), ("beat-2500ms", 2.5)):
        inputs, chain = [], []
        for kind, value in pieces:
            if kind == "speech":
                inputs += ["-i", str(value)]
            else:
                seconds = beat if kind == "beat" else float(value)
                inputs += ["-f", "lavfi", "-t", f"{seconds}", "-i", "anullsrc=r=44100:cl=mono"]
        n = len(pieces)
        graph = "".join(f"[{i}:a]aresample=44100,aformat=channel_layouts=mono[a{i}];" for i in range(n)) + \
                "".join(f"[a{i}]" for i in range(n)) + f"concat=n={n}:v=0:a=1[out]"
        target = LISTEN / f"{label}.mp3"
        subprocess.run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", graph, "-map", "[out]",
                        "-c:a", "libmp3lame", "-b:a", "64k", str(target)], check=True)
        print(f"  {target.relative_to(ROOT)}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--locale", default="en", choices=["en", "tr"])
    parser.add_argument("--voice", default="feminine", choices=["feminine", "masculine"])
    parser.add_argument("--block", default="")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--listening-test", action="store_true")
    parser.add_argument("--upload", action="store_true")
    args = parser.parse_args()
    try:
        tts.require_tools()
        if args.listening_test:
            listening_test(args.locale, args.voice)
            return 0
        wanted = {b for b in args.block.split(",") if b}
        blocks = [b for b in load_blocks(args.locale) if not wanted or b["id"] in wanted]
        jobs = jobs_for(blocks, args.voice)
        pending = [j for j in jobs.values() if not is_rendered(j)]
        billable = [j for j in pending if not (tts.RAW_DIR / f"{tts.raw_key(text=j['text'], locale=j['locale'], voice_id=j['voice_id'])}.mp3").exists()]
        characters = sum(len(tts.sanitize_speech_text(j["text"])) for j in billable)
        remaining, limit, tier = tts.remaining_characters()
        print(f"{len(blocks)} blok · {len(jobs)} benzersiz kayıt · {len(pending)} üretilecek · {characters} karakter · "
              f"kalan kota {remaining}/{limit} ({tier})")
        if args.dry_run:
            return 0
        if characters > remaining:
            print(f"KOTA YETMİYOR: {characters} > {remaining}", file=sys.stderr)
            return 2
        for job in pending:
            meta = render(job)
            print(f"  {job['usages'][0][0]}#{job['usages'][0][2]} {meta['duration_ms']} ms{'  ⚠ dinle' if meta['suspicious'] else ''}", flush=True)
        if args.upload:
            metas = [json.loads((OUT / j["locale"] / j["voice"] / f"{j['hash']}.json").read_text()) for j in jobs.values()]
            upload(metas)
        return 0
    except tts.RenderError as error:
        print(f"DURDU: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
