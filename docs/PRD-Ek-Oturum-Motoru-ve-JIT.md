# PRD Eki — Oturum motoru, kademeli üretim ve adım sonu sorusu

Tarih: 2026-09-09. Durum: **tasarım onaylandı, uygulama başlıyor.**
Üst doküman: `PRD-Ek-Path-Uretimi-ve-AI.md` (§2 blok şeması, §5 TTS, §6 kademe C,
§7 JIT). Bu ek o dokümanı **uygulanabilir hâle getirir** ve iki yeni karar ekler:
adım sonu sorusu ve sesle senkron arka plan.

---

## 0. Bir bakışta

| Soru | Cevap |
|---|---|
| Duraklamaları kim ayarlıyor? | **LLM değil.** Blok kütüphanesindeki `silence.sec`, insan yazımı. Duraklama tekniğin parçası. |
| Konuşma süresi nereden geliyor? | Ölçülüyor — ses dosyasının kendi uzunluğu. Hiçbir yerde tahmin edilmiyor. |
| Oturum uzunluğu nasıl tutturuluyor? | Blok **seçimiyle** (E2 ± %20 doğrulaması), metni uzatıp kısaltarak değil. |
| Kütüphane nerede? | Supabase `blocks` tablosu, `script` jsonb. İstemci indirir ve cache'ler. |
| Ne zaman üretiliyor? | Aḋım N **başlarken** N+1'in planı; N **biterken** (soru cevaplandıktan sonra) N+1'in slot metni + sesi. |
| Adım sonu sorusu neye yarıyor? | Sonraki adımın slot metnine girdi. Ekranda okunur, **TTS'e gitmez** → maliyeti sıfır. |
| Arka plan sesle nasıl hareket ediyor? | Zarf takipçisinden (`voiceEnergy`) gelen **küçük bir ek terim**. Taban hareket hiç durmaz. |

---

## 1. Oturum betiği — tek veri yapısı

### 1.1 Blok `script`i (kaynak)

`PRD-Ek-Path-Uretimi-ve-AI.md` §2.1'deki şema aynen kullanılır, üç tip:

```jsonc
"script": [
  { "type": "fixed",   "text": "Omuzlarını bir kez yukarı kaldır, sonra bırak." },
  { "type": "silence", "breaths": 1 },
  { "type": "slot",    "name": "technique_bridge" },
  { "type": "fixed",   "text": "Şimdi dörde kadar sayarak nefes al." },
  { "type": "silence", "breaths": 3, "hold": "exhale" }
]
```

Üst dokümandan **tek sapma**: `silence` saniye yerine **nefes döngüsü** sayar
(`breaths`). Gerekçe: arka plan 10 saniyelik döngüyle soluyor ve saniyeyle yazılmış
bir sessizlik döngünün ortasında bitiyor — kullanıcı nefes verirken ses başlıyordu.
Saniye gerekirse `sec` de kabul edilir; ikisi bir arada yazılamaz.

`hold` alanı isteğe bağlı: sessizliğin nefes döngüsünün **hangi evresinde** bitmesini
istediğimizi söyler (`inhale` / `exhale`). "Şimdi ver" dedikten sonraki sessizlik
nefes verme evresinde bitmeli.

### 1.2 Derlenmiş oturum (çalışma zamanı)

İstemci `script`i tek bir zaman çizelgesine derler:

```swift
enum SessionCueKind { case speech(SpeechCue), silence(SilenceCue) }

struct SpeechCue {
    let text: String            // ekranda gösterilecek
    let source: AudioSource     // .library(assetID) | .personal(slotName) | .none
    let leadIn: TimeInterval    // önündeki boşluk
}

struct SilenceCue {
    let breaths: Double
    let landOn: BreathPhase?    // nil = serbest
}
```

**Konuşma süresi çizelgede yazmaz.** Çalarken ses dosyasının gerçek uzunluğu
kullanılır; ses yoksa (yedek yol) metin uzunluğundan konuşma hızıyla tahmin edilir
(`Speech.charactersPerSecond`, ölçülerek kalibre edilir).

---

## 2. Doğal akış — kurallar

