# PRD Eki — Ton, Whimsy ve Davranışsal Nudge Katmanı

**Ana doküman:** PRD.md
**Durum:** Taslak v0.1
**Tarih:** 4 Eylül 2026

---

## 0. Önce bir uyarı: bu üründe whimsy'nin çoğu yasaktır

İki skill'i uygularken standart kütüphanelerini olduğu gibi almadım. Sebep:

Whimsy-injector'ın varsayılan repertuarı — konfeti patlaması, "Boom! You're officially awesome", uçuşan emoji, rainbow konami modu — bir SaaS dashboard'unda harika çalışır. **Kaygı, tükenmişlik ve uykusuzlukla gelen bir kullanıcıda ters teper.** Panik hâlindeki birine "High five! 🎉" demek, onu ciddiye almadığınız mesajını verir.

Behavioral-nudge-engine'in "variable-reward engagement loops" ve "opt-out architectures that dramatically increase participation" önerileri de PRD'de bilinçli olarak reddettiğimiz mekaniklerdir. Değişken ödül, kumar makinesi psikolojisidir; kaygı ürününde etik değildir.

Bu yüzden aşağıdaki her şey **bağlama göre kapılı**. Ürünün kişiliği tek değil, dört farklı sıcaklık kademesinde çalışır.

---

## 1. Kişilik spektrumu — dört sıcaklık kademesi

| Kademe | Nerede | Ton | Whimsy izni |
|---|---|---|---|
| 🔴 **Nötr** | Kriz ekranı, Kova C raporu, Destek al, tıbbi feragat | Sade, yavaş, sıfır süsleme | **Yok. Hiçbiri.** |
| 🟠 **Sakin** | Oturum içi, ölçüm ekranları, path haritası | Sıcak ama sessiz | Sadece hareket/geçiş |
| 🟡 **Sıcak** | Path sonu (Kova A/B), rozet, oturum sonu | İçten, kutlayan ama abartısız | Mikro-animasyon + metin |
| 🟢 **Oyuncu** | Keşfet, nefes egzersizleri, boş durumlar, ayarlar, Easter egg | Hafif esprili | Serbest |

**Kural:** Bir ekranın kademesi yukarı çıkmaz. Kova C ekranına "en azından denedin! 💪" eklenmez. Şüphe varsa bir kademe aşağı in.

### 1.1 Marka sesi — üç sıfat

**Sakin · Dürüst · Yanında.**

- **Sakin:** Asla acele ettirmez, asla bağırmaz. Ünlem işareti neredeyse hiç kullanılmaz.
- **Dürüst:** İlerleme yoksa "ilerleme var" demez. Abartmaz. Garanti vermez.
- **Yanında:** Öğretmen değil, yol arkadaşı. "Yapmalısın" değil, "birlikte bakalım".

**Ses testi:** Yazdığın cümleyi, gece 2'de uyuyamayan ve kendini kötü hisseden birine yüksek sesle söyleyebiliyor musun? Söyleyemiyorsan yaz baştan.

---

## 2. Whimsy taksonomisi — ekran ekran

### 2.1 Subtle (fark edilmeyen ama hissedilen)

| Nerede | Ne | Amaç |
|---|---|---|
| Oturum ekranı | Nefes ritmine senkron yavaş dalga animasyonu (4s in / 6s out) | Kullanıcı farkında olmadan nefesini yavaşlatır — **fonksiyonel whimsy** |
| Path haritası | Tamamlanan adım dolarken 400ms'lik yumuşak dolgu, konfeti yok | İlerleme hissi, kutlama gürültüsü olmadan |
| Buton basımı | 0.98 scale + 12ms haptic | Fiziksellik |
| Ekran geçişleri | Slide yok. Onboarding'de **sıralı fade**: 160ms çıkış → 340ms giriş, gelen içerik 14pt aşağıdan süzülür | Sarsıntısızlık. Kabuk (üst çubuk) geçişe katılmaz — "yeni sayfa açıldı" değil, "aynı ekranda içerik değişti" |
| Tek seçimlik soru | Dokunmak cevaptır; seçim 240ms görünür kalır, sonra akış ilerler | Onay adımı yok — 31 ekranlık akışta gereksiz dokunuş |
| Gece modu | 21:00'dan sonra otomatik olarak arayüz sıcaklaşır ve kontrastı düşer | Uyku path'lerinde işlevsel |

