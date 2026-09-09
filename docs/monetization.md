# Patika Monetization Strategy — Global / US

> **Durum:** Onaylanmış lansman monetization tasarımı  
> **Tarih:** 9 Eylül 2026  
> **Pazar:** Global, başlangıç fiyatları USD  
> **Geliştirici profili:** Bireysel Apple Developer hesabı, Enterprise sözleşmesi yok

Bu belge, Patika'nın ücretsiz içeriğini korurken kişiselleştirilmiş path üretiminden
nasıl sürdürülebilir gelir elde edeceğini tanımlar. Rakamlar planlama varsayımıdır;
gerçek dönüşüm ve kullanım verileri geldikçe aynı formüllerle güncellenir.

---

## 1. Yönetici özeti

Patika, lansmanda abonelik-first bir ürün olmayacaktır. Ana gelir modeli,
**tek seferlik kişisel path satın alımıdır**.

- Hazır path'ler, nefes egzersizleri ve SOS ücretsiz kalır.
- Kullanıcıya kişisel path haritası ve **ilk tam kişisel oturum ücretsiz** verilir.
- Path'in kalan kısmı, uzunluğa göre tek seferlik satın almayla açılır.
- İlk sürümde otomatik yenilenen abonelik bulunmaz.
- Abonelik ancak tekrar kullanım talebi ürün verisiyle doğrulanırsa eklenir.
- Reklam, lifetime paket ve sınırsız AI path sunulmaz.

Bu tercih ürün davranışıyla uyumludur: kullanıcı belirli bir sorunla gelir, başlangıcı
ve sonu olan bir program tamamlar, sonra bir süre uygulamaya ihtiyaç duymayabilir.
Kullanıcıyı sırf gelir için sürekli aboneliğe zorlamak yerine, aldığı somut path için
ödeme yapması daha açık ve daha güvenilir bir değer değişimidir.

---

## 2. Neden path-first model

### 2.1 Önerilen model: ücretsiz kütüphane + ücretli kişiselleştirme

| Katman | Kullanıcı ne alır? | Marj etkisi |
|---|---|---|
| **Ücretsiz** | Hazır path'ler, nefes, tek seferlik oturumlar, SOS | Önceden üretilmiş; kullanıcı başına TTS üretimi yok denecek kadar az |
| **Kişisel önizleme** | Kişisel path haritası + ilk tam oturum | Kullanıcı başına yaklaşık $0.19 |
| **Tek path** | Path'in kalan adımları ve kalıcı erişim | Birincil lansman geliri |
| **Üyelik** | Düzenli yeni path + geçmişten öğrenme | Yalnız tekrar talebi kanıtlandıktan sonra |

### 2.2 Reddedilen alternatifler

#### Abonelik + 7 günlük otomatik deneme

Lansmanda kullanılmayacaktır. Kişiselleştirilmiş sesin yedi gün açık olması ücretsiz
kullanıcı maliyetini artırır; kullanıcı henüz ürüne güvenmeden otomatik yenileme
kararı vermek zorunda kalır. Ayrıca Patika'nın abonelik yorgunu hedef kitlesiyle
çelişir.

#### Üç günlük takvim denemesi

Takvim süresi kullanıcıyı acele ettirir. Üç oturumu üç günde tamamlamak zorunda
bırakmak, suçluluk üretmeyen ürün tonuna uymaz. Ücretsiz hak zamanla değil,
**ilk tamamlanan kişisel oturumla** tanımlanır.

#### Kredi/jeton mağazası

Teknik olarak kullanılabilir fakat kullanıcıya gösterilmez. Ruh sağlığı ve iyi oluş
ürününü jeton ekonomisi gibi hissettirmek güveni azaltır. App Store tarafında path
satın alımı tüketilebilir ürün olarak modellenebilir; arayüzde kullanıcı yalnızca
"Bu path'i aç" görür.

---