Bugünkü davranışın sorunu şu: her yönerge, içeriğinden bağımsız olarak N nefes
döngüsü ekranda kalıyor. Bağlantılı iki cümle arasında 30 saniye bekleniyor, ve
kullanıcı "bir şey mi oldu" diye gözünü açıyor. Yeni kurallar:

**K1 · Konuşma konuşmayı bekletmez.** Ardışık `fixed`/`slot` parçaları arasında
yalnızca `Speech.joinGap` (350 ms) var. Aynı fikrin cümleleri peş peşe akar.

**K2 · Sessizlik yalnızca yazıldığı yerde.** Boşluk otomatik eklenmez; `silence`
girdisi yoksa boşluk yoktur. Sessizliğin tek gerekçesi kullanıcının **bir şey
yapması**: nefes almak, bedeni taramak, bir şey fark etmek.

**K3 · Konuşma nefes sınırına yuvarlanmaz.** Konuşma ne kadar sürüyorsa o kadar
sürer. Yalnızca **sessizlikler** nefes döngüsüne hizalanır (`landOn`).

**K4 · Uzun sessizlikten sonra yumuşak giriş.** Bir nefes döngüsünden uzun
sessizliği takip eden konuşma 600 ms'de açılır (normalde 250 ms). Gözü kapalı,
gevşemiş bir kullanıcıya ses aniden girmemeli.

**K5 · Ekran metni sesle aynı anda değişir.** Metin, sesi **beklemez** ve
**öndelemez**. Sessizlik sırasında son cümle ekranda kalır — boş ekran "bitti mi?"
sorusunu doğuruyor.

**K6 · Toplam süreyi blok seçimi tutturur.** Metni uzatıp kısaltmak yasak. E2'nin
5/10/15 dakikası, seçilen blokların `duration_sec` toplamıyla ± %20 içinde
tutulur (üst doküman §3, Adım 4 doğrulama tablosu). Bugünkü "teknik sahnelerini
ölçekle" yaklaşımı **kaldırılır** — o yaklaşım nefes sayımını uzatıp tekniği
bozuyordu.

---

## 3. Ses

### 3.1 Seviye

- Sistem ses düzeyine **dokunulmaz**. `AVAudioSession` seviye ayarlamaz.
- Karıştırıcıda ses tek kanal: `voice`. v1'de müzik yatağı yok.
- Her parça 250/600 ms açılır ve 250 ms kapanır (K4). Tık sesi ve ani giriş yok.
- Blok kütüphanesi render'ı **tek seferde ve aynı ayarlarla** yapılır; parçalar
  arası seviye farkı olmamalı. Render hattında normalizasyon (hedef −16 LUFS)
  zorunlu — farklı günlerde render edilmiş iki parçanın seviye farkı oturumun
  ortasında duyuluyor.

### 3.2 Üretim ayarları

Üst doküman §5.7'deki ayarlar geçerli (`stability 0.65`, `style 0`, `speed 0.92`).
**Ses kimliği sabittir**; değiştirmek tüm kütüphaneyi yeniden render ettirir.

### 3.3 Veri ikametgâhı — sağlayıcı seçimini bağlayan kısıt

TTS'e giden metin kullanıcının **kendi cümlesini** içeriyor (aha momenti tam olarak
bu). Bu, GDPR Madde 9 anlamında **sağlık verisi**dir: normal kişisel veriden daha
yüksek bir eşik.

Pratik sonuçları:

1. **Sağlayıcı bir veri işleyicidir** → DPA (veri işleme sözleşmesi) şart.
2. **AB dışına aktarım** ancak geçerli bir mekanizmayla olur: sağlayıcının
   EU–US Data Privacy Framework sertifikası ya da imzalı SCC'ler.
3. **Zincirdeki her halka ayrı bir işleyicidir.** Bugünkü kod fal.ai üzerinden
   ElevenLabs'e gidiyor: iki işleyici, iki DPA, iki aktarım analizi.

> **Karar:** TTS'e **doğrudan** sağlayıcıya gidilir, aracı üzerinden değil.
> Zincirden bir halka çıkarmak hem hukuki yüzeyi hem hata yüzeyini yarıya indiriyor.
> Sağlayıcı AB uç noktası sunuyorsa o kullanılır (ElevenLabs:
> `api.eu.residency.elevenlabs.io`).

