# Kişisel İz Yol Haritası Tasarımı

**Tarih:** 2026-09-10  
**Durum:** Ürün sahibi tarafından onaylandı  
**Kapsam:** F2 “Yolun hazır” ve onboarding sonrası “Yolum” haritası  
**Kapsam dışı:** Path üretim algoritması, oturum motoru, ölçüm skoru, ödeme akışı ve F1 üretim izi

## 1. Amaç

Mevcut sağa-sola kıvrılan haritayı, kullanıcıya ait gerçek programın yapısını
gösteren özgün bir **Kişisel İz** sistemine dönüştürmek. Harita bir ders ağacı,
ödül yolu veya dekoratif içerik listesi olmayacak. Kullanıcının onboarding
yanıtlarından sunucuda üretilen path başlığı, gerçek adımlar, fazlar, teknikler,
ölçüm günleri ve tamamlanma durumu tek bir sakin rota üzerinde okunacak.

Başarı ölçütü yalnızca “daha güzel görünmesi” değildir:

- Kullanıcı ilk bakışta sıradaki adımı, gelecekte ne olduğunu ve yolun sonlu
  olduğunu ayırt edebilmeli.
- Haritadaki hiçbir başlık veya teknik rastgele ya da yalnızca dekorasyon için
  üretilmemeli.
- Normal koşullarda kaydırma ve sürekli mikro hareket 60 fps hedefini korumalı.
- Yeni görsel dil F2 ile “Yolum” arasında tek ortak bileşen olarak kalmalı.
- Harita tonu `Sakin` düzeyini aşmamalı.

## 2. Araştırma ve seçilen yön

Mobbin incelemesinde şu davranışlar değerlendirildi:

- How We Feel: editoryal tipografi, geniş boşluk ve rotaya gömülü küçük işaretler.
- Brightmind: geniş sağ-sol ritim ve yolun ekranda açıkça devam etmesi.
- Alan: içerikle düğümün tek bir birim gibi okunması.
- Life Reset: aktif ve kilitli durum arasındaki sakin kontrast.
- Mimo, Liven, Ahead ve Noom: para, ödül, maskot, numaralı oyun düğümü, canlı
  illüstrasyon ve ilerleme baskısı nedeniyle Patika için reddedildi.

Değerlendirilen alternatifler:

1. **Editoryal Yol:** En sade yaklaşım; ancak mevcut haritadan yeterince
   ayrışmama riski taşıyor.
2. **Sessiz Topografya:** Katmanlı kontur çizgileriyle daha mekânsal; ancak
   dekorasyon ve render maliyeti riski yüksek.
3. **Kişisel İz:** Editoryal sadelik, faz duyarlı rota ve gerçek içerik
   bağlantısı. Onaylanan yön budur.

## 3. Temel görsel fikir

Kişisel İz, bütün program boyunca kesintisiz devam eden tek renkli bir
“mürekkep izi”dir. Standart ve tekrarlanan bir S eğrisi değildir. Yatay ritim,
programın gerçek fazına göre değişir:

- `relief`: İz merkeze daha yakın, dönüşler kısa ve topludur.
- `awareness`: İz iki yana açılmaya başlar fakat simetrik değildir.
- `skill`: En geniş ama hâlâ sakin sağ-sol ritim burada görülür.
- `behavior`: İz yeniden merkeze yaklaşır; yükselen başarı grafiği oluşturmaz.
- `closing`: Son düğüm merkeze yakın ve görsel olarak kapanmış bir uçtur.

Bu biçimler psikolojik durum veya beklenen sonuç iddiası taşımaz. Yalnızca
programın aşamalarını birbirinden ayıran yön bulma dilidir. Rota yukarı doğru
“tırmanmaz”; içerik dikey olarak yukarıdan aşağı okunur.

Faz değişiminde ayrı bir kart, rozet veya ödül kullanılmaz. İz kısa bir boşlukla
ikiye ayrılır ve gerçek faz etiketi bu **sessiz eşik** üzerinde görünür.

## 4. Bilgi hiyerarşisi

### 4.1 F2

F2 mevcut yapısal sırasını korur:

1. Kişiye hitap eden başlık.
2. Mevcut `illustration-f2-path-ready` illüstrasyonu.
3. Gerçek path başlığı, toplam gün ve seçilen oturum süresi.
4. Kişisel İz üzerinde gerçek adımlar.
5. Mevcut `Yola çık` basılı tutma eşiği.

Yeni raster görsel üretilmez. Mevcut illüstrasyon, dağınık girdinin kurulmuş bir
yola dönüşmesini anlatmaya devam eder; haritanın içinde ikinci bir raster odak
oluşturulmaz.

F2’nin bir defalık aşağı-inip-geri-dönme turu korunur. Tur bilgi vermek içindir,
CTA’yı kilitlemez ve ilk kullanıcı dokunuşunda iptal olur.

### 4.2 Yolum