## 3. Ücretsiz ve ücretli haklar

### 3.1 Ücretsiz katman

- Hazır path kütüphanesi
- Nefes egzersizleri
- SOS ve kriz yönlendirmeleri
- Tek seferlik hazır oturumlar
- Baseline ölçümü
- Kişisel path planı ve bütün gün başlıklarının önizlemesi
- İlk tam kişisel oturum
- Ücretli path yerine ücretsiz hazır path seçebilme

Hazır içeriklerin sesi önceden render edilir. Kullanıcı hazır bir path seçtiğinde
yeniden TTS çağrısı yapılmaz; yalnız bant genişliği ve depolama gideri oluşur.

### 3.2 Tek seferlik kişisel path

- Satın alınan path'in kalan bütün oturumları
- Path içi ölçümler ve sonuç raporu
- Kişiye özel kapanış artifact'i
- Path'e kalıcı erişim
- Uygulama silinse bile hesap üzerinden geri yükleme

### 3.3 Değişmez etik sınırlar

- SOS, kriz yardımı ve uzman desteği yönlendirmesi hiçbir zaman ücretli olmaz.
- Fiyat, kullanıcının sorununun ağırlığına veya yazdığı özel metne göre değişmez.
- Fiyat yalnızca açıkça gösterilen path uzunluğuna bağlıdır.
- Kova C'deki ücretsiz devam hakkı korunur.
- Kullanıcı satın almadan önce toplam fiyatı görür.
- Sahte geri sayım, sahte indirim veya gizli otomatik yenileme kullanılmaz.

---

## 4. Kullanıcı ve paywall akışı

```text
Onboarding ve kişisel değerlendirme
        ↓
Önerilen path uzunluğu + toplam fiyat şeffaflığı
        ↓
Kişisel path haritası oluşturulur
        ↓
İlk tam kişisel oturum ücretsiz tamamlanır
        ↓
Oturum sonu geri bildirimi alınır
        ↓
Tek seferlik "Path'i aç" paywall'ı
        ├─ Satın al → kalan adımlar JIT üretilir
        └─ Şimdi değil → ücretsiz hazır path önerilir
```

Kullanıcının path haritasını oluşturmak ödeme zorunluluğu doğurmaz. Ses üretimi
tam zamanında yapılır: satın alma gerçekleşmeden 2. ve sonraki kişisel oturumlar
render edilmez.

### 4.1 Fiyat şeffaflığı metni

> Sana uygun yolu ücretsiz oluşturacağız. İlk oturum bizden. Devam etmek istersen
> tek sefer ödeme yaparsın; abonelik gerekmez.

### 4.2 Ana paywall örneği — 21 günlük path

**Başlık**

> Bu yol, anlattıklarının etrafında şekillendi.

**Değer açıklaması**

> İlk adımı tamamladın. Önündeki 20 adım; uyku öncesi zihinsel hızlanma,
> kaçınma döngüsü ve sana uygun akşam düzeni üzerine kuruluyor.

**Ana CTA**

> Kalan 20 adımı aç — $14.99 tek sefer

**İkincil CTA**

> Şimdilik ücretsiz hazır bir path seç

Paywall'da abonelik seçeneği lansmanda gösterilmez. Close/geri dönüş görünürdür;
kullanıcı path haritasını ve ücretsiz kütüphaneyi kaybetmez.

---

## 5. Lansman fiyatları

| Path uzunluğu | Liste fiyatı | Kullanıcıya gösterilen değer |
|---|---:|---|
| **7 gün** | **$7.99** | Kısa ve odaklı başlangıç |
| **14 gün** | **$11.99** | Tek davranış döngüsü üzerinde çalışma |
| **21 gün** | **$14.99** | Ana ve önerilen program |
| **28 gün** | **$18.99** | Daha katmanlı program |