> **En değerli whimsy bu kategoride.** Kullanıcı bunları göremez ama vücudu fark eder.

### 2.2 Interactive (kullanıcının tetiklediği)

| Nerede | Ne |
|---|---|
| Adım tamamlama | Adım halkası dolar, tek bir yumuşak ton (isteğe bağlı), haptic |
| Rozet kazanma | Rozet 600ms'de belirir, hafif parlar, durur. Kalıcı olarak koleksiyona düşer |
| Ölçüm barları | Barlar sağa doğru 800ms'de akar — sayı hemen görünmez, önce hareket |
| SOS butonu | Basılı tutunca büyür, bırakınca ses başlar (kaza koruması + fiziksel rahatlama) |
| Artifact indirme | Ses dosyası "cebine düşer" animasyonu — sahiplik hissi |

### 2.3 Discovery (Easter egg)

Bu kategoride **az ve anlamlı** olmak zorunda. Üç tane öneriyorum:

**1. Uzun basılan nefes butonu**
Nefes egzersizi ekranında ortadaki daireyi 10 saniye basılı tutarsan, ekran tamamen boşalır ve sadece daire kalır. Hiçbir metin, hiçbir sayaç. Adı yok, açıklaması yok.
> *Amaç: Deneyimli kullanıcılara "biz de sessizliği seviyoruz" demek.*

**2. Yolun sonundaki not**
Bir path'i tamamlayınca haritanın en altında, son adımın altında küçük bir işaret belirir. Dokununca o path boyunca yazdığın ilk cümle karşına çıkar:
> *"3 hafta önce şunu yazmıştın: '...'"*

Bu, ürünün en güçlü duygusal anı olabilir. Teknik olarak bedava, etkisi büyük.

**3. Üç kez üst üste "odaklanamadım"**
Dördüncüde sistem şunu der:
> *"Odaklanmak bugünlerde zor, biliyoruz. İstersen 90 saniyelik bir versiyon var — sadece nefes, konuşma yok."*

Easter egg gibi görünüyor ama aslında bu bir nudge (Bölüm 5.4).

**Yasak:** Konami kodu, rainbow modu, uçuşan emoji, gizli oyunlar. Ürünün ciddiyetini bozar.

### 2.4 Contextual (duruma özel)

Boş durumlar, hata ekranları, mevsimsel — Bölüm 3'te metinleriyle.

---

## 3. Mikrometin kütüphanesi (TR)

### 3.1 Boş durumlar

| Ekran | Metin |
|---|---|
| Henüz path yok | "Burası şimdilik boş. Bir şey anlatmaya hazır olduğunda buradayız." |
| Rozet yok | "İlk patikanı bitirdiğinde burada bir şey olacak. Acelesi yok." |
| Kaydedilmiş oturum yok | "Bir patikayı tamamladığında, sana ait kalıcı bir kayıt burada duracak." |
| Keşfet — arama sonucu yok | "Bunu bulamadık. Ama belki aradığın şey aşağıdakilerden biridir." |
| Geçmiş ölçüm yok | "İlk ölçümünü yaptığında burada bir çizgi belirmeye başlayacak." |

> Hiçbirinde şaka yok, hiçbirinde suçlama yok. "Acelesi yok" cümlesi ürünün imzası.

### 3.2 Hata durumları

| Durum | Metin |
|---|---|
| İnternet yok | "Bağlantı gitti. Merak etme — indirdiğin oturumlar çevrimdışı da çalışıyor." |
| Ses yüklenemedi | "Ses yüklenemedi. Tekrar deneyelim mi, yoksa şimdilik metin olarak mı okuyalım?" |
| Path üretilemedi | "Bir şeyler ters gitti, bizim tarafımızda. Yazdıkların kayboldu değil — tekrar deniyoruz." |
| Ödeme başarısız | "Ödeme geçmedi. Yolun olduğu gibi duruyor, hiçbir şey kaybolmadı." |
| Sunucu hatası | "Şu an bir sorun yaşıyoruz. Bu senin yüzünden değil ve birazdan düzelecek." |