Sağlayıcı seçimi (kalite ve maliyet) hâlâ açık — üst doküman §5.4'teki Türkçe kör
testi yapılmadı. Bu yüzden **çağrı bir arayüzün arkasında durur** ve sağlayıcı
değiştirmek bir yapılandırma değişikliğidir, yeniden yazım değil.

---

## 4. Arka plan sesle nefes alır

Gözü kapalı bir kullanıcı için arka plan **bilgi taşımaz**; ortam yaratır. Bu
yüzden ses senkronu ölçülü olmalı: göz açıldığında ekranın konuşmayla birlikte
kıpırdadığı hissedilmeli, ama hareket sesin görselleştirmesi (ekolayzer) olmamalı.

### 4.1 Zarf takipçisi

```
mixer.installTap → 50 ms pencere → RMS
  → asimetrik tek kutuplu filtre:  atak 80 ms, bırakış 450 ms
  → voiceEnergy ∈ [0, 1]
```

Asimetri bilinçli: hızlı atak konuşmanın başladığını yakalar, yavaş bırakış
hecelerin arasında titremeyi engeller. RMS **doğrudan** hiçbir yere bağlanmaz —
"smooth" isteğinin karşılığı bu filtredir.

### 4.2 Nereye giriyor

`voiceEnergy` mevcut hareketin **üstüne eklenir**, yerine geçmez:

```
nokta konumu = merkez
             + sinüs₁ + sinüs₂          ← taban hareket, hiç durmaz
             + nefes(t) × genlik        ← 10 sn döngü
             + voiceEnergy × 0.03       ← YENİ, küçük
```

- Tavan **0.03**. Mevcut genlik tavanı 0.13'tü ve üstüne çıkınca mesh bükülüyordu;
  ses terimi o bütçenin dörtte birini alıyor.
- Ses sustuğunda terim sıfıra iner, **taban hareket devam eder**. "Sürekli hareket
  halinde olsunlar" isteği zaten mimaride var; ses onu durdurmuyor.
- Shader parlaklığına da çok küçük bir katkı (≤ %4) — ses varken ekran bir tık
  canlanıyor.
- **Reduce Motion'da tamamen kapalı.** Ses de olsa arka plan hareket etmiyor.

---

## 5. Kademeli (JIT) üretim — düzeltilmiş model

Üst doküman §7.2 "N tamamlanınca N+2 kuyruğa" diyordu. **Adım sonu sorusu bu modeli
bozuyor** ve daha iyi bir modele zorluyor.

### 5.1 Neden eski model çalışmıyor

N+1'in slot metni, N'in sonunda sorulan soruya verilen cevabı içerecek. Yani N+1
**N bitmeden finalize edilemez**. Erken üretmek, cevabı kullanamamak demek.

### 5.2 Üretimin iki parçası

| Parça | Neye bağlı | Ne zaman hazır | TTS maliyeti |
|---|---|---|---|
| **İskelet** — `block_ids`, `step_title`, faz | Yalnızca onboarding cevapları | F1'de, 21 günün tamamı | **Sıfır** — ekranda okunur |
| **Sabit ses** — blokların `fixed` parçaları | Hiçbir şeye | Kütüphane render'ında, bir kez | **Sıfır** — amortize |
| **Slotlar** — metin + ses | Önceki adımların cevapları | Adım biterken | **Tamamı burada** |

Yani JIT'in birimi adım değil, **slotlar**. Oturumun %47'si (teknik gövdesi) zaten
hazır bekliyor; üretilen yalnızca çerçeve.

### 5.3 Değişmez kural

> **Sıradaki başlanmamış adımın slotları her zaman hazır ya da üretimde olmalı.**

Bunu sağlayan tetikleyiciler:

| Olay | Tetiklenen |
|---|---|
| F1 (onboarding) | İskelet (21 gün) + **1. adımın slotları ve sesi**, öncelikli kuyruk |
| Adım N **bitti**, soru cevaplandı/geçildi | **N+1'in slotları ve sesi** |
| Akşam hatırlatmasından ~1 saat önce | Sıradaki adım hâlâ hazır değilse tamamla |
| 7. gün ödemesi | 8…21 arası kuyruğa (düşük öncelik) |

