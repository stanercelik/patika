# Yolum: topoğrafik rota — 16 Eylül 2026

## Amaç

Ürün sahibinin ana sayfadaki patikayı yeniden tasarlama talebi. Gerçek adım
başlıkları, erişim kuralları, ölçüm noktaları ve oturum motoru korunur.

## Mobbin araştırması

Üç ayrı sorguda 15 ekran görsel olarak incelendi: kişisel program rotaları,
günlük meditasyon odak alanları ve illüstrasyonlu öğrenme haritaları.

- [Ahead: manzaranın içine yerleştirilen rota](https://mobbin.com/screens/bb650f80-dbb9-4af0-bb02-aa0e1b7743f3).
- [Alan: adım ve içeriği aynı okuma biriminde tutma](https://mobbin.com/screens/e1e3e7be-aead-4b39-a178-966ffb0a1cca).
- [Open: sakin atmosfer ve belirgin oturum odağı](https://mobbin.com/screens/3240de8e-d9f3-48f6-a2f8-dd198959e568).
- [Headspace: rota üzerinde okunur içerik kartları](https://mobbin.com/screens/1cba404f-413c-4a8b-be36-d791e9ca4fed).

Referanslardaki seri, sosyal kanıt, geri sayım ve ödül mekanikleri kullanılmaz.

## Uygulama

- Başlık tam kullanılabilir genişlikte, semantik `largeTitle` rolündedir.
- Açılan oturum kartı iki kolon arasına sıkışmaz; tam genişlikte açılır.
- Kartın üstündeki topoğrafik görsel native Canvas ile üretilir. Rota,
  mesafe veya sonuç verisi iddiası taşımayan dekoratif bir metafordur.
- Işıklı nokta ortak nefes kaynağına bağlıdır; yeni bir animasyon saati yoktur.
- Kartı açma ve oturumu başlatma birbirinden bağımsız düğmelerdir.
- Aktif merkez değiştiğinde komşu satırların sınırları birlikte hesaplanır;
  kesintisiz yol korunur. F2'nin sunum düzeni değişmez.
- Gelecek ve tamamlanan adımların başlık kontrastı yükseltilmiştir.
- AX boyutlarında görsel kalkar; kart ve metin tam genişlikte büyüyebilir.
- Reduce Motion, düşük güç, termal baskı ve arka plan davranışları ortak
  `JourneyMotionValueReader` tarafından yönetilir. Reduce Transparency
  kartı opaklaştırır ve dekoratif hareketi durdurur.

## 16 Eylül düzenlemesi

- Başlık artık aynı ScrollView içinde. Yukarı kayarken render katmanında
  %14 parallax, opacity ve en fazla 3 pt blur ile kaybolur; geri dönüşte görünür.
- Adım yazıları ayrı bir sol rota koridorunun yanında tam yükseklikte sarılır.
  Metne clip uygulanmaz. Mevcut adımın kartı tam genişliktedir.
- Mevcut adım da açılıp kapanır; konumu ve “Buradasın” etiketi korunur.
- Yolun Bezier kontrol noktaları daha yumuşak dönüşler için düzenlendi.
- Faz görselleri, topoğrafik çizgiler ve kategori ışığı birlikte kullanılır.
  Statik konturlar animasyon saatinin dışında çizilir.
- Ek Mobbin incelemesi: [Liven](https://mobbin.com/screens/c2a31d18-6bf5-4ab4-888b-1c2c429c7870),
  [Alan](https://mobbin.com/screens/df679b59-f12a-4b1a-bc95-de27f6388e29),
  [Noom](https://mobbin.com/screens/3ef3dce1-8f8e-416b-b8c2-5d52d177fe26),
  [Ahead](https://mobbin.com/screens/5dd5c706-0120-43a2-878c-95cfebcd3170).

## Doğrulama

Xcode 27 ile iPhone 18 Pro simulator hedefinde BUILD SUCCEEDED.
Bu makinede actool kuyruğu kilitlendiği için yalnızca derleme komutuna
`IBToolNeverDeque=YES` eklendi; sistem ayarı değiştirilmedi.

Gerçek uygulama simulator görüntülerinde incelendi:
- iPhone 18 Pro / iOS 27: başlangıç başlığı, açık ve kapalı mevcut adım,
  uzun gelecek adım başlıkları.
- iPhone 16e / iOS 26: AX5 yazı boyutu, normal boyut, Reduce Motion ve
  Reduce Transparency açık görünüm. Ayarlar sonrasında eski değerlerine döndürüldü.
- AX5 konum etiketindeki sözcük bölünmesi düzeltildi. Kart başlığı tam
  genişlikte büyür; uzun içerik dikey kaydırılır.

Görsel kontroller açıkça etkinleştirilen DEBUG fixture ile yapılır:
`-patika-debug-step yolum -patika-debug-path-preview`.
`-patika-debug-path-day 3`, `-patika-debug-path-collapsed` ve
`-patika-debug-path-ax5` ilgili başlangıç durumlarını seçer.
Fixture Release derlemesine girmez; sunucuya veri yazmaz ve oturum başlatmaz.

Device Hub'ın bilgisayar kontrol bağlantısı zaman aşımına uğradığından fiziksel
kaydırma/dokunma ile animasyon akıcılığı ve VoiceOver etkileşim testi tamamlanmadı.
Statik ekran kontrolü performans ölçümü değildir. Test target yok; xcodebuild test
çalıştırılmadı. Kaynak farkında boşluk kontrolü geçti.

## Telefonda boş ekran — 16 Eylül devamı

Kod incelemesinde DEBUG doğrudan girişte kök görünümün, örnek taslaktan gerçek
patika üretimi tamamlanmadan kurulabildiği görüldü. Ekranın ilk sorgusu boş dönünce
üretim sonrasında yenileme yoktu. Kök artık bu hazırlık tamamlandıktan sonra kurulur.
Bu, telefondaki hesabın sunucu kaydının incelendiği anlamına gelmez.

Patika kaydı olmayan hesapta topoğrafik başlangıç ekranı, gerçek onboarding'e
açılan “Yola çık” ve yeniden sorgulama aksiyonu vardır. Kullanıcı hesap verisi
silinmez veya onboarding bayrağı sıfırlanmaz. DEBUG sürümünde boş ekrandaki
“Tasarım önizlemesi · örnek patika” gerçek sunucu kaydı oluşturmadan tasarımı açar;
önizleme etiketi görünür ve oturum başlatma devre dışıdır.

Ortak birincil/ikincil düğmelerde uzun metin sarılması ve 44 pt minimum hedef
korunur. SOS hedefi de en az 44 pt'dir.

Boş durum araştırması:
- [Calm](https://mobbin.com/screens/4b4c33cb-b5d7-4ce5-8325-c6206a489601)
- [5 Minute Journal](https://mobbin.com/screens/baf3a62c-3bad-4d6e-bc02-f86c1000ff92)
- [pillowtalk](https://mobbin.com/screens/bcbd96d6-2474-4347-8b7c-27bed199dd48)

Bu referanslarda boş durumun açıklama + tek başlangıç aksiyonu etrafında
kurulması incelendi. Patika'nın kendi topoğrafik dili korundu.

## 17 Eylül — Ahead esinli manzara ve birleşim düzeltmesi

Önceki topoğrafik harita yerine `IllustratedPathMap` native durakları ve açılabilen
mevcut adım kartını bir guaj manzaraya yerleştirir. Başlıklar doğal yükseklik alır.
İlk bağımsız forest/water resimlerinin koyu kenarları kullanıcı tarafından
reddedildi. Güncel `journey-world-continuous` 724×2172 boyutunda tek uzun resimdir.
Üst/alt açık çayırlar %12 örtüşür; yeni katman opak eski katmanın üstüne girer,
alttaki koyu zemin açığa çıkmaz. Yerleşim içerik uzunluğuna göre tekrar eder.

Başlık normal Dynamic Type'ta üstte ölçülen bir overlay'dir; içerikte aynı
ölçüde boşluk ayrıldığı için gizlenmesi haritayı zıplatmaz. Aşağı 28 pt hareket
saklar, yukarı 18 pt hareket gösterir. Yön değişiminde eşik sıfırlanır, bounce
sınırları sıkıştırılır. 340 ms smooth geçiş; Reduce Motion'da 180 ms opacity.
Arkadaki gerçek sahneyi bulanıklaştıran light regularMaterial son 32 pt'de solar.
AX boyutlarında başlık normal içerikte kaydırılır ve durakları örtmez.

Doğrulama: iOS Simulator derlemesi başarılı. iPhone 16e normal boyutta üst,
mevcut adım ve 5–7. adımlar incelendi; sahne birleşiminde koyu bant görünmüyor.
iPhone 18 Pro AX5 ekranında başlık sarılması kontrol edildi. Native jestle
başlığın geri dönüşü, VoiceOver ve kare süresi ölçümü henüz doğrulanmadı.
Reduce Motion/Transparency dalları kodda mevcut; bu revizyonda OS ayarlarının
uygulamaya yansıması doğrulanmış sayılmıyor. Test target yok, build test değildir.

Yeni görsel built-in image_gen ile üretildi. Tam prompt ve ölçü bilgisi:
`assets/illustrations/gouache/continuous-world-prompt.json`.

### Aynı görsel dile uyarlama — 17 Eylül devamı

Durak etiketleri krem kâğıt / koyu yeşil metin kullanır; yumuşak gölgeler ve
240 ms basma geçişi vardır. Mevcut yaprak, kart açıldığında 8 derece yön değiştirir.
Yol artık satırların ayrı çizgileri değildir: node anchor'ları ölçülür ve gerçek
merkezler tek kesintisiz Bézier hattıyla bağlanır. Böylece kart yüksekliği ve
Dynamic Type değişirken satır birleşiminde köşe oluşmaz.

Sahne parallax'ı 24 pt ile sınırlı, yalnızca render katmanında; Reduce Motion'da
kapalıdır. Başlığın yön eşiği kaydı gözlemlenmeyen referans üzerinde tutulur:
her kaydırma pikseli bütün haritayı yeniden değerlendirmez. Tamamlanan duraklar
VoiceOver değerinde de açıkça tamamlandı bilgisini taşır.

Normal iPhone 18 Pro görünümünde mevcut adım ve 4/5 durakları incelendi.
Derleme başarılı; gerçek cihaz kare süresi ve jest testi henüz yapılmadı.