Her problem her uzunlukta sunulmaz. Path şablonu güvenli biçimde kısaltılamıyorsa
ucuz seçenek yaratmak için içerik kesilmez. Kullanıcı önerilen uzunluğu düzenlediğinde
fiyat, satın alma öncesinde yeniden ve açıkça gösterilir.

### 5.1 Pazar çıpası

ABD App Store'da Calm $14.99/ay ve $69.99/yıl; Headspace $12.99/ay ve $69.99/yıl
seviyesindedir. Patika'nın $14.99'lık 21 günlük kişisel ürünü, büyük içerik
kütüphaneleriyle fiyat yarışına girmek yerine somut ve kişisel bir sonuç satar.

### 5.2 App Store ürün yapısı

Path'ler tekrar tekrar satın alınabildiği için StoreKit tarafında dört adet
**consumable IAP** kullanılır:

```text
path.unlock.7d     $7.99
path.unlock.14d   $11.99
path.unlock.21d   $14.99
path.unlock.28d   $18.99
```

Kullanıcı arayüzünde kredi veya consumable ifadesi gösterilmez. Doğrulanmış
StoreKit işlemi, sunucuda ilgili `path_id` için kalıcı hakka dönüştürülür. Consumable
işlemler Apple makbuzunda kalıcı restore kaydı sağlamadığından, path sahipliği
sunucuda kullanıcı hesabına yazılır. İşlem doğrulanmadan TTS kuyruğu başlatılmaz.

---

## 6. Bireysel geliştirici için maliyet modeli

### 6.1 Değişken maliyet varsayımları

| Kalem | Planlama değeri | Not |
|---|---:|---|
| fal.ai ElevenLabs Multilingual v2 | **$0.10 / 1.000 karakter** | Pay-as-you-go, minimum abonelik varsayılmadı |
| 21 günlük path taze TTS | **30.600 karakter** | PRD Kademe C |
| LLM | **$0.03 / path** | Sağlayıcı değişimine karşı muhafazakâr rezerv |
| CDN, depolama ve kuyruk | **$0.05–0.13 / path** | Path uzunluğuna göre |
| Ücretsiz ilk oturum | **$0.19 / kayıt** | TTS + LLM planı + küçük altyapı rezervi |

LLM için Mistral veya ücretli Gemini doğrudan kullanılabilir. Monetization hesabı
sağlayıcı seçimine duyarlı değildir; asıl değişken TTS'tir. Gerçek kullanıcı metni
ücretsiz Gemini geliştirme kotasına gönderilmez. API anahtarları uygulamaya gömülmez;
bütün çağrılar backend üzerinden yapılır.

### 6.2 App Store kesintisi

Bireysel geliştiriciler de şartları sağladığında App Store Small Business Program'a
başvurabilir. Program oranı %15'tir. Satış vergileri ve ülke farkları nedeniyle bu
belgede liste fiyatının yalnızca **%70'i planlama geliri** kabul edilir. Bu, doğrudan
%15 çıkarılmasından daha muhafazakâr bir bütçedir.

```text
Planlama geliri = Liste fiyatı × 0.70
```

Gerçek App Store Connect proceeds verisi geldikten sonra `0.70` katsayısı ülke
karışımına göre güncellenir.

### 6.3 Sabit başlangıç giderleri

| Kalem | Aylık planlama bütçesi |
|---|---:|
| Apple Developer üyeliği | $8.25 eşdeğeri ($99/yıl) |
| Backend + veritabanı | $25–75 |
| Log, e-posta, alan adı, küçük servisler | $0–25 |
| **Toplam sabit platform bütçesi** | **$35–110/ay** |

Kurucunun emeği, hukuki/muhasebe desteği ve ücretli reklam bu tabloya dahil değildir.
MVP'de araç sayısı düşük tutulur; aynı işi yapan iki analitik veya iki ödeme altyapısı
birlikte kullanılmaz.

---

## 7. Path başına birim ekonomi

