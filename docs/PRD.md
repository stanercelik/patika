# PRD — Patika (çalışma adı)

**Durum:** Taslak v0.1
**Sahibi:** Novum Apps
**Tarih:** 4 Eylül 2026
**Doküman tipi:** Ürün Gereksinim Dokümanı (uçtan uca)

> **Not:** "Patika" çalışma adıdır. İsim kararı Bölüm 18'de açık soru olarak duruyor.

---

## 1. Tek paragrafta ürün

Patika, kullanıcının kendi sorununu kendi kelimeleriyle anlattığı ve buna karşılık **sonu olan, ölçülen bir program** aldığı bir zihinsel iyi oluş uygulamasıdır. Kullanıcı derdini yazar; uygulama ona 7–28 günlük, adım adım bir yol haritası çıkarır; her adım o kişiye özel üretilmiş rehberli bir meditasyon oturumudur. Programın başında, ortasında ve sonunda aynı yapıda kısa bir ölçüm yapılır. Program bittiğinde kullanıcı "iyi hissettim" demez — **neyin ne kadar değiştiğini sayıyla görür.**

Rakiplerden ayrıştığı yer kişiselleştirme değil (2026'da o bir hijyen faktörü), **kapanışı ve kanıtı olan bir ark** sunması.

---

## 2. Problem

### 2.1 Kullanıcı tarafı

Meditasyon uygulamalarını indiren insanların büyük çoğunluğu 30 gün içinde bırakıyor. Sebepleri:

| Problem | Bugünkü ürünlerin durumu |
|---|---|
| "Nereden başlayacağımı bilmiyorum" | Yüzlerce başlıklı kütüphane, seçim felci |
| "Bu benim sorunuma değmiyor" | Genel içerik, herkese aynı ses kaydı |
| "İşe yarıyor mu bilmiyorum" | Hiçbir ölçüm yok, sadece streak sayısı |
| "Ne zaman biteceğini bilmiyorum" | Sonsuz kütüphane, bitiş çizgisi yok |
| "Kaçırdığımda kendimi kötü hissediyorum" | Streak sıfırlanır, suçluluk üretir |

### 2.2 Neden şimdi

- AI ile kişiye özel içerik üretmenin marjinal maliyeti oturum başı ~€0.05'e indi
- Kategoride D2C büyüme yavaşladı; farklılaşma içerik hacminden **sonuç iddiasına** kayıyor
- Rakiplerin hiçbiri öncesi/sonrası ölçüm yapmıyor — açık bir boşluk

### 2.3 Kanıt durumu (dürüst)

Bu PRD şu an **kanıt eksikliğiyle** yazılıyor. Elimizde 0 kullanıcı görüşmesi, 0 davranışsal veri var. Aşağıdaki her şey hipotezdir. Faz 0 (Bölüm 16) tam olarak bu boşluğu kapatmak için var. Kod yazmadan önce en az 10 problem görüşmesi yapılmadan Faz 1'e geçilmemeli.

---

## 3. Hedef kullanıcı

### Birincil persona — "Ne yapacağını bilmeyen ama arayan kişi"

- 22–38 yaş, şehirli, yüksek öğrenim
- Belirgin ve isimlendirilebilir bir sıkıntısı var: sınav kaygısı, iş tükenmişliği, uykuya dalamama, ayrılık sonrası, sosyal kaygı
- Terapiye gitmiyor (maliyet, sıra, damgalanma, "bu kadar da ciddi değil" hissi)
- Daha önce en az bir meditasyon uygulaması indirmiş ve bırakmış
- Ödeme gücü var ama abonelik yorgunluğu yaşıyor

### İkincil persona — "Dönen kişi"

Daha önce bir path bitirmiş, aylar sonra aynı ya da yeni bir sorunla geri dönen kullanıcı. **LTV'nin ana kaynağı bu personadır** (Bölüm 12.5).

### Hedef dışı (v1)

- Klinik tanı almış ve tedavi gören kişiler → ürün bu grubu hedeflemez, karşılaşınca yönlendirir
- 18 yaş altı → v1'de kapalı
- Deneyimli meditasyon pratisyenleri → onlar timer ister, program değil
- Kurumsal / B2B2C → v3'ten önce hayır

---

## 4. Konumlandırma

**Ana mesaj:** "Streak yok. Suçluluk yok. Sonu ve kanıtı olan bir yol."

**Kategori cümlesi:** Kütüphane değil, program. Podcast değil, ölçülen bir süreç.

**Rakip haritası:**

| Rakip | Onların modeli | Bizim farkımız |
|---|---|---|
| Calm, Headspace | Büyük kütüphane + kürasyon | Bitişi ve ölçümü olan ark |
| StillMind, ELYND, MediTailor, InTheMoment | Anlık AI üretimi, tek oturum | Oturum değil, çok günlü yapılandırılmış program |
| Zorio, Ube | Streak + karakter gamification | Kayıp kaçınması yok; ilerleme geri gitmez |
| Finch | Alışkanlık + sanal evcil hayvan | Alışkanlık değil, sorun çözme |
| ChatGPT (gerçek rakip) | Bedava, sınırsız sohbet | Ses + ritüel + yapı + ölçüm |

**Söylemeyeceğimiz şeyler:** "Terapi", "tedavi", "iyileştirir", "klinik olarak kanıtlanmış", "anksiyeteni geçirir". Bunlar hem yanlış hem de mağaza reddi ve düzenleyici risk sebebi.

---

## 5. Non-goals (v1'de yapmayacaklarımız)

Bunlar unutulduğu için değil, **bilinçli olarak** kapsam dışı:

- Sosyal özellikler, arkadaş ekleme, topluluk, paylaşım akışı
- Lig, sıralama tablosu, kullanıcılar arası kıyaslama
- Streak ve can/enerji sistemi
- Wearable entegrasyonu (Apple Health, Oura, uyku evresi algılama)
- Canlı terapist/koç bağlantısı veya randevu alma
- Metin sohbet arayüzü (chatbot) — ürün sohbet değil, program
- Çoklu dil (v1: TR + EN)
- Tablet / web / masaüstü
- Uykuda ses çalma, TMR, subliminal içerik
- Kurumsal panel, B2B satış

---

## 6. Bilgi mimarisi

```
┌─ Onboarding (ilk açılış)
│   └─ Karşılama → Sorun girişi → Baseline ölçüm → Path önerisi → Path başlangıcı
│
├─ ANA SEKME: Yolum
│   ├─ Aktif path haritası (dikey, kaydırmalı)
│   ├─ Günün adımı (birincil CTA)
│   ├─ Ara ölçüm kartları (7. / 14. gün)
│   └─ Path sonu raporu
│
├─ SEKME: Keşfet
│   ├─ Hazır path'ler (ücretsiz)
│   ├─ Tek seferlik oturumlar
│   └─ Nefes egzersizleri
│
├─ SEKME: Ben
│   ├─ Tamamlanan path'ler + rozetler
│   ├─ İlerleme grafikleri (tüm zamanlar)
│   ├─ Kaydedilmiş kişisel oturumlarım
│   └─ Ayarlar / Gizlilik / Abonelik
│
├─ HER EKRANDA: SOS butonu (sağ üst, sabit)
└─ MENÜDE HER ZAMAN: "Destek al" (Bölüm 11)
```

---

## 7. Ekran ekran akış

### 7.1 Onboarding — Karşılama (3 ekran, atlanabilir)

Amaç: beklenti kurmak, yanlış kullanıcıyı erkenden ayırmak.

1. "Sana özel bir yol çizeceğiz. Ama önce seni tanımamız lazım."
2. "Bu bir kütüphane değil. Başı, ortası ve sonu olan bir program. Sonunda ne değiştiğini birlikte göreceğiz."
3. "Bu bir terapi değil ve terapinin yerini tutmaz. Zor bir dönemdeysen, bir uzmanla konuşmak en iyisi olabilir — bunun için de sana yardımcı olacağız."

**Hesap açma burada YOK.** İlk değer görülmeden kayıt istemiyoruz. Kayıt, 3. adım tamamlandıktan sonra ("ilerlemeni kaydedelim mi?") isteniyor.

### 7.2 Onboarding — Sorun girişi

İki mod, kullanıcı seçer:

**Mod A — Yazarak (birincil)**

> **"Şu an seni en çok ne zorluyor?"**
> Serbest metin, 20–500 karakter.
> Alt metin: *"İstediğin kadar kısa ya da uzun yaz. Kimse okumuyor, sadece sana bir yol çizmek için kullanılıyor."*

Takip soruları (metin analiz edildikten sonra, 3 adet, tek tek):

| # | Soru | Tip |
|---|---|---|
| 1 | "Bu ne kadar zamandır böyle?" | Tek seçim: Birkaç gün / Birkaç hafta / Aylardır / Yıllardır |
| 2 | "En çok ne zaman ortaya çıkıyor?" | Tek seçim: Sabah / Gün içinde / Akşam / Yatarken / Belirsiz |
| 3 | "Bu yüzden yapmaktan kaçındığın bir şey var mı?" | Serbest metin, atlanabilir |

**Mod B — Seçerek (ikincil, "yazmak istemiyorum" diyene)**

Kart ızgarası, çoklu seçim (maks 2):
Kaygı · Uykusuzluk · Tükenmişlik · Odaklanamama · Öfke · Kendime sert davranma · Sosyal ortamlar · Ayrılık / kayıp · Sınav / performans · Belirsiz bir huzursuzluk

Ardından aynı 3 takip sorusu.

**Kritik:** Bu adımda metin **kriz sınıflandırıcısından geçer** (Bölüm 11). Sinyal varsa akış durur, path üretilmez.

### 7.3 Onboarding — Baseline ölçüm

Tam tasarım Bölüm 8'de. Onboarding'de 8 soru, ~60 saniye. Ekranda süre göstergesi olsun ("1 / 8").

Bitişte kullanıcıya **hiçbir skor gösterilmez.** Sadece: *"Teşekkürler. Bunları 7. günde tekrar soracağız — farkı görmek için."*

> Gerekçe: Baştan skor göstermek kullanıcıyı etiketler ("kaygı skorun 68") ve sonraki cevaplarını çapalar. Skorlar ilk kez 7. günde, karşılaştırmalı olarak gösterilir.

### 7.4 Path önerisi ekranı

Kullanıcının kendi kelimelerini geri yansıtan bir özet + öneri:

> **"Anladığım kadarıyla:**
> Akşamları yatağa girdiğinde zihnin hızlanıyor ve bu birkaç aydır sürüyor. Bu yüzden yatma saatini erteliyorsun.
>
> **Senin için önerdiğim yol: 21 günlük 'Zihni akşam yavaşlatma' patikası.**
> 21 adım · Günde 8–12 dakika · İlk 3 adım ücretsiz"

Butonlar: **Bu yolu başlat** / *Yolu düzenle* / *Farklı bir şey anlatmak istiyorum*

"Yolu düzenle": süre (7/14/21/28), günlük oturum uzunluğu (5/10/15 dk), sesli/sessiz tercihi.

### 7.5 Path haritası (ana ekran)

Dikey, yukarıdan aşağı akan yol. **Tüm adımlar 1. günden itibaren görünür.**

- **Tamamlanan adımlar:** dolu, işaretli
- **Bugünün adımı:** vurgulu, büyük CTA
- **Kilitli adımlar:** soluk ama **başlıkları okunur**
  - Örn: `Gün 12 — Kaçınmayla yüzleşme` · `Gün 18 — Uyku öncesi protokol`
- **Ölçüm noktaları:** 1 / 7 / 14 / son günde belirgin işaret

> **Tasarım kararı:** Kilitli adım başlıklarını göstermek, "geride ne bıraktığını bilmek" hissini yaratır. Bu, streak'in yerini alan ana ilerleme mekaniğidir. Duolingo'nun iyi tarafı budur; kötü tarafı (kayıp kaçınması) alınmaz.

**Kaçırılan gün davranışı:** Hiçbir şey sıfırlanmaz, geri gitmez, uyarı çıkmaz. Kullanıcı 5 gün sonra döndüğünde ekran: *"Buradasın. Kaldığın yerden devam edelim."* Nokta. Suçluluk dili yok, "seni özledik" yok.

### 7.6 Günlük oturum akışı

```
[Adıma dokun]
  ↓
Ön kontrol (tek soru, 5 sn)
  "Şu an nasılsın?" → 5 emoji ölçek
  ↓
Oturum ekranı
  - Minimal: dalga animasyonu + kalan süre + duraklat
  - Arka planda ses manzarası, üstte rehber ses
  - Ekran otomatik karartılır (15 sn sonra)
  ↓
Oturum sonu
  - "Nasıl geçti?" → 3 seçenek: İyi geldi / Zorlandım / Odaklanamadım
  - (Bu cevap sonraki adımın kişiselleştirmesine girer)
  ↓
Mikro-kapanış
  - Tek cümlelik bir not veya soru
  - "Yarın: [sonraki adımın başlığı]"
  ↓
Haritaya dön (adım dolar, animasyon)
```

**"Zorlandım" veya "Odaklanamadım" üst üste 3 kez gelirse:** sonraki adım otomatik olarak daha kısa ve daha yönlendirmeli bir bloğa düşürülür. Kullanıcıya sessizce uyarlanır, "başaramadın" denmez.

### 7.7 Ara ölçüm — 7. gün (ÖDEME DUVARI BURADA)

Akış sırası kritik. Ölçüm **önce**, paywall **sonra**.

```
Gün 7 adımı tamamlanır
  ↓
"Bir haftadır buradasın. Aynı soruları tekrar soralım."
  ↓
Ölçüm (8 soru, madde ifadeleri döndürülmüş — Bölüm 8.3)
  ↓
KARŞILAŞTIRMA EKRANI  ← ürünün en önemli ekranı
  ↓
PAYWALL
```

**Karşılaştırma ekranı içeriği:**

```
7 günde neredesin

Kaygı şiddeti        ▓▓▓▓▓▓░░░░  −30%   ↓ iyileşme
Uykuya dalma         ▓▓▓▓▓▓▓░░░  −22%   ↓ iyileşme
Öz-yeterlik          ▓▓▓▓▓░░░░░  +18%   ↑ iyileşme
Kaçınma davranışı    ▓▓▓▓▓▓▓▓▓░   −3%   → neredeyse aynı

"Nefes ve topraklama tekniklerin oturmuş. Kaygının şiddeti
belirgin şekilde düşmüş.

Ama kaçınma davranışın neredeyse hiç değişmemiş — o düşünce
geldiğinde hâlâ konuyu değiştiriyorsun.

Kalan 14 gün tam olarak bunun üzerine kurulu."
```

Sonra paywall:

```
Devam etmek için

  Bu patikayı tamamla          €14.99  (tek seferlik)
  ─────────────────────────────────────
  Sınırsız patika              €12.99/ay
  + geçmişin korunur, seni tanımaya devam eder

  [Devam et]     [Şimdilik burada duralım]
```

> **Neden 7. gün:** Meditasyonun etkisi tipik olarak 7–10. günde hissedilir. 3. günde duvara çarpan kullanıcı henüz hiçbir fayda hissetmemiştir → dönüşüm düşer. 14. günde değerin çoğu alınmış olur → dönüşüm de düşer, LTV de.
>
> **Neden ölçümden sonra:** Kullanıcı "işe yarıyor mu" sorusunu ürünün iddiasıyla değil, **kendi verisiyle** cevaplamış olur. Bu, dönüşümü en çok artıran tek tasarım kararıdır.
>
> **Neden kısmi ilerleme gösterilir:** Tam başarı bildirisi kapanış hissi yaratır → kullanıcı gider. İsimlendirilmiş bir eksik, açık döngü bırakır.

**"Şimdilik burada duralım" diyene:** Suçlandırma yok. *"Tamam. İstediğin zaman buradan devam edebilirsin — yolun kayıtlı kalıyor."* → 3. gün, 10. gün ve 30. günde birer nazik hatırlatma, sonra sus.

### 7.8 Ara ölçüm — 14. gün

Paywall yok, sadece trend gösterimi. Üç nokta (1/7/14) çizgi grafiği.

> Gerekçe: İki nokta karşılaştırması ortalamaya dönüş yanılsamasına açık. Üç nokta trend gösterir, çok daha güvenilir.

### 7.9 Path sonu raporu — üç kova

Son ölçüm alınır, sonuç **üç kovadan birine** düşer. `başarılı/başarısız` dili **hiçbir yerde kullanılmaz.**

#### Kova A — Belirgin ilerleme
(Bileşik skorda ≥%25 iyileşme veya ≥2 alt boyutta ≥%30)

```
21 gün önce ve bugün

[öncesi/sonrası grafik]

En çok değişen: uykuya dalma süresi (−41%)
En az değişen: sabah kaygısı (−8%)

Kazandığın: "Gece protokolün" — senin kendi cümlelerinden
oluşturulmuş 3 dakikalık kayıt. Abonelik bitse bile sende kalır.

[Kaydı indir]   [Rozeti gör]   [Sırada ne var?]
```

#### Kova B — Kısmi ilerleme
(%10–25 iyileşme veya karışık sinyal)

```
Bazı şeyler değişti, bazıları henüz değil.

İlerlediğin yer: kaygının şiddeti (−19%)
Duran yer: kaçınma davranışın (−2%)

Bazen yol düşündüğümüzden uzun olur — bu normal ve
sık görülen bir şey.

Bu ikinci kısım kaçınma üzerine kurulu:
[14 günlük devam patikası]
```

#### Kova C — İlerleme yok veya geriye gidiş
(≤%5 değişim veya herhangi bir boyutta kötüleşme)

```
Bu üç haftada sayılar pek değişmemiş — bazıları
biraz da kötüleşmiş.

Bu senin başarısızlığın değil. Bazen bu tür şeyler
uygulamayla çözülmüyor, ve bunu erken fark etmek iyi.

Bir uzmanla konuşmayı düşünmek isteyebilirsin.

    [Yakınımdaki psikologlar]
    [Nasıl uzman bulunur?]

İstersen devam da edebiliriz — bu sefer farklı bir
yaklaşımla, ve ücretsiz.

    [Devam patikasına geç — ücretsiz]
```

> **Kritik ticari karar:** Kova C'de **satış yapılmaz** ve devam patikası **ücretsizdir**.
>
> Bunun üç gerekçesi var:
> 1. **Etik:** İyileşmemiş kullanıcıya daha fazla ürün satmak, ürünü kullanıcının aleyhine çalıştırmaktır.
> 2. **Teşvik hizalaması:** "İşe yaramazsa devamı bizden" modelinde şirket **sadece kullanıcı iyileştiğinde** para kazanır. Bu, içeriden kalite baskısı yaratır.
> 3. **Pazarlama:** Bu cümleyi Calm da Headspace de Zorio da söyleyemez, çünkü hiçbiri sonuç ölçmüyor. Kategorinin en büyük şüphesine (bu uygulamalar işe yaramıyor) doğrudan cevap.
>
> **Suistimal sınırı:** Kullanıcı başına ömür boyu 2 ücretsiz devam. Ayrıca ölçüm sadece öz-bildirime dayanmaz (Bölüm 8.2), bu manipülasyonu zorlaştırır.

### 7.10 Yeni path'e geçiş

Path sonunda üç seçenek:

1. **Devam patikası** — aynı sorunun bir sonraki katmanı (AI önerir)
2. **Hazır patika seç** — kütüphaneden, ücretsiz
3. **Yeni bir şey anlat** — 7.2'ye döner, yeni özel path

Abonelik yukarı satışı burada yapılır (memnuniyetin zirvesi), **indirimle değil, farkla:**

> "Tek tek almak: her patika €14.99
> Abonelik: €12.99/ay — ve geçmişin korunuyor. Bir sonraki patika, bu üç haftada öğrendiklerimizin üstüne kurulur."

> **Neden indirim yok:** Her geçişte indirim verirsen kullanıcı indirimi beklemeyi öğrenir ve tam fiyat anlamını yitirir. Aboneliğin farkı ucuzluk değil, **süreklilik** olmalı.

### 7.11 Keşfet sekmesi

- **Hazır path'ler** (ücretsiz, önceden üretilmiş, AI maliyeti sıfır): "7 günde nefes temelleri", "14 günde uyku rutini", "10 günde sabah sakinliği" vb.
- **Tek seferlik oturumlar** (ücretsiz): 5–15 dk, kategorilere göre
- **Nefes egzersizleri** (ücretsiz, sıfır maliyet): kutu nefesi, 4-7-8, koherans — sadece animasyon

> Bu katman edinme motorudur ve ASO yakıtıdır. Pahalı ve değerli olan şey — kişiselleştirme — paralı tarafta kalır.

### 7.12 SOS

Her ekranda sağ üstte sabit. İki dokunuşta ses başlar.

- 60–90 saniyelik acil sakinleşme oturumları
- Önceden üretilmiş, ücretsiz, çevrimdışı çalışır
- Panik, öfke, uyuyamama, ağlama krizi için ayrı varyantlar
- Ekranda tek bir büyük nefes animasyonu, başka hiçbir şey yok

> En yüksek duygusal bağ yaratan içerik türü budur, çünkü ihtiyaç anında açılır. Asla ücretli olmamalı.

### 7.13 Ben sekmesi

- Tamamlanan path'ler, her biri rozet + o path'in öncesi/sonrası farkı ile
- Tüm zamanlar ilerleme grafiği (tüm ölçümler tek çizgide)
- Kaydedilmiş kişisel oturumlar (indirilebilir, abonelik bitse bile kalır)
- Ayarlar: bildirimler, ses tercihi, dil, **veri indirme**, **hesap silme**, abonelik yönetimi

---

## 8. Ölçüm sistemi

Ürünün kalbi bu. Yanlış tasarlanırsa hem işe yaramaz hem yasal risk yaratır.

### 8.1 Tasarım ilkeleri

- **Klinik ölçek kullanılmaz.** GAD-7, PHQ-9, PSS gibi ölçekler doğrudan kullanılmaz. Sebep: (a) lisans meselesi, (b) skor üretip yorumlamak tıbbi cihaz düzenlemesine doğru kaydırır, (c) teşhis imasına yol açar.
- **Kendi ölçeğimizi kurarız**, kanıta dayalı yapıları referans alarak ama birebir kopyalamadan.
- **Her ekranda çerçeve dili:** *"Bu bir klinik değerlendirme değildir. Amacı sadece kendi değişimini görmen."*
- Skorlar **asla mutlak olarak yorumlanmaz** ("kaygı skorun 68 — yüksek"). Sadece **kendi içinde karşılaştırılır** ("7 gün öncesine göre %30 düşük").

### 8.2 Üç katman

Sadece "nasıl hissediyorsun" sormak yetersiz — en oynak ve en manipüle edilebilir katman odur.

| Katman | Ne ölçer | Ağırlık | Örnek madde |
|---|---|---|---|
| **Duygu şiddeti** | Öznel yoğunluk | %30 | "Son 3 günde bu his ne kadar güçlüydü?" (0–10) |
| **Davranış** | Gözlemlenebilir çıktı | %40 | "Dün gece uykuya dalman ne kadar sürdü?" (dakika) |
| **Öz-yeterlik** | Baş edebilme algısı | %30 | "Bu his geldiğinde ne yapacağımı biliyorum." (1–5) |

> **Davranış katmanı en yüksek ağırlığı alır** çünkü en sağlam sinyaldir ve en zor manipüle edilir. **Öz-yeterlik** meditasyonun en gerçekçi çıktısıdır ve genelde en hızlı iyileşen boyuttur — bu, erken ölçümde pozitif sinyal üretme ihtimalini artırır.

### 8.3 Madde rotasyonu

Baştaki ve sondaki test **aynı yapıda ama birebir aynı ifadelerle değil.**

- Her boyut için 3 eşdeğer madde havuzu tutulur
- Ölçüm 1: A varyantı · Ölçüm 2: B · Ölçüm 3: C · Ölçüm 4: A
- Skorlama aynı, ifade farklı

> Gerekçe: İnsanlar ne cevap verdiklerini hatırlar ve "ilerlemiş görünme" eğilimine girer. Rotasyon bunu azaltır.

### 8.4 Ortalamaya dönüş problemi

İnsanlar en kötü hissettikleri gün uygulamayı indirir. 3 hafta sonra hiçbir şey yapmasalar da skorları düzelir. Yani ölçtüğümüz iyileşmenin bir kısmı **istatistiksel yanılsamadır.**

Azaltma yöntemleri:
- Baseline'ı tek noktada değil, **ilk 2 günün ortalaması** olarak al
- 4 ölçüm noktası (1/7/14/son) — trend, iki nokta farkından güvenilir
- İç raporlamada asla "uygulamamız X iyileştirdi" deme; "kullanıcılar X değişim bildirdi" de

### 8.5 Path tipine göre özelleşme

Her path tipinin kendi davranış maddesi vardır:

| Path tipi | Davranış maddesi |
|---|---|
| Uyku | Uykuya dalma süresi (dk), gece uyanma sayısı |
| Sınav / performans | Kaçınılan çalışma seansı sayısı |
| Sosyal kaygı | Reddedilen sosyal davet sayısı |
| Tükenmişlik | Mola alabilme, iş dışında iş düşünme sıklığı |
| Öfke | Pişman olunan tepki sayısı |

### 8.6 Ölçüm uzunlukları

| Nokta | Soru sayısı | Süre |
|---|---|---|
| Baseline (gün 1) | 8 | ~60 sn |
| Ara (gün 7) | 8 | ~60 sn |
| Ara (gün 14) | 6 | ~45 sn |
| Son | 8 | ~60 sn |
| Günlük ön kontrol | 1 | 5 sn |

---

## 9. Path mimarisi

### 9.1 AI'ın rolü — ve sınırı

**AI sıfırdan içerik icat etmez.** Onaylanmış tekniklerden oluşan bir blok kütüphanesinden **seçer, sıralar ve kişiselleştirir.**

```
Kullanıcı girdisi
    ↓
[Sınıflandırma] → sorun tipi, şiddet, zamanlama, kaçınma var mı
    ↓
[Kriz kontrolü] → sinyal varsa AKIŞ DURUR (Bölüm 11)
    ↓
[Path şablonu seçimi] → sorun tipine göre iskelet
    ↓
[Blok seçimi + sıralama] → kütüphaneden N adet, uygun sırayla
    ↓
[Kişiselleştirme katmanı] → kullanıcının kendi kelimeleri, örnekleri,
                              zamanlaması metne işlenir
    ↓
[Güvenlik kontrolü] → çıktı taranır
    ↓
[Ses üretimi] → hibrit (Bölüm 13.2)
```

**Gerekçe:** Path yapısını tamamen modele bırakmak üç sorun üretir — kalite tutarsızlığı, fiyatlanamaz değişkenlik (birine 9 adım, diğerine 34), ve güvenlik riski. Blok kütüphanesi üçünü de çözer ve maliyeti düşürür.

### 9.2 Blok kütüphanesi (v1)

Her blok: teknik + hedef + süre aralığı + zorluk + ön koşul.

| Kategori | Bloklar |
|---|---|
| **Temel** | Nefes farkındalığı, kutu nefesi, 4-7-8, koherans nefesi, topraklama (5-4-3-2-1) |
| **Beden** | Body scan (kısa/uzun), progresif kas gevşetme, gerilim tarama |
| **Bilişsel** | Düşünceden ayrışma, düşünce etiketleme, "bu bir düşünce" pratiği, endişe erteleme |
| **Kabul** | Zor duyguya yer açma, öz-şefkat, "izin verme" pratiği |
| **Davranışsal** | Kaçınmayla kademeli yüzleşme, mikro-eylem planlama, tetikleyici haritalama |
| **Uyku** | Uyku öncesi kapanış, zihinsel boşaltma, yatak-uyku bağı |
| **Kapanış** | Günü kapatma, niyet belirleme, öğrenilenin özeti |

**v1 hedefi: ~40 blok.** Her blok TR + EN metin şablonu olarak yazılır.

### 9.3 Path şablonları

Sabit uzunluk kovaları: **7 / 14 / 21 / 28 gün.**

> "Sana özel 19 günlük patika" satılamaz; "21 günlük program" satılır. Fiyatlandırma, beklenti yönetimi ve pazarlama sabit kovayı gerektirir.

Standart 21 günlük ark:

| Gün | Faz | Amaç |
|---|---|---|
| 1–3 | **Rahatlama** | Hızlı etki, güven inşası, "işe yarıyor" hissi |
| 4–7 | **Farkındalık** | Tetikleyicileri görme, örüntü fark etme |
| 7 | **ÖLÇÜM + PAYWALL** | — |
| 8–14 | **Beceri** | Teknikleri gerçek duruma uygulama |
| 14 | **ÖLÇÜM** | — |
| 15–20 | **Davranış** | Kaçınmayla yüzleşme, asıl değişim |
| 21 | **Kapanış + ÖLÇÜM** | Rapor, artifact, sonraki adım |

> **Tasarım kararı:** Zor ve en değerli içerik arka yarıda. Hem pedagojik olarak doğru (temel olmadan ileri teknik çalışmaz) hem de "bu kadarı yeter" hissini geciktirir.

### 9.4 Uyarlanabilirlik

Path oluşturulduktan sonra donmuş değil:

- 3 kez üst üste "zorlandım" → sonraki blok daha kısa ve daha yönlendirmeli
- 3 kez üst üste "odaklanamadım" → süre kısaltılır, aktif blok (nefes) tercih edilir
- 7. gün ölçümünde bir boyut hiç değişmemiş → kalan adımlar o boyuta ağırlık verir
- 5+ gün ara verilmiş → dönüşte bir "yeniden ısınma" adımı eklenir

Kullanıcıya bunların hiçbiri "seni geriye aldık" diye sunulmaz. Sessizce uyarlanır.

---

## 10. Gamification spec

**Çalışacaklar:**

| Mekanik | Nasıl |
|---|---|
| Görünür path haritası | Tüm adımlar 1. günden görünür, kilitli olanların başlıkları okunur |
| Rozet | Her tamamlanan path için; üstünde o path'in öncesi/sonrası farkı yazar |
| Ölçüm ekranı | Asıl ödül mekaniği bu — ayrı puan sistemine gerek yok |
| Doğal kilit | İleri teknikler öncekiler yapılmadan açılmaz (yapay değil, gerçekten öyle) |
| Koleksiyon | Biriken rozetler zamanla kişinin kendi haritasını oluşturur |
| Kalıcı artifact | Path sonunda kişiye özel 3 dk'lık kayıt, indirilebilir, kalıcı |

**Kullanılmayacaklar ve neden:**

| Mekanik | Neden hayır |
|---|---|
| Streak | Kaygı ürününde kayıp kaçınması = manufacture edilmiş kaygı |
| Lig / sıralama | Sosyal kıyaslama bu kitlede toksik |
| Can / enerji sistemi | Yapay kıtlık, dark pattern |
| "Seni özledik" bildirimleri | Suçluluk üretir |
| Sıfırlanan ilerleme | İlerleme asla geri gitmez |

---

## 11. Güvenlik ve kriz protokolü

> Bu bölüm opsiyonel değildir. Hem etik zorunluluk hem mağaza onay şartı hem de şirketi batırabilecek sorumluluk riski.

### 11.1 Kriz tespiti

Kullanıcının yazdığı **her serbest metin**, path üretilmeden önce sınıflandırıcıdan geçer:

- İntihar düşüncesi / kendine zarar verme
- Başkasına zarar verme
- İstismar, şiddet, taciz bildirimi
- Ağır madde kullanımı
- Yeme bozukluğu işaretleri
- Akut psikoz / gerçeklikten kopma işaretleri

**Sinyal varsa:** Path üretilmez. AI oturum yazmaz. Ekran değişir:

```
Yazdığın şey ciddi ve önemli.

Bu uygulama bu konuda sana yardımcı olabilecek doğru
yer değil — ama yardım alabileceğin yerler var.

    [Acil yardım hattı — tek dokunuş, arama başlatır]
    [Yakınımda destek bul]

İstersen sakinleşmene yardımcı olabilecek kısa bir
nefes egzersizi de var.

    [Nefes egzersizi]
```

Yerelleştirme zorunlu: TR, DE, EN için ayrı hat numaraları, ülkeye göre otomatik.

### 11.2 Sistem prompt sınırları

Üretim yapan modelin sistem prompt'unda kesin sınırlar:

- Teşhis koymaz, teşhis ima etmez
- İlaç önermez, ilaç hakkında yorum yapmaz
- "İyileşeceksin", "geçecek" gibi garanti vermez
- Travma anlatısını deşmez, detay istemez
- Terapötik müdahale (EMDR, maruz bırakma vb.) yapmaz
- Kullanıcının kendi kelimelerini kullanır ama yorumlamaz

Çıktı da ikinci bir güvenlik kontrolünden geçer.

### 11.3 "Destek al" özelliği

**Konum:** Menüde **her zaman** görünür. Sadece "ilerleme yok" ekranında değil.

> Gerekçe: Butonun sadece kötü sonuçta belirmesi onu "başarısız oldun" sinyaline çevirir ve terapiyi ceza olarak kodlar. Her zaman oradaysa, kötü günde açmak normal bir hareket olur.

**İçerik:**

1. **Acil durum** (üstte): Ülkeye göre yardım hattı, tek dokunuş arama
2. **Uzman bul:** Resmî dizin bağlantısı **birincil**, harita ikincil
   - TR: Türk Psikologlar Derneği / TPD üye dizini
   - DE: therapie.de, KV-Terminservice (Kassensitz ve bekleme listesi bilgisiyle)
   - Diğer: Google Maps "yakınımdaki psikolog" fallback
3. **Nasıl uzman bulunur?** — kısa açıklayıcı: ne beklemeli, ne sormalı, maliyet, sigorta

> **Harita neden ikincil:** "Psikolog" araması ülkeye göre çok değişken sonuç veriyor — koçlar, sertifikasız danışmanlar, kapanmış ofisler karışıyor. Almanya'da ayrıca Kassensitz ve aylarca bekleme listesi var; sadece konum göstermek yanıltıcı.

**Mutlak kurallar:**

- ❌ Bu özellik **asla paraya çevrilmez** — yönlendirme komisyonu yok, terapist reklamı yok, "önerilen partner" yok. Bu açıkça yazılır.
- ❌ **Ödeme duvarının arkasında olmaz.** Hiçbir koşulda.
- ❌ Kriz anında harita açılmaz — gece 3'te panikteki birine harita işe yaramaz, ona numara lazım.

### 11.4 Yaş sınırı

18+. Kayıt sırasında doğum tarihi. Mağaza yaş derecelendirmesi buna göre.

---

## 12. Fiyatlandırma

### 12.1 Katmanlar

| Katman | İçerik | Fiyat |
|---|---|---|
| **Ücretsiz** | Hazır path'ler, tek seferlik oturumlar, nefes egzersizleri, SOS, ilk 6 adım (özel path'te), tüm ölçümler, Destek al | €0 |
| **Tek patika** | Bir adet kişiye özel path, tamamı + artifact | €14.99 |
| **Abonelik (aylık)** | Sınırsız kişisel path + süreklilik + hafıza | €12.99/ay |
| **Abonelik (yıllık)** | Aynısı | €79/yıl (€6.58/ay) |