> **Tasarım kararı:** Her hata metninde "kaybolmadı / senin yüzünden değil" ifadesi var. Kaygılı kullanıcı hatayı otomatik olarak kendine mal eder. Bunu her seferinde kesiyoruz.

### 3.3 Yükleme durumları

Path üretimi 10–20 saniye sürebilir. Bu ekran genelde israf edilir; biz onu beklenti kurmak için kullanıyoruz. Sırayla:

```
"Yazdıklarını okuyorum..."            (0–4 sn)
"Sana uygun adımları seçiyorum..."     (4–10 sn)
"Yolu sıraya diziyorum..."             (10–16 sn)
"Neredeyse hazır."                     (16+ sn)
```

> Espri yok. Bu an ciddi — kullanıcı az önce derdini anlattı. "Sprinkling some digital magic ✨" burada tam bir saygısızlık olur.

**Ama** Keşfet sekmesindeki hazır path'ler yüklenirken (🟢 Oyuncu kademesi) hafifleyebilir:
> "Rafları karıştırıyoruz..."

### 3.4 Buton metinleri

| Standart | Bizimki | Neden |
|---|---|---|
| Başla | **Yola çık** | Metafor tutarlılığı |
| Devam et | **Kaldığın yerden** | Kayıp değil süreklilik vurgusu |
| İptal | **Şimdilik değil** | Reddetmeyi suçsuzlaştırır |
| Atla | **Bugün geç** | "Atlamak" kalıcı, "geçmek" geçici |
| Kaydet | **Bende kalsın** | Sahiplik |
| Bitir | **Burada duralım** | Off-ramp tonu |
| Tekrar dene | **Bir daha bakalım** | Yumuşak |

### 3.5 Kutlama metinleri — kademeye göre

**🟡 Path sonu, Kova A:**
> "21 gün. Baştaki halinle şu anki halin arasında gerçek bir fark var — ve bu farkı sen yarattın."

Ünlem yok, emoji yok, "tebrikler" yok. Sadece gerçeğin sade ifadesi.

**🟡 Rozet:**
> "Uyku patikası tamamlandı. Uykuya dalma süren %41 kısaldı."

Rozetin üstünde soyut bir başlık değil, **sayı** var. Rozeti anlamlı kılan bu.

**🟠 Günlük adım sonu:**
> "Tamam. Yarın: Düşünceden ayrışma."

Bu kadar. Her günü kutlamak, kutlamayı değersizleştirir.

### 3.6 Asla kullanılmayacak ifadeler

| Yasak | Neden |
|---|---|
| "Harika iş çıkardın! 🎉" | Küçük bir eylem için abartılı → sahte hissettirir |
| "Seni özledik" | Suçluluk üretir |
| "Serini kaybetmek üzeresin" | Kayıp kaçınması — PRD kararı #5'e aykırı |
| "Sadece 2 gün kaldı!" | Aciliyet baskısı |
| "Diğer kullanıcılar..." | Sosyal kıyaslama — bu kitlede toksik |
| "Endişelenme" / "Sakin ol" | Kaygılı kişiye söylenecek en işe yaramaz iki cümle |
| "Bunu aşacaksın" | Garanti verilemez |
| "Başarısız" | PRD kararı #2 |

---

## 4. Whimsy bütçesi

Delight, sık olduğunda gürültüye dönüşür ve dikkat çeker — meditasyon ürününde dikkat çekmek başarısızlıktır.

**Oturum başına maksimum 2 "fark edilir" delight anı.**

| Oturum tipi | İzin verilen |
|---|---|
| Günlük adım | 1 (adım dolma animasyonu) |
| Ölçüm günü | 2 (bar animasyonu + rapor geçişi) |
| Path sonu | 3 (rozet + artifact + koleksiyon düşüşü) |
| SOS | **0** — hiçbir animasyon, hiçbir ses efekti |