Aşağıdaki tablo doğrudan üretim katkısını gösterir. Kova C garantisi ve iade için
ayrılan risk rezervi bir sonraki bölümde ayrıca düşülür.

| Path | Fiyat | Planlama geliri (%70) | TTS | LLM + altyapı | Katkı | Net gelir üzerinden katkı marjı |
|---|---:|---:|---:|---:|---:|---:|
| 7 gün | $7.99 | $5.59 | $1.02 | $0.08 | **$4.49** | **%80** |
| 14 gün | $11.99 | $8.39 | $2.04 | $0.11 | **$6.24** | **%74** |
| 21 gün | $14.99 | $10.49 | $3.06 | $0.13 | **$7.30** | **%70** |
| 28 gün | $18.99 | $13.29 | $4.08 | $0.16 | **$9.05** | **%68** |

Bu katkı, satın alan kullanıcının ücretsiz ilk oturumunu zaten path TTS toplamının
içinde sayar. Satın almayan kullanıcıların ücretsiz önizleme maliyeti kohort
hesabında ayrıca düşülür.

### 7.1 Etik garanti ve iade rezervi

Doğrudan üretim maliyeti tek başına yeterli bütçe değildir. PRD'deki Kova C
garantisi ve iadeler için 21 günlük path başına şu rezerv ayrılır:

| Rezerv | Hesap | Beklenen maliyet |
|---|---:|---:|
| Kova C ücretsiz devam | %20 olasılık × $2.15 tutarında 14 günlük devam | $0.43 |
| İade/ters ibraz | Planlama gelirinin %3'ü | $0.31 |
| **Toplam risk rezervi** |  | **$0.74** |

Bu rezervle 21 günlük path'in risk ayarlı değişken maliyeti **$3.93**, ücretsiz
edinme maliyeti öncesi katkısı ise **$6.56** olur. Kova C gerçek oranı ve iade verisi
geldiğinde rezerv aylık olarak yeniden hesaplanır; garanti kaldırılarak marj
düzeltilmez.

### 7.2 21 günlük path için başa baş dönüşüm

```text
Ödeyen başına katkı, ücretsiz edinme maliyeti hariç = $10.49 - $3.93 = $6.56
Satın almayan önizleme maliyeti                 = $0.19
Değişken maliyet başa baş dönüşümü              ≈ %2.81
```

Bu eşik sabit işletme giderlerini ve reklam CAC'ini kapsamaz. Lansman hedefi başa baş
değil, kayıt → satın alma için en az **%5** olmalıdır.

---

## 8. 100 / 1.000 / 10.000 kayıt senaryoları

Varsayım: Bütün satın alımlar 21 günlük $14.99 path; planlama geliri liste fiyatının
%70'i; Kova C ve iade rezervi dahil ücretli path maliyeti $3.93; satın almayan
önizleme maliyeti $0.19.

| Kayıt | Dönüşüm | Ödeyen | Planlama geliri | Ücretli path maliyeti | Satın almayan önizlemeleri | **Katkı** |
|---:|---:|---:|---:|---:|---:|---:|
| 100 | %5 | 5 | $52.47 | $19.65 | $18.05 | **$14.77** |
| 100 | %8 | 8 | $83.94 | $31.44 | $17.48 | **$35.02** |
| 100 | %12 | 12 | $125.92 | $47.16 | $16.72 | **$62.04** |
| 1.000 | %5 | 50 | $524.65 | $196.50 | $180.50 | **$147.65** |
| 1.000 | %8 | 80 | $839.44 | $314.40 | $174.80 | **$350.24** |
| 1.000 | %12 | 120 | $1,259.16 | $471.60 | $167.20 | **$620.36** |
| 10.000 | %5 | 500 | $5,246.50 | $1,965.00 | $1,805.00 | **$1,476.50** |
| 10.000 | %8 | 800 | $8,394.40 | $3,144.00 | $1,748.00 | **$3,502.40** |
| 10.000 | %12 | 1.200 | $12,591.60 | $4,716.00 | $1,672.00 | **$6,203.60** |

