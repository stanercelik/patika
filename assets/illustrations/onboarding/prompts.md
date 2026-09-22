# Onboarding illüstrasyonları — 21 Eylül 2026 (kâğıt kart içi kesitler)

Onboarding yeniden tasarımının kâğıt kart içi **şeffaf** kesitleri. Tam ekran opak
sahneler (A1 dahil — artık A1'e özgü değil, **her** onboarding ekranının bir sahnesi
var) buradan çıkarıldı: `assets/illustrations/scenes/prompts.md`'ye bak
(22 Eylül 2026, gradyan kaldırma kararı).

Bu dosya görseller üretilmeden **önce** yazıldı ve kod görselsiz de eksiksiz çalışır:
varlık yoksa görsel yer kaplamaz (`PatikaArt.exists`, `-patika-debug-no-art` ile denenir).

## Bir kural: renkli guaj nerede durabilir

Renkli, opak bir guaj parçası tam ekran sahnenin üstünde yüzerse sahneyle çakışır ya
da onu ezer. Bu yüzden kâğıt kart içi kesitler **yalnızca kâğıt kartın üstünde**
dururlar (aşağıdaki PAPER bloğu) — tam ekran sahne zemininin kendisi ayrı bir aile
(`scenes/prompts.md`, SCENE bloğu).

## Nereye konacak

`MyApp/Assets.xcassets/Onboarding/<ad>.imageset/`. Hepsi **şeffaf PNG**. Adlar birebir
aynı olmalı, kod bu adlarla arıyor (`OnboardingArtwork`). Boş yuvalar (`Contents.json`)
hazır; dosyayı yuvanın içine `<ad>.png` olarak koy.

| Image Set adı                | Ekran           | Boyut                 | Ekranda                |
| ----------------------------- | --------------- | --------------------- | ---------------------- |
| `onboarding-identity`         | İsim (ilk kimlik ekranı) | 1024×1024    | Kartın üstünde ~96 pt  |
| `onboarding-b-weather`        | B3 zamanlama    | 1024×1024              | Kartın üstünde ~120 pt |
| `onboarding-c3-fork`          | C3              | 1024×1024              | Kart içinde ~180 pt    |
| `onboarding-c4-horizon`       | C4              | 1024×1024              | Kart içinde ~150 pt    |
| `onboarding-commit`           | Taahhüt         | 1024×1024              | Kart içinde ~160 pt    |
| `onboarding-d0-still`         | D0 ölçüm girişi | 1024×1024              | Kart içinde ~160 pt    |
| `illustration-f2-path-ready`  | F2 yol haritası | 1024×1024              | Sahne üstünde ~208 pt  |
| `onboarding-h2-lantern`       | H2 bildirim     | 1024×1024              | Kart içinde ~150 pt    |
| `onboarding-h1-shelter`       | H1 hesap        | 1024×1024              | Kart içinde ~150 pt    |

`illustration-shelter` **boş değil**: `JourneyPhaseDecoration` onu kullanıyor. H1 bu yüzden
kendi parçasını alıyor. Kimlik artık üç ayrı ekran (isim, cinsiyet, yaş, 2026-09-22); bu
görsel yalnızca **isim** ekranında kullanılıyor, cinsiyet ve yaş görselsiz.

Aynen kalanlar: `illustration-reflection` (C1), `illustration-belonging` (C2),
`illustration-rest` (G2). Referans görsel olarak bunları ve `illustration-trail`i ver.

## Teknik şartlar