### 12.2 Aboneliğin farkı ucuzluk değil, süreklilik

Bu ayrım hem dürüst hem de doğal bir yukarı satış yolu açar:

- **Tek path alan kişi:** bir programa sahip olur
- **Abone olan kişi:** kendini tanıyan bir rehbere sahip olur — path'ler arası hafıza, birikmiş bağlam, "geçen sefer bunu konuşmuştuk"

> Bu aynı zamanda ürünün gerçek savunulabilir avantajıdır. AI kişiselleştirmesi commodity; **biriken bağlam** değil. Rakip ürünü kopyalayabilir, kullanıcının 6 aylık geçmişini kopyalayamaz.

### 12.3 Ücretsiz katman neden hazır path'ler

Hazır path'ler önceden üretilmiştir → **AI maliyeti sıfır.** Hem edinme motoru hem ASO yakıtı. Kişiselleştirme — pahalı ve değerli olan — paralı tarafta kalır.

### 12.4 Adil kullanım

Abonelikte aynı anda **1 aktif path.** Ayda 2–3 path üreten ağır kullanıcı marjı sıkıştırır.

### 12.5 Geri dönüş — LTV'nin asıl kaynağı

Derinlik ürününün laneti: sorun çözülünce kullanıcı gider. Bu **kayıp değil, beklenen davranıştır.**