---

## 5. Davranışsal nudge motoru

### 5.1 Tercih keşfi — onboarding'de sorulur

Nudge motorunun ilk kuralı: **varsayma, sor.** Onboarding'in sonunda, path başlamadan önce üç soru:

**Soru 1 — Zamanlama**
> "Günün hangi saatinde sana uygun?"
> Sabah (07–10) · Öğlen (12–15) · Akşam (18–21) · Gece (21–24) · Sabit saat istemiyorum

**Soru 2 — Hatırlatma sıklığı**
> "Sana ne sıklıkta hatırlatalım?"
> Her gün · Sadece kaçırdığımda · Haftada bir · Hiç hatırlatma

**Soru 3 — Ton**
> "Nasıl bir dil sana iyi geliyor?"
> Sakin ve kısa · Biraz daha teşvik edici · Sadece bilgi, yorum yok

> **Kanal notu:** Push bildirimi dışında kanal yok. SMS ve e-posta ile ruh sağlığı içeriği göndermek gizlilik riski — telefon başkasının eline geçebilir, kilit ekranında görünür. Bu, nudge-engine'in çoklu kanal önerisinden bilinçli sapmadır.

**iOS uygulama notu:** Günlük hatırlatmalar sunucudan değil, **cihazda** `UNCalendarNotificationTrigger` ile planlanır. Üç avantajı var: (1) kullanıcının saat tercihi ve path durumu sunucuya gitmez, (2) çevrimdışı çalışır, (3) push token yönetimi gerekmez. Sadece geri kazanım mesajları (60/120 gün) sunucudan push olarak gider.

`UNNotificationInterruptionLevel` her zaman `.active` — asla `.timeSensitive` veya `.critical` kullanılmaz. Bu ürün acil değildir ve Odak modunu delmemelidir.

### 5.2 Bildirim yazım kuralları

**Kilit ekranında ne yazdığına dikkat.** Bildirim metni asla path adını veya sorunu içermez.

| ❌ Yanlış | ✅ Doğru |
|---|---|
| "Sınav kaygısı patikanın 8. adımı hazır" | "Bugünün adımı hazır" |
| "Uykusuzluk programını 3 gündür açmadın" | "Buradayız, hazır olduğunda" |

> Kullanıcının telefonuna bakan biri, onun neyle uğraştığını öğrenmemeli.

### 5.3 Nudge sekansı — durum bazlı

Nudge, takvime göre değil **duruma göre** tetiklenir.

| Durum | Zamanlama | Metin | Aksiyon |
|---|---|---|---|
| Normal gün | Tercih edilen saatte | "Bugünün adımı hazır." | Adımı aç |
| 1 gün kaçırdı | Ertesi gün, aynı saatte | "Bugün devam edelim mi?" | Adımı aç |
| 2–3 gün kaçırdı | 3. gün, bir kez | "Buradayız. Kaldığın yerden devam edebilirsin." | Haritayı aç |
| 4–7 gün kaçırdı | 7. gün, bir kez | "İstersen bugün sadece 2 dakikalık bir versiyon var." | Mikro-oturum |
| 8–14 gün | 14. gün, bir kez | "Yolun duruyor, kaybolmadı." | Haritayı aç |
| 14+ gün | **Sus.** 30. günde tek bir mesaj, sonra hiç | "Bir ara buradaydın. Ne zaman istersen." | Ana ekran |
| Path bitti, 60 gün | 60. gün | "Uyku patikanı tamamlamıştın. Nasıl gidiyor?" | 2 dk mini ölçüm |
| Path bitti, 120 gün | 120. gün | Aynı, son kez | Mini ölçüm |

**Kural:** Aynı durumda **asla ikinci bildirim yok.** Nudge frekansı zamanla artmaz, azalır.

### 5.4 Mikro-sprint — nudge motorunun en değerli uygulaması

