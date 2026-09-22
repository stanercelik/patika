# Görsel kaynaklar

Üretilen görsellerin **kaynak dosyaları** ve prompt'ları burada durur. Uygulamaya giren
kopyalar `MyApp/Assets.xcassets/` altındaki imageset'lerdedir.

## Güncel yön: ortak guaj ailesi (17 Eylül 2026 kararı)

Koyu teal, adaçayı, soluk mavi, krem ve kayısı; guaj dokusu, düzensiz kesme-kâğıt
kenarlar. Bu, önceki "tek mürekkepli, monokrom kırık beyaz" brief'inin yerini alır: o
brief gerçek zeminin paletle değiştiği bir dönemden kalmaydı ve bu dosyanın eski
sürümü hâlâ onu buyuruyordu. Yeni parçalar tam da bu çizgide durduğu için düzeltildi.

### Gradyan kalktı (22 Eylül 2026 kararı) — renkli guaj artık nerede durabilir

`MeshGradient` + Metal shader + 10 kategori paleti tamamen kaldırıldı
(`docs/onboarding-redesign.md`). "Canlı kategori mesh'i" diye bir şey artık yok;
onun yerini **tam ekran opak guaj sahneler** aldı — A2'den B6'ya kadar sahne
kategoriye göre değişir, bu işi eskiden canlı palet yapıyordu.

| Nerede | Ne durabilir |
| --- | --- |
| **Kâğıt kart** (krem `#EDE7D9`) | Renkli, şeffaf alfalı guaj kesit |
| **Tam ekran sahne zemini** (artık **her** onboarding ekranında) | Tam ekran **opak** guaj manzara; kodda düz bir perde (`WoodlandStyle.background.opacity(dimming)`) bindirilir |

## Klasörler

| Klasör | İçerik | Prompt'lar |
| --- | --- | --- |
| `gouache/` | Ortak aile: yansıtma, aidiyet, sığınak, iz, dinlenme, defter; Yolum dünyası | `prompts.json`, `world-prompts.json` |
| `onboarding/` | Kâğıt kart içi 9 şeffaf kesit (isim, B3, C3, C4, taahhüt, D0, F2, H2, H1) | `prompts.md` |
| `scenes/` | **16 tam ekran opak sahne** (6 bölüm + 10 kategori) — henüz üretilmedi | `prompts.md` |
| `session/` | Oturum ekranı faz görselleri (`session-trailhead` vb.) | `prompts.md` |
| `discover/` | Keşfet v2 kart görselleri ve manzara | `prompts.md` |
| `me/`, `me-v2/`, `journey/` | Ben sekmesi ve Yolum faz görselleri | kendi klasöründe |
| `c1-mirror/`, `c2-common/`, `f2-path-ready/` | **Eski kaynaklar.** C1 ve C2 artık `illustration-reflection` ve `illustration-belonging` kullanıyor; buradaki iki imageset silindi (yetimdi). Kaynak PNG'ler tarihçe için durur | — |

## Nasıl eklenir

1. İlgili klasördeki `prompts.md` içinde parçanın bloğunu **aynen** yapıştır (her parça ayrı
   sohbet). Referans olarak mevcut aile görsellerini ver.
2. Şeffaf parçalarda arka planı sil ve gerçek alfa bırak; opak sahnelerde alfa olmasın.
3. Dosyayı ilgili imageset'e koy. Şeffaf: `<ad>.png` (`Contents.json`ta 2x). Opak: `<ad>.jpg`
   (universal). Düz `.png` dosyasını katalog dışında bırakma: `UIImage(named:)` onu görmez.
4. `-patika-debug-no-art` ile bütün ekranlarda görselsiz hâli de aç.

## Görsel yokken ne olur

Hiçbir şey kırılmaz. Her yerleşim önce `PatikaArt.exists(_:)` ile varlığı sorar; yoksa
görsel yer kaplamaz (kâğıt içi kesit) ya da düz `WoodlandStyle.background`'a düşer (tam
ekran sahne, `OnboardingSceneLayer`). Görselleri istediğin sırayla, tek tek ekleyebilirsin.

## Ortak kurallar

- Metin, rakam, işaret, UI, insan, yüz, el yok. Ödül, zirve, kupa, bayrak imgesi yok.
- Ölçüm ekranlarında ve kriz modunda dekoratif görsel gösterilmez.
- Görseller VoiceOver'dan gizlidir; anlamı hiçbir zaman yalnızca görsel taşımaz.
- Erişilebilirlik boyutlarında (AX Dynamic Type) dekoratif görseller saklanır.
