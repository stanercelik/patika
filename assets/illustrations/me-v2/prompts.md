# Ben v2 illüstrasyonları — 19 Eylül 2026

"Ben" sekmesi v2'nin görsel teslimatları: illüstrasyonlu defter kapağı, defter
sayfasının krem kâğıt dokusu, "Ne değişti" guaj ikonu, 14 kilometre taşı rozeti ve
opsiyonel arka plan şeridi. Kararların tamamı: `docs/profile-v2-plan.md` ("Görsel
teslimatları") ve `docs/profile-design.md` §21.

Bu dosya görseller üretilmeden **önce** yazıldı; kod aşamaları görseller olmadan da
ilerler ve ekranlar kırılmaz: varlık yoksa defter kartı adaçayı düz kart olarak
çizilir, rozet yuvası yer kaplamaz.

## Nereye konacak

Her varlık Xcode'da `MyApp/Assets.xcassets/Me/` altında aynı adla bir Image Set
içine konur. Adlar birebir aynı olmalı — kod bu adlarla arar. Kaynak PNG'ler
`assets/illustrations/me-v2/` altında tutulur.

| Image Set adı | Boyut / tür | Nerede görünür |
| --- | --- | --- |
| `me-journal-cover` | 1536×1024, opak | `JournalCoverCard` — defter kartının tamamını kaplayan kapak |
| `me-journal-paper` | 1024×1024, döşenebilir | `JournalView` — defter sayfasının krem kâğıt dokusu |
| `me-change` | 512×512, alfa | `CompactChangeCard` — "Ne değişti" kartında küçük guaj ikon |
| `badge-first-step`, `badge-phase-relief`, `badge-phase-awareness`, `badge-phase-skill`, `badge-phase-behavior`, `badge-phase-closing`, `badge-path-complete` | 512×512, alfa | Yol rozetleri (7) |
| `badge-measure-day7`, `badge-measure-day14` | 512×512, alfa | Ölçüm rozetleri (2) — katılımdan verilir, sonuçtan değil |
| `badge-week-3`, `badge-week-5`, `badge-week-7` | 512×512, alfa | Seri rozetleri (3) |
| `badge-note-first`, `badge-note-10` | 512×512, alfa | Defter rozetleri (2) |
| `me-backdrop` (opsiyonel) | 1536×768, opak | `MeBackdrop` üst şeridi; yalnızca `journey-world-continuous` üst kesiti yeterli olmazsa üretilir |

## Teknik şartlar

- **Opak varlıklar** (`me-journal-cover`, `me-journal-paper`, `me-backdrop`): tuval
  kenardan kenara dolu; çerçeve, beyaz köşe, vinyet bandı yok. `me-journal-paper`
  **dikişsiz döşenebilir** (tileable) ve çok düşük kontrastlı — üstüne koyu mürekkep
  metin WCAG AA (4.5:1) ile okunacak.
- **Alfa varlıklar** (`me-change`, `badge-*`): gerçek şeffaf zemin; dama tahtası,
  kâğıt dikdörtgeni, düşen gölge yok. Kenarlarda ~%8 şeffaf pay.
- Rozetler yuvarlak madalyon. **Kilitli rozet için ayrı görsel üretilmez**: aynı
  görsel kodda gri tona çevrilip %30 opaklıkla çizilir.
- **Sayı ve harf yok.** 7/14 ölçüm farkı noktalı halkayla, 3/5/7 seri farkı taş
  sayısıyla anlatılır.
- Rozetler ekranda 64 pt'e kadar küçülür; silüet o boyutta tek şekil olarak
  okunmalı.
- İnsan, yüz, el, metin, çerçeve, yıldız, kupa, konfeti, parıltı yok.

## Ortak stil blokları

Mevcut guaj ailesiyle (`assets/illustrations/gouache/prompts.json`) birebir aynı
dil. Referans görseller: `Assets.xcassets/Illustrations` içindeki
`illustration-trail`, `illustration-rest`, `illustration-shelter`.

### A — alfa spot (`me-change` ve 14 rozet)

```
Use case: illustration-story. Create ONE production-ready transparent PNG spot illustration for the native iOS app Patika. Reference images are STYLE REFERENCES ONLY, not edit targets. Match their handmade gouache, softly irregular cut-paper edges, rich dry-brush pigment texture, flat editorial storybook depth; absolutely not 3D, glossy, clay, glass, photorealistic or vector clipart. Palette: dark teal, muted sage, dusty cobalt blue, warm cream and a little apricot/ochre. The illustration will sit on a dark sage card, so include warm light shapes and distinguishable silhouette edges. TRUE transparent alpha background around the entire irregular cutout including all corners and negative spaces; no solid or checkerboard background, no paper rectangle, no cast shadow, no frame, no text, no watermark. Square 512x512 canvas with generous 8% transparent padding. All objects fully within frame; no clipped edges. No people, no faces, no hands, no text, no letters, no numbers. Very calm, quiet, low visual noise.
```

### B — opak sahne (`me-journal-cover`, `me-journal-paper`, `me-backdrop`)

```
Use case: illustration-story. Create ONE production-ready opaque PNG illustration for the native iOS app Patika. Reference images are STYLE REFERENCES ONLY, not edit targets. Match their handmade gouache, rich dry-brush pigment texture, flat editorial storybook depth; absolutely not 3D, glossy, clay, glass, photorealistic or vector clipart. Palette: dark teal, muted sage, dusty cobalt blue, warm cream and a little apricot/ochre. The image fills the canvas completely edge to edge; no frame, no border, no vignette, no text, no letters, no watermark, no people, no faces. Very calm, quiet, matte, soft even light.
```

## 1. `me-journal-cover` — kapalı guaj defter (1536×1024, opak)

Kartın tamamını kaplayan kapalı defter; kartın sağ yarısına metin gelecek.

```
[B — opak sahne] A single closed journal lying flat, viewed straight from above, filling the whole frame: a dark teal cloth-bound notebook cover with softly brushed gouache texture, a warm cream spine band running along the left edge, a dusty apricot ribbon bookmark slipping out from under the bottom edge and lying flat across it, and a few muted sage leaves tucked neatly at the lower left corner. The right half of the cover stays calm and almost empty, only quiet cloth texture, because app text will be placed there. Nothing stacked on the book; no writing, no emblem, no monogram, no sticker, no pen on top. Landscape 1536x1024.
```

Kontrol: sağ yarı metin alanı olarak sade mi? Kapağın koyu teal + krem + kayısı
paleti kartın koyu adaçayı zemininden ayrışıyor mu?

## 2. `me-journal-paper` — krem kâğıt dokusu (1024×1024, döşenebilir)

Defter sayfasının zemini; içerik sütununda kâğıt yaprağı gibi döşenir.

```
[B — opak sahne] A seamless tileable warm cream paper texture painted in gouache: gently broken, slightly fibrous handmade paper with tiny soft speckles of pigment, very low contrast, no pattern, no lines, no objects, no vignette, no visible edges, perfectly even illumination so the tile repeats in any direction without a seam. Cream tones only, from warm off-white (#F2EFE9) to slightly darker warm grey; quiet enough that small dark-ink text reads easily on top. Square 1024x1024.
```

Kontrol: 2×2 döşemede dikiş görünmüyor mu? Üstüne koyu metin koyunca AA kontrastı
korunuyor mu?

## 3. `me-change` — pusula/filiz (512×512, alfa)

Ölçümün **sonuç değil yön** olduğunu anlatan sade sembol.

```
[A — alfa spot] A single small symbolic object, centered with generous transparent space: a round gouache compass with a warm cream face and a dark teal painted rim; its single needle is a softly sprouting muted sage stem ending in two small cream-veined leaves instead of an arrow point. Flat frontal view. The object reads as one calm shape at 64 pixels: a compass whose needle grows — direction, not a score, no destination marker, no map, no radiating light.
```

## 4. Rozetler (14 × 512×512, alfa)

Ortak madalyon kalıbı — her rozet aynı kalıptan, yalnızca merkez sembolü değişir:

```
[A — alfa spot] A single round badge medallion, centered with generous transparent space: a warm cream disk with a soft gouache dry-brush edge, a painted dark teal rim ring, and at its center [SEMBOL]. The medallion fills about 70% of the canvas, perfectly circular, flat frontal view, reads as one shape at 64 pixels. No ribbon, no star, no laurel wreath, no metal shine, no text, no letters, no numbers.
```

### Yol rozetleri (7)

| Image Set | Sembol | Anlam |
| --- | --- | --- |
| `badge-first-step` | filiz | İlk adım |
| `badge-phase-relief` | göl | Rahatlama fazı |
| `badge-phase-awareness` | yaprak | Farkındalık fazı |
| `badge-phase-skill` | köprü | Beceri fazı |
| `badge-phase-behavior` | patika | Davranış fazı |
| `badge-phase-closing` | fener | Kapanış fazı |
| `badge-path-complete` | ev | Yol tamamlandı |

Sembol eşlemesi oturum görsellerinin kurulu diliyle uyumlu: Rahatlama = durgun göl
(`session-relief`), varış = ışıklı kapı/eve dönüş (`session-closing`).

Madalyon kalıbındaki `[SEMBOL]` yerine:

- `badge-first-step`: `a tiny sprouting seedling with two cream-veined sage leaves rising from a small rounded mound of soil`
- `badge-phase-relief`: `a small still oval pond of calm muted blue water with one faint cream ripple`
- `badge-phase-awareness`: `a single broad sage leaf with soft cream veins, resting still`
- `badge-phase-skill`: `a small arched cream stone bridge crossing a narrow band of muted blue water`
- `badge-phase-behavior`: `a soft winding cream footpath curving through two low sage hills`
- `badge-phase-closing`: `a small round apricot lantern with a softly glowing warm center`
- `badge-path-complete`: `a tiny cream cottage with a small warmly lit apricot doorway and one sage sprig beside it`

### Ölçüm rozetleri (2)

Katılımdan verilir, sonuçtan değil. 7/14 farkı **noktalı halkayla** anlatılır:

- `badge-measure-day7`: `a gouache compass with a warm cream face and a dark teal rim, a single dotted muted sage ring circling it`
- `badge-measure-day14`: `the same compass with two concentric dotted muted sage rings`

### Seri rozetleri (3)

Bir takvim haftasında tamamlanan adım günü; fark **taş sayısıyla** anlatılır:

- `badge-week-3`: `a row of three smooth flat pebbles in cream and dusty blue, side by side on a small dark sage ground`
- `badge-week-5`: `a row of five smooth flat pebbles in cream and dusty blue, side by side on a small dark sage ground`
- `badge-week-7`: `a row of seven smooth flat pebbles in cream and dusty blue, side by side on a small dark sage ground`

### Defter rozetleri (2)

- `badge-note-first`: `a single freshly sharpened ochre pencil tip lying at a gentle diagonal angle`
- `badge-note-10`: `a small closed muted blue journal with a dusty apricot ribbon bookmark`

## 5. `me-backdrop` (opsiyonel, 1536×768, opak)

Yalnızca mevcut `journey-world-continuous` görselinin üst kesiti yeterli olmazsa
üretilir; üretilmezse `MeBackdrop` o görseli kullanır ve yeni varlık gerekmez.

```
[B — opak sahne] A wide quiet landscape strip seen from slightly above: low rolling muted sage meadow grass with soft gouache dry-brush texture, a few small dark teal shrubs and smooth cream stones scattered near the top edge. The lower 40% of the image gradually fades into a single flat muted sage color with no texture, calm and almost empty, so UI cards can sit on it. No sky, no horizon line, no sun, no moon, no path, no flowers, no people. Landscape 1536x768.
```

## Kabul kontrolü

1. Opak görseller kenardan kenara dolu mu (beyaz köşe, çerçeve yok)?
2. `me-journal-paper` 2×2 döşemede dikişsiz mi? Üstüne koyu mürekkep metin AA
   sınırında okunuyor mu?
3. 14 rozet yan yana aynı aileden mi; 64 pt'te tek silüet olarak okunuyor mu?
4. Rozetlerde sayı ya da harf var mı? (Olmamalı — 7/14 noktalı halkayla, 3/5/7 taş
   sayısıyla anlatıldı.)
5. Defter kapağının sağ yarısı metin alanı olarak sade mi?
6. Kilitli rozet için ayrı görsel üretilmedi; gri ton %30 opaklık kodda denenir.
7. Simülatör: `MeDebugSeed` v2 durumlarıyla kontrol (`-patika-debug-me v2full`,
   aşama 8'de eklenir).
