# PRD Eki — Path Üretimi ve AI Mimarisi

**Sürüm:** 2.0 · **Tarih:** 9 Eylül 2026 · **Sahibi:** Novum Apps

Bu ek, PRD §9 (path mimarisi) ve §13 (teknik) bölümlerinin **uygulanabilir** hâlidir:
programın arkada nasıl üretildiğini, hangi işi hangi AI'ın yaptığını, hangi modelin
nerede ve ne zaman çağrıldığını, ne üreteceğini ve neyi **asla** üretmeyeceğini tarif
eder.

> **Uyarı — fiyat bilgisi tarihlidir ve hızlı değişiyor.** Model fiyatları Eylül 2026
> taramasına dayanıyor; bazılarının ilan edilmiş zam tarihi var (örn. Gemini 3.7 Flash,
> 1 Ocak 2027). **Uygulamaya başlamadan önce her sağlayıcının fiyat sayfasından
> doğrulayın.** Fiyatlar $ cinsindendir; €/$ ayrımı yapılmamıştır.
>
> **Türkçe TTS kalitesi hiçbir ucuz sağlayıcı için doğrulanmadı** ve bu, dokümandaki
> maliyet tablolarının tamamını belirleyen tek testtir (§5.4).

---

## 0. Bir bakışta

```
Kullanıcı (onboarding B1–B6, D1–D8, E1–E3)
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│ 0. İSTEMCİ ÖN FİLTRE      CrisisClassifier (Swift, cihaz) │  AI yok
├───────────────────────────────────────────────────────────┤
│ 1. SINIFLANDIRMA          yapılandırılmış etiketler        │  Ucuz LLM
├───────────────────────────────────────────────────────────┤
│ 2. KRİZ KONTROLÜ ⛔        bloklayıcı, tek yönlü           │  Ucuz LLM + kural
├───────────────────────────────────────────────────────────┤
│ 3. ŞABLON SEÇİMİ          deterministik tablo              │  AI yok
├───────────────────────────────────────────────────────────┤
│ 4. BLOK SEÇİMİ + SIRALAMA blok kütüphanesinden N adet      │  Güçlü LLM
├───────────────────────────────────────────────────────────┤
│ 5. KİŞİSELLEŞTİRME        yalnızca adlandırılmış slotlar   │  Güçlü LLM (aynı çağrı)
├───────────────────────────────────────────────────────────┤
│ 6. ÇIKIŞ GÜVENLİK TARAMASI kural + ikinci model            │  Kural + ucuz LLM
├───────────────────────────────────────────────────────────┤
│ 7. SES ÜRETİMİ            hibrit: hazır blok + taze slot   │  TTS sağlayıcı
├───────────────────────────────────────────────────────────┤
│ 8. TESLİM                 imzalı URL + istemci cache       │  AI yok
└───────────────────────────────────────────────────────────┘
```

**Sekiz adımın üçünde AI yok.** Bu tesadüf değil; §1.2'deki kural bunu zorunlu kılıyor.

---

## 1. Temel ilkeler

### 1.1 AI içerik icat etmez, seçer ve doldurur

PRD §9.1'in kuralı burada tek cümleye indirgenmiştir:

> **LLM'in çıktısı metin değil, bir plandır.** Plan JSON'dur, şeması sabittir ve
> içindeki serbest metin yalnızca sayısı ve uzunluğu önceden belirlenmiş slotlardır.

Bir LLM'e "bu kullanıcıya 21 günlük meditasyon programı yaz" demek üç sorun üretir:

1. **Kalite tutarsızlığı.** Aynı prompt iki kullanıcıya iki farklı kalitede program
   verir; hangisinin kötü olduğunu ölçemezsiniz.
2. **Fiyatlanamaz değişkenlik.** Birine 9 adım, diğerine 34 adım üretir. Sabit kova
   (7/14/21/28) satılamaz hâle gelir.
3. **Güvenlik riski.** Ruh sağlığı alanında serbest üretim, tek bir kötü cümlenin
   mağazadan dönmeye ve gerçek zarara yol açtığı yerdir.

Blok kütüphanesi üçünü de çözer ve maliyeti bir mertebe düşürür.

### 1.2 AI'ın dokunmadığı üç yer

| Yer | Neden AI yok |
|---|---|
| **Ölçüm skorlaması** | Skor deterministik olmalı. Aynı cevaplar her zaman aynı skoru vermeli, yoksa "kendi geçmişinle karşılaştırma" iddiası çöker. Basit ağırlıklı toplam (PRD §8.2) yeterli ve denetlenebilir. |
| **Kova ataması (A/B/C)** | Eşikler sözleşmedir. "Kova C'de satış yok" taahhüdü, kovayı bir modelin belirlediği üründe anlamsızdır. |
| **Path uzunluğu** | Sabit kovalar ticari karardır (PRD §9.3), modelin takdiri değil. |

### 1.3 Kriz kontrolü tek yönlüdür

Sınıflandırıcı bir sinyali **yükseltebilir, indiremez.** İstemci ön filtresi "sinyal
var" dediyse sunucu modeli bunu geri alamaz. Gerekçe asimetrik maliyet: yanlış
pozitifin bedeli kullanıcının yardım ekranını görmesi, yanlış negatifin bedeli kriz
sinyali vermiş birine program satmaktır.

---

## 2. Blok kütüphanesi — sistemin asıl içeriği

Modelin kalitesi değil, **bu kütüphanenin kalitesi** ürünün kalitesidir. Model sadece
kütüphaneden seçer; kötü bir kütüphaneden iyi bir program çıkmaz.

### 2.1 Blok şeması

