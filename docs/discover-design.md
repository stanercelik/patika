# Keşfet — 16 Eylül 2026

## Ürün kontratı

Kullanıcının açık talebiyle hazır patika kütüphanesi uygulanır: Evening, unhurried;
Room to breathe; One thing at a time. Her biri yedi özgün adım içerir. Bunlar
kişiselleştirilmiş program veya klinik müdahale değildir. Gün bekleme zorunluluğu
yoktur; sonraki adım ses gerçekten tamamlanınca açılır. Uygulamayı kapatma oturum
sonunda birincil çıkıştır. Tekrar oynatma mümkündür.

Önizleme yalnızca içerik ve kadın/erkek anlatıcı seçimini gösterir. Katılım onayı
alınmadan oynatma yetkisi verilmez. Sesler eksikse katılım devre dışıdır. Kişisel
patika sunucuda korunur; hazır patika ilerlemeleri cihazda UserDefaults üzerinden
ayrı saklanır. Bu sürümde hesaplar/cihazlar arasında senkronizasyon yoktur ve
katılım açıklaması cihazda saklamayı belirtir.

## Görsel yön

Koyu orman zemini, kırık beyaz tipografi, kayısı vurgular; guaj ve kesilmiş kağıt
hissinde dört özgün illüstrasyon. Yazı resim üzerine bindirilmez. Önizleme rozeti,
kilit ve durum metni renk dışında anlam taşır. Yerel sheet/confirmation geçişleri
ve ortak CalmButtonStyle kullanılır. Sürekli dekoratif hareket eklenmez.
Büyük erişilebilirlik boyutlarında katılım alanı sabitlenmez; içerikle kayar.
Yolum'un üst dekoratif görseli kaldırılmıştır.

Mobbin araştırması (hiyerarşi ve illüstrasyonun içerikteki rolü; birebir kopya değil):
- https://mobbin.com/screens/a2a14b62-94c2-4db3-9dbf-5aa5b39c39b9
- https://mobbin.com/screens/22b861df-e8d9-4284-a4f9-a25dc6c6dbcc
- https://mobbin.com/screens/d05b1798-9389-4073-999b-693b84cca19e

## İçerik ve gerçek ses

`MyApp/Content/Discover/discover-catalog.json` kanonik içeriktir. Sunucu kopyası
`supabase/functions/render-discover-audio/catalog.json` ile aynı tutulmalıdır.
Her metin sabit ID altında en/tr çifti içerir. `Discover.xcstrings` arayüz çevirilerini
tutar. İlk sürüm bilinçli olarak İngilizcedir; uygulama genelinin dil geçişi ayrı iştir.

İki anlatıcı için 84 ses referansı, ortak kapanışlar sayesinde 44 benzersiz kayıt
üretilir. Sunucu mevcut ElevenLabs ses kimliklerini ve eleven_v3 modelini kullanır.
Ses + 40 saniyelik gerçek sessizlik + kapanış SessionManifest ile oynatılır.
İlerleme ayrı sayaçtan değil SessionAudioPlayer'ın ses zamanından hesaplanır.

Yayın aracı: `scripts/render-discover-audio.py`. İncelenmiş katalog dışından metin
kabul etmeyen sunucu fonksiyonu yalnızca `PATIKA_CONTENT_PUBLISHER_ID` ile yetkili
kullanıcıya açıktır. Uygulama ücretli ses üretimini tetiklemez. MP3'ler ve süre/hash
manifesti uygulamaya paketlenir. Kullanıcıya özel ses verisi bu araçtan geçmez.

### Açık engel

ElevenLabs gerçek üretim isteğine `402 payment_required` döndürdü. Kayıt üretilmedi;
bu nedenle uçtan uca ses/katılım doğrulaması tamamlanmadı. Sahte ses veya süreyle
çalışıyor izlenimi verilmez. Geçici yayıncı hesabı silindi; dağıtılan fonksiyon
tekrar ortam değişkenindeki yayıncı kontrolüne döndürüldü. Ödeme düzeltildiğinde
yetkili yayıncıyla üretim yeniden çalıştırılmalı, MP3'ler dinlenmeli ve paketlenmelidir.

## Doğrulama

- Swift standalone test harness: önizleme engeli, eksik ses, sıralı açılma,
  tamamlanan adımı tekrar oynatma yetkisi, patikalar arası geçiş, kalıcı ilerleme,
  yedi adımın tamamlanması geçti.
- Simulator derlemesi geçti (MyApp). Bu bir XCTest çalıştırması değildir.
- iPhone 16e/iOS 26 ana ekran ve iPhone 18 Pro/iOS 27 önizleme ekranı görüntülendi.
- AX5 önizleme kontrolünde sabit alt alanın içeriği sıkıştırması bulundu ve düzeltildi.
- Etkileşimli kaydırma/dokunma otomasyonu kullanılamadı; ses üretimi engeli nedeniyle
  gerçek çalma, kesinti, arka plan ve tamamlanma UI akışı henüz doğrulanmadı.
- Reduce Motion/Transparency cihaz senaryolarının tam uçtan uca kontrolü bekliyor.
