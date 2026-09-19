# Oturum ekranı illüstrasyonları — 19 Eylül 2026

Oturum (meditasyon) ekranının ortasında, sahne metninin üstünde duran tek görsel.
Görsel adımın **fazından** seçilir (`SessionArtwork`), bütün oturum boyunca aynı
kalır ve arka planla aynı nefes ritminde %3 büyüyüp küçülür. Görsel eklenmemişse
ekran yalnızca metinle çalışır; hiçbir şey kırılmaz.

## Nereye konacak

Her görsel için Xcode'da `MyApp/Assets.xcassets/` altında **`Session`** adlı bir
klasör (namespace kapalı) ve içinde aşağıdaki adla bir Image Set oluştur, PNG'yi
"Universal" yuvasına sürükle. Adlar birebir aynı olmalı — kod bu adlarla arıyor.

| Image Set adı | Nerede görünür | Faz |
| --- | --- | --- |
| `session-trailhead` | G1 — onboarding'deki ilk oturum | — |
| `session-relief` | Yolum, Rahatlama fazındaki adımlar | relief |
| `session-practice` | Yolum, Farkındalık / Beceri / Davranış fazları | awareness, skill, behavior |
| `session-closing` | Yolum, Kapanış fazındaki adımlar | closing |

Kaynak dosyaları (üretilen ham PNG'ler) bu klasöre koyabilirsin:
`assets/illustrations/session/`.

## Teknik şartlar

- **1024×1024 PNG, gerçek alfa kanalı.** Görsel ekranda en fazla 280×220 pt
  kutuya `scaledToFit` ile oturur; kare tuval kenarlarda boşluk bırakır, bu istenen.
- Kompozisyon **yatay-oval bir kesit**: yüksekliğin ~%60'ı dolu, üst ve alt
  kenarlarda bol şeffaf boşluk. Görsel nefesle ölçeklendiği için hiçbir öğe
  kenara değmemeli (≥ %8 şeffaf pay).
- Zemin koyu ve kategoriye göre renk değiştiren bir gradyan (lacivert, teal,
  mor tonları). Silüet kenarları koyu zeminde okunmalı — sıcak krem/kayısı ışık
  şekilleri bunu sağlıyor.
- Metin, insan, yüz, sıkıntı içindeki figür, sayı, işaret, çerçeve, gölge,
  dama tahtası zemin **yok**.
- Görsel VoiceOver'dan gizli; anlamı hiçbir zaman yalnızca görsel taşımaz.

## Ortak stil bloğu

Her prompt'un başına bunu koy (mevcut guaj ailesiyle birebir aynı dil —
`assets/illustrations/gouache/prompts.json`):

```
Use case: illustration-story. Create ONE production-ready transparent PNG spot illustration for the native iOS app Patika. Reference images are STYLE REFERENCES ONLY, not edit targets. Match their handmade gouache, softly irregular cut-paper edges, rich dry-brush pigment texture, flat editorial storybook depth; absolutely not 3D, glossy, clay, glass, photorealistic or vector clipart. Palette: dark teal, muted sage, dusty cobalt blue, warm cream and a little apricot/ochre. The illustration will sit on a very dark, slowly shifting navy/teal gradient UI, so include warm light shapes and distinguishable silhouette edges. TRUE transparent alpha background around the entire irregular cutout including all corners and negative spaces; no solid or checkerboard background, no paper rectangle, no cast shadow, no frame, no text, no watermark. Square 1024x1024 canvas, subject is a compact horizontal oval vignette occupying the central ~60% of the height, generous 8-10% transparent padding on every side. All objects fully within frame; no clipped edges. No people, no faces, no animals looking at the viewer. Very calm, quiet, meditative; low visual noise so it can sit above a single line of text.
```

Referans görsel olarak `illustration-trail`, `illustration-rest` ve
`illustration-shelter` PNG'lerini ver (Assets.xcassets/Illustrations).

## 1. `session-trailhead` — ilk oturum, yolun başı

```
[ortak stil bloğu]
The very beginning of a path: a soft cream footpath starts at the lower center of the vignette and curves gently away into an open arch of sage and deep teal foliage. Two or three flat stepping stones at the start of the path. A single small warm apricot lantern glow hangs low in the arch, like the first light of a walk. Low rounded shrubs frame both sides. The path does not reach a destination; it simply opens. Feeling: an invitation, nothing required yet.
```

## 2. `session-relief` — Rahatlama fazı

```
[ortak stil bloğu]
A still, shallow pond at dusk seen from slightly above. Perfectly calm muted blue water with a single pale cream moon reflection as a soft oval, two or three thin reeds and rounded sage leaves along the near edge, a smooth cream stone resting half in the water. Almost no motion: only one faint ring ripple around the stone. Feeling: the body settling, the first exhale after a long day.
```

## 3. `session-practice` — Farkındalık, Beceri, Davranış

```
[ortak stil bloğu]
A small sprouting seedling with two cream-veined sage leaves grows from a curled, cupped dark teal leaf that holds a little rich soil. Around it, a loose ring of tiny flat pebbles in cream and dusty blue suggests an unhurried daily practice, like steps laid one at a time. A few soft sage sprigs on either side. One gentle apricot light touch on the leaf tips. Feeling: steady, patient growth; attention returning again and again.
```

## 4. `session-closing` — Kapanış fazı

```
[ortak stil bloğu]
A small cream cottage doorway, slightly open, with warm apricot light spilling onto a single flat stone step. Sage sprigs and a rounded dark teal shrub beside the door, a low curving leaf canopy above, and one small pale cream crescent in the transparent sky space above the roof. No path leading away; the scene rests. Feeling: arriving, rest earned quietly, no celebration.
```

## Kabul kontrolü

1. Koyu lacivert ve koyu teal bir zemin üstünde önizle: silüet kenarları seçiliyor mu?
2. Kenarlarda en az %8 şeffaf pay var mı? (Nefesle %3 büyüyünce kırpılmamalı.)
3. Dört görsel yan yana aynı aileden mi görünüyor — `illustration-trail` ile aynı fırça dokusu ve palet?
4. Bir yüz, figür, sayı ya da harf yok mu?
5. Simülatörde kontrol: `xcrun simctl launch booted devplaceholder.X9RQKIJ8.MyApp -patika-debug-step g1` (temiz kurulumda) `session-trailhead`'i gösterir; Yolum'da örnek patikadan bir adım başlatınca faz görselleri görünür.
