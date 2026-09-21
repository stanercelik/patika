#!/usr/bin/env python3
"""Keşfet ses kayıtlarını yerelde üretir ve pakete koyar.

    ELEVENLABS_API_KEY=... python3 scripts/render-discover-audio.py [seçenekler]

    --locale en|tr          konuşulan dil (varsayılan en; MVP yalnızca İngilizce)
    --voice feminine|masculine   varsayılan feminine (MVP tek ses: kadın)
    --path breath,evening   yalnızca bu patikalar
    --step breath-1,...     yalnızca bu adımlar
    --limit N               en çok N benzersiz kayıt üret
    --force                 var olanı yeniden üret (ham önbellek kullanılmaz)
    --dry-run               hiçbir şey üretme; karakter ve kalan kotayı yaz
    --workers 3

## Güven sınırı

Yalnızca `MyApp/Content/Discover/discover-catalog.json` okunur. Başka hiçbir
metin sese dönüşemez: eski uç fonksiyon "katalog dışı metin seslendirilmesin"
diye vardı, bu işi artık burası yapıyor. Anahtar ortam değişkeninden gelir;
depoya, dosyaya ya da komut satırına yazılmaz.

## Ne üretir

Katalog v2'de bir adım `segments` + `closing`. Her bölüm ayrı bir kayıt; paylaşılan
`closing` tek kayda çöker. Aralarındaki sessizlik TTS'e **hiç gitmez**: istemcide
`SessionScheduler` zamanlar.

Çıktı: `MyApp/Resources/DiscoverAudio/discover-<anahtar12>.mp3` ve her dosyadan
sonra güncellenen `discover-audio.json`. Devam edilebilir: alias var, dosya var,
`sha256` ve `renditionKey` tutuyorsa atlanır; bir metin düzeltmesi yalnızca
etkilenen dosyaları yeniler.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import patika_tts as tts  # noqa: E402

ROOT = tts.ROOT
CATALOG = ROOT / "MyApp/Content/Discover/discover-catalog.json"
OUT = ROOT / "MyApp/Resources/DiscoverAudio"
MANIFEST = OUT / "discover-audio.json"


def load_jobs(locale: str, voice: str, only_paths: set[str], only_steps: set[str]) -> dict[str, dict]:
    """rendition anahtarı -> iş. Aynı metin (paylaşılan kapanış) tek işe çöker."""
    catalog = json.loads(CATALOG.read_text())
    if catalog.get("version") != 2:
        raise tts.RenderError("Katalog v2 değil (segments bekleniyor).")
    voice_id = tts.voice_id_for(voice)
    jobs: dict[str, dict] = {}
    for path in catalog["paths"]:
        if only_paths and path["id"] not in only_paths:
            continue
        for step in path["steps"]:
            if only_steps and step["id"] not in only_steps:
                continue
            parts = [(f"segment-{i}", seg["text"][locale]) for i, seg in enumerate(step["segments"])]
            parts.append(("closing", step["closing"][locale]))
            for part, text in parts:
                key = tts.rendition_key(text=text, locale=locale, voice_id=voice_id)
                job = jobs.setdefault(key, {"key": key, "text": text, "locale": locale, "voice": voice,
                                            "voice_id": voice_id, "aliases": []})
                job["aliases"].append(f"{step['id']}.{locale}.{voice}.{part}")
    return jobs


def is_current(job: dict, manifest: dict) -> bool:
    for alias in job["aliases"]:
        entry = manifest.get(alias)
        if not entry or entry.get("renditionKey") != job["key"]:
            return False
        file = OUT / entry["file"]
        if not file.exists() or tts.sha256_file(file) != entry["sha256"]:
            return False
    return True


def render(job: dict, manifest: dict, force: bool) -> tuple[dict, dict]:
    if force:
        # Ham önbellek de atlanır: kullanıcı sağlayıcıdan taze ses istedi.
        raw = tts.RAW_DIR / f"{tts.raw_key(text=job['text'], locale=job['locale'], voice_id=job['voice_id'])}"
        for suffix in (".mp3", ".json"):
            raw.with_suffix(suffix).unlink(missing_ok=True)
    audio, alignment = tts.synthesize_raw(text=job["text"], locale=job["locale"], voice_id=job["voice_id"])
    filename = f"discover-{job['key'][:12]}.mp3"
    result = tts.post_process(audio, alignment, OUT / filename)
    entry = {
        "file": filename,
        "durationMs": result["measured_ms"],
        "voice": job["voice"],
        "locale": job["locale"],
        "sha256": tts.sha256_file(OUT / filename),
        "renditionKey": job["key"],
    }
    return entry, result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--locale", default="en", choices=["en", "tr"])
    parser.add_argument("--voice", default="feminine", choices=["feminine", "masculine"])
    parser.add_argument("--path", default="")
    parser.add_argument("--step", default="")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--workers", type=int, default=3)
    args = parser.parse_args()

    try:
        tts.require_tools()
        OUT.mkdir(parents=True, exist_ok=True)
        manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
        jobs = load_jobs(args.locale, args.voice,
                         {p for p in args.path.split(",") if p}, {s for s in args.step.split(",") if s})
        pending = [j for j in jobs.values() if args.force or not is_current(j, manifest)]
        if args.limit:
            pending = pending[: args.limit]
        # Ham önbellekte olanlar para harcamaz; kota yalnızca gerçekten gidecek metni sayar.
        billable = [j for j in pending
                    if not (tts.RAW_DIR / f"{tts.raw_key(text=j['text'], locale=j['locale'], voice_id=j['voice_id'])}.mp3").exists()]
        characters = sum(len(tts.sanitize_speech_text(j["text"])) for j in billable)
        remaining, limit, tier = tts.remaining_characters()
        print(f"{len(jobs)} benzersiz kayıt · {len(pending)} üretilecek ({len(billable)} sağlayıcıya gider) · "
              f"{characters} karakter · kalan kota {remaining}/{limit} ({tier})")
        if args.dry_run or not pending:
            return 0
        if characters > remaining:
            print(f"KOTA YETMİYOR: {characters} karakter gerekiyor, {remaining} kaldı. "
                  f"--limit ile küçült ya da planı yükselt.", file=sys.stderr)
            return 2

        # Önce tek iş: anahtar/plan sorunu tam katalogu denemeden ortaya çıksın.
        first = pending[0]
        entry, result = render(first, manifest, args.force)
        for alias in first["aliases"]:
            manifest[alias] = entry
        MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True))
        print(f"  ilk kayıt: {first['aliases'][0]} {entry['durationMs']} ms ({result['input_lufs']:.1f} LUFS ham)")

        suspicious: list[str] = [first["aliases"][0]] if result["suspicious"] else []
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = {pool.submit(render, job, manifest, args.force): job for job in pending[1:]}
            for future in concurrent.futures.as_completed(futures):
                job = futures[future]
                entry, result = future.result()
                for alias in job["aliases"]:
                    manifest[alias] = entry
                MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True))
                flag = "  ⚠ dinle" if result["suspicious"] else ""
                if result["suspicious"]:
                    suspicious.append(job["aliases"][0])
                print(f"  {job['aliases'][0]} {entry['durationMs']} ms{flag}", flush=True)
        print(f"Tamam: {len(pending)} kayıt, manifest {len(manifest)} takma ad.")
        if suspicious:
            print("Süresi hizalamadan çok sapan kayıtlar, dinlenmeli:", ", ".join(suspicious))
        return 0
    except tts.RenderError as error:
        print(f"DURDU: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