Kaygı, tükenmişlik, uykusuzluk döngüseldir. 7. günde iyi hissedip giden kullanıcı, sorun tekrarladığında dönecek bir müşteridir.

**Geri kazanım akışı:** Path bitiminden 60 ve 120 gün sonra:
> "Uyku patikanı Mart'ta tamamlamıştın. O zamandan beri nasıl gidiyor? İstersen 2 dakikada bir kontrol yapalım."

→ Ücretsiz mini ölçüm → skor düştüyse yeni path önerisi.

Bu, yeni kullanıcı bulmaktan çok daha ucuzdur. **LTV abonelik süresinden değil, geri dönüşlerden gelir.**

### 12.6 Kova C ücretsiz devam — maliyet etkisi

Kullanıcıların tahmini %15–25'i Kova C'ye düşecek. Bunlara ücretsiz devam vermek doğrudan bir COGS kalemidir (~€2–4/kullanıcı). Bunu **pazarlama gideri** olarak muhasebeleştir, kayıp olarak değil.

---

## 13. Teknik

### 13.1 Stack

**Platform kararı: iOS-only, SwiftUI native.** Cross-platform değil. Gerekçe 13.1.1'de.

| Katman | Seçim | Gerekçe |
|---|---|---|
| İstemci | **Swift + SwiftUI, iOS 18+** | Ses ve görsel katmanı native'de belirgin şekilde iyi |
| Ses motoru | **AVAudioEngine + AVAudioSession** | Arka plan çalma, miksaj, ducking, kilit ekranı |
| Görsel | **MeshGradient + Metal shader** (iOS 18+) | Üçüncü parti kütüphane yok, bkz. Görsel Sistem eki |
| Animasyon | **Rive iOS runtime** | Yol animasyonu, rozetler |
| Yerel depolama | **SwiftData** | Path, ölçüm, tercihler |
| Backend | Node/Python + Postgres | Standart, hızlı |
| Auth | Sign in with Apple (birincil) + e-posta | Sürtünmesiz, gizlilik dostu |
| LLM | Orta seviye model, blok seçimi + kişiselleştirme | Path üretimi ucuz, sık değil |
| TTS | Hibrit (13.2) | Marj koruma |
| Ödeme | **StoreKit 2** (+ RevenueCat opsiyonel) | Abonelik + tek seferlik satın alma birlikte |
| Analitik | PostHog veya Amplitude | Funnel takibi |
| Depolama | Ses CDN + imzalı URL + agresif yerel cache | Tekrar üretim maliyeti sıfır |

