# Onboarding sahneleri — 22 Eylül 2026 (gradyansız yeniden tasarım)

Gradyan (`MeshGradient` + Metal shader + 10 kategori paleti) tamamen kaldırıldı
(`docs/onboarding-redesign.md`, Faz 1). Yerine her bölümün kendi tam ekran guaj
sahnesi geldi; A2'den B6'ya kadar sahne **seçilen kategoriye göre** değişir —
eskiden bu işi canlı palet yapıyordu.

Bu dosya görseller üretilmeden **önce** yazıldı. Kod görselsiz de eksiksiz çalışır:
her adımın bir sahnesi var (`OnboardingFlowViewModel.currentScene`), görsel yoksa
`OnboardingSceneLayer` düz `WoodlandStyle.background`'a düşer — hiçbir ekran kırılmaz
(`-patika-debug-no-art` ile denenir).

## Nereye konacak

`MyApp/Assets.xcassets/Onboarding/<ad>.imageset/artwork.jpg` — **opak JPEG**
(`onboarding-threshold` zaten bu kalıpla içeride; ~600 KB/görsel). Adlar birebir
aynı olmalı, kod bu adlarla arıyor (`OnboardingArtwork`).

| Image Set adı                                                 | Ekranlar                                             |
| ------------------------------------------------------------- | ---------------------------------------------------- |
| `onboarding-threshold`                                        | A1 (**hazır**)                                       |
| `bg-gathering`                                                | İsim, cinsiyet, yaş                                  |
| `bg-category-<key>` (10 tane, `ProblemCategory` ile bire bir) | A2 (seçimle canlı değişir), B1–B6                    |
| `bg-reflection`                                               | C1–C4, taahhüt                                       |
| `bg-measure`                                                  | D0–D8                                                |
| `bg-prepare`                                                  | E1, F1, F2                                           |
| `bg-session`                                                  | G1 **ve bütün Yolum oturumları** (`PathSessionView`) |
| `bg-settle`                                                   | G2, fiyat, H2, H1                                    |

Kriz ekranında hiçbir sahne yok — bilerek. Kategori sahnesi 7 ekran (A2→B6) sürer,
C'den itibaren anlatı sahnesine geçilir. İki kategori seçilirse **birincil** (ilk
seçilen) kategorinin sahnesi kullanılır; iki görsel karışmaz.

## Teknik şartlar

- **PORTRAIT 1024×2048, tam kaplayan, tamamen opak** (şeffaflık yok, beyaz zemin yok).
- **Üst %14 ve alt %46 sakin, düşük kontrastlı, neredeyse tek düze parlaklıkta**
  kalmalı — üst çubuk, krem kâğıt kart ve düğme oralara biniyor. Bütün detay ve
  tek sıcak ışık üst-orta bantta.
- Metin, rakam, işaret, UI, insan, yüz, el yok. Zirve, kupa, bayrak, bitiş çizgisi
  imgesi yok — ürün ilerlemeyi ölçer, ödül vermez.
- **Öfke için kırmızı yok** — bu bir ürün kararı (öfkeli kullanıcıya kırmızı
  göstermek durumu pekiştirir); `bg-category-anger` yeşil-teal bir akarsu.
- Görsel VoiceOver'dan gizli; anlamı hiçbir zaman yalnızca görsel taşımaz.
- Ölçüm ekranlarında (`bg-measure`) ve kriz modunda dekoratif hareket/görsel yok.
- Kod perde uyguluyor (`WoodlandStyle.background.opacity(dimming)`, B6'da ruh hâline
  göre 0,26–0,50 arası); orta tonları **son hâlinden biraz daha açık** tut.

## Ortak SCENE bloğu (her prompt'un başına aynen)

```
Use case: illustration-story. Production illustration background for the native iOS app Patika, PORTRAIT 1024x2048, full bleed and completely OPAQUE (no transparency, no white background, no transparent corners). Match the reference's hand-painted gouache and cut-paper textures, organic botanical silhouettes, muted sage, deep teal, dusty blue and tiny warm cream and apricot accents. Broad slow organic curves, sophisticated illustrated storybook atmosphere. Not 3D, no gloss, no vector clipart, no photorealism. There must be no letters, numbers, UI, icons, badges, circles, people, faces, hands, borders or watermark. No summit, no trophy, no flag, no finish line. CRITICAL LAYOUT: the top 14% and the bottom 46% of the canvas must be quiet, low-contrast terrain of almost uniform brightness, because a navigation bar, a cream paper card and a button are overlaid there; all detail and the single warm light live in the upper-middle band. A dark scrim will be applied over the whole image in code, so keep the midtones a little brighter than final.
```

Referans olarak `onboarding-threshold`, `journey-world-continuous` ve
`discover-world`i ver (mevcut guaj ailesiyle aynı dil).

---

## 6 bölüm sahnesi

### 1. `bg-gathering` — İsim, cinsiyet, yaş