Katkı; Kova C ve iade rezervini içerir; sabit platform gideri, kurucu emeği ve
ücretli reklam düşülmeden önceki tutardır. %8 dönüşümde kayıt başına yaklaşık
**$0.35** katkı oluşur. Aylık $35–110 sabit platform bütçesini kapatmak için aynı
dönüşümde yaklaşık **100–315 yeni kayıt** gerekir.

### 8.1 Reklam kararı

Organik kayıt başına katkı ve 90 günlük tekrar satın alma ölçülmeden ücretli reklam
ölçeklenmez. İlk reklam testi için:

```text
İzin verilen CAC ≤ doğrulanmış 90 günlük LTV'nin %35'i
Hedef geri ödeme süresi ≤ 3 ay
```

Yalnız ilk satın alma verisi varken güvenli başlangıç CAC tavanı yaklaşık **$2.25**
olur. Bu tavanı aşan kampanya, tekrar satın alma kanıtlanana kadar durdurulur.

---

## 9. Abonelik: lansman ürünü değil, doğrulanacak ikinci aşama

Abonelik yalnız şu koşul sağlandığında açılır:

> Ücretli bir path'i tamamlayan kullanıcıların en az %20'si, 90 gün içinde ikinci
> kişisel path oluşturma niyeti gösterir veya satın alır.

Niyet; "yeni kişisel path oluştur" tıklamasıyla ölçülür. Yalnız anket cevabı yeterli
değildir.

### 9.1 Doğrulama sonrası üyelik fiyatları

| Ürün | Fiyat | Hak |
|---|---:|---|
| Aylık üyelik | **$14.99/ay** | Her 30 günde 1 yeni kişisel path + geçmişten öğrenme |
| Yıllık üyelik | **$79.99/yıl** | Yılda 6 kişisel path + geçmişten öğrenme |
| Üye ek path'i | **$9.99** | Mevcut üyelik sırasında ek tek path |

- Aynı anda yalnızca bir aktif kişisel path bulunur.
- Kullanılmayan aylık hak en fazla bir dönem devreder.
- "Sınırsız path" ifadesi kullanılmaz.
- Üyelik sona erse bile daha önce tek seferlik satın alınmış path'ler kalır.
- Yıllık üyelik, tekrar talebi kanıtlanmadan paywall'a eklenmez.

### 9.2 Yıllık üyelik ekonomisi

Altı adet 21 günlük path'in tamamının kullanıldığı muhafazakâr senaryo:

```text
$79.99 × %70 planlama geliri = $55.99
6 × $3.19 doğrudan maliyet    = $19.14
Kova C rezervi                = $2.58
İade rezervi                  = $1.68
Yıllık risk ayarlı katkı      = $32.59
```

Bu nedenle altı path sınırı korunur; lifetime veya sınırsız yıllık paket verilmez.

---

## 10. Ölçüm planı

### 10.1 Temel event'ler

```text
onboarding_completed
personal_path_plan_created
personal_preview_started
personal_preview_completed
path_paywall_viewed
path_purchase_started
path_purchase_completed
path_purchase_failed
free_ready_path_selected
paid_path_day7_reached
paid_path_completed
second_personal_path_requested
refund_observed
```

Her event; `path_length`, `session_length`, `locale`, `price`, `product_id` ve anonim
kaynak kanalını taşır. Kullanıcının serbest metni analitik event'e yazılmaz.

### 10.2 Lansman hedefleri

| Metrik | İlk kabul eşiği | İyi hedef |
|---|---:|---:|
| Path planı → ücretsiz oturum başlangıcı | %60 | %70+ |
| Ücretsiz oturum tamamlama | %60 | %70+ |
| Kayıt → path satın alma | **%5** | %8–12 |
| Paywall → satın alma | %10 | %15+ |
| Ödeme → 7. güne ulaşma | %55 | %65+ |
| Ödeme → path tamamlama | %40 | %55+ |
| İade oranı | <%5 | <%3 |
| Değişken katkı marjı, ücretsiz önizleme dahil | >%35 | >%50 |
| 90 günde ikinci path isteği | %20 | %30+ |

