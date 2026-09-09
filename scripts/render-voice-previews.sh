#!/usr/bin/env bash
# Onboarding E4 ekranındaki ses örneklerini üretir.
#
# Örnekler uygulama paketine gömülür: anında çalar, çevrimdışı çalışır ve
# kullanıcı başına maliyeti sıfırdır. Dört dosya = 2 ses × 2 dil.
#
# Kullanım:
#   ELEVENLABS_API_KEY=sk_... ./scripts/render-voice-previews.sh
#
# Çıktı: MyApp/Resources/voice-preview-<ses>-<dil>.mp3
#
# Metinler bilerek **gerçek bir oturumun açılışı gibi** yazıldı. "Merhaba, ben
# rehberiniz" tarzı bir tanıtım, kullanıcının asıl duyacağı şeyi temsil etmiyor
# ve seçimi yanlış bilgiyle yaptırıyor.
set -euo pipefail

: "${ELEVENLABS_API_KEY:?ELEVENLABS_API_KEY gerekli (sk_ ile başlar)}"

BASE_URL="${ELEVENLABS_BASE_URL:-https://api.eu.residency.elevenlabs.io}"
MODEL="${ELEVENLABS_MODEL:-eleven_v3}"
VOICE_FEMININE="${ELEVENLABS_VOICE_FEMININE:-zNk6QuA4ZKSf5GTyAPuF}"
VOICE_MASCULINE="${ELEVENLABS_VOICE_MASCULINE:-pFQStpMdprGFILRDrWR2}"

OUT_DIR="$(cd "$(dirname "$0")/.." && pwd)/MyApp/Resources"
mkdir -p "$OUT_DIR"

TEXT_TR="Şimdi birkaç dakika burada duracağız. Yapman gereken bir şey yok... sadece nefesini kendi hâlinde bırak."
TEXT_EN="We are going to stay here for a few minutes. There is nothing you need to do... just let your breath be as it is."

render() {
  local voice_id="$1" pref="$2" lang="$3" text="$4"
  local out="$OUT_DIR/voice-preview-$pref-$lang.mp3"
  local response
  response="$(mktemp)"
  trap 'rm -f "$response"' RETURN
  echo "→ $pref / $lang"
  curl -sS -X POST "$BASE_URL/v1/text-to-speech/$voice_id/with-timestamps?output_format=mp3_44100_128" \
    -H "xi-api-key: $ELEVENLABS_API_KEY" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    --fail-with-body \
    -d "$(python3 -c "
import json,sys
print(json.dumps({
  'text': sys.argv[1],
  'model_id': sys.argv[2],
  'language_code': sys.argv[3],
  # Sunucudaki üretimle **birebir aynı ayarlar**: örnekte duyduğu ses ile
  # oturumda duyacağı ses farklı olursa seçim anlamını yitirir.
  'voice_settings': {
    'stability': 0.5, 'similarity_boost': 0.8,
    'style': 0.0, 'use_speaker_boost': True,
  },
  'apply_text_normalization': 'auto',
}))" "$text" "$MODEL" "$lang")" \
    -o "$response"
  python3 - "$response" "$out" <<'PY'
import base64,json,sys
with open(sys.argv[1], encoding="utf-8") as source:
    payload=json.load(source)
with open(sys.argv[2], "wb") as target:
    target.write(base64.b64decode(payload["audio_base64"]))
PY
  echo "  $(du -h "$out" | cut -f1) → $out"
}

render "$VOICE_FEMININE" feminine tr "$TEXT_TR"
render "$VOICE_FEMININE" feminine en "$TEXT_EN"
render "$VOICE_MASCULINE" masculine tr "$TEXT_TR"
render "$VOICE_MASCULINE" masculine en "$TEXT_EN"

echo
echo "Bitti. Dosyalar MyApp/Resources/ altında; hedef file-system synchronized"
echo "group kullandığı için Xcode'a elle eklemeye gerek yok."