Her blok versiyonlanmış bir kayıttır (Postgres + git'te düz metin kaynak):

```jsonc
{
  "id": "breath.box.v1",              // ASLA değişmez; ses dosyası adı buna bağlı
  "version": 3,                        // metin değişirse artar → yeniden render
  "category": "temel",                 // PRD §9.2 tablosu
  "technique": "Kutu nefesi",
  "goal": ["akut_gerginlik", "uyku_oncesi"],
  "phase": ["relief", "awareness"],    // hangi fazlarda kullanılabilir
  "difficulty": 1,                     // 1–3; zor bloklar arka yarıda
  "duration_sec": [180, 420],          // min–maks; E2 tercihiyle eşleşmeli
  "prerequisites": [],                 // ["breath.awareness.v1"] gibi
  "contraindications": ["panik_atak_gecmisi"],  // seçilemeyeceği durumlar
  "locale": "tr",
  "script": [
    { "type": "fixed",  "text": "Omuzlarını bir kez yukarı kaldır..." },
    { "type": "silence", "sec": 8 },
    { "type": "slot",   "name": "mid_bridge", "max_chars": 320 },
    { "type": "fixed",  "text": "Şimdi dörde kadar sayarak nefes al..." }
  ]
}
```

**`script` üç tipten oluşur ve bu üçü dışında bir tip yoktur:**

- `fixed` — insan tarafından yazılmış, klinik olarak gözden geçirilmiş metin.
  **Önceden render edilir**, bir kez. Oturumun ~%70'i budur.
- `silence` — TTS'e **hiç gitmez**, istemcide `scheduleBuffer` ile enjekte edilir
  (PRD §13.2). Meditasyon sesinin yarısı budur; TTS ile üretmek maliyeti ikiye katlar.
- `slot` — LLM'in doldurabileceği **tek** yer. Adı, karakter sınırı ve kabul kuralları
  şemada yazılı.

### 2.2 Slot tipleri

Slotlar **kişiselleştirme kademesine** göre doldurulur (§6.2). Aşağıdaki liste kademe
**C** içindir — seçilen kademe budur.

| Slot | Nerede | Sınır | İçerik |
|---|---|---|---|
| `step_opening` | Her adımın başı | 350–520 karakter | Karşılama + kullanıcının durumuna bağlanma. **1. adımda bu slot aynı zamanda aynalamadır** ve kullanıcının kendi cümlesini içerir — G1'deki aha momenti |
| `technique_bridge` | Teknik gövdesinden hemen önce | 250–420 karakter | Bugün neden bu teknik, onun durumunda ne işe yarayacak |
| `mid_bridge` | Teknik gövdesi içinde, en fazla 1 kez | 150–320 karakter | Gövdenin ortasında kullanıcıya dönüş |
| `step_closing` | Adımın sonu | 300–460 karakter | Kapanış + yarına bağlanma |
| `step_title` | Her adım | 48 karakter | Harita başlığı ("Gün 12 — Kaçınmayla yüzleşme") — ses değil, ekran |
| `phase_subtitle` | Her faz | 90 karakter | F2 haritasındaki faz açıklaması — ses değil, ekran |

**Sesli slotların toplamı adım başına 1.050–1.720 karakter** (10 dk oturumda ortalama
~1.450, yani konuşmanın ~%53'ü). Bu sayı **marjın kendisidir** — §5.3'teki her satır
buradan türüyor. Slot eklemek veya sınır yükseltmek doğrudan COGS artışıdır ve ürün
sahibi kararı gerektirir.

> **`step_title` ve `phase_subtitle` TTS'e gitmez.** Ekranda okunuyorlar; ses
> maliyetleri sıfır. Bu yüzden bunları cömertçe kişiselleştirmek bedava — F2'nin
> haritasındaki 21 başlığın tamamı kullanıcıya özel olabilir ve hiçbir şeye mal olmaz.

### 2.3 v1 hedefi

~40 blok, TR + EN. Blok yazımı **LLM'e verilmez** — bunlar klinik gözden geçirmeden
geçmesi gereken metinlerdir. LLM bir taslak üretmekte kullanılabilir ama üretilen
metin insan onayı olmadan kütüphaneye girmez ve bu bir süreç kuralıdır.

---

## 3. Üretim hattı — adım adım

### Adım 0 · İstemci ön filtresi (AI yok)

**Nerede:** iOS, `CrisisClassifier.swift`. **Ne zaman:** B1 ve B4 çıkışında, anında.

Anahtar ifade taraması + Türkçe küçük harf/aksan normalizasyonu. İma ve mecaz
yakalamaz — **bu bir ön filtredir, karar mercii değildir.** Eşiği bilerek gevşek.

Sinyal varsa akış orada durur; sunucuya hiç gidilmez.

---

### Adım 1 · Sınıflandırma

**Katman:** ucuz LLM (§4.2) · **Ne zaman:** F1 başlarken, tek çağrı ·
**Çıktı:** structured output (JSON şema)

Kullanıcının serbest metni + B2–B6 cevapları → yapılandırılmış etiketler:

```jsonc
{
  "primary_problem": "sleep_onset",       // enum, 10 kategoriden türetilmiş alt tipler
  "secondary_problem": "rumination",
  "severity": 3,                           // 1–5
  "timing": "bedtime",
  "avoidance_present": true,
  "avoidance_domain": "work_task",
  "therapy_context": "ongoing",            // B5'ten
  "language_register": "informal",
  "summary_for_generation": "..."          // ≤ 400 karakter, ham metin DEĞİL
}
```

**Neden ucuz kademe:** Bu bir etiketleme işi; şema dar, karar uzayı küçük. Sınıflandırma
kalitesi güçlü kademeye çıkarıldığında ölçülebilir şekilde artmıyorsa (eval ile
bakılmalı) maliyeti 5× artırmanın karşılığı yok. **Bu ürün sahibinin maliyet kararıdır** —
varsayılan tercih her zaman en yetenekli model olmalıdır; buradaki düşürme bilinçli
ve ölçülerek yapılmalıdır.

**`summary_for_generation` kritik:** Adım 4'e ham metin değil bu özet gider
(PRD §13.5). Tek istisna 1. adımın `step_opening` slotudur — §12.2'ye bakın.

---

### Adım 2 · Kriz kontrolü ⛔ (bloklayıcı)

**Katman:** ucuz LLM, ayrı ve dar bir prompt · **Ne zaman:** Adım 1 ile aynı
anda (paralel), sonucu beklenmeden ilerlenmez.

Ayrı çağrı olması bilinçli: kriz taraması, sınıflandırma prompt'unun içine bir alan
olarak gömülürse, uzun bir sistem prompt'unun ortasında kaybolan bir talimata dönüşür.
Kendi çağrısında modelin tek işi vardır.

```jsonc
{
  "signal": true,
  "category": "self_harm_ideation",   // enum
  "confidence": "high",               // low | medium | high
  "evidence_span": "..."              // metinden alıntı, loglanmaz
}
```

**Karar kuralı (kod, model değil):**

```
istemci_sinyali VEYA (model_sinyali VE confidence != "low")  →  AKIŞ DURUR
```

Akış durduğunda: path üretilmez, ölçüm yapılmaz, kayıt istenmez, ödeme istenmez,
ekranda hareket olmaz (`BreathAmplitude.crisis` = 0). Kullanıcıya ülkesine göre
yerelleştirilmiş yardım hattı **numarası** gösterilir — harita değil.

**Refusal ihtimali burada gerçektir.** Kriz metinleri güvenlik sınıflandırıcılarını
tetikleyebilir: yanıt HTTP 200 döner ama `stop_reason == "refusal"` olur. Kod
`content`'i okumadan önce `stop_reason`'ı kontrol etmeli ve **refusal'ı sinyal
saymalıdır** — çünkü modelin cevap vermeyi reddettiği bir metin, tanımı gereği
tedirgin edici bir metindir. Ayrıca sunucu tarafı fallback açık olmalı:
`betas: ["server-side-fallback-2026-07-01"]` + `fallbacks: "default"`.

---

### Adım 3 · Şablon seçimi (AI yok)

`(primary_problem, severity, timing)` → şablon kimliği. Düz bir tablo araması.

Şablon: faz sınırları (PRD §9.3 arkı), ölçüm günleri, her faz için hangi blok
kategorilerinin uygun olduğu. Kod tarafında `PathPlan` bu tablonun istemci
yansımasıdır.

**Neden AI yok:** Bu eşleme ürünün iskeleti ve denetlenebilir olmalı. "Neden bu
kullanıcıya bu şablon verildi" sorusunun cevabı bir tablo satırı olmalı, bir model
çıktısı değil.

---

### Adım 4 + 5 · Blok seçimi, sıralama ve kişiselleştirme

**Katman:** güçlü LLM (§4.2) · **Ne zaman:** Tek çağrı, F1 sırasında ·
**Beklenen süre:** 8–20 sn · **Çıktı:** structured output

Bu, sistemin **tek yaratıcı** adımıdır ve en yetenekli modeli hak eden tek yer burasıdır.
Model şunları alır:

- Blok kütüphanesinin tamamı (id + teknik + hedef + faz + zorluk + süre; `script`
  metinleri **gitmez**, sadece meta veri) — ~40 blok, ~6–8k token
- Şablon iskeleti (faz sınırları, ölçüm günleri, adım sayısı)
- `summary_for_generation` + yapılandırılmış etiketler
- E bölümü tercihleri (süre, ton)

ve şunu döner:

```jsonc
{
  "path_title": "Zihni akşam yavaşlatma",
  "steps": [
    {
      "day": 1,
      "block_ids": ["breath.box.v1", "closing.day.v1"],
      "step_title": "Zihni yavaşlatmaya başlamak",
      "slots": {
        "step_opening":     "Merhaba Elif. Az önce yazdıklarını okudum...",
        "technique_bridge": "Bu ilk adımda zihnini susturmaya çalışmayacağız...",
        "mid_bridge":       "Zihnin bu arada birkaç kez yarına gitmiş olabilir...",
        "step_closing":     "Yarın aynı saatte buradayız Elif..."
      }
    }
    // ... 21 adım
  ],
  "phase_subtitles": { "relief": "...", "awareness": "..." }
}
```

**Şema zorlaması:** `output_config.format` ile JSON şeması verilir; `block_ids` alanı
`enum` olarak **kütüphanedeki gerçek kimliklerle** sınırlanır. Model var olmayan bir
blok uyduramaz — uydurma denemesi şema doğrulamasında ölür, üretim aşamasında değil.

**Doğrulama (kod, model değil).** Model çıktısı şu kontrollerden geçmeden kabul
edilmez:

| Kontrol | Başarısızlıkta |
|---|---|
| Adım sayısı = şablon uzunluğu | Yeniden dene (1 kez), sonra jenerik şablona düş |
| Her `block_id` kütüphanede var | Aynı |
| Blok faz uyumu (`phase` alanı) | Aynı |
| Ön koşullar sırada karşılanmış | Aynı |
| Zorluk artışı monoton (kabaca) | Uyarı, blokla değil |
| Adım süreleri E2 tercihine ± %20 uyuyor | Blok değiştir (deterministik) |
| Slot uzunlukları sınır içinde | Kırp |
| Aynı blok 3 günden yakın tekrar etmiyor | Yeniden dene |

**Neden güçlü kademe:** Buradaki iş gerçek bir muhakeme: 40 blok arasından 21 günlük tutarlı
bir ark kurmak, ön koşulları sırada tutmak, kullanıcının cümlesini üründe **onun**
cümlesi gibi yansıtmak. Bu adımda kalite düşüşü doğrudan üründe hissedilir ve path
başına yalnızca bir kez ödenir (~€0.05). Ucuzlatılacak yer burası değil.

**Efor ve düşünme (Claude örneği):** `thinking: {type: "adaptive"}` (Opus 5'te zaten
varsayılan), `output_config: {effort: "high"}`. `budget_tokens` **kullanılmaz** —
Opus 5'te 400 döner. Gemini/GPT karşılıkları için sağlayıcı dokümanına bakılır;
arayüz (§4.2) bu farkı içeride tutar.

---

### Adım 6 · Çıkış güvenlik taraması

İki katman, sırayla. İkisi de geçmeden ses üretimine gidilmez.

**6a — Deterministik (kod):**

- `BannedPhrases` taraması (Ton eki §3): "harika iş çıkardın", "seni özledik",
  "bunu aşacaksın", "endişelenme", "başarısız"…
- Teşhis/tedavi/garanti sözcük listesi: "tedavi", "klinik olarak kanıtlanmış",
  "iyileşeceksin", "geçecek"
- Emoji taraması (üründe emoji yok — bir tane bile)
- Uzunluk ve dil kontrolü (slot metni beklenen dilde mi)

**6b — Model yargıcı:** ucuz LLM

Yalnızca **slot metinlerini** görür (blokların sabit metnini değil — onlar zaten insan
onaylı). Tek soru sorar: *"Bu metin bir teşhis, garanti, tedavi vaadi veya terapi
ikamesi imasında bulunuyor mu? Ton kademesi uygun mu?"* Cevap yapılandırılmış:
`{ "verdict": "pass" | "revise" | "block", "reason": "..." }`.

`revise` gelirse slot **yeniden üretilmez** — jenerik yedeğine düşer. Gerekçe: iki kez
üretmek maliyeti ve gecikmeyi ikiye katlar ve yedek metin zaten yeterince iyidir.

**Bu adım atlanamaz.** Ölçülen maliyeti path başına ~€0.002; atlanmasının bedeli
mağaza incelemesi.

---

### Adım 7 · Ses üretimi

Ayrıntı §5–§7'de. Özet: `fixed` blokları kütüphaneden hazır gelir (üretim maliyeti sıfır),
`slot` metinleri taze render edilir, `silence` hiç TTS'e gitmez.

---

### Adım 8 · Teslim

Ses parçaları CDN'de, kullanıcıya özel **imzalı URL** ile. İstemci agresif cache'ler;
tekrar dinleme maliyeti sıfır. SOS blokları uygulama paketinde (~2 MB, çevrimdışı).

---

## 4. AI kullanım tablosu — hangi model, nerede, ne zaman

Sistemdeki **tek** referans tablo budur. Yeni bir AI çağrısı eklemek bu tabloya satır
eklemek demektir ve gerekçesi yazılmadan eklenmez.

| # | İş | Katman | Ne zaman | Girdi | Çıktı | Path başına |
|---|---|---|---|---|---|---|
| 1 | Kriz ön filtresi | **AI yok** (Swift) | B1, B4 çıkışı | Ham metin | Bool | 2 çağrı |
| 2 | Sınıflandırma | Ucuz LLM | F1 başı | Ham metin + B cevapları | Etiket JSON | 1 |
| 3 | Kriz kontrolü | Ucuz LLM | F1 başı (paralel) | Ham metin | Sinyal JSON | 1 |
| 4 | Blok seçimi + kişiselleştirme | **Güçlü LLM** | F1 | Kütüphane meta + özet | Path planı JSON | 1 |
| 5 | Çıkış yargıcı | Ucuz LLM | Adım 6 | Yalnızca taze metinler | Verdict JSON | 1 |
| 6 | TTS — taze metin | TTS | Adım 7 | Taze cümleler | Ses | Adım başına |
| 7 | TTS — blok kütüphanesi | TTS | **Path'te değil**, kütüphane yazıldığında bir kez | Blok `fixed` metinleri | Ses | 0 |
| 8 | Uyarlama (gün içi) | **AI yok** (kural) | Geri bildirim sonrası | Feedback | Blok değişimi | 0 |
| 9 | Ölçüm skorlaması | **AI yok** (formül) | Ölçüm sonrası | Cevaplar | Skor | 0 |
| 10 | Kova ataması | **AI yok** (eşik) | Path sonu | Skorlar | A/B/C | 0 |
| 11 | Rozet metni | Ucuz LLM | Path sonu | Skor deltaları | Tek cümle | 1 |

Tabloda model **adı** değil, **rolü** yazılı ("ucuz LLM", "güçlü LLM"). Somut model
seçimi §4.2'de ve değişebilir; roller değişmez.

### 4.1 LLM maliyetin sorunu değil — TTS öyle

Bu, dokümandaki en önemli tek sayıdır:

| Kalem | Path başına | Toplamın payı |
|---|---|---|
| Tüm LLM çağrıları (5 adet) | ~$0.03–0.05 | **%2–8** |
| TTS | ~$0.60–7.00 | **%92–98** |

**Sonuç: LLM sağlayıcısını parçalayarak tasarruf edilmez.** Sınıflandırmayı Haiku 4.5
yerine GPT-5-nano'ya taşımak path başına ~$0.003 kazandırır ve karşılığında ikinci bir
SDK, ikinci bir hata yüzeyi, ikinci bir DPA, ikinci bir güvenlik davranışı getirir.
Optimizasyon eforunun tamamı §5'e (TTS) gitmeli.

### 4.2 LLM sağlayıcı karşılaştırması

Fiyatlar $/1M token (girdi/çıktı), Eylül 2026 taraması. **Uygulamadan önce doğrulayın**
— bu pazarda fiyatlar üç ayda bir değişiyor ve bazılarının ilan edilmiş zam tarihi var.

| Model | Girdi | Çıktı | Not |
|---|---|---|---|
| **Claude Opus 5** | 5.00 | 25.00 | 1M bağlam; şema uyumu ve talimat takibi güçlü |
| Claude Sonnet 5 | 2.00 | 10.00 | 1M bağlam |
| Claude Haiku 4.5 | 1.00 | 5.00 | 200K bağlam |
| **Gemini 3.1 Pro** | 2.00 (≤200K) / 4.00 (üstü) | doğrulanmalı | Uzun bağlam ucuz |
| Gemini 3.8 Flash | 0.375 | 1.88 | Eylül 2026'da çıktı |
| Gemini 3.7 Flash | 0.75 | 3.75 | **1 Ocak 2027'de iki katına çıkıyor** |
| Gemini 2.5 Flash-Lite | 0.10 | 0.40 | En ucuz uçlardan |
| **GPT-5.6 Sol** | 5.00 | 30.00 | Amiral gemisi |
| GPT-5.6 Terra | 2.00 | 12.00 | |
| GPT-5.6 Luna | 0.20 | 1.20 | |
| GPT-5 | 1.25 | 10.00 | |
| GPT-5-mini | 0.25 | 2.00 | |
| GPT-5-nano | 0.05 | 0.40 | Sınıflandırma sınıfı |

Üç sağlayıcıda da **cache'lenmiş girdi ~%90 indirimli** ve **batch %50 indirimli.**
Bizim kullanım profilimizde (sabit blok kütüphanesi prefix'i) cache indirimi model
seçiminden daha belirleyici (§7.1).

**Öneri: tek sağlayıcı, iki kademe.**

| Rol | Birinci tercih | Eşdeğer alternatif | Gerekçe |
|---|---|---|---|
| Güçlü LLM (üretim) | `claude-opus-5` | `gemini-3.1-pro`, `gpt-5.6-sol` | Path başına 1 çağrı, ~$0.04. Buradaki kalite doğrudan üründe duyuluyor; ucuzlatılacak yer değil |
| Ucuz LLM (sınıflandırma, kriz, yargıç, rozet) | `claude-haiku-4-5` | `gemini-2.5-flash-lite`, `gpt-5-nano` | Toplam etkisi path başına ~$0.004; sağlayıcı birliği bu farktan değerli |

**Sağlayıcı bağımsızlığı yine de kodda korunur.** Üretim çağrısı bir `PathGenerator`
arayüzünün arkasında durur; sağlayıcı değişimi tek dosya olmalı. Gerekçe fiyat değil
**risk**: tek bir sağlayıcının güvenlik politikası ruh sağlığı içeriğine karşı
sertleşirse (bu gerçek bir senaryo, bkz. §3 Adım 2 refusal) alternatifin hazır olması
gerekir.

### 4.3 Asla yapılmayacaklar

- **Kullanıcıyla sohbet eden bir LLM yok.** Ne onboarding'de ne oturum içinde. Serbest
  sohbet, güvenlik taraması yapılamayan sonsuz bir yüzey açar.
- **Kullanıcı girdisi doğrudan prompt'a yapıştırılmaz.** Sınıflandırma çıktısı üzerinden
  geçer; ham metnin gittiği yerler §12.2'de sayılıdır.
- **Model, kullanıcıya gösterilecek bir sayı üretmez.** Ne skor, ne yüzde, ne "diğer
  kullanıcılar". Sayılar formülden gelir.
- **Model kriz kararını tek başına vermez.** Kararı §3 Adım 2'deki kural verir.

---

## 5. Ses (TTS) — maliyetin yaşadığı yer

### 5.1 Karakter matematiği (her hesabın temeli)

Bütün maliyet tahminleri bu üç sayıdan türüyor:

| Ölçü | Değer | Gerekçe |
|---|---|---|
| Türkçe ortalama kelime uzunluğu | ~6,2 harf + boşluk ≈ **7,2 karakter** | Türkçe sondan eklemeli; İngilizceden ~%20 uzun |
| Meditasyon anlatım hızı | **~85 kelime/dakika** | Normal konuşma 130–150; meditasyon bilinçli olarak yavaş |
| Bir oturumun konuşma payı | **~%45** | Kalan %55 sessizlik ve TTS'e hiç gitmiyor |

**10 dakikalık oturum** = 4,5 dk konuşma = ~380 kelime = **~2.750 karakter.**
5 dk ≈ 1.400 · 15 dk ≈ 4.100 karakter.

**21 günlük path (10 dk) = ~57.750 karakter.** Bu sayı aşağıdaki her tabloda geçiyor.

### 5.2 Sağlayıcı karşılaştırması

$/1M karakter. Eylül 2026 taraması; **Türkçe desteği ve kalitesi ayrıca doğrulanmalı**
(§5.4).

| Sağlayıcı / model | $/1M karakter | Türkçe | Not |
|---|---|---|---|
| ElevenLabs `eleven_multilingual_v2` | ~120 | ✅ 32 dil | En yüksek sadakat; v1 kalite referansı |
| ElevenLabs `eleven_v3` | ~120 | ✅ | En geniş dil desteği, en zengin ifade |
| ElevenLabs `eleven_flash_v2_5` | ~60 | ✅ 32 dil | ~75 ms; bizde gecikme sorun değil |
| **OpenAI `tts-1-hd`** | ~30 | doğrulanmalı | ElevenLabs'in ¼ fiyatı |
| OpenAI `tts-1` | ~15 | doğrulanmalı | En ucuz büyük sağlayıcı |
| fal.ai — MiniMax Speech-02 HD | ~100 | doğrulanmalı | $0,10/1k karakter |
| fal.ai — Orpheus / F5-TTS | ~50 | doğrulanmalı | $0,05/1k karakter |
| fal.ai — Dia TTS | ~40 | doğrulanmalı | $0,04/1k karakter |
| fal.ai — Kokoro | ~20 | ❌ muhtemelen yok | En ucuz; dil listesinde Türkçe görünmüyor |
| fal.ai — Chatterbox (çok dilli) | ~15 (dk bazlı) | ✅ 23 dil | Türkçe listede |
| fal.ai — xAI TTS | doğrulanmalı | ✅ 20 dil | Türkçe listede |

> **fal.ai'ın asıl değeri fiyat değil, esneklik.** Tek arayüzden çok sayıda açık model
> denenebiliyor; Türkçe A/B'sini burada koşmak ElevenLabs'e kilitlenmeden karar
> vermeyi sağlıyor. Dezavantajı: açık modellerde ses kimliğinin uzun vadeli
> kararlılığı sağlayıcı garantisi altında değil (§5.5).

### 5.3 Path maliyeti — sağlayıcı × kişiselleştirme derinliği

Aşağıdaki dört kademe §6'da tanımlı. Sayılar **21 günlük, 10 dakikalık** bir path için,
taze üretilen karakter × birim fiyat.

| | A · Yalnız açılış (%13) | B · Çerçeve (%36) | C · Teknik hariç her şey (%53) | D · Literal %100 |
|---|---|---|---|---|
| **Taze karakter** | 7.500 | 20.800 | 30.600 | 57.750 |
| ElevenLabs multilingual ($120) | $0.90 | $2.50 | $3.67 | **$6.93** |
| ElevenLabs flash ($60) | $0.45 | $1.25 | $1.84 | $3.47 |
| fal.ai orta kademe ($40) | $0.30 | $0.83 | $1.22 | $2.31 |
| OpenAI `tts-1-hd` ($30) | $0.23 | $0.62 | $0.92 | $1.73 |
| fal.ai ucuz kademe ($20) | $0.15 | $0.42 | $0.61 | $1.16 |

**PRD §13.3'ün hedefi path başına €0.75–1.15 idi.** Tabloya bakıldığında bu hedef,
ElevenLabs ile ancak A kademesinde tutuyor; C veya D isteniyorsa ya hedef ya sağlayıcı
değişmek zorunda. Bu, dokümanın en önemli çelişkisi ve §6.4'te karara bağlanıyor.

> **PRD içi tutarsızlık.** PRD §13.2 "2–3 dakika taze TTS" diyor, §13.3 ise oturum başı
> €0.03–0.05. 2–3 dakika ≈ 1.800–2.700 karakter; ElevenLabs fiyatıyla bu oturum başına
> $0.22–0.32 eder, yani §13.3'ün 6 katı. **§13.3'ün rakamları ancak taze kısım ~350
> karakter (≈25 saniye) olduğunda tutuyor.** PRD bu iki sayıdan birini düzeltmeli.

### 5.4 Türkçe kalite testi — kararı veren şey

Ucuz modellerin hiçbirinin Türkçe kalitesi doğrulanmadı ve **bu tek test COGS'u 6×
değiştiriyor.** Canlıya çıkmadan önce koşulmalı:

**Test protokolü.** Aynı 5 metin, her aday modelde, aynı ayarlarla:

1. Nefes yönergesi (sayı okuma: "dörde kadar", "yediye kadar")
2. Yumuşak ünsüz yoğun cümle ("yavaşça", "şimdi", "göğsün")
3. Uzun bileşik cümle (nefes alma yeri doğru mu)
4. Kullanıcı cümlesi yansıtması (doğal mı, robotik mi)
5. İngilizce alıntı içeren Türkçe cümle (kod değiştirme)

**Değerlendirme (kör, en az 5 kişi):** vurgu doğruluğu, "ş/ç/ğ/ı" telaffuzu, sayı
okuma, duraklama yerleri, 4 dakika dinlendiğinde yorucu mu.

**Geçme ölçütü:** ElevenLabs referansına karşı kör testte %70'ten fazla kişi "fark
edilir derecede kötü" demiyorsa aday geçer.

### 5.5 Tek ses, tek model — pazarlıksız

**Aynı `voice_id` ve aynı model her yerde.** Önceden render edilmiş blok ile taze
üretilen cümle arka arkaya çalıyor; ikisi arasında model farkı olursa **dikiş duyulur**
ve bu, ürünün en hassas anında (G1 aha momenti) olur.

Doğrudan sonucu: **"sabit bloklar kaliteli modelle, taze kısım ucuz modelle" yapılamaz.**
Cazip görünüyor, tam olarak duyulan dikişi üretiyor. Tek model seçilir, kütüphanenin
tamamı onunla render edilir.

> **Ses değiştirmenin maliyeti:** `voice_id` veya model değişirse **tüm blok kütüphanesi
> yeniden render edilir.** Bu yüzden §5.4 testi kütüphane yazımından **önce** yapılmalı
> (PRD §18 açık soru #4).

### 5.6 Neden gecikme bizim sorunumuz değil

Path üretimi F1'de asenkron ve kullanıcı ilk oturumu ancak F2'den sonra dinliyor —
~15–20 saniyemiz var, 75 ms değil. Düşük gecikmeli modelin kalite ödünü karşılıksız
kalır. Tek istisna: 1. adımın sesi öncelik kuyruğunda üretilir.

### 5.7 Üretim ayarları (ElevenLabs örneği)

```jsonc
// POST /v1/text-to-speech/{voice_id}   ·   AB uç noktası: api.eu.residency.elevenlabs.io
{
  "text": "...",
  "model_id": "eleven_multilingual_v2",
  "voice_settings": {
    "stability": 0.65,          // meditasyonda kararlılık > çeşitlilik
    "similarity_boost": 0.80,
    "style": 0.0,               // abartı yok (Ton eki §2)
    "speed": 0.92,              // varsayılandan yavaş
    "use_speaker_boost": true
  }
}
```

- `output_format`: teslimde `mp3_44100_128`; arşivde `pcm_44100` (format değişirse
  yeniden üretim gerekmesin).
- `language_code` **`multilingual_v2` ile desteklenmiyor**; dil zorlaması gerekirse
  `eleven_v3` veya flash ailesi.
- `optimize_streaming_latency` kullanılmaz (kaldırılmaya alınmış).
- Telaffuz sözlüğü (istekte en fazla 3 sözlük): Türkçe özel adlar ve yabancı terimler.

### 5.8 Veri ikametgâhı

ElevenLabs bölgesel uç nokta sunuyor: `api.eu.residency.elevenlabs.io`. **AB uç noktası
kullanılmalı** — TTS'e giden metin kullanıcının kendi cümlesini içeriyor, GDPR Madde 9
özel kategori veri. Aynı gereklilik seçilecek her sağlayıcı için geçerli; AB bölgesi
sunmayan bir sağlayıcı bu ürün için eleme sebebidir.

---

## 6. Kişiselleştirme derinliği — "her şey kişiye özel" ne kadar mümkün

### 6.1 Bir oturumun anatomisi

10 dakikalık bir oturumun 2.750 karakteri şöyle dağılıyor:

| Bölüm | Karakter | Pay | Kişiselleştirilebilir mi |
|---|---|---|---|
| Açılış / karşılama | ~350 | %13 | **Evet** — kullanıcının kendi cümlesi |
| Tekniğe giriş, gerekçe | ~400 | %15 | **Evet** — onun durumuna bağlanır |
| **Tekniğin gövdesi** | ~1.300 | **%47** | **Hayır** — aşağıya bak |
| Geçiş / köprü cümleleri | ~300 | %11 | **Evet** |
| Kapanış | ~400 | %15 | **Evet** |

**Tekniğin gövdesi neden kişiselleştirilmiyor:**

> "Dörde kadar sayarak nefes al. Yarım saniye tut. Altıya kadar sayarak ver."

Bu cümlenin kişiselleştirilmiş bir versiyonu **yok**. Sayılar klinik; sırayı değiştirmek
tekniği bozar. Kişiye göre değiştirilirse (a) kullanıcı hiçbir fark hissetmez, (b) her
oturumda yeniden TTS ödenir, (c) klinik gözden geçirmeden geçmemiş metin sese dönüşür.
**Bu %47'yi taze üretmek, sıfır algılanan değer karşılığında maliyeti iki katına
çıkarmaktır.**

Kullanıcının "bu benim için yazılmış" diye hissettiği şey gövde değil, **çerçevedir**:
onu adıyla karşılayan açılış, kendi cümlesini geri duyması, kendi kaçındığı işin örnek
olarak geçmesi, kapanışta kendi hedefine dönülmesi.

### 6.2 Dört kademe

| Kademe | Ne taze | Taze pay | Hissiyat |
|---|---|---|---|
| **A** | Yalnızca 1. adımın açılışı | %13 | "İlk gün beni tanıdı, sonra jenerikleşti" |
| **B** | Her adımın açılışı + kapanışı | %36 | "Her gün bana sesleniyor" |
| **C** | Teknik gövdesi hariç her şey | %53 | "Tamamı benim için yazılmış" |
| **D** | Literal her kelime | %100 | C ile **duyulabilir farkı yok** |

**C ile D arasında algılanan fark yok, maliyet farkı ~2×.** D'nin tek getirdiği şey
nefes sayımının da her kullanıcıya yeniden okunması.

### 6.3 Kademe C'nin içinde ne var — örnek

Aynı 2. adımın açılışı, iki farklı kullanıcı için:

**Kullanıcı 1** — *"Akşam yatağa girince zihnim durmuyor, yarın yapacaklarımı sayıklıyorum."*

> "Dün gece de aynı şey olduysa şaşırma. Yatağa girdiğinde zihnin yarını planlamaya
> başlıyor — bu, gün boyu susturulmuş bir zihnin ilk sessizlikte konuşmaya başlaması.
> Bugün onu susturmaya çalışmayacağız. Sadece nereye koyacağını göstereceğiz."

**Kullanıcı 2** — *"Sınav yaklaştıkça çalışmaktan kaçıyorum, kitabı açıp kapatıyorum."*

> "Kitabı bugün de açıp kapattıysan, bu tembellik değil. Açtığın anda gelen o baskı
> hissi, kaçmayı en mantıklı seçenek gibi gösteriyor. Bugün baskıyı yok etmeye
> çalışmayacağız. Sadece onunla aynı odada kalmayı deneyeceğiz."

İkisinin de arkasındaki teknik aynı blok. Değişen çerçeve.

### 6.4 Karar

> **Kademe C seçilir** ve TTS sağlayıcısı, C'yi §5.3'teki bütçeye sığdıracak şekilde
> **§5.4 testiyle** belirlenir.
>
> ElevenLabs multilingual + C = path başına $3.67. Bu, PRD §13.3 hedefinin 3–5 katı.
> Yani ya:
> - **(a)** Türkçesi geçen daha ucuz bir sağlayıcı bulunur (C + $30/1M = **$0.92**), ya da
> - **(b)** kademe B'ye inilir (ElevenLabs + B = $2.50), ya da
> - **(c)** fiyatlandırma hedefi yukarı çekilir.
>
> **Öneri (a).** Ses kimliği testi (§5.4) bu yüzden yol haritasının en erken maddesi.

---

## 7. Ne zaman üretilir — kademeli üretim ve ücretsiz pencere

Bu bölüm, kişiselleştirme kademesinden **daha büyük** bir maliyet kaldıracı içeriyor.

### 7.1 Sorun: ilk 7 gün ücretsiz

Ürün kararı: kullanıcı 7. güne kadar ödeme yapmıyor (PRD-Ek Onboarding §7.3). Yani
**tüm üretim maliyeti, ödeme ihtimali olmayan bir kullanıcı için baştan ödeniyor.**

21 günlük path'in tamamı F1'de üretilirse ve kullanıcı 2. günde bırakırsa, 19 günlük
ses boşa üretilmiş olur.

### 7.2 Çözüm: tam zamanında (JIT) üretim

| Ne zaman | Ne üretilir |
|---|---|
| F1 (onboarding) | **Path planı (21 gün, tüm başlıklar)** + **yalnızca 1. adımın sesi** |
| 1. adım biterken | 2. adımın sesi arka planda |
| Her akşam, hatırlatmadan önce | Ertesi günün sesi |
| **7. gün ödemesinden sonra** | 8–21. adımların sesi, kuyruğa |

**Kullanıcı bir fark hissetmiyor:** F2'deki harita 21 günün tamamını gösteriyor
(başlıklar plandan geliyor, ses gerektirmiyor), ilk oturum anında başlıyor, sonraki
her gün sesi hazır bekliyor.

**Risk:** kullanıcı bir günde iki adım yapmak isterse ses hazır olmayabilir. Çözüm:
her zaman **bir adım ileri** hazır tutulur (N tamamlanınca N+2 kuyruğa girer).

### 7.3 Kohort matematiği

Varsayım (Faz 0 verisiyle değiştirilecek **hipotez**):

| Gün | 1 | 2 | 3 | 4 | 5 | 6 | 7 | Toplam |
|---|---|---|---|---|---|---|---|---|
| Kalan kullanıcı | %100 | %70 | %58 | %50 | %44 | %39 | %35 | — |
| Üretilen oturum (100 kayıt) | 100 | 70 | 58 | 50 | 44 | 39 | 35 | **396** |

- **Baştan üretim:** 100 kayıt × 7 gün = **700 oturum**
- **JIT üretim:** **396 oturum**
- **Tasarruf: %43** — tek satır kod değişikliğiyle değil, kuyruk mimarisiyle.

### 7.4 Ücretsiz kullanıcı başına maliyet

Kademe C, JIT, kayıt başına ortalama 3,96 oturum:

| TTS sağlayıcı | Oturum başı taze | Ses maliyeti | + LLM | **Kayıt başına** |
|---|---|---|---|---|
| ElevenLabs multilingual ($120) | $0.175 | $0.69 | $0.045 | **$0.74** |
| ElevenLabs flash ($60) | $0.087 | $0.35 | $0.045 | $0.39 |
| fal.ai orta ($40) | $0.058 | $0.23 | $0.045 | $0.28 |
| OpenAI `tts-1-hd` ($30) | $0.044 | $0.17 | $0.045 | **$0.22** |
| fal.ai ucuz ($20) | $0.029 | $0.12 | $0.045 | $0.16 |

**Neden bu tablo belirleyici:** €14.99'luk tek path satışında, dönüşüm oranı %8 ise
her ödeyen kullanıcı 12,5 ücretsiz kullanıcının maliyetini taşıyor:

| Sağlayıcı | Ödeyen başına taşınan COGS | €14.99'a oranı |
|---|---|---|
| ElevenLabs multilingual | $9.25 | **%62 — sürdürülemez** |
| OpenAI `tts-1-hd` | $2.75 | %18 — kabul edilebilir |
| fal.ai ucuz | $2.00 | %13 — rahat |

> **Karar kapısı.** Dönüşüm %8 varsayımıyla ElevenLabs + kademe C kombinasyonu brüt
> marjı %38'e indiriyor. PRD §13.3'ün %82–94 hedefine ulaşmak için ya ucuz TTS ya
> daha yüksek dönüşüm gerekiyor. **Bu, ürünün en kırılgan sayısıdır ve Faz 0'da
> ölçülmelidir.**

### 7.5 İkinci kaldıraç: ilk 3 gün daha kısa

Adım süresi E2'de seçiliyor (5/10/15 dk) ama **ilk üç gün bilinçli olarak kısa
tutulabilir** — pedagojik olarak da doğru (PRD §9.3: "hızlı etki, güven inşası").
5 dakikalık ilk üç adım, en çok kullanıcının bulunduğu yerde maliyeti yarıya indirir:

100 kayıtta ilk üç gün 5 dk yapılırsa: (100+70+58) × 1.400 + (50+44+39+35) × 2.750
= 319.200 + 462.000 = 781.200 karakter — hepsi 10 dk olsaydı 1.089.000 idi.
**%28 daha az.**

---

## 8. Uçtan uca örnek akışlar

Bu bölüm dokümanın geri kalanını somutlaştırır: gerçek bir kullanıcı girdisinden
başlayıp, üretilen plana, söylenen cümlelere ve ödenen kuruşa kadar.

> Aşağıdaki bütün cümleler **Ton eki §2–3'e uygun** yazılmıştır: teşhis yok, garanti
> yok, "geçecek" yok, emoji yok, ünlem yok. Ses testi uygulanmıştır — her cümle gece
> 2'de uyuyamayan birine yüksek sesle söylenebilir.

---

### 8.1 Vaka 1 — Uyku / ruminasyon

**Onboarding çıktısı**

| Alan | Değer |
|---|---|
| Ad | Elif |
| Yaş / cinsiyet | 25–34 / kadın |
| A2 kategori | Uyuyamamak (birincil), Kaygı (ikincil) |
| **B1 serbest metin** | *"Akşam yatağa girince zihnim durmuyor. Yarın yapacaklarımı tek tek sayıklıyorum, sonra da uyuyamadığım için kendime kızıyorum. Sabah kalktığımda zaten yorgunum."* |
| B2 süre | Aylardır |
| B3 zamanlama | Yatağa girince |
| **B4 kaçınma** | *"Yatma saatimi sürekli erteliyorum. Nasılsa uyuyamayacağım diye telefonda kalıyorum."* |
| B5 denenenler | Başka meditasyon uygulamaları |
| B6 ruh hâli | Ağır |
| D ölçüm | Uykuya dalma 1–2 saat · gece 2–3 kez uyanma · öz-yeterlik düşük |
| E tercihler | 23:00 · 10 dakika · Sakin ve kısa |

**Adım 1 — Sınıflandırma çıktısı** (ucuz LLM)

```jsonc
{
  "primary_problem": "sleep_onset_rumination",
  "secondary_problem": "self_criticism",
  "severity": 4,
  "timing": "bedtime",
  "avoidance_present": true,
  "avoidance_domain": "bedtime_procrastination",
  "therapy_context": "none",
  "summary_for_generation":
    "Yatağa girince ertesi günün planını zihninden geçiriyor; uyuyamayınca kendini
     suçluyor. Sabah yorgun uyanıyor. Yatma saatini telefonla erteliyor. Aylardır
     sürüyor. Daha önce meditasyon uygulaması denemiş, sürdürememiş."
}
```

**Adım 2 — Kriz kontrolü:** `signal: false`. Akış devam eder.

**Adım 4 — Üretilen plan (özet)**

| Gün | Faz | Bloklar | Başlık (taze) |
|---|---|---|---|
| 1 | Rahatlama | `breath.coherence.v1` + `closing.day.v1` | Zihni yavaşlatmaya başlamak |
| 2 | Rahatlama | `body.scan.short.v2` | Bedenin nerede gergin |
| 3 | Rahatlama | `breath.478.v1` | Uykuya geçiş için nefes |
| 4 | Farkındalık | `cog.thought.labeling.v1` | Zihnin yarını planladığı an |
| 5 | Farkındalık | `sleep.mental.unload.v1` | Yarını yatağa taşımamak |
| 6 | Farkındalık | `cog.defusion.v1` | "Uyuyamayacağım" düşüncesi |
| **7** | **Ölçüm** | — | İlk ölçüm |
| 8–14 | Beceri | uyku-bağı, öz-şefkat, endişe erteleme | … |
| **14** | **Ölçüm** | — | Ara ölçüm |
| 15–20 | Davranış | yatma saati erteleme ile kademeli çalışma | … |
| 21 | Kapanış | `closing.path.v1` | Kapanış ve son ölçüm |

**1. adımda ne söyleniyor — tam metin**

Etiketler: `[TAZE]` = bu kullanıcı için üretildi ve TTS'te ücretlendirilir ·
`[SABİT]` = kütüphaneden, önceden render, maliyeti sıfır · `[SESSİZLİK]` = TTS'e
hiç gitmez.

> `[TAZE]` "Merhaba Elif. Az önce yazdıklarını okudum.
>
> Akşam yatağa girince zihnin durmuyor demiştin — yarın yapacaklarını tek tek
> sayıklıyorsun. Sonra uyuyamadığın için kendine kızıyorsun. Ve sabah zaten yorgun
> kalkıyorsun.
>
> Bu, gün boyu susturulmuş bir zihnin ilk sessizlikte konuşmaya başlaması. Aylardır
> böyle olması da onu daha karmaşık yapmıyor, sadece daha yerleşmiş yapıyor."
>
> `[SESSİZLİK 4 sn]`
>
> `[TAZE]` "Bu ilk adımda zihnini susturmaya çalışmayacağız. Susturmaya çalışmak,
> senin de fark ettiğin gibi, onu daha çok konuşturuyor. Bunun yerine nefesini
> yavaşlatacağız ve zihnin peşinden gelip gelmediğine bakacağız. Beş dakika sürecek."
>
> `[SESSİZLİK 3 sn]`
>
> `[SABİT · breath.coherence.v1]` "Yattığın yerde, sırtın yatağa değdiği yeri fark et.
> Omuzlarını bir kez yukarı kaldır, sonra bırak. Çeneni gevşet.
>
> Şimdi burnundan yavaşça nefes al. Beşe kadar sayarak. Bir… iki… üç… dört… beş.
>
> Ve yine beşe kadar sayarak ver. Bir… iki… üç… dört… beş.
>
> `[SESSİZLİK 10 sn]`
>
> Devam et. Sayıları ben söylemesem de aynı ritimde. Almak beş, vermek beş.
>
> `[SESSİZLİK 25 sn]` …" *(blok bu ritimde ~4 dakika sürüyor)*
>
> `[TAZE]` "Zihnin bu arada birkaç kez yarına gitmiş olabilir. Yarının listesine,
> saate, ne kadar uyuyabileceğine. Gittiyse, onu geri çağırmana gerek yok. Sadece fark
> et. Bu adımda yapılacak olan tam olarak buydu."
>
> `[SESSİZLİK 5 sn]`
>
> `[SABİT · closing.day.v1]` "Nefesini normale bırak. Acele etme.
>
> Hazır olduğunda gözlerini açabilirsin — ya da açmayabilirsin, uyuyacaksan gerek yok."
>
> `[TAZE]` "Yarın aynı saatte buradayız Elif. İkinci adım bedenle ilgili olacak."

**Karakter dökümü — 1. adım**

| Katman | Karakter | Not |
|---|---|---|
| `[TAZE]` | ~1.480 | Ücretlendirilir |
| `[SABİT]` | ~1.290 | Kütüphaneden |
| `[SESSİZLİK]` | 0 | İstemcide enjekte |
| **Toplam konuşma** | ~2.770 | %53 taze — kademe C |

**Maliyet — 1. adım**

| Kalem | Hesap | Tutar |
|---|---|---|
| Sınıflandırma (ucuz LLM) | ~1.400 girdi + 300 çıktı | $0.0016 |
| Kriz kontrolü (ucuz LLM) | ~900 girdi + 80 çıktı | $0.0013 |
| Path üretimi (güçlü LLM) | ~9.500 girdi (cache'li: ~7.200 okuma) + 4.800 çıktı | $0.0296 |
| Çıkış yargıcı (ucuz LLM) | ~1.100 girdi + 60 çıktı | $0.0014 |
| **TTS · 1. adım** (1.480 karakter) | ElevenLabs $120/1M | $0.178 |
| | OpenAI `tts-1-hd` $30/1M | $0.044 |
| **1. adım toplamı** | ElevenLabs | **$0.211** |
| | OpenAI | **$0.078** |

> LLM'in tamamı $0.034 — 1. adımın sesinin **beşte biri.** §4.1'in kanıtı.

**7 günlük ücretsiz pencere (JIT, kohort ortalaması 3,96 oturum)**

| Sağlayıcı | Ses | LLM | Toplam |
|---|---|---|---|
| ElevenLabs multilingual | $0.69 | $0.034 | **$0.73** |
| OpenAI `tts-1-hd` | $0.17 | $0.034 | **$0.21** |

**Ödeme sonrası (8–21. adımlar, 14 oturum)**

| Sağlayıcı | Tutar |
|---|---|
| ElevenLabs | $2.44 |
| OpenAI | $0.61 |

**Tam path (ödeyen kullanıcı, 21 adım)**

| Sağlayıcı | Ses | LLM | **Toplam** | €14.99'a oranı |
|---|---|---|---|---|
| ElevenLabs | $3.67 | $0.034 | **$3.70** | %25 |
| OpenAI `tts-1-hd` | $0.92 | $0.034 | **$0.95** | %6 |

---

### 8.2 Vaka 2 — Sınav kaygısı / kaçınma

**Onboarding çıktısı**

| Alan | Değer |
|---|---|
| Ad | *(vermedi)* |
| Yaş / cinsiyet | 18–24 / belirtmedi |
| A2 kategori | Sınav, performans baskısı |
| **B1** | *"Sınava iki ay var ama çalışmaya oturamıyorum. Kitabı açıyorum, on dakika sonra kapatıyorum. Sonra çalışmadığım için panikliyorum ve daha da yapamıyorum."* |
| B2 | Birkaç haftadır |
| B3 | Gün içinde |
| **B4** | *"Çalışma masasına oturmayı erteliyorum. Kütüphaneye gitmiyorum artık."* |
| B5 | Hiçbir şey denemedim |
| B6 | Ortalarda |
| E | 14:00 · 5 dakika · Biraz daha yönlendirici |

**Not:** Ad verilmedi → metinlerin **isimsiz sürümü** kullanılır. C3 gösterilmez
(B5'te uygulama denenmemiş). Süre 5 dk → oturum başına ~1.400 karakter.

**Üretilen plan (özet)**

| Gün | Faz | Başlık |
|---|---|---|
| 1 | Rahatlama | Masaya oturmadan önce |
| 2 | Rahatlama | Paniğin bedendeki yeri |
| 3 | Rahatlama | On dakikalık başlangıç |
| 4 | Farkındalık | Kitabı kapattığın an |
| 5 | Farkındalık | "Yetişmeyecek" düşüncesi |
| 6 | Farkındalık | Ertelemenin verdiği kısa rahatlama |
| **7** | **Ölçüm** | İlk ölçüm |
| 8–14 | Beceri | Odaklanma aralıkları, kaygıya yer açma |
| 15–20 | Davranış | Masaya kademeli yaklaşma, kütüphaneye dönüş |
| 21 | Kapanış | Kapanış ve son ölçüm |

**4. adımda ne söyleniyor — tam metin**

> `[TAZE]` "Bugün dördüncü adımdayız. Ve bugün biraz zor bir şeye bakacağız.
>
> Kitabı açıp on dakika sonra kapattığını yazmıştın. O on dakikanın sonundaki an —
> kitabı kapattığın an — bugünkü konumuz. Çünkü orada bir şey oluyor ve genelde çok
> hızlı oluyor, fark edilmiyor."
>
> `[SESSİZLİK 3 sn]`
>
> `[TAZE]` "Kapattığın anda muhtemelen kısa bir rahatlama geliyor. Bir–iki saniye
> sürüyor. Sonra yerini panik alıyor. O bir–iki saniye, ertelemenin neden bu kadar
> zor bırakıldığını açıklıyor: kısa vadede gerçekten işe yarıyor."
>
> `[SESSİZLİK 4 sn]`
>
> `[SABİT · cog.trigger.mapping.v1]` "Şimdi gözlerini kapat ve o anı zihninde canlandır.
> Sahneyi kur: nerede oturuyorsun, önünde ne var, elin nerede.
>
> `[SESSİZLİK 12 sn]`
>
> Şimdi kapatmadan hemen önceki saniyeye dön. Bedeninde ne oluyordu. Göğsünde mi,
> midende mi, omuzlarında mı.
>
> `[SESSİZLİK 15 sn]`
>
> Adını koymana gerek yok. Sadece nerede olduğunu bul.
>
> `[SESSİZLİK 20 sn]` …"
>
> `[TAZE]` "Bulduğun yer, önümüzdeki günlerde çalışacağımız yer. Kitabı kapatma
> kararını değiştirmeye çalışmıyoruz — o kararın nereden geldiğini görüyoruz.
>
> Bugün masaya oturmanı istemiyorum. Sadece bugün bir kez, kitabı kapattığın anda
> bedeninde nereye baktığını hatırla. Hepsi bu."

**Karakter dökümü — 4. adım (5 dk)**

| Katman | Karakter |
|---|---|
| `[TAZE]` | ~810 |
| `[SABİT]` | ~590 |
| **Toplam** | ~1.400 · %58 taze |

**Maliyet**

| Kalem | ElevenLabs | OpenAI `tts-1-hd` |
|---|---|---|
| 4. adım TTS | $0.097 | $0.024 |
| 7 günlük pencere (JIT, 3,96 oturum) | $0.35 | $0.087 |
| + LLM | $0.034 | $0.034 |
| **Ücretsiz pencere toplamı** | **$0.38** | **$0.12** |
| Tam path (21 adım) | $1.87 | $0.47 |

> **5 dakikalık tercihin etkisi:** aynı kullanıcı 10 dakika seçseydi maliyet iki katı
> olurdu. E2 bir tercih ekranı değil, aynı zamanda bir COGS anahtarıdır.

---

### 8.3 Vaka 3 — Tükenmişlik, terapi görüyor

**Onboarding çıktısı (kısaltılmış)**

| Alan | Değer |
|---|---|
| Ad | Mert · 35–44 · erkek |
| A2 | Tükenmişlik (birincil) |
| **B1** | *"Sabah kalktığımda zaten yorgunum. İşte otururken saatlerin nasıl geçtiğini bilmiyorum ama hiçbir şey bitmiyor. Eve gelince de kafam işte kalıyor."* |
| B5 | **Terapi (devam ediyor)** + Başka meditasyon uygulamaları |
| B6 | Çok ağır |
| E | 21:30 · 10 dakika · Sadece bilgi, yorum yok |

**Bu vakanın üç farkı**

1. `therapy_context: "ongoing"` → **ton değişir.** Prompt'a ek kural girer: ürün
   terapinin yerine geçme imasında bulunmaz, "terapinle birlikte" çerçevesi kullanılır.
2. `B6 = veryHeavy` → arka plan lacivert eksene kayar, ekran kısılır, **ilk adım daha
   kısa ve daha yönlendirici** başlar (`MoodLevel.suggestsGentlerStart`).
3. `E3 = infoOnly` → taze metinler daha kısa ve yorumsuz. **Bu doğrudan maliyeti
   düşürür:** aynı kademede taze pay %53 yerine ~%42.

**1. adım açılışı — infoOnly tonu**

> `[TAZE]` "Merhaba Mert. Bu ilk adım sekiz dakika sürecek.
>
> Yazdıklarına göre: sabah dinlenmiş uyanmıyorsun, gün içinde zaman geçiyor ama iş
> bitmiyor, akşam kafan işte kalıyor. Terapi de görüyorsun. Bu program onun yerine
> geçmiyor; yanında duruyor.
>
> Bugün yapacağımız şey bedeni taramak. Bunun tükenmişlikte işe yaramasının sebebi
> şu: yorgunluk zihinde hissediliyor ama bedende birikiyor ve genelde nerede
> biriktiği fark edilmiyor."

Karşılaştırma — aynı açılışın **"Sakin ve kısa"** tonundaki hâli daha uzun ve daha
sıcak olurdu ("Bu, uzun süre yüksek tempoda kalan hemen herkesin karşılaştığı bir
hâl…"). `infoOnly` yorum katmanını kaldırıyor.

**Maliyet farkı**

| | Sakin ve kısa | Sadece bilgi |
|---|---|---|
| Oturum başı taze karakter | ~1.460 | ~1.155 |
| ElevenLabs · 7 gün (JIT) | $0.69 | $0.55 |
| OpenAI · 7 gün (JIT) | $0.17 | $0.14 |

---

### 8.4 Üç vakanın karşılaştırması

| | Vaka 1 (Elif) | Vaka 2 (isimsiz) | Vaka 3 (Mert) |
|---|---|---|---|
| Süre tercihi | 10 dk | 5 dk | 10 dk |
| Ton | Sakin ve kısa | Yönlendirici | Sadece bilgi |
| Oturum başı taze karakter | 1.480 | 810 | 1.155 |
| **Ücretsiz pencere · ElevenLabs** | $0.73 | $0.38 | $0.59 |
| **Ücretsiz pencere · OpenAI hd** | $0.21 | $0.12 | $0.18 |
| Tam path · ElevenLabs | $3.70 | $1.87 | $2.95 |
| Tam path · OpenAI hd | $0.95 | $0.47 | $0.77 |

**Okunacak üç şey:**

1. **Süre en büyük değişken.** 5 dk seçen kullanıcı 10 dk seçenin yarısı kadar
   maliyetli. E2'nin varsayılanı (10 dk, "önerilen") bilinçli bir COGS kararıdır.
2. **Ton ikinci değişken.** `infoOnly` ~%20 daha ucuz, çünkü daha az yorum cümlesi.
3. **Sağlayıcı farkı hepsinden büyük.** Aynı vakada ElevenLabs ile ucuz sağlayıcı
   arasındaki fark 4×; süre ve ton tercihlerinin toplam etkisinden fazla.

---
## 9. Prompt mühendisliği ve maliyet disiplini

### 12.1 Prompt cache'i mimarinin parçasıdır

Blok kütüphanesi meta verisi her path üretiminde **aynıdır** — mükemmel cache adayı.
Render sırası `tools` → `system` → `messages`; sabit içerik başa, değişken içerik
(kullanıcı özeti, tercihler) son cache noktasından **sonra** konur.

```python
response = client.messages.create(
    model="claude-opus-5",
    max_tokens=16000,
    system=[
        {"type": "text", "text": GENERATION_RULES},                    # sabit
        {"type": "text", "text": BLOCK_LIBRARY_JSON,
         "cache_control": {"type": "ephemeral", "ttl": "1h"}},         # sabit, büyük
    ],
    messages=[{"role": "user", "content": user_context_json}],         # değişken
    output_config={"format": {"type": "json_schema", "schema": PATH_SCHEMA},
                   "effort": "high"},
    thinking={"type": "adaptive"},
)
```

**Doğrulama:** `usage.cache_read_input_tokens` sıfırsa sessiz bir bozan var demektir —
prompt'a sızmış bir zaman damgası, sırasız JSON anahtarları, sürüm sayacı. Bu metrik
üretim panosunda **izlenmelidir**; sessizce bozulur ve faturayı kimse fark etmeden
büyütür.

Blok kütüphanesi değiştiğinde cache doğal olarak geçersizleşir — bu doğru davranış,
kütüphane sürümü zaten yeni render gerektiriyor.

### 12.2 Sistem prompt'unun iskeleti (Adım 4)

Prompt **kural listesi değil, sözleşme** olmalı. Kabaca:

1. **Rol:** "Onaylanmış bir blok kütüphanesinden program kuruyorsun. Yeni teknik
   icat etmiyorsun."
2. **Sert sınırlar:** teşhis yok, garanti yok, terapi ikamesi yok, sayı yok, emoji yok.
   Yasak ifade listesi burada da tekrarlanır (kod tarafındaki taramaya ek olarak —
   kemer ve askı).
3. **Ark kuralları:** faz sırası, zorluk artışı, ön koşullar, tekrar aralığı.
4. **Slot kuralları:** her slotun amacı, karakter sınırı, ton kademesi.
5. **Ton:** Ton eki §2'nin dört kademesi ve "bir kademe aşağı in" kuralı.
6. **Ses testi:** "Yazdığın cümleyi gece 2'de uyuyamayan birine yüksek sesle
   söyleyebiliyor musun?"

> **Prompt sürümlenir.** `prompt_version` her üretilen path kaydına yazılır. Bir
> regresyonun hangi prompt sürümünden geldiğini bilmeden düzeltemezsiniz.

### 12.3 Maliyet kaldıraçları, sırayla

Bedava olanlar önce, kalite ödünü verenler sonra:

1. **Prompt cache** (§6.1) — en büyük tek kazanç, kalite ödünü sıfır.
2. **Girdi hijyeni** — blokların `script` metinleri prompt'a **girmiyor**, sadece meta
   veri giriyor. Bu tek karar girdi token'ını ~4× düşürüyor.
3. **Çıktı hijyeni** — şema `enum` ve `maxLength` ile dar; model uzun gerekçe yazamaz.
4. **Batch API** — path üretimi gecikmeye duyarlı, uygun **değil**. Ama blok kütüphanesi
   çeviri/gözden geçirme işleri %50 indirimle batch'te koşar.
5. **Efor kademesi** — `effort: "high"` varsayılan. `medium` ölçülerek denenebilir;
   `low` bu adım için değil.
6. **Model düşürme** — en son çare ve §4.1'deki uyarıya tabi.

---

## 10. Uyarlanabilirlik (PRD §9.4) — kural, AI değil

Path üretildikten sonra donmuş değil. Ama uyarlama **deterministik**:

| Tetik | Eylem | Kim yapıyor |
|---|---|---|
| 3× üst üste "zorlandım" | Sonraki blok bir zorluk kademesi aşağı, daha yönlendirici varyant | Kural |
| 3× üst üste "odaklanamadım" | Süre kısalır, aktif blok (nefes) tercih edilir | Kural |
| 7. gün ölçümünde bir boyut hiç değişmemiş | Kalan adımlarda o boyutun blokları ağırlıklanır | Kural |
| 5+ gün ara | Dönüşte "yeniden ısınma" adımı eklenir | Kural |

**Neden AI yok:** Bu kurallar zaten ölçülebilir sinyallere bağlı ve bir modelin
takdirine bırakıldığında hem açıklanamaz hem test edilemez hâle gelir. Ayrıca uyarlama
**sessizdir** — kullanıcıya "seni geriye aldık" denmez, bu yüzden kararın kendisi de
sade olmalı.

Uyarlama yeni blok seçimi gerektiriyorsa (nadir), Adım 4 aynı şemayla tekrar çağrılır —
ama **yalnızca kalan adımlar için**, tüm path yeniden üretilmez.

---

## 11. Maliyet defteri — özet

Tüm ayrıntı §5 (birim fiyatlar), §7 (kohort) ve §8'de (vakalar). Burası tek sayfalık özet.

### 11.1 Üç kaldıraç, etki sırasına göre

| # | Kaldıraç | Etki | Kalite ödünü |
|---|---|---|---|
| 1 | **TTS sağlayıcı seçimi** | 4–6× | Türkçe kalitesi (§5.4 testiyle ölçülür) |
| 2 | **JIT üretim** (§7.2) | ~%43 | **Yok** |
| 3 | **Kişiselleştirme kademesi** (§6.2) | 1,5–4× | Algılanan kişiselleştirme |
| 4 | Sessizlik enjeksiyonu | ~2× | Yok — zaten uygulanıyor |
| 5 | Blok kütüphanesi ön render | ~2× | Yok — zaten uygulanıyor |
| 6 | İlk 3 gün 5 dk (§7.5) | ~%28 | Yok, pedagojik olarak da doğru |
| 7 | Prompt cache (§9.1) | LLM'de ~%70 | Yok |
| 8 | LLM model düşürme | path başına ~$0.003 | Var — **buna değmez** (§4.1) |

### 11.2 Hedef ve kırmızı çizgi

| Metrik | Hedef | Kırmızı çizgi |
|---|---|---|
| Ücretsiz kullanıcı başına (7 gün, JIT) | **< $0.30** | $0.60 |
| Tam path (21 adım) | **< $1.20** | $2.00 |
| LLM payı | < %10 | — |
| Ödeyen başına taşınan ücretsiz COGS | < %20 (fiyatın) | %35 |

Kırmızı çizgi aşılıyorsa sebep neredeyse her zaman şu üçünden biridir:
taze karakter payı büyümüş, JIT bozulmuş (baştan üretime dönülmüş), veya prompt cache
sessizce geçersizleşmiş.

### 11.3 Amortize edilen kütüphane maliyeti

~40 blok × ortalama 4 dk konuşma ≈ 160 dk ≈ **816.000 karakter**, bir kez.

| Sağlayıcı | Kütüphane render'ı (bir defalık) |
|---|---|
| ElevenLabs multilingual | ~$98 |
| OpenAI `tts-1-hd` | ~$25 |

Sonraki sürümlerde yalnızca değişen blok yeniden render edilir (`id` sabit,
`version` artar). **Ses kimliği değişirse bu maliyet baştan ödenir** — §5.5.

## 12. Gizlilik ve veri sınırları

### 12.1 Katı kurallar

- Ham problem metni **şifreli** ve ayrı tabloda (PRD §13.5).
- Ham metin ve ölçüm verisi **asla** analitik araçlara (PostHog/Amplitude) gitmez.
- Path kaydında ham metin **tutulmaz**; `personalization_context` özettir.
- Ses dosyaları kullanıcıya özel imzalı URL ile; tahmin edilebilir yol yok.
- TTS ve LLM çağrıları AB uç noktalarından (§5.5).

### 12.2 Ham metnin gittiği tam liste

Bu liste kısadır ve **uzaması karar gerektirir**:

| Nereye | Neden | Saklanıyor mu |
|---|---|---|
| `CrisisClassifier` (cihaz) | Güvenlik | Hayır, cihazdan çıkmaz |
| Sınıflandırma çağrısı (Adım 1) | Etiket üretimi | Hayır |
| Kriz çağrısı (Adım 2) | Güvenlik | Hayır |
| 1. adımın `step_opening` slotu (Adım 5) | **Ürünün kendisi** — aynalama | Kısaltılmış hâli path'te |
| TTS (Adım 7) | Kullanıcının cümlesi seslendiriliyor | Hayır |

> **Kabul edilen gerilim.** PRD §13.5 "LLM'e giden bağlam özettir, ham metin değil"
> diyor; ama G1'in aha momenti tam olarak kullanıcının **kendi cümlesinin** ona geri
> okunmasıdır. İkisi aynı anda tutulamaz. Karar: ham metin üretim anında bir kez
> kullanılır, hiçbir yere loglanmaz, path kaydına özet olarak yazılır. PRD §13.5 bu
> istisnayı yazacak şekilde güncellenmelidir.

### 12.3 Veri işleyici sözleşmeleri

Anthropic ve ElevenLabs **veri işleyicidir** (GDPR Madde 28). Canlıya çıkmadan önce
ikisiyle de DPA imzalanmış ve gizlilik politikasında alt işleyici olarak listelenmiş
olmalıdır. Bu bir mühendislik işi değil, bloklayıcı bir yasal iştir.

---

## 13. Kalite ölçümü — eval olmadan bu mimari hipotezdir

Yukarıdaki model seçimlerinin hiçbiri şu an ölçülmüş değil. Canlıya çıkmadan önce en
az üç eval kümesi gerekiyor:

| Eval | Ne ölçer | Geçme ölçütü |
|---|---|---|
| **Kriz vaka tablosu** | Sınıflandırıcı + model, ima ve mecaz dâhil | Yanlış negatif **sıfır** hedefi; yanlış pozitif serbest |
| **Path yapısı** | Üretilen path şema, faz, ön koşul kurallarına uyuyor mu | %100 — kural ihlali kabul edilmez |
| **Ton ve güvenlik** | Slot metinleri yasak ifade, teşhis, garanti içeriyor mu | %100 |

Kriz vaka tablosu şu an `CrisisClassifier.swift` yanında elle koşturuluyor; test hedefi
eklendiğinde oraya taşınmalı ve **sunucu tarafı sınıflandırıcı da aynı tabloyla
koşmalı**.

Model düşürme kararları (§4.1) ancak bu evaller kurulduktan sonra doğrulanabilir.

---

## 14. Hata ve fallback matrisi

| Nerede bozulur | Kullanıcı ne görür | Sistem ne yapar |
|---|---|---|
| Sınıflandırma başarısız | Fark etmez | Kategori + B cevaplarından kural tabanlı etiketleme |
| Kriz çağrısı başarısız | Fark etmez | **İstemci sinyali belirleyici olur**; şüphede akış durur |
| Kriz çağrısı `refusal` | Kriz ekranı | Sinyal sayılır (§3 Adım 2) |
| Path üretimi başarısız | `Copy.Error.pathGenerationFailed` | 1 kez yeniden dene → jenerik şablon (kategori varsayılanı) |
| Path şema doğrulaması başarısız | Aynı | Aynı |
| Yargıç `block` | Fark etmez | Slot jenerik yedeğe düşer |
| TTS başarısız (1. adım) | `Copy.Error.audioFailed` | Metin olarak okuma seçeneği + arka planda yeniden dene |
| TTS başarısız (2–21) | Fark etmez | Kuyrukta yeniden dene; o güne kadar zaman var |
| CDN erişilemiyor | Çevrimdışı mesajı | İndirilmiş oturumlar çalışır |

**Her hata metninde "kaybolmadı / senin yüzünden değil" geçer** (Ton eki §3.2).
Jenerik şablona düşüldüğünde kullanıcıya bunu söylemeyiz — ama iç telemetride
`generation_fallback_used` işaretlenir ve bu oran izlenir; %2'yi geçerse mimaride
sorun var demektir.

---

## 15. Yapılma sırası

Sıra, her adımın bir öncekini doğrulayacak şekilde:

1. **TTS Türkçe kalite testi (§5.4).** Her şeyden önce. Ses kimliği kararı hem
   kütüphane render'ını hem COGS modelini kilitliyor; yanlış sırayla yapılırsa
   kütüphane iki kez render edilir.
2. **Blok kütüphanesi v1 (TR).** ~40 blok, elle yazılmış, klinik gözden geçirmeden
   geçmiş. **AI yok.** Faz 0'ın elle uygulanan path'i bu kütüphaneden çıkmalı.
3. **Şema ve doğrulayıcı.** Path planı JSON şeması + Adım 4'ün doğrulama kontrolleri.
   Model olmadan, elle yazılmış planlarla test edilir.
4. **Kriz sınıflandırıcısı (sunucu) + vaka tablosu.** Bloklayıcı. Path üretiminden
   **önce** çalışır durumda olmalı.
5. **Adım 1 + 4 + 6** (sınıflandırma, üretim, yargıç). Prompt cache günü sıfırdan kurulur.
6. **TTS kütüphane render'ı.** 1. maddedeki karar kesinleştikten sonra.
7. **JIT üretim kuyruğu (§7.2).** Taze slot render'ı + istemci ses motoru + "bir adım
   ileri hazır" mantığı.
8. **Uyarlama kuralları.** En son; gerçek geri bildirim verisi olmadan kalibre edilemez.

## 16. Karar günlüğü

| # | Karar | Gerekçe | Geri alınırsa |
|---|---|---|---|
| 1 | LLM plan üretir, metin değil | Kalite tutarlılığı, fiyatlanabilirlik, güvenlik (PRD §9.1) | Ürün denetlenemez hâle gelir |
| 2 | Kriz taraması ayrı ve dar bir çağrı | Uzun prompt'un içine gömülen talimat kaybolur | Yanlış negatif riski artar |
| 3 | Kriz sinyali tek yönlü yükseltilir | Asimetrik maliyet | Kriz sinyali vermiş kullanıcıya program satılır |
| 4 | Sınıflandırma/yargıç ucuz kademe, üretim güçlü kademe | Maliyet; **ölçülmedi** (§13) | Kalite artar, LLM maliyeti ~5× — ama path COGS'unda %3'ten az |
| 5 | Tek `voice_id` **ve** tek TTS modeli | Hazır blok ile taze slot arasındaki dikiş duyulur | Aha momenti bozulur |
| 6 | Flash/turbo TTS seçilmedi | Gecikme bizde sorun değil, kalite önemli (§5.3) | Kalite düşer, kazanç yok |
| 7 | Sessizlik istemcide enjekte edilir | TTS maliyetinin yarısı sessizlik | Maliyet ~2× |
| 8 | Blok `script` metinleri prompt'a girmez | Girdi token'ı ~4× düşüyor | Cache ve maliyet bozulur |
| 9 | Uyarlama kural tabanlı | Açıklanabilirlik ve test edilebilirlik | Sessiz uyarlama denetlenemez |
| 10 | Ölçüm, kova ve uzunluk AI'sız | Bunlar sözleşme, takdir değil | Kova C taahhüdü anlamsızlaşır |
| 11 | `revise` verdiğinde yeniden üretim yok | Maliyet ve gecikme ikiye katlanır; yedek yeterince iyi | COGS artar |
| 12 | AB uç noktaları zorunlu | Özel kategori veri (GDPR M9) | Yasal risk |
| 13 | Tek LLM sağlayıcısı, iki kademe | LLM path COGS'unun %2–8'i; parçalamak ikinci SDK/DPA/hata yüzeyi getiriyor | Karmaşıklık artar, tasarruf ~$0.003 |
| 14 | Üretim çağrısı sağlayıcı arayüzü arkasında | Fiyat değil **risk**: sağlayıcının güvenlik politikası ruh sağlığı içeriğine sertleşebilir | Kilitlenme |
| 15 | Kişiselleştirme kademesi **C** (teknik gövdesi hariç her şey) | D ile duyulabilir fark yok, maliyet 2× | Algılanan kişiselleştirme düşer |
| 16 | Teknik gövdesi kişiselleştirilmez | Nefes sayımının kişiye özel versiyonu yok; sıfır algılanan değer, iki kat maliyet | COGS 2× |
| 17 | **JIT üretim** — F1'de yalnızca 1. adımın sesi | Ücretsiz penceredeki üretimin %43'ü boşa gidiyordu | Ücretsiz kullanıcı maliyeti ~2× |
| 18 | 8–21. adımların sesi ödeme sonrası | Dönüşmeyen kullanıcı için 14 oturum boşa üretiliyordu | Ödeyen başına taşınan COGS ~3× |
| 19 | TTS sağlayıcısı Türkçe testiyle seçilir, marka tercihiyle değil | COGS'u 4–6× değiştiren tek karar | Marj hedefi tutmaz |

---

## 17. Açık sorular

Bunlar kapanmadan üretim mimarisi kesinleşmiş sayılmaz. Sıra, bloklama derecesine göre:

1. **TTS sağlayıcı ve ses kimliği** (PRD §18 #4). §5.4 testi. **Her şeyi bloke ediyor:**
   kütüphane render'ını, COGS modelini, fiyatlandırma marjını.
2. **Kişiselleştirme kademesi onayı.** §6.4 kademe C öneriyor; bu ürün sahibinin
   kararı ve doğrudan §7.4'teki tabloyu belirliyor.
3. **Dönüşüm oranı varsayımı.** §7.4'ün tamamı %8 dönüşüm varsayıyor. Faz 0'da
   ölçülmeden marj hesabı hipotez.
4. **Retention eğrisi.** §7.3'ün kohort tablosu tahmin; JIT'in gerçek tasarrufu buna
   bağlı.
5. **Kategori → path tipi eşlemesi** (PRD §18 #3) — D5 ölçüm maddesi ve şablon seçimi
   buna bağlı.
6. **Ucuz LLM sınıflandırmada yeterli mi?** Eval kurulmadan bilinmiyor (§13).
7. **Blok kütüphanesi kim yazıyor ve kim onaylıyor?** Klinik gözden geçirme süreci
   tanımlı değil. İçerik ve sorumluluk sorusu, mühendislik sorusu değil.
8. **PRD §13.2 ↔ §13.3 tutarsızlığı** (§5.3 kutusu) hangi yönde düzeltilecek —
   taze pay mı düşecek, maliyet hedefi mi yükselecek?
