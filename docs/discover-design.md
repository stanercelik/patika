# Keşfet — 16 Eylül 2026, v2: 20 Eylül 2026

## Ürün kontratı

Kullanıcının açık talebiyle hazır patika kütüphanesi uygulanır. Kütüphane v2'de on patikadır,
A2'deki on problem kategorisinin her biri için bir tane. Her biri yedi özgün adım içerir. Bunlar
kişiselleştirilmiş program veya klinik müdahale değildir. Gün bekleme zorunluluğu
yoktur; sonraki adım ses gerçekten tamamlanınca açılır. Uygulamayı kapatma oturum
sonunda birincil çıkıştır. Tekrar oynatma mümkündür.

Önizleme yalnızca içerik ve kadın/erkek anlatıcı seçimini gösterir. Katılım onayı
alınmadan oynatma yetkisi verilmez. Sesler eksikse katılım devre dışıdır. Kişisel
patika sunucuda korunur; hazır patika ilerlemeleri cihazda UserDefaults üzerinden
ayrı saklanır. Bu sürümde hesaplar/cihazlar arasında senkronizasyon yoktur ve
katılım açıklaması cihazda saklamayı belirtir.

## Keşfet v2 (20 Eylül 2026)

Ben v2 ve Yolum manzara patikasından sonra Keşfet ortak guaj diline taşınıyor.
Uygulama planı: `docs/discover-v2-plan.md`. Bu bölüm aşağıdaki "Görsel yön"ün
**yerine geçer**; eski bölüm yalnızca tarihçedir.

Onaylanan kararlar:

1. Kütüphane **10 patika**, A2'deki 10 problem kategorisine birer tane; her biri
   7 adım. Bugün 3'ü var (`breath`, `evening`, `focus`), kalan 7'nin içeriği
   plan aşama 7'de yazılır.
2. Gruplama **bölüm başlıklarıyla dikey akış**, her bölüm yatay kart şeridi.
   Filtre çipi yok. Bölüm: Yükü hafifletmek (anxiety, anger, exam) · Gün sonu ve
   dinlenme (sleep, burnout) · Dikkat ve bulunmak (focus, social) · Kendine karşı
   (selfcrit, grief, unnamed). Patikası olmayan bölüm çizilmez.
3. Dil `AppLocale.current`e uyar; katalog zaten TR/EN çift. Ses ilk sürümde
   İngilizce kalır ve ekranda yazılır (`discover.collectionNote`).
4. Tasarım ve içerik metinleri şimdi, ses üretimi sonra. **Sesi olmayan patika
   listede görünür, "Yakında" işaretlenir, katılım açılmaz.** Sahte ses, sahte
   süre, sahte ilerleme yok.
5. Katılınan hazır patika **Keşfet'te kalır**; Yolum sekmesini devralmaz.
   Aynı anda birden fazla hazır patikaya katılınabilir. Kişisel patika Yolum'un
   tek sahibidir. (Uygulama: plan aşama 6.)
6. Keşfet'e özgü yeni manzara `discover-world`; Yolum'un `journey-world-continuous`
   görseli paylaşılmaz.