**Minimum hedef: iOS 18.0.** Haziran 2026 itibarıyla son dört yılda çıkan iPhone'ların %86'sı, tüm iPhone'ların %79'u iOS 26 çalıştırıyor — iOS 18+ pratik olarak tüm pazarı kapsıyor.

**Uygulama koyu moda sabitlenir** (`.preferredColorScheme(.dark)`). Tüm paletler koyu; açık mod desteklemek gradyan interpolasyonunda öngörülemeyen ara tonlar üretiyor ve meditasyon ürünü için zaten doğru karar değil.

#### 13.1.1 Neden cross-platform değil

Bu üründe React Native / Flutter'ın sunduğu kod paylaşımı avantajı normalden **küçük**, maliyeti ise **büyük**:

1. **İş mantığının çoğu sunucuda.** Path üretimi, blok seçimi, LLM kişiselleştirmesi, TTS, ölçüm skorlaması — hepsi backend. Paylaşılacak istemci mantığı az.
2. **Paylaşılmayan kısım tam da cross-platform'un en zayıf yeri.** Ses motoru ve GPU shader arka planı. Yani RN en az değer verdiği yerde en çok maliyet çıkarır.
3. **Ses bu ürünün kendisi.** Arka plan çalma, kilit ekranı kontrolleri, narration + müzik yatağı miksajı, sessizlik enjeksiyonu (13.2), telefon geldiğinde ducking, AirPlay — native'de temiz, RN'de sürekli savaş.