“Yolum”da ekranın ilk işlevsel odağı sıradaki adımdır. Bu adım varsayılan açık
kalır. Tamamlanan adımlar tekrar açılabilir; gelecek adımların başlığı okunur
fakat içerikleri açılamaz. Kaçırılan gün, sıfırlanma, seri veya gecikme dili
oluşturmaz.

## 5. Düğüm ve iz durumları

| Durum | Biçim | İz | Etkileşim |
|---|---|---|---|
| `done` | 36 pt dolu düğüm, küçük onay işareti | Kesintisiz, orta opaklık | Yolum’da tekrar açılabilir |
| `active` | 50 pt nefes odağı; dolu merkez ve yumuşak dış halka | Aktif düğüme kadar daha parlak | Varsayılan açık, oturum başlatılabilir |
| `pending` | 34 pt boş halka ve kilit | İnce kesikli | Başlık okunur, içerik açılamaz |
| `milestone` | 42 pt çift halka | Fazla aynı tek mürekkep | “Kısa kontrol” metniyle açıklanır |

Renk tek başına hiçbir durumu anlatmaz. Kilit simgesi, onay işareti, halka
yapısı ve metin aynı durumu birlikte taşır. Ölçüm için yıldız veya emoji yoktur.

## 6. İçerik bağlantısı

Metin bağımsız bir kart gibi rotanın yanında yüzmez. Rota düğümden sonra kısa
bir yatay bağlantıyla metin bloğuna yaklaşır. Bu bağlantı yalnızca düzen kurar;
ok veya yön işareti değildir.

- Gün etiketi küçük ve ikincil.
- Gerçek adım başlığı ana satırdır.
- Teknik bilgisi sunucu `blockIds` verisinden çözülebiliyorsa gösterilir.
- Ölçüm notu yalnızca gerçek ölçüm günlerinde görünür.
- Aktif/açık adımda arka planda düşük opaklıklı, tek mürekkepli bir yüzey
  belirir; kapalı adımlarda kart zemini yoktur.

Aktif yüzey material blur kullanmaz. Mevcut MeshGradient kimliğini korumak için
yalnızca sabit beyaz/siyah opaklık katmanları ve ince border kullanır.

## 7. Kişiselleştirme sözleşmesi

| Kaynak | Haritadaki karşılık |
|---|---|
| Seçilen kategori ve ruh hâli | Mevcut `Palette` ve `MeshGradient` |
| Üretilen path uzunluğu | Gerçek düğüm sayısı, ölçüm ve faz aralıkları |
| `GeneratedPath` / `ActivePath` | Path başlığı, adım başlıkları ve sıra |
| `blockIds` | Varsa gerçek teknik adları |
| `completedAt` ve `nextStep` | `done`, `active`, `pending` durumu |
| `PathLength.measurementDays` | Çift halkalı ölçüm düğümleri |
| `SessionLength` | Gerçek oturum süresi metni |

Ham problem metni haritada dekoratif alıntı olarak gösterilmez. Cinsiyet ve yaş
rota biçimini değiştirmez. String hash’i, rastgele sayı veya görsel çeşitlilik
amacıyla uydurulan veri kullanılmaz. Sunucu tekniği çözülemiyorsa işaret ya da
etiket üretmek yerine alan tamamen atlanır.

## 8. Hareket koreografisi

Harita tonu `Sakin`dir. Aynı anda birbirinden bağımsız sürekli hareketler
çalışmaz. Mesh, aktif düğüm ve aktif iz aynı nefes değerini paylaşır.

| Tetik | Hareket | Süre / ritim |
|---|---|---|
| İlk görünüş | Rota `trim` ile çizilir | 440 ms |
| Satır sırası | Başlangıçlar üstten alta ötelenir | 45 ms; gecikme en fazla 300 ms |
| Metin girişi | Opacity ve en fazla 8 pt dikey yerleşme | 280–340 ms |
| Aktif nefes | Ölçek 1.00–1.04, halka ve aktif iz opaklığı | 10 sn: 4 / 0.5 / 5.5 |
| Adım açma | Zeminin ve içeriğin kontrollü yayla yerleşmesi | response 0.42, damping 0.86 |
| Faz eşiği | Kısa çizgi açılması ve etiket opacity | 260 ms, bir kez |
| Tamamlama | İzin aktif bölümü dolar | 400 ms ease-out |
| Durum işareti | Düğüm onay işaretine dönüşür | 220 ms |
| Basma geri bildirimi | 0.98 ölçek ve tek soft haptik | 120–160 ms; haptik 12 ms |

Kilitli adım sallanmaz, titreşmez ve haptik üretmez. Haritada hareketli parçacık,
ilerleyen uç düğümü, parıltı kuyruğu, konfeti veya kutlama patlaması yoktur.

F2 otomatik rota turu mevcut ürün sahibi kararındaki süreleri korur: 1.10 sn
bekleme, 1.50 sn aşağı, 0.55 sn duruş ve 1.20 sn yukarı. Bu uzun hareket bir
dokunma geri bildirimi değil, haritanın tamamının varlığını bir kez gösteren
içerik turudur. Diğer hareketlerle yarışmaz.

