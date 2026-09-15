# Yolum: topoğrafik rota — 15 Eylül 2026

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

## Doğrulama

Swift sözdizimi kontrolü (`swiftc -frontend -parse`) ve kaynak farkında boşluk
kontrolü geçti. Bunlar SDK tür denetimi veya uygulama derlemesi değildir.
15 Eylül ikinci denemede iPhone 16e (iOS 26.0) hedefi ve açıkça belirtilen
`-sdk iphonesimulator` ile uygulama derlemesi geçti (`BUILD SUCCEEDED`).
Simülatörün ana ekranına Computer Use erişimi doğrulandı. Uygulama kurulumu
beklediği için Yolum'un normal/AX5 yerleşimi ve kart geçişlerinin görsel
kontrolü henüz tamamlanmadı. Test hedefi çalıştırılmadı.
