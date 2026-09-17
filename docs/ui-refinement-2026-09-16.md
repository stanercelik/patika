# Patika — uygulama genelinde UI/UX düzenlemesi

## Tasarım yönü

Koyu zemin, kırık beyaz tipografi, kişisel kategori ışığı ve dokunsal görseller.
Yolum'daki topoğrafya; Ben'deki defter; kullanıcının cümlelerinde serif yazı.
Dekorasyon içeriğin yanında yer alır; metnin genişliğini daraltmaz.

## Uygulanan alanlar

- **Ortak kontroller:** `CalmSurface` ile seçim kartı ve yazı alanları aynı
  köşe, koyu yüzey ve kenar dilinde. Seçili durum hem sınır hem işaret taşır.
- **Hareket:** ortak basma stili kısa ve kontrollü; Reduce Motion'da ölçek
  hareketi yerine opacity geri bildirimi verir.
- **Düğmeler:** uzun metinler ortalı sarılır, dokunma alanları en az 44 pt.
- **Onboarding:** kategori seçimi erişilebilir yazı boyutlarında tek sütun;
  soru/cevap/alt aksiyon ayrımı tutarlı. Büyük yazıda çıkışsız ekranlarda boş
  çıkış satırı kaldırılır. Giriş ve oturum sonu içerikleri dikey kaydırılabilir.
- **Metin girişi:** daha geniş iç boşluk, belirgin odak sınırı, daha okunur
  placeholder. Otomatik düzeltme ve kriz sınıflandırma davranışları korunur.
- **Yolum:** önceki rota düzenlemesi devam eder; boş hesapta gerçek başlangıç
  ve yeniden sorgulama seçenekleri vardır. DEBUG hazırlığı bitmeden kök kurulmaz.
- **Ben:** semantik başlıklar, metinden ayrılmış defter görseli, erişilebilir
  boyutta dikey bölüm aksiyonları ve kartlarda ince yönlü kenar aydınlığı.
- **Defter/ölçüm:** ikincil metinlerde daha güçlü kontrast.
- **Ayarlar:** ortak koyu arka plan, semantik gövde ağırlığı, daha rahat satırlar.
- **Oturum:** kısa metin merkezde; uzun metin kaydırılır. Büyük yazıda kontroller
  dikey yerleşir. Kullanıcının kendi sözü ortak serif sesini kullanır.
- **Keşfet:** içerik yokken hatalı arama sonucu metni yerine doğru açıklama ve
  Yolum'a çalışan dönüş. Henüz olmayan bir içerik kütüphanesi oluşturulmadı.

## Görsel referanslar

Mobbin ekranları görüntüleriyle incelendi:
- [Oura — odak seçimi](https://mobbin.com/screens/ca80a1fc-2069-47cc-aed0-9edde69af31b):
  koyu yüzey ve seçili sınır hiyerarşisi.
- [pliability — tercih](https://mobbin.com/screens/7d71bea4-42e6-4cb3-8a97-e13178064ee5):
  kart içeriği ile kalıcı alt aksiyonun ayrımı.
- [Me+ — profil](https://mobbin.com/screens/33472a30-0fa3-4c07-bc2f-2123d3d813e9):
  birbirinden ayrılmış, taranabilir içerik bölümleri.
- [Calm — boş durum](https://mobbin.com/screens/4b4c33cb-b5d7-4ce5-8325-c6206a489601):
  açıklama ve belirgin başlangıç aksiyonu.

İncelenen diğer örneklerin streak, sosyal kıyas ve ödül mekanikleri taşınmadı.

## Kontrol notları

Xcode 27 / iPhone 18 Pro simulator derlemesi başarılı. Test target yok.
Simülatörde A2 normal ve AX5, Ben/Defter üst görünümü, B1 giriş alanı,
AX5 karşılama ekranı, Ayarlar ve boş hesap başlangıç ekranı kontrol edildi. Önceki Yolum kontrolleri `path-home-design.md` içindedir.

Computer Use, yeni Device Hub'a bağlanırken zaman aşımına uğruyor. Bu nedenle
kontroller simctl ile uygulamayı açıp ekran görüntüsü inceleyerek yapılıyor;
dokunma, VoiceOver, klavye etkileşimi ve kare süresi ölçümü tamamlanmış sayılmaz.
Fiziksel telefondaki hesap kaydı incelenmedi. Oturum oynatma ve ödeme/sunucu
akışları bu görsel kontrolün kapsamına alınmadı.