Skill'in "cognitive load reduction" ilkesi burada tam oturuyor. Kullanıcı 10 dakikalık oturumu kaldıramayacak durumdaysa, **tam oturumu ısrar etmek yerine küçültülmüş versiyonu öner.**

**Tetikleyiciler:**
- 4+ gün ara verilmiş
- Üst üste 3 kez "odaklanamadım"
- Ön kontrolde en düşük iki duygu seçeneği
- Gece 00:00 sonrası açılış (muhtemelen uykusuz)

**Teklif:**
```
Bugün zor bir gün gibi görünüyor.

İstersen tam adım yerine 2 dakikalık bir versiyon var —
sadece nefes, uzun anlatım yok.

    [2 dakikalık versiyon]
    [Tam adımı yap]
    [Bugün geç]
```

**Kritik:** Mikro versiyon yapıldığında adım **tamamlanmış** sayılır. Yarım sayılmaz, "eksik" damgası yemez. Yoksa amacını kaybeder.

### 5.5 Off-ramp — her oturum sonunda

Skill'in "always offer an opt-out completion" kuralı. Her oturum sonu net bir duruş noktası verir:

```
Bugünlük tamam.

    [Uygulamayı kapat]
    [5 dakika daha — nefes egzersizi]
```

> Varsayılan buton **kapatmak**. Devam etmek ikincil. Bu ters gibi görünür ama güven inşa eder: ürün senden daha fazlasını istemiyorsa, istediği anda ciddiye alırsın.

### 5.6 Varsayılan yanlılığı (default bias)

Skill'in "leverage default biases" ilkesi — kullanıcıya karar yükü bindirmek yerine hazır seçenek sun:

| Karar noktası | Kötü | İyi |
|---|---|---|
| Hatırlatma saati | "Saat seç" (boş picker) | "22:30'a ayarladım — akşam demiştin. Uygun mu?" |
| Path uzunluğu | "7/14/21/28 seç" | "21 gün öneriyorum. Kısaltmak istersen değiştirebilirsin." |
| Oturum süresi | "5/10/15 dk" | "10 dakika ayarladım." |
| Sonraki path | Boş kütüphane | "Sırada bunu öneriyorum: [x]. Başka bir şey de seçebilirsin." |

> **Sınır:** Varsayılan yanlılığı **abonelik ve ödeme kararlarında kullanılmaz.** Önceden işaretli kutu yok, "otomatik yenileme açık" varsayılanı gizlenmez. Burada dark pattern çizgisi çok ince ve geçilmeyecek.

### 5.7 Nudge motorunun kendini kapatması

Skill'in en önemli maddesi bu: *"If they stop responding, autonomously pause and ask."*

**Uygulama:** Art arda 5 bildirim açılmadıysa, bildirimler otomatik durur ve uygulama içinde tek bir kart belirir:

```
Hatırlatmalarımız işe yaramıyor gibi.

    [Haftada bir olsun]
    [Tamamen kapat]
    [Böyle iyi]
```

Kullanıcı hiçbirini seçmezse varsayılan: **haftada bire düşür.**

---

## 6. Kutlama kalibrasyonu

Nudge-engine "immediate positive reinforcement" der. Doğru, ama ölçüsü ürüne göre değişir.

| Eylem | Kutlama şiddeti | Biçim |
|---|---|---|
| Günlük adım | 1/5 | Halka dolar, sessiz |
| 7. gün ölçümü | 3/5 | Bar animasyonu + karşılaştırma |
| 14. gün | 2/5 | Trend çizgisi belirir |
| Path tamamlama (Kova A) | 5/5 | Rapor + rozet + artifact |
| Path tamamlama (Kova B) | 3/5 | Rapor, rozet var, kutlama dili yok |
| Path tamamlama (Kova C) | **0/5** | Hiçbir kutlama unsuru. Nötr kademe. |
| Geri dönüş (60 gün sonra) | 2/5 | "Seni görmek güzel." Sadece bu. |

> **Kova C'de rozet verilir mi?** Evet — ama üstünde sayı değil, sadece "21 gün" yazar. Emek tanınır, sonuç uydurulmaz.

