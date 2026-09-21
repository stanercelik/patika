"""Patika ses üretimi için ortak parçalar: ElevenLabs çağrısı, kanonik anahtar,
ham ses önbelleği ve ffmpeg son işlemi.

`render-discover-audio.py` ve `render-block-audio.py` bunu kullanır. Anahtar
**yalnızca ortam değişkeninden** okunur (`ELEVENLABS_API_KEY`); depoya, komut
satırına ya da bir dosyaya yazılmaz.

## Neden yerelde

Deno edge ortamında ffmpeg yok. Kırpma, -16 LUFS normalizasyonu ve tıklama
önleyici olmadan farklı günlerde render edilmiş iki parça farklı seviyede duyulur;
bu, kişisel oturumda blok sesi ile taze slot sesi arasındaki dikişin sesi olurdu.

## Anahtar iki katmanlı

- **Ham anahtar** (`raw_key`): yalnızca sağlayıcıya giden şey (metin, dil, ses,
  model, ayarlar). Bunu değiştiren her şey **para** demek. Ham ses `build/` altında
  önbelleklenir; son işlem değişirse yeniden ödenmez.
- **Rendition anahtarı** (`rendition_key`): ham anahtar + son işlem parametreleri.
  Dosyanın baytlarını değiştirebilecek her şeyi kapsar.
"""
from __future__ import annotations

import base64
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "build" / "discover-raw"

BASE_URL = os.environ.get("ELEVENLABS_BASE_URL", "https://api.elevenlabs.io")
MODEL_ID = os.environ.get("ELEVENLABS_MODEL", "eleven_v3")

# Sunucudaki `TTS_POLICY_VERSION` ile aynı olmak zorunda (supabase/functions/_shared/tts.ts).
POLICY_VERSION = "patika-v3-paced-2026-09-21"

# `_shared/tts.ts`teki `voice_settings` ile **birebir**: aynı ses iki yerde iki
# ayarla üretilirse dikiş duyulur. Ölçülür: tests/render_script_contract_test.ts.
VOICE_SETTINGS = {
    "stability": 0.5,
    "similarity_boost": 0.8,
    "style": 0.0,
    "use_speaker_boost": True,
}

# Son işlem. 250/600 ms fade'ler gömülmez: onları istemci seçer (K4).
POST = {
    "trim_pad_head_s": 0.04,
    "trim_pad_tail_s": 0.12,
    "lufs": -16,
    "true_peak": -1.5,
    "lra": 11,
    "declick_s": 0.015,
    "bitrate": "64k",
    "sample_rate": 44100,
    "channels": 1,
}

DEFAULT_VOICE_IDS = {
    "feminine": "zNk6QuA4ZKSf5GTyAPuF",
    "masculine": "pFQStpMdprGFILRDrWR2",
}


class RenderError(RuntimeError):
    """Sert durdurma: 401/402 gibi tekrar denemenin anlamsız olduğu hatalar."""


# --- Kanonikleştirme (sunucuyla birebir) ---------------------------------------