```
[SCENE bloğu]
Early morning at the edge of a woodland clearing: low sage meadow in the foreground, a soft pale cream footpath entering from the lower right and curving into an open grove, thin mist between dark teal trees, first light low on the left. Nothing has begun yet; the clearing is simply open and quiet.
```

### 2. `bg-reflection` — C1–C4, taahhüt

```
[SCENE bloğu]
Midday stillness at a woodland pool: a wide calm oval of dusty blue water in the middle band, reflecting the sage and dark teal foliage above it without a ripple, pale stones along the near bank. A single warm apricot leaf floats at the edge. Feeling: seeing something clearly, without judgement.
```

### 3. `bg-measure` — D0–D8

```
[SCENE bloğu]
A very quiet, almost empty woodland floor seen from slightly above: even sage moss, a few pale flat stones set in a loose line, sparse dark teal leaves at the far edges, flat overcast light with no single bright point. No instruments, no markers, no numbers, no path. Extremely low visual noise; the calmest image in the set.
```

### 4. `bg-prepare` — E1, F1, F2

```
[SCENE bloğu]
Late afternoon: a pale cream footpath being revealed through sage grass, with flat stepping stones set at even intervals along it, curving from the lower left up into a dark teal grove. Warm low light rakes across the path from the right. Feeling: a route being laid out, step by step, nothing walked yet.
```

### 5. `bg-session` — G1 ve bütün Yolum oturumları

```
[SCENE bloğu]
Deep night in a sheltered woodland hollow: very dark teal and near-black foliage forming a soft enclosing bowl, a small pool of dusty blue starlight in the centre of the middle band, everything else soft and unlit. The centre of the canvas is the quietest and most even area of all, because a breathing circle sits exactly there. Feeling: being held, eyes closing.
```

### 6. `bg-settle` — G2, fiyat, H2, H1

```
[SCENE bloğu]
Dusk arriving: a low mossy stone bench in a sheltered nook of sage and dark teal leaves, a single warm apricot lantern glow low on the right, the cream footpath ending softly at the nook. Feeling: arriving somewhere and putting something down.
```

---

## 10 kategori sahnesi (A2 → B6)

### 7. `bg-category-sleep`

```
[SCENE bloğu]
Deep indigo night woodland: dark blue-violet foliage, a still pool holding a faint moon glow, very low contrast, everything slowing down.
```

### 8. `bg-category-anxiety`

```
[SCENE bloğu]
Teal woodland just after rain: layered sage and deep teal leaves, a thin clear stream running steadily through the middle band, air washed and settling.
```

### 9. `bg-category-burnout`

```
[SCENE bloğu]
Warm ochre late-summer woodland at low sun: dry sage grasses, amber and umber foliage, a shaded hollow with cool cream light where the ground is soft.
```

### 10. `bg-category-focus`

```
[SCENE bloğu]
Cool blue-teal woodland at clear midday: tall straight cypress silhouettes in ordered rows, crisp edges, a single narrow path running straight through the middle band.
```

### 11. `bg-category-anger`

```
[SCENE bloğu]
Green-teal woodland with moving water: a fast clear stream over dark smooth stones in the middle band, dense cool sage foliage. Cool and green, never red or orange.
```

### 12. `bg-category-selfcrit`

```
[SCENE bloğu]
Soft mauve-plum woodland at dusk: dusty purple and deep teal leaves, a sheltered hollow lined with pale moss, gentle diffuse light with no harsh edge.
```

### 13. `bg-category-social`

```
[SCENE bloğu]
Slate blue woodland clearing: several separate groves of dark teal trees around one open sage clearing in the middle band, comfortable distance between them.
```

### 14. `bg-category-exam`

```
[SCENE bloğu]
Steel blue woodland before dawn: cool blue-grey foliage, a clear level horizon line in the upper-middle band, one warm cream light low and steady.
```

### 15. `bg-category-grief`

```
[SCENE bloğu]
Muted rose-brown woodland in still air: dusty pink-brown and deep teal leaves, a quiet pool with fallen petals on the surface, soft heavy light.
```

### 16. `bg-category-unnamed`

```
[SCENE bloğu]
Neutral sage-grey woodland in soft fog: undefined shapes emerging from mist, no single focal point, quiet grey-green throughout.
```

---

## Doğrulama

1. Her sahneyi imageset'e koy, `-patika-debug-step` ile ilgili ekranı aç
   (`a1|name|gender|age|a2|b1|b3|c1|d1|e1|f1|f2|g1|g2|price|h2|h1`).
2. Hepsini `-patika-debug-no-art` ile de aç — her ekran düz `WoodlandStyle.background`
   ile çalışmalı, hiçbir şey kırılmamalı.
3. AX5, Reduce Motion, Reduce Transparency'de sahne düz zemine düşer (`OnboardingSceneLayer`).
4. A2'de iki kategori seçip sahnenin **canlı** değiştiğini doğrula (`previewCategories`).
5. B6'da beş kademeyi de dene: perde en açıktan (`calm`, 0,26) en koyuya (`veryHeavy`,
   0,50) değişmeli.