**Kabul edilen bedel:** Android geldiğinde istemci baştan yazılacak (Kotlin + Compose). Bu gerçek bir maliyet — Finch'in Android'de aylık 1 milyon doların üzerinde gelir ürettiğini hatırlayın. Ama o karar, elde çalışan bir ürün ve gerçek retention verisi varken verilir. Görsel dil Compose tarafında `RuntimeShader` + AGSL ile birebir kurulabilir (Görsel Sistem eki, Bölüm 2.4).

### 13.2 Hibrit ses mimarisi — kritik

Naif yaklaşım (her oturumu baştan sona TTS ile üretmek) marjı öldürür.

**Üç optimizasyon:**

1. **Sessizlik enjeksiyonu.** Meditasyon sesinin %50–60'ı sessizliktir. Sessizlikleri TTS ile üretme — sadece konuşulan blokları üret, araya istemci tarafında sessizlik koy. Tek başına maliyeti yarıya indirir.

2. **Blok önceden render.** Oturumun ~%70'i (nefes yönergeleri, body scan gövdesi, kapanış) blok kütüphanesinden **önceden render edilmiş** ses parçalarıdır. Sadece açılış ve kişiselleştirilmiş kısım (2–3 dk) taze üretilir.

3. **Ses tutarlılığı.** Aynı ses modeli/voice ID her yerde — önceden render ve taze üretim arasında geçiş duyulmamalı. Ses seçimi sabitlenir, sonradan değiştirilmesi tüm kütüphaneyi yeniden render gerektirir.