- **Şeffaf parçalar:** gerçek alfa kanalı, kare tuval, konu ortada yatay-oval bir kesit
  (yüksekliğin ~%60'ı), her kenarda ≥ %8 şeffaf boşluk. Hiçbir öğe kenara değmemeli.
- **Kâğıt üstünde okunurluk:** krem zeminde kenarlar **koyu teal ve koyu adaçayı silüetle**
  okunur; açık krem/kayısı ışık şekilleri yalnızca vurgudur, tek başına kenar taşımaz
  (koyu zeminde tersi geçerliydi, `session/prompts.md`).
- **Yasaklar (hepsi):** metin, rakam, işaret, UI, insan, yüz, el, sıkıntı içindeki figür, zirve,
  kupa, bayrak, çerçeve, gölge, dama tahtası zemin, filigran. Kazanan/kaybeden ya da "hedefe
  varış" imgesi yok: ürün ilerlemeyi ölçer, ödül vermez.
- Görsel VoiceOver'dan gizli; anlamı hiçbir zaman yalnızca görsel taşımaz.
- **Ölçüm ve kriz:** ölçüm ekranlarında (D1–D8) ve kriz modunda dekoratif görsel yok.

## Ortak stil blokları

Mevcut guaj ailesi (`assets/illustrations/gouache/prompts.json`) ile aynı dil. Her prompt'un
başına ilgili bloğu, sonuna **yalnızca konu cümlesini** koy; blok metnini değiştirme.

### PAPER bloğu — kâğıt üstünde şeffaf kesit

```
Use case: illustration-story. Create ONE production-ready transparent PNG spot illustration for the native iOS app Patika. Reference images are STYLE REFERENCES ONLY, not edit targets. Match their handmade gouache, softly irregular cut-paper edges, rich dry-brush pigment texture, flat editorial storybook depth; absolutely not 3D, glossy, clay, glass, photorealistic or vector clipart. Palette: dark teal, muted sage, dusty cobalt blue, warm cream and a little apricot/ochre. The illustration will sit on a warm cream paper card (#EDE7D9), so its silhouette edges must be carried by DARK teal and dark sage shapes that read clearly against cream; warm cream and apricot are accents only, never the outline. TRUE transparent alpha background around the entire irregular cutout including all corners and negative spaces; no solid or checkerboard background, no paper rectangle, no cast shadow, no frame, no text, no watermark. Square 1024x1024 canvas, subject is a compact horizontal oval vignette occupying the central ~60% of the height, generous 8-10% transparent padding on every side. All objects fully within frame; no clipped edges. No people, no faces, no hands, no animals looking at the viewer, no summit, no trophy, no flag, no finish line. Very calm, quiet, meditative; low visual noise so it can sit beside a paragraph of text.
```

---

> Tam ekran sahneler (`onboarding-threshold` dahil) ve onların SCENE bloğu artık
> `assets/illustrations/scenes/prompts.md`'de.

## 1. `onboarding-identity` — kimlik kartı (PAPER bloğu)

```
[PAPER bloğu]
A small rounded leaf cluster of dark teal and sage leaves, slightly open at the center like a cupped hollow, with one quiet apricot bud resting in the hollow. A single cream curved stem enters from the lower edge. A visual metaphor for a name being written down for the first time: something small and personal being made room for. Compact horizontal composition.
```

## 2. `onboarding-b-weather` — B3 zamanlama, gün içindeki an (PAPER bloğu)

```
[PAPER bloğu]
A time-of-day motif as a single calm arc: a low sweep of dark sage hills at the bottom, above them a wide shallow arc made of four soft round shapes that move from a pale cream sunrise disc on the left, through a warm apricot afternoon disc, to a dusty cobalt blue evening disc and a small deep teal night disc on the right. The discs are flat gouache shapes with dry-brush edges, evenly spaced along the arc, none of them larger or brighter than the others. No sun rays, no stars, no clock, no numbers. A visual metaphor for the hours of a day, none of them better than another. Compact horizontal composition.
```

## 3. `onboarding-c3-fork` — C3, iki rota (PAPER bloğu)

```
[PAPER bloğu]
Two routes that leave the same point: at the left a single cream footpath splits into two gently curving paths of the same width and the same brightness, one bordered by a dense row of dark teal cut-paper shapes and stacked stones, the other bordered by soft sage leaves in an even rhythm. Neither path is marked as better: no arrow, no sign, no destination, no light at the end of either. Both paths simply continue toward the right edge of the vignette and fade out into the transparent background before reaching it. Compact horizontal composition.
```

## 4. `onboarding-c4-horizon` — C4, mesafe, zirve değil (PAPER bloğu)

```
[PAPER bloğu]
Distance, not a summit: a long, low, quiet horizon of layered sage and dark teal hills, each ridge slightly paler than the one in front, with a thin pale cream footpath winding toward the far ridge and out of sight. A dusty blue river glints in the middle distance. The highest point of the composition is barely higher than the rest; there is no peak, no flag, no sun on a summit, no marker at the end of the path. A visual metaphor for a long, steady walk where change appears slowly. Wide, shallow horizontal composition.
```

## 5. `onboarding-commit` — taahhüt anı (PAPER bloğu)

```
[PAPER bloğu]
A single stone set down on a path: a smooth rounded dark teal stone resting at the beginning of a short cream footpath that curves off to the right, with two smaller pale stones already placed behind it like earlier steps. Around the stones, low sage moss and three small apricot blossoms. No footprints, no hands, no person, no flag. A visual metaphor for choosing to begin, quietly, in your own words. Compact horizontal composition.
```

## 6. `onboarding-d0-still` — D0, ölçüm girişi (PAPER bloğu)

```
[PAPER bloğu]
A still pool seen from slightly above: a calm oval of muted dusty blue water with no ripples, held in a ring of dark teal and sage leaves, with a single pale cream reflection line across the water and nothing else. No measuring instruments, no ruler, no scale, no gauge, no numbers, no bars. A visual metaphor for taking an honest look at how things are right now. Compact horizontal composition, extremely low visual noise.
```

## 7. `illustration-f2-path-ready` — F2, yol hazır (PAPER bloğu, karartılmış sahne üstünde)

Bu parça karartılmış sahne zemininde duracağı için silüeti **açık krem ve sıcak kayısı ışık
şekilleriyle** de taşıyabilir; PAPER bloğundaki "koyu silüet" cümlesini şu cümleyle değiştir:
_"The illustration will sit on a dimmed dark forest-green gouache ground, so include warm cream and apricot light shapes that separate the silhouette from a dark background."_

```
[PAPER bloğu, yukarıdaki cümle değişikliğiyle]
A path that has been laid out and is waiting: a pale cream footpath in seven gentle bends running from the lower left to the upper right of the vignette, with seven small flat stones set at even intervals along it, the first one slightly warmer and brighter than the rest. Framing foliage of sage and dark teal on both sides. No destination, no end marker, no gate. A visual metaphor for a route that is ready and can be walked one step at a time. Wide, shallow horizontal composition.
```

## 8. `onboarding-h2-lantern` — H2 bildirim izni (PAPER bloğu)

```
[PAPER bloğu]
A small lantern set on a mossy stone at the side of a path, lit by a quiet apricot glow that stays inside the lantern and only faintly warms the leaves around it. Dark teal foliage frames it. No bell, no envelope, no notification symbol, no clock, no moon. A visual metaphor for a soft light left on for you, one that never calls out. Compact horizontal composition.
```

## 9. `onboarding-h1-shelter` — H1 hesap (PAPER bloğu)

```
[PAPER bloğu]
A small sheltered nook: an arch of dark teal and sage leaves curving over a low mossy stone bench with a folded cream cloth resting on it, and a single lantern-warm apricot leaf tucked at the side. No door, no lock, no key, no padlock, no shield. A visual metaphor for a place set aside so your progress is kept, without anything being closed or guarded. Compact horizontal composition.
```

---

## Doğrulama

1. Her görseli imageset'e koy, sonra `-patika-debug-step a1|identity|b3|c3|c4|commit|d0|f2|h2|h1` ile aç.
2. Bütün ekranları `-patika-debug-no-art` ile de aç: hiçbiri kırılmamalı, boşluk bırakmamalı.
3. AX5 Dynamic Type'ta görseller saklanır; kâğıt kartın boyu metne göre uzar.
4. Krizde (`-patika-debug-step crisis`) hiçbir dekoratif görsel yok.