---

## 7. Erişilebilirlik ve azaltılmış hareket

Bu kitlede zorunlu, opsiyonel değil.

- **`accessibilityReduceMotion` desteklenir.** `@Environment(\.accessibilityReduceMotion)` ile okunur. Açıksa: nefes animasyonu statik daireye, bar animasyonları anlık dolguya, geçişler basit `.opacity` fade'e düşer. Shader'da `u_speed = 0`.
- **`accessibilityReduceTransparency`** açıksa gradyan yerine düz koyu renk kullanılır.
- **Ses efektleri varsayılan olarak KAPALI.** Ayarlardan açılır. Bir meditasyon uygulamasında beklenmedik "ding" sesi, tam olarak istemediğimiz tepkiyi üretir.
- **Haptik varsayılan olarak açık ama tek seviye** — `UIImpactFeedbackGenerator(style: .soft)`, başka stil kullanılmaz. Titreşim hassasiyeti olanlar için kapatılabilir.
- **Tüm animasyonlar 800ms altı.** Uzun animasyon = bekletme = sabırsızlık.
- **Renk tek başına anlam taşımaz.** İyileşme/kötüleşme oku + metin ile birlikte gösterilir.
- **Dynamic Type zorunlu.** Tüm metinler `.font(.body)` gibi semantik stillerle; sabit punto yok. AX5 boyutunda hiçbir ekran kırılmamalı — özellikle D1–D8 ölçüm ekranları ve F2 plan ekranı test edilmeli.
- **VoiceOver:** Dekoratif gradyan ve animasyonlar `.accessibilityHidden(true)`. Ölçüm barları `.accessibilityValue("yüzde 30 azalma")` olarak okunur. Path haritasındaki kilitli adımlar `.accessibilityHint("Henüz açılmadı")`.
- **Oturum ekranı VoiceOver'da** sürekli konuşmamalı — `.accessibilityElement(children: .ignore)` ile tek bir öğe, sadece kalan süre.
- **Kontrast:** WCAG AA minimum, gece modunda AAA hedefi. Doğrulama CI'da otomatik (Görsel Sistem eki, Bölüm 5).

---

## 8. Mevsimsel ve durumsal içerik

Whimsy-injector "seasonal campaigns" öneriyor. Bu üründe **çok dikkatli** kullanılmalı — tatil dönemleri bu kitlede zor dönemlerdir.

| Dönem | Ne yapılır | Ne yapılmaz |
|---|---|---|
| Yılbaşı | "Yeni yıl kararı" baskısı **yok**. Bunun yerine sessiz bir "geçen yılın haritası" | "Yeni yılda yeni sen!" |
| Sınav dönemleri | Sınav kaygısı path'i öne çıkar | Geri sayım, aciliyet |
| Kış (kuzey ülkeleri) | Mevsimsel düşüklük içeriği, ışık/rutin | "Kış depresyonu" teşhisi |
| Bayram / tatil | "Aile ortamında sınır koyma" içeriği | Kutlama teması, "mutlu bayramlar 🎊" |
| Pazar akşamı | Pazartesi kaygısı için özel kısa oturum | — |

> **Pazar akşamı içgörüsü:** Bu, ürünün en yüksek talep anlarından biri ve rakiplerin hiçbiri özel olarak ele almıyor. Küçük ama gerçek bir fırsat.

---

## 9. Metrikler

Bu katmanın işe yarayıp yaramadığını ölçmenin yolu:

| Ne | Metrik | Hedef |
|---|---|---|
| Nudge kalitesi | Bildirim açılma oranı | ≥%25 (düşükse frekansı azalt, metni değiştir) |
| Nudge sağlığı | Bildirim kapatma oranı | ≤%15 (yüksekse rahatsız ediyoruz) |
| Mikro-sprint | Teklif → tamamlama | ≥%50 |
| Mikro-sprint etkisi | Mikro yapan kullanıcının ertesi gün dönüşü | Tam oturum yapanla kıyasla ≥%80 |
| Off-ramp | "5 dk daha" tıklanması | %10–25 arası sağlıklı (çok yüksekse oturumlar kısa geliyor) |
| Easter egg | "Yolun sonundaki not" açılma oranı | ≥%40 (path bitirenler arasında) |
| Ton | Uygulama içi mikro-anket: "Uygulamanın dili sana nasıl geliyor?" | ≥4.2/5 |
| Erişilebilirlik | reduced-motion kullanıcı oranı | Sadece izleme — ürün kararı için |

