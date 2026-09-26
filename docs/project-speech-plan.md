# Meditasyon ses motoru: tempo düzeltmesi + Keşfet ve kişisel patikanın seslendirilmesi

## Context

Ürün sahibi iki şey bildirdi: (1) oturumda **bağlantılı cümleler arasında çok uzun bekleniyor** —
meditasyon ürünün ana değeri ve şu an doğal duyulmuyor; (2) **ses hiç üretilmedi** — Keşfet'in
10 patikası "Yakında" görünüyor, kişisel patika sessiz sürüme düşüyor.

Araştırma iki şeyi ortaya çıkardı:

**Tempo hatası mimaride.** `docs/PRD-Ek-Oturum-Motoru-ve-JIT.md` §2'deki K1–K6 kuralları
(350 ms join, sessizlik yalnızca yazıldığı yerde, konuşma nefes sınırına yuvarlanmaz, uzun
sessizlikten sonra 600 ms yumuşak giriş) **hiç uygulanmamış** — `joinGap`, `leadIn`,
`charactersPerSecond` depoda sıfır kez geçiyor. Şema yalnızca tek tür duraklama biliyor:
`SessionSilence.breaths: Int` × sabit 10 sn. Yazılabilen en kısa bekleme 10 saniye, ve seed
bloklar bunu tam da açıklama→yönerge sınırına koymuş ([20260909130100_seed_blocks_tr.sql:38](supabase/migrations/20260909130100_seed_blocks_tr.sql#L38),
`:72`, `:91`, `:126` + EN eşleri) — oturum başına ~60 saniye boşluk.

**Üç saat birbirini tutmuyor:**

| Saat      | Nerede                                                                                        | Neye inanıyor                                |
| --------- | --------------------------------------------------------------------------------------------- | -------------------------------------------- |
| Zamanlama | [SessionAudioPlayer.swift:144-147](MyApp/Features/Session/SessionAudioPlayer.swift#L144-L147) | sonraki dosya `Σ durationMs` + gap'te başlar |
| Ekran     | [SessionScript.swift:111-141](MyApp/Features/Session/SessionScript.swift#L111-L141)           | süreler `durationMs` ve sabit 10 sn'den      |
| Gerçek    | MP3'ün kendisi                                                                                | `durationMs` ≠ dosya uzunluğu                |

`durationMs` [tts.ts:192](supabase/functions/_shared/tts.ts#L192)'de ElevenLabs'in **son karakterin
hizalama zamanından** türetiliyor; MP3'ün baş/son sessizliğini içermiyor. Yani TTS dolgusu bizim
planladığımız boşluğun **üstüne** biniyor, dosya beyan edilenden uzunsa da sonraki dosyayla çakışıyor.

Ayrıca `blocks.breath_pattern` manifest'e hiç taşınmıyor: `breath.box` 4/4/4/4 = 16 sn/nefes ama
istemci hep 10 sn sayıyor — kutu nefesi sessizlikleri 64 sn yerine 40 sn çalıyor ve ekrandaki
nefes animasyonuyla kalıcı olarak faz dışı.

**Ses üretimi tek bir şeye takılı:** Supabase'teki `ELEVENLABS_API_KEY` geçersiz
(`tts_request_failed_400_invalid_api_key`, sonra 402 `payment_required`). Kodda başka eksik yok;
`render-discover-audio` v3 olarak **dağıtık** durumda (doğrulandı, 2026-09-20).

### Ürün sahibi kararları (bu oturumda alındı)

| Karar              | Seçim                                                                                                     |
| ------------------ | --------------------------------------------------------------------------------------------------------- |
| Keşfet ses dili    | **TR + EN ikisi de**, konuşulan dil `AppLocale.current`'ı izler                                           |
| TTS modeli         | **`eleven_v3` kalır** → `speed` yok, SSML `<break>` yok. Tempo tamamen bizim sessizlik modelimizden gelir |
| Ses kimliği        | **Mevcut iki ses id'si kalır** (`ELEVENLABS_VOICE_FEMININE` / `MASCULINE`), dil `language_code` ile       |
| Keşfet adım yapısı | **İç bölümlü yapıya geçilir**: `guidance` tek metin yerine `segments: [{text, quietMs}]`                  |
| Blok duraklamaları | **Önce dinleme testi** (800/1500/2500 ms), sonra sabitlenir                                               |
| Render sırası      | **Önce küçük örnek** (1 patika + 1 blok), onaylanınca tam render                                          |
| Dosya saklama      | **Git LFS** (`MyApp/Resources/DiscoverAudio/*.mp3`)                                                       |
| Üretim yolu        | Ürün sahibi geçerli ElevenLabs API anahtarını sağlar; yerel script + `supabase secrets set`               |

> **Ön koşul (bloklayıcı):** geçerli `ELEVENLABS_API_KEY`. Aşama 0–3 ve 5 anahtarsız yapılabilir;
> Aşama 4, 6 ve 7 anahtar olmadan başlamaz.

---

## Aşama 0 — Gerçek süreler (şema değişmeden, tek başına gönderilebilir)

Çakışmayı ve "dolgu boşluğun üstüne biniyor" hatasını şema değiştirmeden bitirir.

- **Yeni `supabase/functions/_shared/mp3.ts`**: `mp3DurationMs(bytes): number` — MPEG çerçeve
  başlıklarını yürüyüp `samplesPerFrame / sampleRate` toplar, ID3v2 ve Xing/Info çerçevesini atlar
  (~70 satır, bağımlılık yok). [tts.ts:190-192](supabase/functions/_shared/tts.ts#L190-L192)'nin
  hizalama tabanlı hesabının yerine geçer.
- `SpeechResult`'a `leadSilenceMs` / `tailSilenceMs` eklenir (hizalamanın ilk `start_time` ve
  son `end_time`'ından). `block_audio` ve `audio_assets` tablolarına iki nullable integer sütun.
- **İstemci dosyayı ölçer.** [SessionAudioPlayer.play](MyApp/Features/Session/SessionAudioPlayer.swift#L86-L112)
  şu an zaman çizelgesini dosyaları yüklemeden **önce** kuruyor (`:87` vs `:88-95`). Sıra tersine
  çevrilir: yükle → `file.length / processingFormat.sampleRate` ile ölç → çizelgeyi ölçümlerle kur.
  `private(set) var resolvedTimeline` açılır; [SessionRunner.audioDidStart()](MyApp/Features/Session/SessionRunner.swift#L110-L116)
  segmentleri **çözülmüş** çizelgeden yeniden türetir. Çağıranlar:
  [PathSessionViewModel.startPrepared:216,221-232](MyApp/Features/Path/PathSessionViewModel.swift#L216)
  ve `beginAudio:477-483`.

**Sözleşme:** `durationMs` bundan sonra _planlama_ değeridir (toplam süre, ses gelmeden çizilen iz,
E2 ±%20 doğrulaması). Oynatıcı **asla** ona göre zamanlamaz; yüklediği dosyaya göre zamanlar.

---

## Aşama 1 — Duraklama şeması: üç kademe, tek sözlük

| Kademe       | Uzunluk    | Yazılır mı    | Gösterim                                           | Nefese hizalı                  |
| ------------ | ---------- | ------------- | -------------------------------------------------- | ------------------------------ |
| **join**     | 250–400 ms | Hayır, makine | `speech.leadInMs` (sonraki konuşmanın özelliği)    | asla                           |
| **beat**     | 0.8–3 sn   | Evet          | `{"type":"silence","ms":1500}`                     | asla                           |
| **practice** | ≥ 1 nefes  | Evet          | `{"type":"silence","breaths":N,"landOn":"exhale"}` | evet, bloğun kendi periyoduyla |

Belirleyici hamle: **join bir olay değildir.** Bugün `{type:"gap",milliseconds:300}` kendi
`SessionSegment`'ini üretiyor ([SessionScript.swift:124-130](MyApp/Features/Session/SessionScript.swift#L124-L130)),
bu `runner.currentSegment?.id`'yi değiştiriyor ve [SessionStageView.swift:72](MyApp/Features/Session/SessionStageView.swift#L72)'deki
600 ms cross-fade'i tetikliyor — **aynı cümle 300 ms'lik bir boşluk için solup geri geliyor.**
Join'i `leadInMs`'e katlamak K1 ve K5'i aynı anda çözüyor.

### Sunucu DTO — [supabase/functions/\_shared/session.ts](supabase/functions/_shared/session.ts)

```ts
type SessionSpeechEventDTO = {
  type: "speech";
  source: "personal" | "block";
  assetId: string;
  storagePath: string;
  text: string;
  durationMs: number; // dosyanın gerçek çözülmüş uzunluğu (planlama değeri)
  leadInMs?: number; // 0..2000, komşu dolguları düşülmüş join
};

type SessionSilenceEventDTO = {
  type: "silence";
  ms?: number; // 250..300_000 — yetkili değer, v2'de hep var
  breaths?: number; // 1..60 — eski istemciler için ayna, hep yazılır
  breathMs?: number; // 4000..30_000 — hizalandığı nefes periyodu
  landOn?: "inhale" | "exhale" | null;
  displayText?: string | null;
};
// manifest seviyesinde: breathMs?: number (varsayılan 10_000)
```

**`version` 1'de kalır.** [SessionManifest.swift:49-51](MyApp/Models/SessionManifest.swift#L49-L51)
1 dışındaki her sürümü reddediyor ve ses yolu decode hatasında kapanıyor — 2'ye çıkmak güncellemeyen
her kullanıcıda sesi karartırdı. Tüm yeni alanlar **opsiyonel ve eklemeli**; her sessizlik hem `ms`
hem `breaths` yazar; alt-nefes duraklamalar zaten `silence` olarak hiç yayımlanmaz (join'dir), yani
eski istemci 400 ms'yi asla 10 sn'ye yuvarlayamaz. Eski `gap` olayları birlik içinde kalır ve
doğrulanır, ama bir daha üretilmez.

Doğrulama (`validateSessionManifest`, [session.ts:56-73](supabase/functions/_shared/session.ts#L56-L73)
yerine): `ms` ile `breaths`'in **tutarlılığı** da denetlenir —
`breaths === max(1, round(ms / period))`, yoksa eski istemci için bırakılan ayna yalan söyleyebilir.
`events.length <= 100` sınırı kalır ([20260909150000_adaptive_session_engine.sql:94](supabase/migrations/20260909150000_adaptive_session_engine.sql#L94)'teki
SQL CHECK'in aynası; `gap` olaylarının kalkması sayıyı **düşürür**, migrasyon gerekmez).

### `landOn` sunucuda çözülür

Bugün [SessionManifest.swift:93](MyApp/Models/SessionManifest.swift#L93)'te decode ediliyor ve
**hiçbir yerde kullanılmıyor**. İstemcide çözmek, istemcinin çizelge uzunluğunu değiştirmesi demek
olurdu — sürüklenme geri gelir. `audio-worker.ts`'e saf, Deno'da test edilebilir bir fonksiyon:

```ts
alignedSilenceMs(breaths, breathMs, landOn, phaseOffsetMs): number
```

`phaseOffsetMs` çizelge boyunca biriken nefes-içi konum. Çıktı deterministik bir tamsayı; istemci
aptal kalır.

### İstemci

- `SessionSilence`: `breaths: Int` yerine `milliseconds: Int` yetkili; `breaths`/`breathSeconds`
  opsiyonel. Eski manifestlerde `breaths * (breathMs ?? manifest.breathMs ?? 10_000)`.
- `SessionSpeech.leadInMilliseconds: Int` (`decodeIfPresent ?? 0`).
- [SessionTimeline.swift](MyApp/Features/Session/SessionTimeline.swift) yeniden yazılır:
  `init(manifest:measured: [UUID: TimeInterval] = [:])`, her `Entry`'ye `leadIn`/`fadeIn`/`fadeOut`.
  Bugün bu dosya `breathDuration: TimeInterval = 10` parametresi taşırken `SessionScript.swift:137`
  bağımsız olarak `BreathCycle.period` kullanıyor — **aynı sayı için iki kaynak**; birleştirilir.
- Yeni `MyApp/Features/Session/SessionPacing.swift` — türetilebilir olduğu için DTO alanı değil,
  saf fonksiyon:

```swift
enum SessionPacing {
    static let joinGap: TimeInterval = 0.35      // K1
    static let fadeInShort: TimeInterval = 0.25  // §3.1
    static let fadeInLong: TimeInterval = 0.60   // K4
    static let fadeOut: TimeInterval = 0.25
    static let declick: TimeInterval = 0.015
    static func fadeIn(afterGap gap: TimeInterval, breath: TimeInterval) -> TimeInterval {
        gap > breath ? fadeInLong : fadeInShort
    }
}
```

- `SessionScript.build(from:)` artık `manifest.events` değil **`SessionTimeline.entries`** tüketir
  — ekran ve ses farklı sayı hesaplayamaz. Ayrıca `displayText`'i olmayan bir sessizliği önceki
  konuşmayla **tek segmente birleştirir** (K5: son cümle duraklama boyunca ekranda kalır, yeniden
  belirmez). `displayText` taşıyan sessizlik (Keşfet'in "quiet" metni) kendi segmenti olarak kalır.

---

## Aşama 2 — Sunucu: join, breathMs, seed yeniden yazımı

- [audio-worker.ts:224-227](supabase/functions/_shared/audio-worker.ts#L224-L227): düz 300 ms
  `gap` olayı yerine sonraki konuşmaya `leadInMs`. Dolgu telafisi:
  `leadInMs = max(80, 350 - prev.tailSilenceMs - next.leadSilenceMs)` — TTS dolgusu artık boşluğun
  **üstüne binmek** yerine **içinde soğurulur**. 80 ms taban, join'in sert kesme olmasını önler.
- `breathMsFor(block)` [audio-worker.ts:233-241](supabase/functions/_shared/audio-worker.ts#L233-L241)'den
  çıkarılır ve `for (const block of blocks)` döngüsünde **blok başına** çağrılır; o bloğun yazdığı
  her sessizliğe `breathMs` damgalanır.
- [generate-audio/index.ts:36](supabase/functions/generate-audio/index.ts#L36) `prosody: "manifest-v1"`
  → `"manifest-v2"`.

### Seed yeniden yazımı — kural

Altı `breaths: 1` girdisinin **hiçbiri** tek bir fikrin iki cümlesi arasında değil; hepsi
_açıklama → yönerge_ sınırında. Yani doğru düzeltme 350 ms değil, bir **beat**:

1. `breaths ≥ 2` → **değişmez** (gerçek pratik duraklaması; artık bloğun kendi periyoduyla çalar).
2. `breaths == 1` **`landOn` ile** → **değişmez** (kasten bir fazda bitiyor; join değil, yerleşme).
3. `breaths == 1` **`landOn`suz**, iki konuşma arasında → **`{"ms": <dinleme testinden}`**.

**Yeni migrasyonlar** (eski seed'ler asla düzenlenmez):

- `supabase/migrations/20260921100000_block_script_pacing.sql` — 20 blok için ayrı ayrı açık
  `update ... set script = $json$[…]$json$`, diff'te okunabilir. `blocks.version` **bumplanmaz**
  (metin değişmiyor; `block_audio` çakışma anahtarı `block_version` taşıyor). Sonuna doğrulayıcı:

```sql
create or replace function private.block_script_is_valid(script jsonb) ... -- silence: ms XOR breaths
alter table public.blocks add constraint blocks_script_shape check (private.block_script_is_valid(script));
```

Sıra önemli: `update`'ler CHECK'ten **önce** çalışmalı.

- `supabase/migrations/20260921100100_invalidate_session_manifests.sql` — ayrı dosya, yeniden
  çalıştırılabilir:

```sql
delete from public.session_manifests;   -- türetilmiş artefakt; block_audio/audio_assets'e dokunulmaz
update public.path_steps set audio_status = 'pending'
 where audio_status in ('ready','failed') and completed_at is null;
```

> **Dağıtım sırası:** fonksiyonlar (`manifest-v2` + `TTS_POLICY_VERSION`) **önce**, SQL
> geçersizleştirme **sonra**. Ters sırada ilk istek eski kodla yeniden kurar.
> Ayrıca `PathSessionViewModel.beginAudio:459` yalnızca `pending` durumda ses istiyor — tek başına
> `manifest-v2` yetmez, SQL de gerekir.

---

## Aşama 3 — Oynatma: sıralı zamanlama, gerçek sessizlik, fade

Bugün her dosya tek bir `AVAudioPlayerNode`'a **mutlak** `AVAudioTime`'la zamanlanıyor
([SessionAudioPlayer.swift:144-147](MyApp/Features/Session/SessionAudioPlayer.swift#L144-L147));
`AVAudioPlayerNode` kuyruğu zaten seri, dolayısıyla uzun bir dosya sonrasını sessizce itiyor ve
`:372`'deki `ContinuousClock` kendi fikrinde kalıyor — metin sesin önüne geçiyor.

**Mutlak zamanlar gider, akışın kendisi çizelge olur.** Sırayla, hepsi `at: nil`:

```
[fade-in baş tamponu][orta segment][fade-out son tamponu][sessizlik tamponları][fade-in baş]…
```

Çakışma yapısal olarak imkânsızlaşır.

**Fade yöntemi — değerlendirilen ve elenen seçenekler:**

- _Segment başına `AVAudioPlayerNode`_: **hayır.** `volume`'un örnek-doğru rampası yok; 20–40
  node'un ses seviyesini ana iş parçacığından 50 ms çözünürlükle sürmek gerekirdi — ürünün en
  hassas anında.
- _`AVAudioUnitEQ` / mixer otomasyonu_: **hayır.** AVAudioEngine'de örnek-doğru parametre
  otomasyonu yok.
- _Tamamen önceden fade'lenmiş PCM_: **hayır.** 22 sn mono float32 ≈ 3.9 MB; oturum başına 60–75 MB.
- _Yalnızca **kenar** tamponları_: **evet.** Fade'ler 600/250 ms; o kadar frame okunur, eğri
  yerinde uygulanır (eşit güç, doğrusal değil), ortası `scheduleSegment` ile dosyadan doğrudan
  çalar. Varlık başına ~850 ms PCM ≈ 150 KB. Tek node, otomasyon yok.

**Sessizlik:** node formatında tek bir 1 sn'lik sessiz tampon `floor(saniye)` kez + tam ölçülü
artık. Bu aynı zamanda `:336`'daki RMS tap'in duraklamada gerçek sıfır okumasını sağlar, yani
`audioEnergy` [SessionEnvelope](MyApp/Features/Session/SessionEnvelope.swift#L8)'in 450 ms release'iyle
PRD §4.1'in tarif ettiği gibi sönümlenir.

**Seek/resume** ([:191-208](MyApp/Features/Session/SessionAudioPlayer.swift#L191-L208)): şekli
korur, ilk parça kısmi olabilir — **fade-in yok**, yalnızca 120 ms declick (kullanıcı cümlenin
ortasına inmek istedi; orada 600 ms şişme arıza gibi duyulur).

**Sürüklenme koruması:** `tick()` [:370-375](MyApp/Features/Session/SessionAudioPlayer.swift#L370-L375)'te
saniyede bir `voice.playerTime(forNodeTime:)` ile karşılaştır; |Δ| > 150 ms ise `accumulated`'ı
hizala.

**Yanında düzeltilecek iki gizli hata:** `buildGraph` `isGraphBuilt` korumalı (`:330`) ama `format`
ilk yüklenen dosyadan geliyor (`:96`) — farklı örnekleme hızında ikinci oturum eski bağlantı
formatını kullanır; koruma kaldırılır ya da assert konur.

---

## Aşama 4 — Keşfet: iç bölümlü yapı + TR/EN render

### İçerik: `discover-catalog.json` v2

```jsonc
{ "version": 2, "audioLocales": ["tr", "en"],
  "paths": [ { …, "steps": [ {
      "id": "breath-1", "title": {…},
      "segments": [ { "text": {"en":…,"tr":…}, "quietMs": 30000 }, … ],
      "closing": {"en":…,"tr":…}
  } ] } ] }
```

70 adımın metni yeniden yazılır (4–6 bölüm, adım ~3.5–4 dk). Bugünkü `guidance` ilk bölümün
çekirdeği olarak korunur; yazım `Tone`/`BannedPhrases` kurallarına ve mevcut
[Tests/DiscoverLibraryTests/main.swift](Tests/DiscoverLibraryTests/main.swift)'in "konuşulan metinde
rakam ve uzun tire yok" kısıtına uyar.

### İstemci ([DiscoverLibrary.swift](MyApp/Features/Discover/DiscoverLibrary.swift), [DiscoverCatalog.swift](MyApp/Features/Discover/DiscoverCatalog.swift))

- `audioLocale` → `spokenLocale: AppLocale { AppLocale.current }`.
- Kayıt anahtarı `"<stepId>.<locale>.<voice>.<part>"` (part artık `segment-<i>` | `closing`).
- `audioIsReady` **yalnızca mevcut dil** üzerinden ölçülür (`:123-132` + üç okuma noktası
  [DiscoverPathView.swift:246,251,252](MyApp/Features/Discover/DiscoverPathView.swift#L246),
  `DiscoverTrailMap.swift:31`). İkisini birden şart koşmak, İngilizce render gecikirse Türk
  kullanıcıdan Türkçe patikaları saklardı.
- `playback(for:in:)` (`:133-149`): `quietSeconds / 10` tamsayı bölmesi gider, `SessionSilence(milliseconds:)` gelir.
- **`checkpointID` (`:147`) anahtarına locale eklenir** — dil değiştiren kullanıcı başka zamanlı
  bir kayıtta yanlış konumdan devam ederdi.

### Sunucu

`supabase/functions/render-discover-audio/` **silinir** (fonksiyon + `catalog.json` kopyası). İki işi
vardı: anahtarı yayıncının dizüstünden uzak tutmak (yerel render kararıyla feshedildi) ve katalog
dışı metnin seslendirilmesini engellemek (yerel script'e taşınıyor — yalnızca kanonik katalogdan
okur). Elle bakımlı, 92 KB'lık birebir kopya ve `PATIKA_CONTENT_PUBLISHER_ID` secret'ı da gider.
`docs/discover-design.md:82,91` güncellenir.

### Render script — `scripts/render-discover-audio.py` v2 (yeniden yazım)

Mevcut 52 satırlık script edge fonksiyonuna konuşuyor, `'locale':'en'` gömülü (`:33`) ve hiç
son-işlem yok. Yerine:

```
ELEVENLABS_API_KEY=sk_… python3 scripts/render-discover-audio.py \
  [--locale tr|en] [--voice feminine|masculine] [--path breath,evening] \
  [--limit N] [--force] [--dry-run] [--workers 3]
```

1. Yalnızca `MyApp/Content/Discover/discover-catalog.json` okunur. Başka hiçbir şey sese dönüşemez.
2. Rendition anahtarı baytları değiştirebilecek **her şeyi** kapsar:
   `sha256(json({policy, text, locale, voice_id, model, voice_settings, post:{trim, lufs, tp, bitrate, sr}}))`.
   Paylaşılan `closing` metinleri tek kayda çöker.
3. `POST /v1/text-to-speech/{voice}/with-timestamps?output_format=mp3_44100_128`, `model_id=eleven_v3`,
   `language_code` locale'den, voice_settings [tts.ts:159-171](supabase/functions/_shared/tts.ts#L159-L171)
   ile **birebir aynı**. Ham MP3 + hizalama JSON'u `build/discover-raw/` (gitignore).
4. **Son işlem** (ffmpeg 9.0.1 ve ffprobe kurulu, doğrulandı):
   - **Kırp** — hizalamadan: baş = `start_times[0]`, son = ölçülen − `end_times[-1]`;
     `-ss (baş-0.04) -to (son+0.12)`. Nefesli bir meditasyon sesinde eşik tabanlı `silenceremove`
     güvenilmez; hizalama tabanlı kırpma çok daha sağlam (fallback olarak kalır).
   - **Normalize** — iki geçişli `loudnorm=I=-16:TP=-1.5:LRA=11` (PRD §3.1'in yazıp hiç
     uygulanmadığı kural). Tek geçiş dinamiktir ve deterministik değildir — önbellek anahtarını bozar.
   - **Declick** — iki uçta 15 ms rampa. 250/600 ms fade'ler **gömülmez**; onları K4 uyarınca istemci seçer.
   - **Kodla** — `-c:a libmp3lame -b:a 64k -ac 1 -ar 44100 -write_xing 1`.
   - **Ölç** — konteyner başlığına güvenmeden çözerek:
     `ffmpeg -v error -i out.mp3 -f s16le -ac 1 -ar 44100 - | wc -c` ÷ (2×44100). Bu tam olarak
     `AVAudioFile.length / sampleRate`'in raporlayacağı sayıdır.
   - **Doğrula** — `|ölçülen − hizalama aralığı| < 300 ms`, değilse dinlenmek üzere işaretle.
5. `MyApp/Resources/DiscoverAudio/discover-<key12>.mp3` + her dosyadan sonra `discover-audio.json`
   güncellenir (mevcut script'in devam edilebilirlik deseni korunur). `DiscoverRecording`'e
   `renditionKey` eklenir, `sourceURL` kaldırılır (artık genel URL yok).
6. **Devam:** alias var ∧ dosya var ∧ `sha256` tutuyor ∧ `renditionKey` tutuyor → atla. Bir metin
   düzeltmesi yalnızca etkilenen dosyaları yeniler.
7. **Hızlı başarısızlık:** önce tek iş render edilir; 401/402'de sert dur, 429/5xx'te üstel geri
   çekilme, 3 deneme. `--dry-run` karakter toplamını ve tahmini maliyeti yazar.

### Boyut ve saklama

Ölçüldü: bugünkü katalog 18.886 TR + 20.249 EN benzersiz karakter. İç bölümlü yapıda konuşma
~1.8× büyür (eklenen sürenin çoğu **sessizlik**, o bedava): **~2.9 saat ses, 64 kbps mono ≈ 82 MB.**

- `.gitattributes`: `MyApp/Resources/DiscoverAudio/*.mp3 filter=lfs diff=lfs merge=lfs -text`.
  `git lfs install` **ilk commit'ten önce**.
- `.gitignore`'a `build/discover-raw/` eklenir. `MyApp/Resources/*.mp3` deseni alt dizine
  inmiyor (doğrulandı) — Discover sesleri commit'lenir, bu doğru: çevrimdışı oynatma bir ürün sözü.
- Hedef `PBXFileSystemSynchronizedRootGroup`, dosyayı klasöre koymak yeterli; `.pbxproj` düzenlenmez.
- ~90 MB uygulama, 200 MB hücresel indirme sınırının altında. Daha ince ilk indirme istenirse
  **On-Demand Resources** (patika×dil başına ~3 MB etiket) doğru araç — `resourceURL`
  `NSBundleResourceRequest`'e döner, kapı zaten "patikaya katıl" anında var. **Sonraki sürüm.**

---

## Aşama 5 — Blok kütüphanesi yerelde render (`scripts/render-block-audio.py`)

Kişisel patikada PRD §3.1'i (−16 LUFS, tek seferde aynı ayarlarla) gerçek yapan parça. Blok
kütüphanesi sabit ve sonlu: 20 blok × ~4 `fixed` girdi × 2 ses ≈ 160 kayıt. Aynı son-işlemle yerelde
render edilir, `block_audio` kovasına yüklenir ve satırlar service key ile yazılır — **edge
fonksiyonunun hesapladığı `renditionHash`'in aynısıyla** ([tts.ts:95-106](supabase/functions/_shared/tts.ts#L95-L106)'nın
12 satırlık kanonikleştirmesi Python'da yeniden yazılır + Deno↔Python eşitlik testi).

Sonuç: [audio-worker.ts:158](supabase/functions/_shared/audio-worker.ts#L158) her blok varlığını
önbellekte bulur, sabit metin için TTS'i **hiç** çağırmaz. Canlıya giden tek şey adım başına 4
kişisel slot kalır — tek ses, tek gün, seviye sürüklenmesi sınırlı. Deno'da ffmpeg olmadığı için
bu script olmadan "farklı günlerde render edilmiş iki parça farklı duyuluyor" sorunu kalıcıdır.

`scripts/render-voice-previews.sh` de aynı son-işlemden geçirilir ve `BASE_URL` varsayılanı (`:19`,
AB ikametgâhı) [tts.ts:54](supabase/functions/_shared/tts.ts#L54) ile hizalanır — script'in kendi
"birebir aynı ayarlar" yorumu şu an doğru değil.

---

## Aşama 6 — Anahtar, dinleme testi, kademeli render

1. Ürün sahibi anahtarı verir → `supabase secrets set ELEVENLABS_API_KEY=… PATIKA_TTS_LIVE_ENABLED=true
ELEVENLABS_VOICE_FEMININE=zNk6QuA4ZKSf5GTyAPuF ELEVENLABS_VOICE_MASCULINE=pFQStpMdprGFILRDrWR2`.
   `PATIKA_ALLOW_UNREVIEWED_AUDIO=true` (20 bloğun hepsi `reviewed_at is null`; onsuz worker
   `unreviewed_content` atar).
2. **Dinleme testi (küçük örnek):** `breath.awareness` bloğu TR+EN, iki seste; beat 800/1500/2500 ms
   üç sürüm. Ürün sahibi dinler, beat sabitlenir, seed migrasyonuna yazılır.
3. **Tek patika:** `--path breath --limit …` ile 1 patika × 2 dil × 2 ses. Simülatörde dinlenir:
   tempo, seviye tutarlılığı, ses kimliğinin Türkçedeki tınısı.
4. Onay → tam render (`--dry-run` ile maliyet önce yazdırılır), sonra blok kütüphanesi (Aşama 5).

> **Dürüst uyarı, karar ürün sahibinin:** mevcut kadın sesi `zNk6QuA4ZKSf5GTyAPuF`
> ("Mila", ElevenLabs etiketi `accent: australian`) bir **İngilizce** ses. `language_code: "tr"`
> Türkçeyi doğru okutur ama tını yabancı aksanlı kalır. Kütüphanede `HpvPCQYbrNIxlW357V4h`
> ("Luna – Calm Turkish Meditation Voice", `tr-istanbul`) var. Mevcut sesi korumaya karar verildi; 3. adımdaki dinlemede bu bir kez daha değerlendirilebilir — **tam render'dan sonra değiştirmek
> bütün kütüphaneyi yeniden render ettirir.**

---

## Aşama 7 — `TTS_POLICY_VERSION` ve önbellek geçersizleştirme

`TTS_POLICY_VERSION = "patika-v3-paced-2026-09-21"` ([tts.ts:58](supabase/functions/_shared/tts.ts#L58))
tek başına her şeyi geçersiz kılar. Sırayla beklenen sonuçlar: `block_audio` tamamen ıskalar
(Aşama 5 zaten yeniden render ediyor — **ikisi birlikte yapılır, yoksa iki kez ödenir**);
`audio_assets` ıskalar (her kullanıcının 4 kişisel slotu bir sonraki adımda yenilenir, doğru
davranış); `voice_previews` ıskalar (4 örnek). Eski storage nesneleri `${locale}/${voice}/${digest}.mp3`
altında öksüz kalır — tek seferlik temizlik notu, bloklayıcı değil.

---

## Doğrulama

**Swift (test hedefi yok, elle derlenir):**

```bash
swiftc -o /tmp/pacingtest \
  MyApp/DesignSystem/Breath.swift MyApp/Models/SessionManifest.swift \
  MyApp/Features/Session/SessionTimeline.swift MyApp/Features/Session/SessionPacing.swift \
  MyApp/Features/Session/SessionScript.swift Tests/SessionPacingTests/main.swift && /tmp/pacingtest
```

(`SessionSegment` şu an [FirstSessionViewModel.swift:9](MyApp/Features/Onboarding/GFirstSession/FirstSessionViewModel.swift#L9)'da
— `SessionScript`'in yanına taşınır.) Vakalar:

- `{ms: 1500}` → 1.5 sn, 10 sn'ye **yuvarlanmaz** (K3, kök neden #1)
- `leadInMs` segment üretmez, `currentSegment.id` değişmez (K1/K5)
- `breathMs: 16000` + `breaths: 4` → 64 sn (kök neden #4)
- `measured:` `durationMs`'i ezer; toplam süre dosyaları izler (kök neden #3)
- **Değişmez:** her çizelgede `entries[i].start >= entries[i-1].end` — asla çakışma
- `fadeIn(afterGap:breath:)` → bir nefesin üstünde 0.6, altında/eşitinde 0.25 (K4)
- Konuşma + `displayText: nil` sessizlik tek segmente birleşir; `displayText`'li birleşmez (K5)
- **Eski manifest:** `{breaths: 2}` (ms'siz) ve bir `gap` olayı hâlâ decode olur ve doğru zamanlanır

`Tests/SessionTimelineTests/main.swift:23` beklenen toplam güncellenir; `:29-44`'teki decode
reddi vakaları korunur. `Tests/DiscoverLibraryTests/main.swift`: `:31` (`% 10 == 0` → aralık),
`:57` (`audioLocale` → `audioLocales`), `:67` (locale'li anahtarlar); + yalnızca `tr` anahtarı olan
sahte manifest Türkçe locale'de `audioIsReady` true, İngilizcede false.

**Deno:** `npx --yes deno test --allow-read --allow-env --allow-net supabase/functions/tests/`
— `session_contract_test.ts` (yeni aralıklar, `ms`↔`breaths` tutarlılığı, `leadInMs` sınırları,
ikisini birden ya da hiçbirini taşıyan sessizliğin reddi, eski `gap` manifestinin kabulü);
yeni `pacing_contract_test.ts` (join ekleme, sessizlik üzerinden join eklememe, dolgu telafisi ve
80 ms taban, `breathMsFor` box → 16000, `alignedSilenceMs` exhale sınırı);
yeni `mp3_duration_test.ts` (1.000 sn'lik ffmpeg fixture'ına karşı, ID3v2/Xing atlanıyor mu);
`migration_contract_test.ts` genişletilir; yeni `render_script_contract_test.ts` (script yalnızca
kanonik katalogdan okuyor, `stability 0.5`/`similarity_boost 0.8`/`style 0.0` ve `I=-16` sabit).

**Derleme ve simülatör:**

```bash
xcodebuild -project patika.xcodeproj -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Elle — ve asıl test bu, çünkü tempo duyulur.** `xcrun simctl io` ses yakalamıyor; BlackHole/Audio
Hijack loopback ile kaydedip dalga formunda ölç:

- bir fikrin iki cümlesi arası → hedef 350 ± 50 ms
- eski `breaths:1` beat'ler → dinleme testinde sabitlenen değer
- `breath.box` `{breaths:4}` → 64 sn, ekrandaki mesh kendi 16 sn periyodunda
- hiçbir yerde çakışma yok; oturum boyu entegre ses seviyesi ±1 LU içinde

Sonra dört kesinti yolu ([observeInterruptions:272-319](MyApp/Features/Session/SessionAudioPlayer.swift#L272-L319)
— hepsi artık mutlak zaman yerine sıralı zamanlamayla etkileşiyor): sessizliğin ortasında telefon
görüşmesi → devam; sessizlik sınırından ±15 sn seek; kilit ekranı; kulaklık çıkarma.
Keşfet: iki cihaz dilinde, iki seste, dil değiştirdikten sonra checkpoint'ten devam.

Sonuçlar `docs/discover-design.md`'nin doğrulama günlüğüne, karar ise `CLAUDE.md`'ye tarihli bir
başlıkla yazılır (depo geleneği).

---

## Sıra

| #   | İş                                                                                            | Anahtar gerekir mi              |
| --- | --------------------------------------------------------------------------------------------- | ------------------------------- |
| 0   | Gerçek süreler: `mp3.ts`, `lead/tailSilenceMs`, istemci ölçümü                                | hayır                           |
| 1   | Şema: DTO + doğrulama, `SessionManifest`, `SessionTimeline`, `SessionPacing`, `SessionScript` | hayır                           |
| 2   | Sunucu: join, `breathMs`, `alignedSilenceMs`, iki migrasyon, `manifest-v2`                    | hayır                           |
| 3   | Oynatma: sıralı zamanlama, sessizlik tamponları, kenar fade'leri, seek, drift                 | hayır                           |
| 4   | Keşfet: katalog v2 + 70 adımın iç bölümlü yeniden yazımı, istemci, script, LFS                | metin: hayır / render: **evet** |
| 5   | `render-block-audio.py` + `TTS_POLICY_VERSION` (birlikte)                                     | **evet**                        |
| 6   | Dinleme testi → beat sabitlenir → kademeli render                                             | **evet**                        |

0–3 kendi başına gönderilebilir ve bildirilen hatayı kişisel patikada çözer. 4–6 Keşfet'i açar.

## Sonraya bırakılanlar

- **K6**: [SessionScript.swift:102-103](MyApp/Features/Session/SessionScript.swift#L102-L103)
  sessiz yedek yolda her cue'yu tam nefes döngüsüne yuvarlıyor — aynı hastalık, ama yalnızca ses
  yokken çalışıyor. Düzgün çözümü `Speech.charactersPerSecond` (PRD §1.2, depoda sıfır hit) gerektirir.
- **Noktalama tabanlı tempo**: `eleven_v3`'te `speed` ve `<break>` yok; metin içi tek kaldıraç
  noktalama (üç nokta duraklama üretir). `scripts/render-voice-previews.sh:27-28` bunu zaten
  kullanıyor, seed blokların hiçbiri kullanmıyor. Metin düzenlemesi `blocks.version` bumplar ve
  kütüphaneyi yeniden render ettirir — klinik inceleme ile birlikte yapılmalı.
- **On-Demand Resources** (Aşama 4).
- **Klinik inceleme**: `select * from public.unreviewed_blocks` 20 satır dönüyor; yayından önce boş
  dönmeli (PRD-Ek Path Üretimi §2.3).


---

## Uygulama durumu (2026-09-21)

**Ürün sahibi kararı değişti:** MVP yalnızca İngilizce ve tek (kadın) ses. Bu plandaki TR render'ı,
erkek sesi, iki dilli `audioLocales` ve `spokenLocale` işleri **yapılmadı**, çünkü gereksiz kaldı.
Bunun yerine metinler tek kataloğa toplandı (bkz. CLAUDE.md, 21 Eylül 2026).

| Aşama | Durum |
| --- | --- |
| 0 Gerçek süreler | Tamam ve dağıtıldı |
| 1 Şema | Tamam ve dağıtıldı |
| 2 Sunucu | Tamam ve dağıtıldı. `alignedSilenceMs` yazıldı, worker'a bağlı değil (gerekçe CLAUDE.md) |
| 3 Oynatma | Tamam: `SessionScheduler`, dalga formu testleri |
| 4 Keşfet | Tamam: katalog v2, 10 patikanın 286 kaydı üretildi, LFS |
| 5 Blok render | Tamam: 39 kayıt üretildi ve yüklendi (hizmet anahtarsız, Supabase CLI) |
| 6 Dinleme testi | Tamam: 800 ve 1500 ms beğenildi, 1500 seçildi |
| 7 Politika sürümü | Dağıtıldı: `patika-v3-paced-2026-09-21` |

Ek olarak bulunan ve düzeltilen eski hatalar: `eleven_v3` istek dikişi (`unsupported_model`) ve
`audio_assets` kısmi indeks conflict hedefi (42P10). İki nefes bloğu gerçek sayımla yeniden yazıldı.

Sapmalar: (1) sessizlik kademeleri planla aynı; `SessionScheduler` ayrı dosya (test edilebilirlik
için); (2) `render_script_contract_test.ts` ek olarak depoda gizli anahtar taraması yapıyor;
(3) yükleme hizmet anahtarı yerine Supabase CLI ile.
