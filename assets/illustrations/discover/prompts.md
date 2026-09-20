# Keşfet v2 illüstrasyonları — 20 Eylül 2026

Keşfet v2'nin yeni görsel teslimatları: ekranın arkasında kayan manzara ve yeni
yedi hazır patikanın kart görselleri. Kararların tamamı: `docs/discover-v2-plan.md`
ve `docs/discover-design.md` (Keşfet v2).

Bu dosya görseller üretilmeden **önce** yazıldı; kod görseller olmadan da çalışır:
varlık yoksa manzara çizilmez, kart görseli yer kaplamaz ve kâğıt kart yalnızca
metinle durur (`PatikaArt.exists`).

## Nereye konacak

Her varlık Xcode'da `MyApp/Assets.xcassets/Discover/` altında aynı adla bir Image
Set içine konur (`discover-<ad>.imageset/artwork.jpg` + `Contents.json`). Adlar birebir
aynı olmalı — kod bu adlarla arar. Düz `.png` dosyası katalog tarafından görülmez;
görsel imageset içinde değilse `PatikaArt.exists` false döner ve hiçbir şey çizilmez.
Üretilen tam boyutlu PNG'ler git geçmişinde (`5bbbf5c`) durur; uygulamada JPEG olarak
gönderilir.

| Image Set adı | Boyut / tür | Nerede görünür |
| --- | --- | --- |
| `discover-world` | 1024×3072, opak, dikey döşenebilir | Keşfet ekranının arkasındaki kayan manzara |
| `discover-beat` | 1536×1024, opak | Öfke patikası — kart + detay hero |
| `discover-pressure` | 1536×1024, opak | Sınav/performans patikası |
| `discover-refill` | 1536×1024, opak | Tükenmişlik patikası |
| `discover-rooms` | 1536×1024, opak | Sosyal ortamlar patikası |
| `discover-kinder` | 1536×1024, opak | Kendine sert davranma patikası |
| `discover-carry` | 1536×1024, opak | Kayıp patikası |
| `discover-unnamed` | 1536×1024, opak | Adı konmamış patikası |

Mevcut `discover-evening`, `discover-breath`, `discover-focus`, `discover-personal`
değişmez.

## Teknik şartlar

- Hepsi **opak**, kenardan kenara dolu; çerçeve, beyaz köşe, vinyet bandı yok.
- Kart görselleri kartta üstten kırpılır ve hero olarak alta doğru solar: ilgi
  merkezi karenin **alt yarısında değil ortasında** durmalı.
- `discover-world` **dikey döşenebilir**: `PathLandscapeScene` tekniğiyle %12
  örtüşerek tekrar eder, bu yüzden üst ve alt %12 birebir eşleşmeli.
- İnsan, yüz, el, metin, harf, sayı, çerçeve yok. Zirve, merdiven, bayrak, yükselen
  başarı eğrisi, oyun dünyası, kupa, kutlama yok.
- **Boyut bütçesi:** her görsel ≤600 KB, toplam ≤8 MB. Opak guaj dokusu PNG'ye
  sığmıyor: palet indirgemesi (256 renk) tek görselde bile ~960 KB tuttu ve dokuyu
  bozar. Bunun yerine JPEG, kalite 85-92, kroma altörneklemesiz (4:4:4). Derlenmiş
  pakette on iki görsel toplam ~6,4 MB (`assetutil --info`), Xcode JPEG'i olduğu gibi
  saklıyor.
- Ekran boyunca yazı görselin üstüne binmez; görsel yalnızca yer duygusu taşır.

## Ortak stil bloğu — opak sahne

Mevcut guaj ailesiyle (`assets/illustrations/gouache/prompts.json`) birebir aynı
dil. Referans görseller: `Assets.xcassets/Illustrations` içindeki
`illustration-trail`, `illustration-rest`, `illustration-shelter`.

```
Use case: illustration-story. Create ONE production-ready opaque PNG illustration for the native iOS app Patika. Reference images are STYLE REFERENCES ONLY, not edit targets. Match their handmade gouache, rich dry-brush pigment texture, flat editorial storybook depth; absolutely not 3D, glossy, clay, glass, photorealistic or vector clipart. Palette: dark teal, muted sage, dusty cobalt blue, warm cream and a little apricot/ochre. The image fills the canvas completely edge to edge; no frame, no border, no vignette, no text, no letters, no watermark, no people, no faces, no hands. Very calm, quiet, matte, soft even light. No summit, no staircase, no flag, no rising achievement curve, no game world, no trophy, no celebration. Landscape 1536x1024.
```

## 1. `discover-world` — Keşfet manzarası (1024×3072)