**Aynı gün ikinci adım.** Kullanıcı N'i bitirip hemen N+1'e girerse üretim daha
bitmemiş olabilir. O zaman F1'in ekranı gösterilir (~15–25 sn) — yalan söylenmez,
"hazırlanıyor" denir. Nadir bir durum için bir gün önceden üretmek, cevabı
kullanamamak demek olurdu.

**Terk eden kullanıcı.** N'i bitirmeden bırakan kullanıcı için hiçbir şey
üretilmez. Üst doküman §7.3'ün %43 tasarrufu buradan geliyor ve bu model onu
korur — hatta artırır, çünkü artık N+1 ancak N *bittiğinde* üretiliyor.

### 5.4 Adım başına LLM çağrısı

F1'deki tek dev çağrı ikiye ayrılır:

- **F1 çağrısı:** iskelet (21 gün blok seçimi + başlıklar) + 1. adımın slotları
  + 1. adımın sorusu. Güçlü model, ~8–20 sn.
- **Adım çağrısı (N ≥ 2):** yalnızca N'in slotları + N'in sorusu. Girdi: özet,
  path iskeleti, 1…N-1 arasında hangi bloklar geçti, sorulara verilen cevaplar.
  Güçlü model ama **çok küçük prompt**; blok kütüphanesi meta verisi prompt
  cache'in sabit öneki (üst doküman §12.1).

Maliyet etkisi: LLM çağrı sayısı artıyor ama token sayısı azalıyor (21 adımın
slotunu bir kerede üretmek yerine gerektiği kadarını üretmek). Ve LLM zaten
maliyetin %2–8'i.

---

## 6. Adım sonu sorusu

### 6.1 Ne olduğu

Oturum biter bitmez, G2'de, tek bir soru. LLM üretir ve **kullanıcının kendi
sorunuyla ilgilidir**:

> *"Bugün zihnin yarına gitmeye başladığında ne yapıyordun?"*
> *"Kitabı bugün açtın mı? Açtıysan ne kadar kalabildin?"*

Cevap serbest metin, tek satır, isteğe bağlı.

### 6.2 Kurallar

- **`step_question` bir slot'tur** ama **TTS'e gitmez** — ekranda okunur.
  `step_title` gibi: kişiselleştirmesi bedava (üst doküman §2.2).
- **Sınır 120 karakter.** Uzun soru ekranda ödev gibi duruyor.
- **Atlanabilir.** "Bugün geç" — cevapsız kullanıcı ertesi gün programsız kalmaz;
  N+1 yine üretilir, yalnızca daha jenerik olur. Kaçırılan gün hiçbir şeyi geri
  almaz kuralı burada da geçerli.
- **Serbest metin → kriz sınıflandırıcısı.** İstisnasız. Sinyal varsa akış durur:
  sonraki adım üretilmez, ekranda hareket olmaz, yardım gösterilir.
- **Cevap analitiğe gitmez**, şifreli saklanır ve yalnızca sonraki adımın
  üretiminde özet olarak kullanılır (PRD §13.5).
- Soru **bir ödev değil.** Ton: Sakin kademe. "Yarına kadar düşün" gibi bir
  çerçeve yok; cevaplamak isteyen cevaplar.

### 6.3 Veri modeli

```sql
create table public.path_step_answers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  path_step_id uuid not null references public.path_steps(id) on delete cascade,
  question text not null check (char_length(question) between 1 and 200),
  answer_ciphertext text,          -- ham metin şifreli (PRD §13.5)
  answer_summary text,             -- LLM'e giden özet
  skipped boolean not null default false,
  created_at timestamptz not null default now(),
  unique (path_step_id)
);
```

---

## 7. Ölçüm — 7. günden önce iyileşme gösterilmez

Ürün sahibi kararı, 2026-09-09: **7. güne gelmeden kullanıcı iyileşme görmez.**
Boş bir "henüz veri yok" grafiği veya erken bir yön oku, ölçmediğimiz bir şeyi
ölçmüş gibi gösterir.

- `PathLength.measurementDays` zaten 1. günü içeriyor ([1, 7, 14, 21]).
  **Baseline = gün 0 (onboarding) + gün 1 ortalaması** (PRD §8, ortalamaya dönüş).