Ekran dili (Yolum ve Ben'le aynı üç katman, `PatikaSurface.swift`):

- **Zemin:** `WoodlandStyle.background` + kullanıcının paletinde düşük genlikli
  mesh + `discover-world` manzarası (kaydırılan içeriğin arkasında, 24 pt'e kadar
  parallax).
- **Kâğıt:** patika kartları krem kâğıt, koyu mürekkep yazı; yazı görselin
  **üstüne binmez**, görselin altındaki kâğıtta durur.
- **Cam:** yalnızca yüzen başlık. Aşağı kaydırınca saklanır, yukarı kaydırınca
  geri gelir.
- **Yazı:** yalnızca `Theme.TypeFace`. "Explore/Keşfet" üst etiketi çizilmez;
  başlık cümlesi yüzen başlıktadır.
- **Detay:** sheet yerine push; kart `matchedTransitionSource`, hedef
  `.zoom` geçişi (Ben'deki defter geçişiyle aynı). Zemin patikanın **kendi
  kategorisinin** paletidir, hero görsel `MeBackdrop` matematiğiyle solar.
  Adımlar Yolum'un tabela rotasıdır; rota çizimi `SignpostRoute` ile paylaşılır.
- **Erişilebilirlik:** Reduce Motion parallax ve kayan başlığı kapatır, Reduce
  Transparency ve AX boyutlarında manzara/hero çizilmez ve başlık akışa girer.
  Görsel yoksa (`PatikaArt.exists`) ekran kırılmaz, yer kaplamaz.

Hazır patikada ölçüm, rozet, kova, kişisel soru ve sunucuya cevap yazımı yoktur;
bu sınır değişmez. Faz eşlemesi yalnızca oturum görselinin seçimi içindir.

## Görsel yön (16 Eylül — v2 ile geçersiz, tarihçe)

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

İki anlatıcı için 280 ses referansı (10 patika x 7 adım x 2 anlatıcı x 2 parça), ortak
kapanışlar sayesinde 142 benzersiz kayıt üretilir. Sunucu mevcut ElevenLabs ses kimliklerini ve eleven_v3 modelini kullanır.
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

### Aşama 8 doğrulaması ve görsel sadeleştirme (20 Eylül 2026)

- Sekiz yeni görsel `discover-*.imageset` (JPEG) yapıldı, var olan dört imageset de aynı
  biçime çekildi. Derlenmiş pakette on iki görsel toplam 6,4 MB (`assetutil --info`).
- İlk yerleşimde aydınlık manzara üstünde başlıklar 2,4-2,7:1 kontrastta kaldı ve kartlar
  manzarayla yarıştı. Ürün sahibi kararıyla: manzara %58 karartıldı (`dimming`, yalnızca
  Keşfet), görsel bandı 150 pt'den 112 pt'ye indi, özet metni koyu mürekkep ve bir punto
  büyük oldu, durum etiketi kapsül aldı. Sonuç: başlık medyan 7,2-7,7:1.
- Simulator (iPhone 17 Pro): ana ekran dört kaydırma noktasında, `breath` detayı, AX5.
- **Açık:** Reduce Motion / Reduce Transparency / Increase Contrast cihaz senaryoları,
  VoiceOver, gerçek ses.

### Aşama 7 doğrulaması (20 Eylül 2026)

- Yedi yeni patika (`beat`, `pressure`, `refill`, `rooms`, `kinder`, `carry`, `unnamed`) ve
  49 adım eklendi; katalog 10 patika, 70 adım. Sunucu kopyası birebir aynı.
- `Tests/DiscoverLibraryTests` içerik kurallarını da denetler (yasaklı ifade, adım kimliği,
  ortak kapanış, sessizlik süresi, TTS için rakam/çizgi yok) ve geçti.
- Simulator: dört bölüm ve on kart görünür; yeni kartlar görselsiz ("Yakında").
- **Açık:** metinlerin klinik gözden geçirmesi (özellikle `carry`, `kinder`, `unnamed`). Üç
  patikanın son adımında destek yönlendirmesi cümlesi var, bir ürün kararı olarak bekliyor.

### Aşama 5–6 doğrulaması (20 Eylül 2026)

- Hazır oturum artık `PathSessionView` / `PathSessionViewModel` (Yolum'la aynı sahne,
  kontroller ve motor) üzerinden çalışır; eski `DiscoverSessionView`/`ViewModel` silindi.
  Tamamlanma yalnızca sesi başlamış ve sonuna kadar dinlenmiş oturumdan yazılır ve cihazda
  kalır. Kayıt çalınamazsa adım tamamlanmaz, "Yeniden dene" gösterilir.
- Katılım Keşfet'te kalır; Yolum yalnızca kişisel patikayı gösterir. Birden fazla patikaya
  aynı anda katılınabilir, ilerlemeler ayrı ve karışmaz; "Kaldığın yerden" en son ilerleyen
  patikayı başa alır.
- Test: `Tests/DiscoverLibraryTests` geçti (çoklu katılım yalıtımı, sıra, yeniden dinleme
  ilerleme sayılmaması, `activeID` içeren eski kaydın okunması, kalıcılık).
- Simulator (iPhone 17 Pro): ses yokken `audioUnavailable` ekranı; **geçici, repoya girmeyen**
  test kayıtlarıyla (ffmpeg sinüs MP3'leri, paketin scratch kopyasına eklendi) oturum
  çalıştı: sahne, iz, 15 sn kontrolleri, bitiş ekranı, adımın cihazda 1/7 olarak kalması,
  Keşfet'te "Kaldığın yerden" kartı, Yolum'un kişisel patikada kalması.
- **Hâlâ açık:** gerçek ElevenLabs kayıtlarıyla çalma, kilit ekranı kontrolleri, kesinti ve
  arka plan, VoiceOver turu. Ses üretimi engeli sürdüğü için bunlar doğrulanmadı.

### Keşfet v2 doğrulaması (20 Eylül 2026, aşama 0–4)

- `swiftc` ile derlenen hazır patika testi geçti: bölümler, durum, benzersiz kategori,
  yinelenen kategorinin reddi, önizleme engeli, sıralı açılma, tekrar oynatma, kalıcılık.
- Simulator derlemesi geçti. iPhone 17 Pro'da doğrulandı: ana ekran (TR), kaydırınca
  saklanan başlık, detay (hero, palet, rota, genişleyen durak), katılımlı durum ("Kaldığın
  yerden" kartı, canlı detay), AX5 (ana ekran ve detay), `-patika-debug-no-art`.
- Doğrulanamayanlar: Reduce Motion / Reduce Transparency / Increase Contrast cihaz
  senaryoları, VoiceOver turu, yakınlaştırma geçişinin animasyonu (ekran görüntüsü
  hareketi göstermez), `discover-world` ve yeni kart görselleri (henüz yüklenmedi).


## Güncelleme — 21 Eylül 2026: v2 katalog, tek ses, yerel render

- Katalog `version: 2`: adım `segments` + `closing`, sessizlik yazılan `quietMs` (nefese yuvarlanmaz).
- MVP yalnızca İngilizce ve tek (kadın) ses. Ses seçici kalktı; `render-discover-audio` edge
  fonksiyonu kaldırıldı, üretim `scripts/render-discover-audio.py` ile yerelde.
- Çalma: her bölüm ayrı kayıt, aralarındaki sessizlik istemcide gerçek sessizlik tamponu; son
  yönerge duraklama boyunca ekranda kalır (`displayText` yok).
- Boyut ölçüldü: 31 kayıt / 2,1 MB; tam katalog ~286 kayıt / ~20 MB, ~20 bin karakter.
- Doğrulama günlüğü: `breath` patikası Türkçe cihaz diliyle simülatörde katılınabilir, oturum
  bölümleri sessizlikten sonra ilerliyor, ilerleme çubuğu akıyor (ses simülatörde yakalanamaz;
  tempo `Tests/SessionSchedulerTests`te dalga formundan). Seviye yayılımı 31 dosyada 0,9 LU
  (medyan -16,2 LUFS), true-peak en çok -1,5 dBFS.
- Tamamlandı: 10 patikanın tamamı üretildi (286 kayıt, 18 MB, seviye yayılımı 1,0 LU),
  `discover.duration` "About 4 min each".
