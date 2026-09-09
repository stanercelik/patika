# Onboarding görselleri

Üretilen görsellerin **kaynak dosyaları** burada durur. Uygulamaya giren kopyalar
`MyApp/Assets.xcassets/Onboarding/` altındaki hazır yuvalara konur.

Prompt'ların tamamı (ChatGPT'ye yapıştırılacak haliyle):
[`docs/PRD-Ek-Gorsel-Sistem-ve-Promptlar.md`](../../docs/PRD-Ek-Gorsel-Sistem-ve-Promptlar.md) §11.

## Klasörler

Her görselin kendi klasörü var. Ürettiğin PNG'yi ilgili klasöre koy, sonra
Xcode yuvasına sürükle.

```
assets/illustrations/
├── c1-mirror/          ← C1 Aynalama
├── c2-common/          ← C2 Yalnız değilsin
└── f2-path-ready/      ← F2 Yolun hazır
```

C3, C4 ve F1'de raster görsel yok — üçü de kodla çiziliyor
(`ComparisonColumns`, `ExpectationCurveChart`, `TrailRow`).

## Nasıl eklenir

1. ChatGPT görsel üretiminde ilgili prompt'u §11'den **aynen** yapıştır
   (her görsel ayrı sohbet).
2. **Arka planı sil** — PNG şeffaf olmalı. Görsel bizim gradyanımızın üstünde
   duracak; kendi arka planıyla gelirse ekranda bir kutu gibi görünür.
3. Kaynağı ilgili klasöre kaydet: `c1-mirror.png` vb.
4. Xcode'da `Assets.xcassets → Onboarding` altındaki ilgili yuvaya sürükle
   (2x kutusuna). Yuvalar zaten açık, yenisini oluşturmaya gerek yok.

| Yuva | Ekran | Klasör | Kaynak dosya |
|---|---|---|---|
| `illustration-c1-mirror` | C1 — Aynalama | `c1-mirror/` | `c1-mirror.png` |
| `illustration-c2-common` | C2 — Yalnız değilsin | `c2-common/` | `c2-common.png` |
| `illustration-f2-path-ready` | F2 — Yolun hazır | `f2-path-ready/` | `f2-path-ready.png` |

`illustration-c4-horizon` yuvası **kullanımdan kalktı**: C4 artık kodla çizilen bir
grafik kullanıyor.

## Teknik gereksinimler

- **Boyut:** 1024×1024 üret, sonra içeriğin etrafındaki boşluğu kırp.
- **Ölçek:** 2x yuvaya konacak dosya en az 640 px genişliğinde olsun
  (ekranda ~156 pt yüksekliğinde çiziliyor).
- **Format:** şeffaf PNG.
- **Renk:** kırık beyaz (`#F2EFE9`) ve grileri. Görsel kendi rengini getirmemeli —
  arka plan paleti kullanıcının kategorisine ve ruh hâline göre değişiyor, sabit
  renkli bir görsel bu paletlerin bir kısmıyla çakışır.

## Görsel yokken ne olur

Hiçbir şey. `OnboardingIllustration` varlığı bulamazsa hiç yer kaplamaz; ekranlar
görselsiz de eksiksiz çalışır. Yani görselleri istediğin sırayla, tek tek
ekleyebilirsin.