## 9. Hareket ve performans mimarisi

- SwiftUI ve mevcut Metal shader dışında yeni bağımlılık eklenmez.
- Rota, satır sınırında birleşen native `Shape` parçaları olarak kalır.
- Scroll sırasında `PreferenceKey`, state yazımı veya bütün listenin sürekli
  geometri ölçümü yapılmaz.
- Sürekli hareket için ekranda yalnızca bir 60 Hz `TimelineView` bulunur.
- Aynı nefes değeri aktif düğüm ve aktif iz tarafından paylaşılır.
- Sonlu animasyonlar `trim`, `opacity`, `scaleEffect` ve transform ile kurulur.
- Material blur, animasyonlu gölge, raster video ve parçacık sistemi kullanılmaz.
- Görünür satırların üretimi tembel yapılır; `PathStepRecord` ve
  `GeneratedPathStep` içerikleri View içinde yeniden türetilmez.
- Arka planın kare başına 2 ms render bütçesi korunur.
- Normal koşullarda kare bütçesi 16.67 ms’dir; tekrarlayan missed frame kabul
  edilmez.

`TimelineView(.animation(minimumInterval: 1.0 / 60.0))` 60 Hz isteğini ifade
eder fakat tek başına sonuç garantisi değildir. Kabul, Instruments/Core
Animation ve Metal System Trace ile ölçülür.

## 10. Güç ve yaşam döngüsü

Sürekli mikro hareket şu koşullarda durur:

- `accessibilityReduceMotion == true`
- Scene aktif değilse
- Low Power Mode açıksa
- Termal durum `.serious` veya `.critical` ise

Bu durumlarda düğüm, iz ve mesh statik hâllerine geçer. Uygulama tekrar uygun
duruma geldiğinde tek zaman kaynağı üzerinden devam eder; ayrı timer’lar
oluşturulmaz.

## 11. Erişilebilirlik

- Dynamic Type semantik stillerle çalışır; sabit font boyutu eklenmez.
- AX boyutlarında kıvrım düz sol raya dönüşür ve metin tam genişliği kullanır.
- En küçük dokunma alanı 44×44 pt’dir.
- Dekoratif rota, bağlantılar ve düğüm çizimleri VoiceOver’dan gizlenir.
- Satır label’ı gün, başlık ve varsa teknik bilgisini birlikte okur.
- Kilitli adımın hint’i `Henüz açılmadı` olarak kalır.
- Reduce Motion’da rota tamamlanmış görünür; ölçek, otomatik tur ve trim yoktur.
- Reduce Transparency’de düz koyu yüzey kullanılır.
- Normal metinde güvenli bölgede en az 4.5:1 kontrast korunur.

## 12. Dosya sınırları

Planlanan sorumluluklar:

- `JourneyRouteLayout.swift`: Faz duyarlı, deterministik yatay rota geometrisi.
- `JourneyMotionPolicy.swift`: Reduce Motion, scene, güç ve termal duruma bağlı
  tek hareket kararı.
- `JourneyMap.swift`: Ortak satır düzeni ve bileşen kompozisyonu.
- `JourneyMapNode.swift`: Dört düğüm durumu ve tek nefes animasyonu.
- `JourneyPhaseThreshold.swift`: Sessiz faz eşiği.
- `RoadmapView.swift`: F2 gerçek verisini ortak haritaya bağlama ve mevcut tur.
- `MyPathView.swift` / `MyPathViewModel.swift`: Yolum durumu, faz ve teknik
  descriptor’ları.
- `Theme.swift`: Yalnızca paylaşılan hareket ve çizgi token’ları.

F1 `TrailRow` bu çalışmada yeniden tasarlanmaz. F1 ve harita aynı iz metaforunu
korur, fakat farklı ölçeklerde kalırlar.

## 13. Kabul kriterleri

1. F2 ve Yolum aynı Kişisel İz bileşenlerini kullanır.
2. Haritadaki her başlık gerçek üretilmiş path veya belgelenmiş fallback’tir.
3. Gelecek adımlar kilitli fakat okunabilir; sıradaki adım açıkça baskındır.
4. Faz ritmi `PathPhase` verisinden gelir ve rastgele değildir.
5. Ölçüm günleri çift halka ve metinle anlaşılır.
6. İlk görünüş hareketi 800 ms altında tamamlanır; F2 turu tek belgeli istisnadır.
7. Normal koşullarda aktif nefes ve kaydırma 60 fps kabul ölçümünü geçer.
8. Reduce Motion, Reduce Transparency, Low Power, termal baskı ve scene
   değişimleri tanımlanan statik davranışa geçer.
9. AX5’te metin kırpılmaz, üst üste binmez ve rota düz raya dönüşür.
10. Emoji, ödül, streak, sayaç, konfeti, hareketli parçacık veya sonuç vaadi yoktur.
11. Yeni raster varlık veya üçüncü parti bağımlılık eklenmez.
12. `xcodebuild` iPhone 17 Pro hedefinde başarılı olur ve simülatör görsel
    kontrolleri tamamlanır.