Yolum'un tek patikasına karşılık Keşfet'in **çok yönlü açıklığı**: birkaç patikanın
birbirinden ayrıldığı bir çayır.

```
Create a vertically tileable very tall 1024x3072 gouache landscape background for a scrolling wellness discovery screen. Use reference only for hand painted gouache style and sage/teal palette. Elevated top-down open meadow landscape where three or four soft cream footpaths gently diverge and wander apart, never converging to a single destination. A small still pond in the upper third right, a low sage grove at left middle, a shallow stream curving across the lower third. Wide calm sage clearing down the central 65 percent for overlay interface. CRITICAL top and bottom edges must match seamlessly: both have identical medium sage meadow ground and sparse low shrubs only at extreme lateral edges. No dark vignette, no dark border, no foreground leaves, no horizon, no objects across upper/lower edges, no dark horizontal bands. Keep last and first 12 percent almost uniform sage meadow textured brushwork, same brightness and color, allowing vertical repeat. Trees clustered only at lateral edges in middle 75 percent. Continuous soft natural terrain with consistent brightness, no panel separations. No single dominant path, no text, no UI, no people. Full bleed opaque image. Long aspect ratio 1:3.
```

Kontrol: üst üste iki kez döşendiğinde dikiş görünüyor mu? Orta %65 kartların
altında sakin kalıyor mu? Tek bir baskın yol yok, yollar birbirinden uzaklaşıyor mu?

## 2–8. Patika kartı görselleri

Hepsi `[ortak stil bloğu]` + aşağıdaki sahne cümlesi (bloğun sonuna eklenir).

### `discover-beat` — Tepkiden önce bir an (öfke)
```
[ortak stil bloğu] A single smooth cream stone resting in a shallow teal stream, the water parting calmly around it and rejoining just past it; low sage grasses on both banks; the moment before the current closes again.
```
Feeling: bir an duraklamak.

### `discover-pressure` — Baskı günlerinde (sınav/performans)
```
[ortak stil bloğu] A wide open sage field under a broad quiet sky, with one clear unhurried cream path running straight across it from edge to edge; a few low shrubs at the far lateral edges; nothing blocking the way, nothing rushing.
```
Feeling: baskı varken alanın olması.

### `discover-refill` — Yavaşça toparlan (tükenmişlik)
```
[ortak stil bloğu] A slow narrow stream feeding a small still pool in a sheltered sage hollow at first light; warm cream light gathering on the water surface; the pool is only partly full and filling without hurry.
```
Feeling: yavaşça dolmak.

### `discover-rooms` — İnsanların arasında (sosyal)
```
[ortak stil bloğu] A loose grove of slender dark teal trees with generous warm cream gaps of light between them, and an unhurried cream path passing through the gaps rather than around the grove; open on both sides.
```
Feeling: aralarında geçebilmek.

### `discover-kinder` — Kendine daha yumuşak (kendine sertlik)
```
[ortak stil bloğu] A low sheltering canopy of muted sage leaves arching over a small warm cream clearing, one soft apricot lantern glow resting on the ground beneath it; nothing enclosed, one side open to the meadow.
```
Feeling: kendine sığınak açmak.

### `discover-carry` — Yanında taşımak (kayıp)
```
[ortak stil bloğu] A quiet evening riverbank in deep teal and dusty blue, a single small cream boat moored at the near edge, its long soft reflection on the still water, one small apricot lantern at its bow; the river continues past the frame.
```
Feeling: yanında taşıyarak yürümek.

### `discover-unnamed` — Adını koyamadığında (adı konmamış)
```
[ortak stil bloğu] Soft low morning mist over rolling sage hills, where a warm cream path clearly begins in the foreground and then fades gently into the mist without a visible end; the beginning is certain, the destination is not.
```
Feeling: adını bilmeden başlamak.

## Kabul kontrolü

1. Kırpma: her kart görseli üstten kırpıldığında ilgi merkezi görünüyor mu?
2. Yedi kart yan yana konduğunda aynı elden çıkmış görünüyor mu (palet, doku, ışık)?
3. Hiçbir görselde zirve, merdiven, bayrak, kutlama, insan, yüz veya yazı yok mu?
4. 64 pt'e küçültüldüğünde her görsel tek bir sakin şekil olarak okunuyor mu?
5. Her görsel ≤600 KB mı, `Assets.xcassets/Discover/` altında imageset olarak, adları birebir doğru mu?
6. Simülatör: `-patika-debug-tab kesfet` ile ana ekran, `-patika-debug-no-art` ile
   görselsiz hâl kırılmadan açılıyor mu?