**Bonus:** Bu mimari latency problemini de çözer. Kullanıcı 40 saniye "AI meditasyonun hazırlanıyor" ekranına bakmaz.

#### 13.2.1 iOS uygulama notları

Hibrit mimarinin native karşılıkları:

| İhtiyaç | Çözüm |
|---|---|
| Konuşma + müzik yatağı miksajı | `AVAudioEngine`, iki `AVAudioPlayerNode` → `AVAudioMixerNode` |
| Sessizlik enjeksiyonu | Zamanlanmış `scheduleBuffer` çağrıları; boş buffer üretmeye gerek yok |
| Önceden render + taze parça geçişi | Aynı mixer üzerinde sıralı `scheduleFile`; dikiş duyulmaz |
| Ekran kapalıyken devam | `AVAudioSession` kategorisi `.playback`, `UIBackgroundModes: audio` |
| Kilit ekranı / AirPods kontrolü | `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` |
| Bildirim/telefon gelince | `.duckOthers` yerine session interruption handler — oturum duraklar, kaldığı yerden devam |
| Çevrimdışı SOS | Önceden render bloklar uygulama paketinde (~2 MB) |
| Müzik yatağı seviyesi | Konuşma varken −12 dB, sessizlikte −6 dB otomatik rampa |

**Oturum durumu kalıcılığı:** Kullanıcı oturumu yarıda bırakırsa (uygulama kapanır, telefon gelir) pozisyon SwiftData'ya yazılır. Dönüşte "kaldığın yerden devam et" seçeneği sunulur — bu, PRD-Ek Bölüm 5.5'teki mikro-sprint mantığıyla aynı ruhta.

### 13.3 Maliyet tahmini

| Kalem | Naif | Hibrit |
|---|---|---|
| Oturum başı ses | €0.15–0.50 | €0.03–0.05 |
| 21 günlük path | €3.15–10.50 | €0.70–1.10 |
| LLM (path üretimi) | ~€0.05 | ~€0.05 |
| **Path başına toplam** | **€3.20–10.55** | **€0.75–1.15** |

Tek path satışında (€14.99) marj rahat. Abonelikte aylık 1–2 path = €0.75–2.30 COGS, %82–94 brüt marj.

### 13.4 Veri modeli (özet)