Kayıt → satın alma %2.8'in altında kalırsa değişken maliyet başa başı tehlikededir;
ücretli edinme kapalı tutulur.

---

## 11. Deney sırası

Aynı anda birden fazla fiyat/ücretsiz hak testi yapılmaz; sonuçların nedeni
karışmamalıdır.

### Deney 0 — baz çizgi

- İlk tam kişisel oturum ücretsiz
- 21 günlük path $14.99
- En az 300 nitelikli paywall görüntülemesi
- Ücretli reklam yok

### Deney 1 — 21 günlük fiyat

- Kontrol: $14.99
- Varyant: $17.99
- Birincil metrik: kayıt başına katkı
- Koruma metrikleri: satın alma dönüşümü, iade, 7. güne ulaşma

Kazanan, daha yüksek dönüşüm değil daha yüksek **kayıt başına katkı** üreten
varyanttır.

### Deney 2 — ücretsiz oturum sayısı

Yalnız kayıt → satın alma %5'in altında, ücretsiz oturum tamamlama ise %60'ın
üstündeyse çalıştırılır:

- Kontrol: 1 tam kişisel oturum
- Varyant: 3 tamamlanmış kişisel oturum
- Takvim süresi kullanılmaz

Varyant, artan TTS maliyetinden daha fazla ek katkı getirmiyorsa reddedilir.

### Deney 3 — paywall değer anlatımı

- Kontrol: kalan adımlar ve tek seferlik fiyat
- Varyant: kullanıcının sonraki iki fazından somut örnek + tek seferlik fiyat
- Fiyat ve ücretsiz hak sabit tutulur

### Deney 4 — üyelik talebi

İlk path sonunda gerçek abonelik satmak yerine "Düzenli kişisel yollar" seçeneğinin
tıklanması ölçülür. %20 90 günlük eşik sağlanırsa StoreKit aboneliği geliştirilir.

---

## 12. Operasyon ve maliyet korumaları

### 12.1 Harcama limitleri

- fal.ai ve LLM sağlayıcısında aylık bütçe alarmı kurulur.
- Günlük TTS karakteri ve kullanıcı başına üretim sayısı backend'de limitlenir.
- Satın alma olmadan yalnızca ilk kişisel oturum render edilir.
- Her zaman bir sonraki oturum JIT hazırlanır; tam path baştan render edilmez.
- Aynı metin ve ayar için idempotency anahtarı kullanılır; retry çift ücret üretmez.
- Başarılı ses CDN'e yazılır ve tekrar TTS çağrısı yapılmaz.
- Path üretimi başarısızsa en fazla bir ücretli retry yapılır; sonra hazır yedeğe düşer.

### 12.2 Basit kişisel geliştirici stack'i

- StoreKit 2 doğrudan kullanılır; lansmanda RevenueCat zorunlu değildir.
- App Store Server Notifications ile iade ve işlem değişiklikleri izlenir.
- Path hakları kullanıcı hesabında backend'de saklanır.
- fal.ai TTS ve LLM anahtarları yalnız sunucuda tutulur.
- Sağlayıcıya yalnız gerekli kişiselleştirilmiş cümle gönderilir; ham onboarding
  metni TTS isteğine eklenmez.
- Sağlayıcı hataları kullanıcıya yeni satın alma yaptırmaz; hak verildiyse üretim
  arka planda yeniden denenir.

---

## 13. Lansman yol haritası

### Hafta 1 — ekonomi ve ürünler

- Dört consumable IAP ürününü App Store Connect'te oluştur
- Small Business Program başvurusunu tamamla
- StoreKit test yapılandırmasını ve sunucu hak modelini kur
- Üretim başına maliyet event'lerini tanımla

