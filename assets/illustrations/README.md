# Görsel kaynaklar

Üretilen görsellerin **kaynak dosyaları** ve prompt'ları burada durur. Uygulamaya giren
kopyalar `MyApp/Assets.xcassets/` altındaki imageset'lerdedir.

## Güncel yön: ortak guaj ailesi (17 Eylül 2026 kararı)

Koyu teal, adaçayı, soluk mavi, krem ve kayısı; guaj dokusu, düzensiz kesme-kâğıt
kenarlar. Bu, önceki "tek mürekkepli, monokrom kırık beyaz" brief'inin yerini alır: o
brief gerçek zeminin paletle değiştiği bir dönemden kalmaydı ve bu dosyanın eski
sürümü hâlâ onu buyuruyordu. Yeni parçalar tam da bu çizgide durduğu için düzeltildi.

### Renkli guaj nerede durabilir

| Nerede | Ne durabilir |
| --- | --- |
| **Kâğıt kart** (krem `#EDE7D9`) | Renkli, şeffaf alfalı guaj kesit |
| **Karartılmış sahne zemini** | Tam ekran opak guaj manzara; üstünde açık tonlu şeffaf parça |
| **Canlı kategori mesh'i** | Hiçbir görsel |

Sebebi: onboarding'de A2'nin paleti ve B6'nın ruh hâli **arka planın kendisi**. Renkli opak
bir parça mesh'in üstünde yüzerse paleti ezer ya da onunla çakışır.

## Klasörler

| Klasör | İçerik | Prompt'lar |
| --- | --- | --- |
| `gouache/` | Ortak aile: yansıtma, aidiyet, sığınak, iz, dinlenme, defter; Yolum dünyası | `prompts.json`, `world-prompts.json` |
| `onboarding/` | Onboarding yeniden tasarımının 10 yeni parçası | `prompts.md` |
| `session/` | Oturum ekranı (faz bazlı) | `prompts.md` |
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
görsel yer kaplamaz ya da düz yüzey çizilir. Onboarding'de A1, görsel gelene kadar yol
animasyonunu kullanır. Görselleri istediğin sırayla, tek tek ekleyebilirsin.

## Ortak kurallar

- Metin, rakam, işaret, UI, insan, yüz, el yok. Ödül, zirve, kupa, bayrak imgesi yok.
- Ölçüm ekranlarında ve kriz modunda dekoratif görsel gösterilmez.
- Görseller VoiceOver'dan gizlidir; anlamı hiçbir zaman yalnızca görsel taşımaz.
- Erişilebilirlik boyutlarında (AX Dynamic Type) dekoratif görseller saklanır.