def sanitize_speech_text(value: str) -> str:
    """`_shared/tts.ts` `sanitizeSpeechText`in aynısı."""
    value = re.sub(r"[\[\]{}<>]", "", value)
    value = re.sub(r"[\x00-\x1f\x7f]", " ", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip()[:800]


def language_code(locale: str) -> str:
    return "tr" if locale.lower().startswith("tr") else "en"


def edge_rendition_hash(*, text: str, locale: str, voice: str, model: str = MODEL_ID,
                        prosody: str | None = None, previous_text: str | None = None,
                        next_text: str | None = None) -> str:
    """Edge fonksiyonunun `renditionHash`i ile aynı özet. Blok sesi bu anahtarla
    `block_audio`ya yazılır ve sunucu önbellekte bulur."""
    canonical = json.dumps({
        "policy": POLICY_VERSION,
        "text": sanitize_speech_text(text),
        "locale": language_code(locale),
        "voice": voice,
        "model": model,
        "prosody": prosody or "neutral",
        "previous": sanitize_speech_text(previous_text or ""),
        "next": sanitize_speech_text(next_text or ""),
    }, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def raw_key(*, text: str, locale: str, voice_id: str, model: str = MODEL_ID) -> str:
    """Sağlayıcıya giden her şey; ham ses bu anahtarla önbelleklenir."""
    canonical = json.dumps({
        "text": sanitize_speech_text(text),
        "language": language_code(locale),
        "voice_id": voice_id,
        "model": model,
        "voice_settings": VOICE_SETTINGS,
    }, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def rendition_key(*, text: str, locale: str, voice_id: str, model: str = MODEL_ID) -> str:
    """Dosyanın baytlarını değiştirebilecek her şey: ham anahtar + son işlem + politika."""
    canonical = json.dumps({
        "policy": POLICY_VERSION,
        "raw": raw_key(text=text, locale=locale, voice_id=voice_id, model=model),
        "post": POST,
    }, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


# --- Ortam ----------------------------------------------------------------------

def api_key() -> str:
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key:
        raise RenderError("ELEVENLABS_API_KEY ortam değişkeni yok. Anahtar depoya yazılmaz: "
                          "ELEVENLABS_API_KEY=... python3 scripts/... şeklinde ver.")
    return key


def voice_id_for(voice: str) -> str:
    env = {"feminine": "ELEVENLABS_VOICE_FEMININE", "masculine": "ELEVENLABS_VOICE_MASCULINE"}[voice]
    return os.environ.get(env) or DEFAULT_VOICE_IDS[voice]


def require_tools() -> None:
    for tool in ("ffmpeg", "ffprobe"):
        try:
            subprocess.run([tool, "-version"], capture_output=True, check=True)
        except (OSError, subprocess.CalledProcessError) as error:
            raise RenderError(f"{tool} bulunamadı: {error}")


def remaining_characters() -> tuple[int, int, str]:
    """(kalan, limit, plan). Sunucuya ses göndermeden kotayı görmek için."""
    request = urllib.request.Request(f"{BASE_URL}/v1/user/subscription", headers={"xi-api-key": api_key()})
    with urllib.request.urlopen(request, timeout=20) as response:
        data = json.load(response)
    used, limit = int(data.get("character_count", 0)), int(data.get("character_limit", 0))
    return max(0, limit - used), limit, str(data.get("tier", "?"))


# --- Sağlayıcı ------------------------------------------------------------------

def synthesize_raw(*, text: str, locale: str, voice_id: str, model: str = MODEL_ID) -> tuple[bytes, dict]:
    """Ham MP3 + hizalama. Ham önbellekte varsa **para harcamaz**."""
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    key = raw_key(text=text, locale=locale, voice_id=voice_id, model=model)
    mp3_path, alignment_path = RAW_DIR / f"{key}.mp3", RAW_DIR / f"{key}.json"
    if mp3_path.exists() and alignment_path.exists():
        return mp3_path.read_bytes(), json.loads(alignment_path.read_text())

    clean = sanitize_speech_text(text)
    body = json.dumps({
        "text": clean,
        "model_id": model,
        "language_code": language_code(locale),
        "voice_settings": VOICE_SETTINGS,
        "apply_text_normalization": "auto",
    }).encode()
    url = f"{BASE_URL}/v1/text-to-speech/{voice_id}/with-timestamps?output_format=mp3_44100_128"
    last_error: Exception | None = None
    for attempt in range(3):
        request = urllib.request.Request(url, data=body, method="POST", headers={
            "xi-api-key": api_key(), "Content-Type": "application/json", "Accept": "application/json",
        })
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                payload = json.load(response)
            audio = base64.b64decode(payload["audio_base64"])
            alignment = payload.get("normalized_alignment") or payload.get("alignment") or {}
            if len(audio) < 1_000 or not alignment.get("character_end_times_seconds"):
                raise ValueError("boş ya da hizalamasız yanıt")
            mp3_path.write_bytes(audio)
            alignment_path.write_text(json.dumps(alignment))
            return audio, alignment
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", "replace")[:300]
            if error.code in (401, 402, 403):
                # Tekrar denemek para ve zaman harcar; anahtar/plan sorunu, sert dur.
                raise RenderError(f"HTTP {error.code}: {detail}")
            last_error = RuntimeError(f"HTTP {error.code}: {detail}")
            if error.code < 500 and error.code != 429:
                raise last_error
        except Exception as error:  # ağ, zaman aşımı, bozuk yanıt
            last_error = error
        time.sleep(2 * (2 ** attempt))
    raise RuntimeError(f"sentez başarısız (3 deneme): {last_error}")


# --- ffmpeg ---------------------------------------------------------------------

def _run(args: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(args, capture_output=True, text=True, check=True)


def decoded_seconds(path: pathlib.Path) -> float:
    """Konteyner başlığına güvenmeden **çözerek** ölç: `AVAudioFile.length /
    sampleRate` tam olarak bunu raporlar."""
    process = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "s16le", "-ac", "1", "-ar", str(POST["sample_rate"]), "-"],
        capture_output=True, check=True,
    )
    return len(process.stdout) / 2 / POST["sample_rate"]


def post_process(raw_mp3: bytes, alignment: dict, out_path: pathlib.Path) -> dict:
    """Kırp, iki geçişli -16 LUFS, tıklama önleyici, kodla. Ölçümü döndürür."""
    starts = alignment.get("character_start_times_seconds") or [0.0]
    ends = alignment["character_end_times_seconds"]
    with tempfile.TemporaryDirectory() as tmp:
        raw_path = pathlib.Path(tmp) / "raw.mp3"
        raw_path.write_bytes(raw_mp3)
        raw_length = decoded_seconds(raw_path)

        # Hizalama tabanlı kırpma: nefesli bir meditasyon sesinde eşik tabanlı
        # `silenceremove` güvenilmez, konuşmanın nefes payını keser.
        head = max(0.0, float(starts[0]) - POST["trim_pad_head_s"])
        tail = min(raw_length, float(ends[-1]) + POST["trim_pad_tail_s"])
        trim = f"atrim=start={head:.4f}:end={tail:.4f},asetpts=N/SR/TB"
        target = f"I={POST['lufs']}:TP={POST['true_peak']}:LRA={POST['lra']}"

        # Geçiş 1: ölç. Tek geçiş dinamiktir ve deterministik değildir; önbellek
        # anahtarını bozar.
        first = subprocess.run(
            ["ffmpeg", "-hide_banner", "-nostats", "-i", str(raw_path), "-af",
             f"{trim},loudnorm={target}:print_format=json", "-f", "null", "-"],
            capture_output=True, text=True, check=True,
        )
        match = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", first.stderr, re.S)
        if not match:
            raise RuntimeError("loudnorm ölçümü okunamadı")
        m = json.loads(match.group(0))
        duration = tail - head
        fade = POST["declick_s"]
        chain = ",".join([
            trim,
            f"loudnorm={target}:measured_I={m['input_i']}:measured_TP={m['input_tp']}:"
            f"measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:"
            f"offset={m['target_offset']}:linear=true",
            f"aresample={POST['sample_rate']}",
            f"afade=t=in:d={fade}",
            f"afade=t=out:st={max(0.0, duration - fade):.4f}:d={fade}",
        ])
        out_path.parent.mkdir(parents=True, exist_ok=True)
        _run(["ffmpeg", "-v", "error", "-y", "-i", str(raw_path), "-af", chain,
              "-ac", str(POST["channels"]), "-ar", str(POST["sample_rate"]),
              "-c:a", "libmp3lame", "-b:a", POST["bitrate"], "-write_xing", "1",
              "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
              str(out_path)])

    measured = decoded_seconds(out_path)
    spoken = float(ends[-1]) - float(starts[0])
    return {
        "measured_ms": round(measured * 1000),
        "spoken_ms": round(spoken * 1000),
        # Kırpma payı ~160 ms; büyük sapma dosyanın kesildiği ya da bozulduğu anlamına gelir.
        "suspicious": abs(measured - spoken) > 0.3 + POST["trim_pad_head_s"] + POST["trim_pad_tail_s"],
        "input_lufs": float(m["input_i"]),
    }


def sha256_file(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


# --- Kendini sına -----------------------------------------------------------------

def _selftest() -> None:
    vectors = json.loads((ROOT / "supabase/functions/tests/fixtures/rendition-vectors.json").read_text())
    for vector in vectors["edge_rendition_hash"]:
        got = edge_rendition_hash(**vector["input"])
        assert got == vector["hash"], f"sunucu ile Python farklı hesaplıyor: {vector['input']}\n {got}\n {vector['hash']}"
    assert POLICY_VERSION == vectors["policy"], "TTS_POLICY_VERSION sunucuyla ayrışmış"
    assert VOICE_SETTINGS == vectors["voice_settings"], "voice_settings sunucuyla ayrışmış"
    print(f"patika_tts selftest: {len(vectors['edge_rendition_hash'])} vektör sunucuyla eşleşti")


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        _selftest()