**Kırmızı bayrak metriği:** Bildirim kapatma oranı %25'i geçerse nudge motoru **tamamen durdurulur** ve baştan tasarlanır. Bu üründe rahatsız etmek, kullanmamaktan kötüdür.

---

## 10. Uygulama önceliği

| # | Öğe | Faz | Efor | Etki |
|---|---|---|---|---|
| 1 | Kişilik spektrumu + yasak ifade listesi | **Faz 1** | S | **Yüksek** |
| 2 | Tüm mikrometin (boş/hata/yükleme/buton) | **Faz 1** | M | Yüksek |
| 3 | Tercih keşfi (3 soru) | **Faz 1** | S | Yüksek |
| 4 | Bildirim gizlilik kuralı | **Faz 1** | S | **Kritik** |
| 5 | Off-ramp (her oturum sonu) | **Faz 1** | S | Yüksek |
| 6 | Nefes senkron dalga animasyonu | **Faz 1** | M | Yüksek |
| 7 | Reduced-motion + erişilebilirlik | **Faz 1** | M | **Kritik** |
| 8 | Mikro-sprint sistemi | Faz 2 | M | Yüksek |
| 9 | Durum bazlı nudge sekansı | Faz 2 | M | Orta |
| 10 | Nudge kendini kapatma | Faz 2 | S | Orta |
| 11 | Easter egg: yolun sonundaki not | Faz 2 | S | **Yüksek (duygusal)** |
| 12 | Kutlama kalibrasyonu + rozet animasyonu | Faz 2 | M | Orta |
| 13 | Easter egg: uzun basılan nefes | Faz 3 | S | Düşük |
| 14 | Mevsimsel içerik | Faz 3 | L | Orta |
| 15 | Pazar akşamı oturumu | Faz 3 | S | Orta |

---

## 11. Karar günlüğü (bu ek için)

| # | Karar | Skill'in varsayılanı | Neden saptık |
|---|---|---|---|
| 1 | Dört kademeli kişilik spektrumu | Tek marka sesi | Kriz ve kutlama aynı tonda olamaz |
| 2 | Konfeti / emoji / rainbow modu yok | Whimsy kütüphanesinin merkezi | Kaygılı kitlede ciddiyetsizlik sinyali |
| 3 | Variable-reward loop yok | "Advanced capability" olarak öneriliyor | Kumar psikolojisi; PRD kararı #5 ile çelişir |
| 4 | Sadece push, SMS/e-posta yok | Çoklu kanal nudge | Ruh sağlığı verisi kilit ekranında görünmemeli |
| 5 | Bildirim metni path adını içermez | Kişiselleştirilmiş nudge | Aynı gizlilik gerekçesi |
| 6 | Off-ramp varsayılan buton "kapat" | "Want to do 5 more minutes?" birincil | Güven, ekstra dakikadan değerli |
| 7 | Nudge frekansı zamanla azalır | Eskalasyon sekansı | Israr, bu kitlede terk sebebi |
| 8 | Default bias ödemede kullanılmaz | "Opt-out architectures" | Dark pattern sınırı |
| 9 | Ses efektleri varsayılan kapalı | — | Beklenmedik ses = irkilme |
| 10 | Whimsy bütçesi: oturum başına 2 | Sınır yok | Delight enflasyonu, dikkat dağıtır |
| 11 | Kova C'de kutlama 0/5 ama rozet var | — | Emek tanınır, sonuç uydurulmaz |
| 12 | Mevsimsel kutlama teması yok | "Seasonal campaigns" | Tatiller bu kitlede zor dönemler |