```
User
 ├─ id, auth, locale, created_at, birth_year
 ├─ subscription_status, free_continuation_count
 └─ consent_flags (analytics, personalization, marketing)

ProblemStatement          ← şifreli, özel kategori veri
 ├─ user_id, raw_text, structured_tags
 └─ crisis_flag, created_at

Path
 ├─ user_id, template_id, length_days, status
 ├─ personalization_context (özet, ham metin değil)
 └─ outcome_bucket (A/B/C), completed_at

PathStep
 ├─ path_id, day_index, block_ids[], title
 ├─ audio_url, duration_sec
 └─ completed_at, post_feedback

Measurement
 ├─ user_id, path_id, point (baseline/d7/d14/final)
 ├─ variant (A/B/C), raw_responses{}
 └─ dimension_scores{}, composite_score

Badge / Artifact
 └─ user_id, path_id, audio_url,永続 (kalıcı)
```

### 13.5 Gizlilik mimarisi

- Ham problem metni **şifreli** saklanır, ayrı tabloda
- LLM'e giden bağlam **özettir**, ham metin değil (mümkün olduğunca)
- Ölçüm verisi ve problem metni **asla** analitik araçlara gönderilmez
- Tek dokunuşta **tüm veriyi indir** ve **hesabı sil**
- Ses dosyaları kullanıcıya özel imzalı URL

---

## 14. Yasal ve uyum

### 14.1 GDPR

Ruh sağlığı verisi **Madde 9 özel kategori** veridir. Gereken:

- [ ] Açık rıza (opt-in, önceden işaretli kutu yok)
- [ ] **DPIA** (Veri Koruma Etki Değerlendirmesi) — lansman öncesi zorunlu
- [ ] Tasarımdan itibaren gizlilik
- [ ] Veri sahibi hakları: erişim, silme, taşınabilirlik — üründe uygulanmış
- [ ] Otomatik karar verme şeffaflığı (path nasıl oluşuyor açıklanmalı)
- [ ] Sınır ötesi veri aktarımı yasal dayanağı (LLM sağlayıcısı ABD'deyse)
- [ ] Ölçekli işleme olursa DPO ataması

### 14.2 EU AI Act

- Tüketici wellness uygulaması **yüksek riskli değil** (Annex III kapsam dışı)
- **Ama:** sentetik içerik üretimi (LLM yazımı koçluk metni) için şeffaflık yükümlülüğü — **2 Aralık 2026** tarihini takvime al
- Kapsam dışı olduğun **iddiası da dokümante edilmeli**
- Sağlık skoru hesaplamak = profilleme; bu, Madde 6(3) muafiyetini kapatır

### 14.3 Mağaza kuralları

- Ruh sağlığı kategorisinde kriz kaynakları gösterilmesi zorunlu
- Tıbbi iddia yok → red sebebi
- Yaş derecelendirmesi doğru ayarlanmalı
- Abonelik şartları paywall'da net (deneme süresi, otomatik yenileme, fiyat)

### 14.4 Metin bazlı yasal iş

- ToS + Gizlilik Politikası (avukat, TR + DE + EN)
- Tıbbi feragat metni — her ölçüm ekranında ve onboarding'de
- Tahmini maliyet: €2.000–6.000

---

## 15. Metrikler

### 15.1 Kuzey yıldızı

**7 günlük ölçümü tamamlayan kullanıcı sayısı.**

Neden bu: Kullanıcının hem ürünü hem de kendi ilerlemesini gördüğü an. Hem aktivasyon hem dönüşüm hem değer teslimi bu tek noktada birleşiyor.

### 15.2 Funnel

| Aşama | Metrik | v1 hedefi |
|---|---|---|
| Kurulum → sorun girişi | % | ≥70% |
| Sorun girişi → baseline tamam | % | ≥85% |
| Baseline → 1. adım tamam | % | ≥75% |
| 1. adım → 3. adım | % | ≥50% |
| **3. adım → 7. gün ölçümü** | % | **≥35%** |
| 7. gün ölçümü → ödeme | % | ≥25% |
| Ödeme → path tamamlama | % | ≥55% |
| Path tamamlama → sonraki path | % | ≥40% |

### 15.3 Sonuç metrikleri

| Metrik | Hedef | Not |
|---|---|---|
| Kova A oranı | ≥50% | Düşükse içerik kalitesi sorunu |
| Kova C oranı | ≤20% | Yüksekse ürün gerçekten işe yaramıyor demektir |
| Bileşik skor medyan iyileşme | ≥%25 | Pazarlama iddiasının dayanağı |
| D30 retention | ≥25% | Kategori ortalaması ~10–15% |
| 90 gün geri dönüş | ≥15% | LTV'nin asıl kaynağı |

### 15.4 Sağlık ve güvenlik metrikleri

Bunlar iş metriklerinden **daha yüksek önceliklidir:**

- Kriz sınıflandırıcı tetiklenme sayısı ve sonrası davranış
- "Destek al" tıklanma oranı
- Kova C'de yanlışlıkla satış gösterilme sayısı → **hedef: 0**
- Kullanıcı şikayeti / kötü deneyim raporu

---

## 16. Yol haritası

### Faz 0 — Doğrulama (3–4 hafta, kod yok)

- [ ] 10+ problem görüşmesi
- [ ] Rakip denemesi: ELYND, StillMind, Zorio, Ube gerçekten kullan
- [ ] **Elle tasarlanmış tek bir path** (öneri: uyku veya sınav kaygısı), 21 gün, WhatsApp/e-posta üzerinden 15 kişiye uygulat
- [ ] Ölçüm formunu elle uygula, öncesi/sonrası farkı gerçekten çıkıyor mu bak
- [ ] Landing page A/B: "Meditasyon için Duolingo" vs "Streak yok, suçluluk yok" — kayıt oranı

**Karar kapısı:** Elle uygulanan path'te medyan iyileşme %20'nin altındaysa, ürünün temel iddiası çürük. Faz 1'e geçme, tasarımı değiştir.

### Faz 1 — MVP (10–14 hafta)

Kapsam:
- Onboarding + sorun girişi (Mod A ve B)
- Ölçüm sistemi (4 nokta, 3 katman, rotasyon)
- **3 path şablonu** (uyku, kaygı, tükenmişlik), 21 gün
- ~40 blok kütüphanesi, TR + EN
- Hibrit ses mimarisi
- Path haritası + günlük oturum akışı
- 3 kovalı sonuç raporu
- 7. gün paywall
- SOS + Destek al + kriz protokolü
- **Platform: iOS 18+, SwiftUI native**

Kapsam dışı: Keşfet sekmesindeki hazır path'ler (Faz 2), artifact üretimi (Faz 2), Android (Faz 4'te değerlendirilir), iPad/Mac (hayır).

### Faz 2 — Genişleme (6–8 hafta)

- Hazır path kütüphanesi (ücretsiz katman)
- Kalıcı artifact üretimi
- 14 ve 28 günlük şablonlar
- Rozet ve koleksiyon
- Geri kazanım akışı
- **Widget + Live Activity** (aktif path ilerlemesi)

### Faz 3 — Ölçekleme

- Path tipi sayısını 3 → 10'a çıkar
- Ek diller
- Ücretli edinme ölçekleme
- Apple Watch (nefes oturumu + hatırlatma) — düşük efor, yüksek algı değeri

### Faz 4 (değerlendirilecek)

- **Android (Kotlin + Compose, sıfırdan istemci)** — karar kapısı aşağıda
- B2B2C / kurumsal
- Terapi öncesi köprü ürünü olarak konumlanma

#### Android karar kapısı

Android'e ancak şu üç koşul birlikte sağlanınca geçilir:

1. iOS'ta D30 retention ≥%25 (yani ürün gerçekten çalışıyor)
2. iOS'ta pozitif birim ekonomisi (LTV > CAC)
3. Android istemciyi yazacak ayrı kaynak (kendi ekibi olan bir geliştirici veya ajans)

Bu koşullar sağlanmadan Android'e geçmek, çalıştığı kanıtlanmamış bir ürünü iki kere yazmak demektir. Sağlandığında ise geciktirmeyin: Finch Android'de aylık 1 milyon doların üzerinde gelir üretiyor ve orada aktif reklam veriyor.

**Yeniden kullanılabilecekler:** Backend'in tamamı, blok kütüphanesi, ses varlıkları, tüm metinler, ölçüm mantığı, shader'ın matematiği (AGSL'e port edilir). **Yeniden yazılacaklar:** UI katmanı, ses motoru, ödeme entegrasyonu.

---

## 17. Riskler

| Risk | Olasılık | Etki | Azaltma |
|---|---|---|---|
| Ölçüm anlamlı fark göstermiyor | Orta | **Kritik** | Faz 0 karar kapısı; öz-yeterlik boyutu (en hızlı iyileşen) dahil |
| Kova C oranı yüksek çıkıyor | Orta | Yüksek | Ücretsiz devam maliyeti bütçelenmiş; içerik iterasyonu |
| Ses kalitesi deneyimi bozuyor | Orta | Yüksek | Ses seçimi erken sabitlenir, kullanıcı testi ile |
| Headspace/Calm aynı özelliği ekliyor | **Yüksek** | Orta | Hız + niş odak; biriken bağlam moat'ı |
| CAC sürdürülemez | Yüksek | Yüksek | Ücretsiz katman + organik ASO; ölçüm sonucu pazarlama iddiası |
| Kriz vakası kötü yönetiliyor | Düşük | **Kritik** | Sınıflandırıcı + insan gözden geçirme + yerel hatlar |
| GDPR / DPIA eksikliği | Orta | Yüksek | Lansman öncesi avukat, DPIA tamamlanmadan yayın yok |
| Ücretsiz devam suistimali | Düşük | Düşük | Ömür boyu 2 limit; davranış katmanı manipülasyonu zorlaştırır |
| 7. gün paywall dönüşümü düşük | Orta | Yüksek | A/B: gün 5 / 7 / 9; ölçüm ekranı metni iterasyonu |
| **Android pazarı kaçırılıyor** | Kesin (Faz 1–3) | Orta | Bilinçli tercih; Faz 4 karar kapısı tanımlı. Backend ve içerik yeniden kullanılabilir |
| **Swift geliştirici bağımlılığı** | Orta | Orta | Tek platform = tek uzmanlık. Ekipte Swift yoksa bu karar yeniden değerlendirilmeli |
| iOS 18 altı cihazlar kapsam dışı | Düşük | Düşük | Pazarın ~%5'i; MeshGradient için gerekli |

---

## 18. Açık sorular

1. **Ürün adı.** "Patika" çalışma adı. TR+global çalışacak, telaffuz edilebilir, domain ve mağaza müsait bir isim gerekli.
2. **Birincil pazar.** TR mi, DE/EN mi? Bu, fiyatlandırmayı (€12.99 Türkiye için yüksek), ASO'yu ve içerik önceliğini değiştirir. **Faz 1 öncesi kararlaştırılmalı.**
3. **İlk path tipi.** Uyku (en geniş pazar, en ölçülebilir davranış metriği) vs sınav kaygısı (en net tetikleyici, mevsimsel) vs tükenmişlik (en yüksek ödeme gücü). Öneri: **uyku** — davranış metriği en sağlam.
4. **Ses kimliği.** Tek ses mi, birkaç seçenek mi? Tek ses maliyeti ve tutarlılığı lehine, ama kişiselleştirme vaadine ters düşer mi?
5. **Kova eşikleri.** %25 / %10 / %5 eşikleri şu an tahmin. Faz 0 verisiyle kalibre edilmeli.
6. **Ücretsiz adım sayısı.** 6 adım (gün 7'ye kadar) mi, ilk path tamamen ücretsiz mi? İkincisi cesur ve "işe yaradığını gördükten sonra öde" konumlandırmasıyla mükemmel uyuşuyor ama CAC'yi geri kazanmayı zorlaştırır. **A/B test edilmeli.**

---

## 19. Karar günlüğü

| # | Karar | Alternatif | Gerekçe |
|---|---|---|---|
| 1 | Ödeme duvarı 7. günde, ölçümden sonra | 3. gün | Fayda 7–10. günde hissediliyor; ölçüm kullanıcıya kendi kanıtını veriyor |
| 2 | "Başarısız" dili yok, 3 kova var | Başarılı/başarısız | Kaygılı kullanıcıya yetersizlik belgesi vermek zarar verir |
| 3 | Kova C'de ücretsiz devam, satış yok | İndirimli devam | Teşvik hizalaması: sadece kullanıcı iyileşince kazan |
| 4 | İndirim yerine "abonelik = süreklilik" | Geçişte indirim | İndirim beklentisi tam fiyatı öldürür |
| 5 | Streak yok | Streak + affedicilik | Kayıp kaçınması, kaygı ürününde ters teper |
| 6 | AI blok seçer, içerik icat etmez | Serbest üretim | Kalite tutarlılığı + fiyatlanabilirlik + güvenlik |
| 7 | Sabit uzunluk kovaları (7/14/21/28) | Değişken uzunluk | "19 günlük patika" satılamaz |
| 8 | Klinik ölçek kullanılmıyor | GAD-7/PHQ-9 | Lisans + tıbbi cihaz düzenlemesi riski |
| 9 | Destek al her zaman menüde | Sadece Kova C'de | Belirmesi "başarısız oldun" sinyali olur |
| 10 | Ücretsiz katman = hazır path'ler | Süre sınırlı deneme | Önceden üretilmiş → sıfır AI maliyeti + ASO yakıtı |
| 11 | Hibrit ses mimarisi | Tam gerçek zamanlı TTS | Marj 5–10x fark; latency de çözülüyor |
| 12 | **iOS-only, SwiftUI native** | React Native / Flutter | İş mantığı sunucuda; paylaşılmayan kısım (ses + shader) cross-platform'un en zayıf yeri |
| 13 | Minimum iOS 18 | iOS 16/17 desteği | MeshGradient iOS 18+; pazarın ~%95'i zaten üstünde |
| 14 | Uygulama koyu moda sabit | Açık/koyu mod desteği | Gradyan interpolasyonu açık modda öngörülemeyen ara tonlar üretiyor; meditasyon için de doğru |
| 15 | Android Faz 4'e ertelendi, karar kapısı tanımlı | Faz 2'de Android | Kanıtlanmamış ürünü iki kere yazmamak |
| 16 | StoreKit 2 birincil | RevenueCat zorunlu | Tek platformda RevenueCat'in ana faydası (çapraz platform abonelik senkronu) yok |
| 17 | Gamification kısmen serbest bırakıldı (2026-09-19, Ben v2): kilometre taşı rozetleri, nazik haftalık seri ve sade kutlama serbest; toplam sayılar, lig/kıyas, sıfırlanan ilerleme, kayıp bildirimi, sahte aciliyet ve can/enerji yasak kalır | Karar #5'in tamamı (streak dâhil tam yasak) | Emek görünür ve tanınır olmalı; zarar veren kayıp kaçınması mekanikleri değil. Seri kırılınca mesaj yok, bildirimde seri yok; rozet anı kutlaması Sıcak kademesinde, kriz ve Kova C'de Nötr (kutlama yok) |