### Hafta 2 — ücretsiz önizleme ve paywall

- Yalnız ilk kişisel oturumu JIT üret
- Fiyat şeffaflığı ve tek seferlik paywall akışını uygula
- Ücretsiz hazır path'e dönüş seçeneğini ekle
- Satın alma başarı, hata ve bekleyen işlem durumlarını test et

### Hafta 3 — maliyet koruması

- Kullanıcı/gün karakter limitleri
- Idempotent TTS kuyruğu
- CDN cache ve yeniden deneme davranışı
- Harcama alarmları ve günlük maliyet paneli

### İlk 30 gün — baz çizgi

- Fiyat testi yapmadan önce en az 300 nitelikli paywall görüntülemesi topla
- Kayıt → satın alma, ücretsiz oturum tamamlama ve iade oranını ölç
- Ücretli reklam açma

### 2–3. ay — optimizasyon

- Deney 1'i çalıştır
- Yeterli trafik varsa ücretsiz oturum deneyini koşullu olarak çalıştır
- İkinci path talebini ölç; aboneliği yalnız %20 eşiği geçilirse planla

---

## 14. Karar tablosu

| Karar | Seçim | Gerekçe |
|---|---|---|
| Ana gelir modeli | Tek seferlik path | Ürünün başlangıç/son yapısıyla uyumlu |
| İlk kişisel deneyim | İlk tam oturum ücretsiz | Aha anını gösterir, maliyeti sınırlar |
| Hazır path'ler | Ücretsiz | Edinme ve güven; marjinal AI maliyeti yok |
| 7 günlük trial | Yok | Ücretsiz TTS yükü ve otomatik yenileme sürtünmesi |
| 3 günlük trial | Yok | Takvim baskısı ürün tonuna aykırı |
| Abonelik | Lansmanda yok | Tekrar talebi henüz kanıtlanmadı |
| Üyelik açma eşiği | 90 günde %20 ikinci path isteği | Davranış temelli doğrulama |
| Sınırsız/lifetime | Yok | Sürekli AI maliyeti fiyatlanamaz |
| Reklam | Yok | Güven ve iyi oluş deneyimini bozar |
| Fiyat farklılaştırma | Yalnız path uzunluğu | Şeffaf ve etik |
| TTS | fal.ai üzerinden Multilingual v2 | Bireysel geliştirici için pay-as-you-go |
| App Store kesintisi | Planlamada liste fiyatının %30'u | Vergi + komisyon için muhafazakâr tampon |

---

## 15. Kaynaklar ve fiyat tarihi

- [fal.ai — ElevenLabs Multilingual v2](https://fal.ai/models/fal-ai/elevenlabs/tts/multilingual-v2)
  — $0.10 / 1.000 karakter, 9 Eylül 2026 kontrolü
- [fal.ai model API billing](https://fal.ai/docs/documentation/model-apis/pricing)
  — başarılı çıktı bazlı, prepaid kullanım
- [Apple App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)
  — uygun hesaplarda %15 komisyon
- [Apple StoreKit — persisting a purchase](https://developer.apple.com/documentation/storekit/persisting-a-purchase)
  — consumable satın alımların uygulama/sunucu tarafından kalıcılaştırılması
- [Calm — US App Store](https://apps.apple.com/us/app/calm/id571800810)
  — $14.99/ay, $69.99/yıl fiyat çıpası
- [Headspace — US App Store](https://apps.apple.com/us/app/headspace-sleep-meditation/id493145008)
  — $12.99/ay, $69.99/yıl fiyat çıpası

Model ve mağaza fiyatları hızlı değişir. Her üretim yayını öncesi sağlayıcı sayfaları
yeniden kontrol edilir; fakat ürün kararı tek bir sağlayıcının geçici indirimine göre
değiştirilmez.