- Gün 1 ölçümü **kısadır** — sekiz sorunun tamamı değil, duygu şiddeti ve
  davranış maddesi. Sekiz soruyu iki gün üst üste sormak onboarding'i uzatmanın
  başka bir yolu olurdu. *(Bu bir öneri; hangi maddelerin tekrarlanacağı ürün
  sahibi onayı bekliyor.)*
- Gün 7'den önce profil ve harita **hiçbir yön, ok, çubuk ya da sayı göstermez**;
  yalnızca "İlk karşılaştırma 7. günde" cümlesi.
- Gün 7'de ölçüm **oturumdan önce** yapılır ve sonuç oturumdan sonra gösterilir
  (PRD §7.3: paywall ölçüm ekranından sonra).

---

## 8. Yapılma sırası

| # | İş | Bağımlılık |
|---|---|---|
| 1 | `blocks` tablosu + `script` şeması + ~10 gerçek blok | — |
| 2 | `path_step_answers` tablosu, ölçüm yazma yetkileri | — |
| 3 | İstemci: blok indirme + cache, `SessionScript` derleyici | 1 |
| 4 | İstemci: yeni zaman çizelgesi (K1–K6), ses/metin senkronu | 3 |
| 5 | Zarf takipçisi + arka plana `voiceEnergy` | 4 |
| 6 | TTS sağlayıcı arayüzü, doğrudan çağrı, AB uç noktası | — |
| 7 | `generate-step` Edge Function (N ≥ 2 slotları + soru) | 1, 2 |
| 8 | G2'de soru ekranı + kriz taraması | 2, 7 |
| 9 | Gün 7 ölçümü + okuma + profil | 2 |

---

## 9. Açık sorular

1. **TTS sağlayıcısı.** Türkçe kör testi (üst doküman §5.4) hâlâ yapılmadı. COGS'u
   4–6× değiştiriyor ve ses kimliğini kilitliyor.
2. **Gün 1 ölçümünün kapsamı.** Sekiz maddenin hangileri tekrarlanacak?
3. **Blok kütüphanesinin klinik gözden geçirmesi.** Üst doküman §2.3: LLM taslak
   yazabilir, insan onayı olmadan kütüphaneye girmez. Bu süreç kurulmadı.
4. **Konuşma hızı kalibrasyonu.** Ses yokken metin süresi tahmini için
   `charactersPerSecond` gerçek render'lardan ölçülmeli.

---

## Karar günlüğü

| # | Karar | Gerekçe |
|---|---|---|
| S1 | Duraklamayı LLM değil blok kütüphanesi belirler | Duraklama tekniğin parçası; klinik gözden geçirmeden geçmeli |
| S2 | `silence` saniye değil **nefes döngüsü** sayar | Saniyeyle yazılan sessizlik döngü ortasında bitiyor, ses nefes verirken giriyordu |
| S3 | Konuşma nefes sınırına yuvarlanmaz | Bağlantılı cümleler arasında 30 sn bekleniyordu; "aşırı bekleme" şikâyetinin kaynağı |
| S4 | Oturum uzunluğunu blok seçimi tutturur, metin ölçekleme değil | Ölçekleme nefes sayımını uzatıp tekniği bozuyordu |
| S5 | JIT'in birimi adım değil **slotlar** | Adım sonu sorusu N+1'i N bitmeden finalize edilemez hâle getirdi |
| S6 | N+1 üretimi N **bittiğinde** başlar | Cevabı kullanabilmenin tek yolu; terk eden kullanıcıda tasarrufu da artırıyor |
| S7 | Adım sonu sorusu TTS'e gitmez | `step_title` ile aynı gerekçe: ekranda okunuyor, maliyeti sıfır |
| S8 | Soru atlanabilir | Kaçırılan gün hiçbir şeyi geri almaz; zorunlu soru o kuralı deler |
| S9 | TTS'e aracısız gidilir | Her halka ayrı bir veri işleyici; GDPR Madde 9 verisi için zinciri kısaltmak |
| S10 | `voiceEnergy` mevcut harekete **eklenir** | Taban hareket hiç durmamalı; ses ekolayzer değil, ortam |
| S11 | 7. günden önce iyileşme gösterilmez | Ölçmediğimiz şeyi ölçmüş gibi göstermemek |
