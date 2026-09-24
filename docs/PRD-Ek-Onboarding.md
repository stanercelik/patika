# PRD Eki — Onboarding Akışı

**Ana doküman:** PRD.md · **İlgili ek:** PRD-Ek-Ton-ve-Nudge.md
**Durum:** Taslak v0.1
**Tarih:** 4 Eylül 2026

> **24 Eylül 2026 güncellemesi:** İlk tam kişisel oturumun G2 özeti
> sonrasında RevenueCat paywall açılır. F4 fiyat ekranı ve gün 7 ödeme
> taslağı geçersizdir. Ayrıntı [monetization.md](monetization.md).

---

## 0. Yönetici özeti

**Toplam: 31 ekran, hedef süre 4–5 dakika (3 dakikası gerçek meditasyon).**

Uzun geliyor olabilir ama bu, sağlık/fitness kategorisinin ortalamasının (25 ekran) hafif üstü ve Duolingo'nun kayıt öncesi 60 ekranının yarısı. Ekran sayısı sorun değil; **her ekranın kullanıcı hakkında olmaması** sorun.

**Tek kuralımız:** Her ekran ya kullanıcı hakkında bir şey öğrenir, ya öğrendiğimizi ona geri yansıtır. Kendimizden bahseden tek bir ekran yok.

**Akışın omurgası:**

```
Kanca (2) → Problem keşfi (6) → Yansıtma & ikna (4) → Ölçüm (9)
→ Tercihler (3) → Üretim & teslim (4) → İLK DEĞER (2) → Hesap & izin (3)
```

**En kritik üç karar:**

1. **Paywall onboarding'de YOK.** Yerine fiyat şeffaflığı ekranı var (Bölüm 7).
2. **Kayıt en sona.** Duolingo modeli — kullanıcı ilk meditasyonunu dinledikten sonra kayıt olur.
3. **İlk oturum onboarding'in içinde ve kullanıcının kendi kelimelerini içerir.** Aha momenti bu.

---

## 1. Neden bu kadar uzun? (İç savunma)

Ekibin ilk itirazı "çok uzun" olacak. Cevaplar:

**Veri ne diyor:**

- Ortalama uygulama 25 onboarding ekranına sahip; en uzun kategoriler finans, sağlık, fitness ve eğitim. En uzun akışlara sahip uygulamaların bazıları aynı zamanda en başarılı olanlar.
- Duolingo, incelenen 986 uygulama arasında en uzun akışlardan birine sahip: kayıt olmadan önce 60 ekran. Ve uzun hissettirmiyor.
- Cal AI 20 adımlık akışıyla indirme başına ~2.50 dolar üretiyor.
- Houzz kayıt formunu birden fazla ekrana böldüğünde dönüşüm %15 arttı — yani bir yere eklenen sürtünme, başka bir yerdeki sürtünmeyi kaldırıyor.

**Ama karşı uyarı da gerçek:**

- 2 dakikayı aşan onboarding kullanıcıları ciddi şekilde sıkmaya başlıyor (Medaxa/Selim Şen sunumu).

**Çelişki nasıl çözülür:** Süre değil, **his** önemli. Sıkan şey ekran sayısı değil, _kendisi hakkında olmayan_ ekran sayısı. Bizim akışta soru bölümü **2 dakika 20 saniye** hedefinde; kalan süre kullanıcının kendi meditasyonunu dinlemesi — o zaten ürünün kendisi, onboarding değil.

**Zaman bütçesi:**

| Bölüm                   | Ekran  | Hedef süre  |
| ----------------------- | ------ | ----------- |
| A — Kanca               | 2      | 12 sn       |
| B — Problem keşfi       | 6      | 55 sn       |
| C — Yansıtma & ikna     | 4      | 30 sn       |
| D — Ölçüm               | 9      | 60 sn       |
| E — Tercihler           | 3      | 18 sn       |
| F — Üretim & teslim     | 4      | 35 sn       |
| **Soru bölümü toplamı** | **28** | **~3:30**   |
| G — İlk oturum          | 2      | 3:00 (ürün) |
| H — Hesap & izin        | 3      | 25 sn       |

---

## 2. BÖLÜM A — Kanca (2 ekran)

### A1 — Ürünü hareket halinde göster

**Tip:** Animasyon, metin minimum. Buton: tek.

En iyi onboarding ekranlarının ortak özelliği özellik listelemek değil, sonucu satmak. Bazı uygulamalar bunu animasyonla yapıyor — uygulamayı açtığın an tek kelime okumadan ne yaptığını hissediyorsun.

**Ekranda ne var:** 4 saniyelik döngüsel animasyon. Bir yol çiziliyor, adımlar sırayla doluyor, sonda iki bar yan yana beliriyor ve biri diğerinden kısalıyor. Metin:

> **"Sonu olan bir yol."**
> Derdini anlat, sana özel bir program çıkaralım. 21 gün sonra neyin değiştiğini birlikte görelim.
>
> `[Başlayalım]`

**Neden böyle:** Kullanıcı App Store'da zaten ekran görüntülerini gördü. Onboarding'de aynı görselleri tekrarlamak en yaygın hatalardan biri — kullanıcıyı gereksiz yere yormak demek. Bu yüzden A1, mağaza görsellerinin **hiçbirini** tekrarlamaz; mağazada statik ekranlar varsa burada hareket var.

**Yasak:** Kaydırmalı 4 ekranlık "özellikler" karuseli. Kullanıcı "next next" yapacaksa o ekranları hiç koymamak daha iyi.

### A2 — İlk soru, hemen

**Tip:** Çoklu seçim kartları. **Maks 2 seçim.**

> **"Seni buraya ne getirdi?"**
>
> 😰 Kaygı, huzursuzluk
> 🌙 Uyuyamamak
> 🔥 Tükenmişlik, bitkinlik
> 🎯 Odaklanamamak
> 💢 Öfke, sinirlilik
> 🫥 Kendime sert davranmak
> 👥 Sosyal ortamlar
> 📚 Sınav, performans baskısı
> 💔 Ayrılık, kayıp
> ❓ Tam adını koyamıyorum
>
> `[Devam]`

**Neden çoklu seçim:** Headspace kullanıcılarının uygulamaya birden fazla sorunla geldiğini fark etti; tek hedef seçtirmek yerine birden fazla seçmelerine izin verdiler ve bu basit değişiklik ücretsiz deneme dönüşümünde %10 artış getirdi.

**Neden ilk ekran soru:** Kullanıcı ilk 5 saniyede ürünün kendisiyle ilgilendiğini görmeli. "❓ Tam adını koyamıyorum" seçeneği kritik — kaygının en yaygın hâli isimsiz olanıdır ve bu seçeneği koymamak o kullanıcıyı dışlar.

---

## 3. BÖLÜM B — Problem keşfi (6 ekran)

> Bu bölümün amacı iki katlı: (1) path'i gerçekten kişiselleştirecek veriyi toplamak, (2) kullanıcıya "beni dinliyor" hissini vermek. İkincisi birincisinden önemli.

### B1 — Kendi cümlelerinle

**Tip:** Serbest metin. Atlanabilir ama güçlü teşvik edilir.

> **"Kendi cümlelerinle anlatır mısın?"**
>
> _Ne kadar kısa ya da uzun istersen. Bu metni kimse okumuyor — sadece sana bir yol çizmek için kullanılıyor._
>
> `[metin alanı — placeholder: "Akşamları yatağa girince zihnim durmuyor..."]`
>
> `[Devam]` · `Yazmak istemiyorum`

**Neden bu ekran akışın en değerli ekranı:** Bu metin, F2'de kullanıcıya geri yansıtılacak ve G1'de **kendi kelimeleriyle seslendirilecek**. Aha momentinin yakıtı burada toplanıyor. Bu yüzden "atla"yı görünür ama ikincil tutuyoruz.

**Placeholder rotasyonu:** A2'de seçilen kategoriye göre placeholder değişir. Uyku seçtiyse yukarıdaki, tükenmişlik seçtiyse _"Sabah kalktığımda zaten yorgunum..."_. Küçük ama doldurma oranını ciddi artıran bir detay.

> ⚠️ **KRİTİK — Kriz kontrolü burada.** Metin gönderildiği anda sınıflandırıcıdan geçer. Sinyal varsa akış durur ve PRD Bölüm 11.1'deki ekran gösterilir. Path üretilmez, ölçüm yapılmaz, kayıt istenmez.

### B2 — Süre

> **"Bu ne kadar zamandır böyle?"**
> Birkaç gündür · Birkaç haftadır · Aylardır · Yıllardır · Emin değilim

### B3 — Zamanlama

> **"Genelde ne zaman ortaya çıkıyor?"**
> Sabah uyanınca · Gün içinde · Akşama doğru · Yatağa girince · Belli bir zamanı yok

**Neden soruyoruz:** Bu cevap doğrudan E1'deki varsayılan hatırlatma saatini belirliyor. Sorduğumuz her şeyin görünür bir karşılığı olmalı.

### B4 — Kaçınma

> **"Bu yüzden yapmaktan kaçındığın bir şey var mı?"**
>
> _Örneğin: bir konuşmayı ertelemek, bir yere gitmemek, bir işe başlamamak._
>
> `[kısa metin alanı]` · `Yok / emin değilim`

**Neden:** Kaçınma davranışı, ölçüm sisteminin en sağlam metriği (PRD 8.2) ve path'in ikinci yarısının omurgası. Ayrıca kullanıcıya "bu soru fazla iyi soruldu" hissi verir.

### B5 — Daha önce ne denedin?

**Tip:** Çoklu seçim.

> **"Daha önce ne denedin?"**
> Başka meditasyon uygulamaları · YouTube videoları · Terapi (şu an devam ediyor) · Terapi (geçmişte) · Nefes egzersizleri · Hiçbir şey · Diğer

**Neden:** Cal AI, kullanıcıya uygulamayı nereden duyduğunu ve benzer uygulamalar denediğini soruyor — kullanıcı akışı bitirmese bile bu bedava pazar araştırması.

Bizde ek işlevi var: **"Terapi (şu an devam ediyor)"** seçilirse ton değişir (_"Terapinle birlikte kullanabileceğin bir şey kuralım"_) ve ürün asla terapinin yerine geçme imasında bulunmaz. **"Başka meditasyon uygulamaları"** seçilirse C3'te karşılaştırma ekranı gösterilir, seçilmezse atlanır.

### B6 — Şu an nasılsın? (yumuşak geçiş)

**Tip:** 5'li ölçek, tek dokunuş.

> **"Şu an, tam bu anda nasılsın?"**
> _Tek dokunuş yeter._
>
> Çok ağır · Ağır · Ortalarda · Fena değil · Sakin

**Neden:** Ölçüm bölümüne ısınma. Ayrıca bu, günlük ön kontrolün aynısı — kullanıcı ürünün ritmini onboarding'de öğrenmiş oluyor.

> ⚠️ **Emoji ölçek uygulanmadı** (karar #13). Bu ekran yukarıda 😔😕😐🙂😌 olarak tarif edilmişti; emoji üründe hiçbir yerde kullanılmıyor — çok renkli, platforma göre değişken ve tek mürekkepli tasarım sistemini bozuyor. Yerine monokrom SF Symbols hava metaforu (`cloud.heavyrain` → `sun.max`): aynı beş kademe, aynı tek dokunuş, aynı skorlama.
>
> Etiketler yargısız seçildi — "kötü" değil "ağır". Kullanıcı kendi hâline not vermiyor, tarif ediyor. İkonun altında yalnızca **seçili** kademenin etiketi yazar: beş etiketi birden göstermek satırı okunmaz yapıyor, hiç göstermemek ise anlamı ikona bırakıyor (renk/şekil tek başına anlam taşımaz — Ton eki §7).

---

### B bölümü — uygulama notları

_Uygulandı: 2026-09-08._

**İlerleme ölçeği.** Soru bölümü = A2 + B1–B6, yani 7 ekran. İz B6'da dolar. C bölümünde soru sorulmadığı için iz **solar** ve D bölümü kendi ölçeğiyle yeniden başlar. 31 ekranın tamamı üzerinden tek bir ölçek göstermek caydırıcı olurdu.

**Kaçış kapıları seçeneğin içinde.** §10 tablosu B2–B4'ü atlanabilir sayıyor, ama B2 ve B3'e ayrı bir "geç" bağlantısı konmadı: _"Emin değilim"_ ve _"Belli bir zamanı yok"_ zaten dürüst birer cevap. Atlamakla bilmemek aynı şey değil ve ikincisi daha iyi veri. B1, B4 ve B5'te çıkış açık bir ikincil bağlantı.

**Serbest metin alanlarında otomatik düzeltme kapalı.** B1 ve B4'te kullanıcının kendi kelimeleri ürünün kendisi: bu metin F2'de geri yansıtılıyor ve G1'de seslendiriliyor. Türkçe otomatik düzeltmenin cümleyi yeniden yazması, sonra kullanıcıya yazmadığı bir cümleyi okutmak demek. Karakter sayacı da yok — yazmayı ödeve çevirir.

**Kriz taraması B1 ve B4'te.** §3.1 taramayı yalnızca B1'de tarif ediyor; B4 de serbest metin olduğu için oraya da uygulandı. "Kullanıcının yazdığı her serbest metin sınıflandırıcıdan geçer" kuralı istisnasız.

> ⚠️ **Sunucu sınıflandırıcısı hâlâ bloklayıcı eksik.** Şu an cihazda çalışan bir **ön filtre** var (`CrisisClassifier`): anahtar ifade taraması, Türkçe küçük harf ve aksansız yazım normalizasyonu ile. İma, mecaz ve yazım hatası yakalamıyor. Eşik bilerek gevşek — yanlış pozitifin bedeli kullanıcının yardım ekranını görmesi, yanlış negatifin bedeli kriz sinyali vermiş birine program satmaya çalışmak. Path üretimi eklendiğinde metin sunucuda **yeniden** değerlendirilmeli (PRD §11.1).

**B3 → E1 bağı kodda.** `ProblemTiming.suggestedReminderHour` cevabı doğrudan hatırlatma saatine çeviriyor ve saat şikâyetin **öncesine** denk geliyor. Ekranın ipucu bunu kullanıcıya söylüyor ("Hatırlatma saatini buna göre öneriyoruz") — sorduğumuz her şeyin görünür bir karşılığı olmalı.

**B5 → C3 ve terapi tonu kodda.** `PreviousAttempt.showsLibraryComparison` C3'ün koşulu; `requiresTherapyAwareTone` terapi notunu açıyor. Bayraklar enum üzerinde, ekranda `if` ile hesaplanmıyor. "Hiçbir şey" seçeneği diğerleriyle birlikte seçilemez (`isExclusive`) — çelişki uyarı göstermeden sessizce çözülür.

---

## 4. BÖLÜM C — Yansıtma ve ikna (4 ekran)

> Burada soru sormuyoruz. Anlatıyoruz. Ama kendimizden değil, **kullanıcıdan** bahsederek anlatıyoruz.

### C1 — Aynalama

**Tip:** Metin, kullanıcının verisiyle doldurulmuş.

> **"Anladığım kadarıyla:"**
>
> Akşamları yatağa girdiğinde zihnin hızlanıyor. Bu **birkaç aydır** sürüyor ve bu yüzden **yatma saatini erteliyorsun.**
>
> Bu, en sık karşılaştığımız örüntülerden biri. Ve üzerine çalışılabilir bir şey.
>
> `[Devam]`

**Neden çalışır:** Kullanıcının kendi cevapları, kendi kelimeleriyle geri veriliyor. Bu ekran hiçbir şey satmıyor ama akışın en yüksek güven üreten anı. Kullanıcı burada "bu form doldurtmuyor, beni okuyor" diye düşünüyor.

**Teknik not:** Bu metin LLM ile üretilir ama **şablon kısıtlıdır** — 3 cümle, kullanıcının kelimelerini kullanır, yorum yapmaz, teşhis koymaz.

### C2 — Yalnız değilsin (sosyal kanıt)

> ⚠️ **LANSMANDA DİKKAT:** Sıfır kullanıcıyla başlarken "10.000 kişi bunu kullanıyor" yazamayız. Uydurma sosyal kanıt hem etik dışı hem de bu kategoride yakalanınca ölümcül.

**Lansman versiyonu (kullanıcı verisi yokken):** Kategori düzeyinde dürüst veri kullan.

> **"Bu çok yaygın."**
>
> Yetişkinlerin yaklaşık üçte biri düzenli olarak uykuya dalmakta zorlanıyor.
>
> Ve iyi haber: bu, üzerine en çok çalışılmış ve en iyi sonuç alınan alanlardan biri.
>
> `[Devam]`

**Olgunluk versiyonu (3+ ay sonra, gerçek veri varken):**

> Senin gibi "akşam zihnim durmuyor" diyen **1.240 kişi** bir patika tamamladı.
> Ortalama uykuya dalma süresi **%34 kısaldı.**

**Kural:** Bu ekran, gerçek veri oluşana kadar **sayı içermez.** Veri geldiğinde ekran değişir, önceden yazılmaz.

### C3 — Neden kütüphane değil, yol _(koşullu: B5'te başka uygulama denemişse)_

**Tip:** Basit görsel karşılaştırma.

> **"Daha önce denediysen, muhtemelen böyle bitti:"**
>
> ❌ Yüzlerce başlık, nereden başlayacağını bilememek
> ❌ Birkaç gün, sonra unutmak
> ❌ İşe yarayıp yaramadığını hiç bilememek
>
> **Biz farklı bir şey deniyoruz:**
>
> ✓ Tek bir yol, sırası belli
> ✓ Başında ve sonunda ölçüm
> ✓ Sonunda ne değiştiğini rakamla görüyorsun
>
> `[Devam]`

**Neden koşullu:** Hiç meditasyon uygulaması denememiş kullanıcı için bu ekran anlamsız ve akışı uzatır. Denemiş olan için ise en ikna edici ekran — çünkü tarif edilen başarısızlık onun kendi hikâyesi.

### C4 — Dürüst beklenti (Cal AI dersi)

> **"Baştan söyleyelim:"**
>
> İlk 2–3 gün muhtemelen büyük bir fark hissetmeyeceksin. Bu normal.
>
> Değişim genelde **7–10. günde** fark edilmeye başlıyor. Zaten ilk ölçümünü 7. günde yapacağız — o zaman rakamlarla göreceksin.
>
> `[Anladım]`

**Neden bu ekran değerli:** Cal AI, "kilo vereceksin" demek yerine ilk sonuçların yavaş olduğunu, momentum kazanmanın zaman aldığını söylüyor. Aşırı vaat vermek yanlış beklenti kurar; baştan dürüst olmak hem iade taleplerini azaltıyor hem de güven ve inandırıcılık inşa ediyor.

Bizde ekstra iki işlevi var:

1. **Erken churn'ü düşürür.** 3. günde "işe yaramıyor" diye bırakacak kullanıcıya cevap önceden verilmiş oluyor.
2. **7. gün paywall'ını önceden kuruyor.** Kullanıcı ödeme anını beklenen bir kilometre taşı olarak görüyor, sürpriz olarak değil.

---

## 5. BÖLÜM D — Baseline ölçüm (9 ekran)

### D0 — Ölçüm giriş ekranı

> **"Şimdi 8 kısa soru."**
>
> Bunlar senin başlangıç noktan. **Aynılarını 7. günde tekrar soracağız** — ne değiştiğini görmek için.
>
> Yaklaşık 1 dakika sürüyor. Doğru cevap yok.
>
> `[Başla]`

**Neden ayrı bir giriş ekranı:** Soruların _neden_ sorulduğunu bilmeyen kullanıcı, form dolduruyor gibi hisseder ve terk eder. Bir cümlelik gerekçe, tamamlanma oranını belirgin şekilde artırır.

### D1–D8 — Sorular (her biri ayrı ekran)

Houzz kayıt formunu birden fazla ekrana böldüğünde dönüşüm %15 arttı. Aynı mantık: 8 soruyu tek ekrana yığmak "iş" gibi görünür; teker teker göstermek "hızlı" hissettirir.

**Yapı:** Her ekranda tek soru, üstte ince ilerleme çubuğu (`3 / 8`), altta 5–7 dokunmatik seçenek. Geri butonu var.

| #   | Katman      | Örnek soru                                                       | Tip                                  |
| --- | ----------- | ---------------------------------------------------------------- | ------------------------------------ |
| D1  | Duygu       | "Son 3 günde bu his ne kadar güçlüydü?"                          | 0–10 kaydırıcı                       |
| D2  | Duygu       | "Gün içinde bu duygu kaç kez kapını çaldı?"                      | 5 kova                               |
| D3  | Davranış    | "Dün gece uykuya dalman ne kadar sürdü?"                         | <15dk / 15-30 / 30-60 / 1-2sa / 2sa+ |
| D4  | Davranış    | "Son bir haftada bu yüzden ertelediğin/kaçındığın kaç şey oldu?" | 0 / 1-2 / 3-5 / 5+                   |
| D5  | Davranış    | _Path tipine özel_ (PRD 8.5)                                     | değişken                             |
| D6  | Öz-yeterlik | "Bu his geldiğinde ne yapacağımı biliyorum."                     | 1–5 katılıyorum                      |
| D7  | Öz-yeterlik | "Bu durumun değişebileceğine inanıyorum."                        | 1–5                                  |
| D8  | Etki        | "Bu, günlük hayatını ne kadar etkiliyor?"                        | 1–5                                  |

**Kritik kural:** Bu ekranların sonunda **hiçbir skor gösterilmez.** (PRD 7.3) Skorlar ilk kez 7. günde, karşılaştırmalı olarak görünür.

---

## 6. BÖLÜM E — Tercihler (3 ekran)

> Bu bölüm "kişiselleştirme tiyatrosu" değil. Kullanıcıya renk seçtirmek kişiselleştirme değildir — gerçek kişiselleştirme, cevabın uygulamanın davranışını değiştirmesidir. Buradaki üç cevabın üçü de ürünün davranışını doğrudan değiştiriyor.

### E1 — Ne zaman?

**Varsayılan yanlılığı uygulanmış** (PRD-Ek 5.6). B3'teki cevaba göre önceden doldurulmuş:

> **"Günlük adımın için 22:30'u ayarladım."**
> _"Yatağa girince" demiştin — yatmadan biraz önce iyi çalışıyor._
>
> `[Uygun]` · `Başka saat seç`

### E2 — Ne kadar?

> **"Adımların ne kadar sürsün?"**
> 5 dakika (kısa ve öz) · **10 dakika (önerilen)** · 15 dakika (derin)

### E3 — Nasıl bir dil?

> **"Sana nasıl bir ses iyi gelir?"**
> Sakin ve kısa · Biraz daha yönlendirici · Sadece bilgi, yorum yok

**Neden E3:** PRD-Ek Bölüm 5.1'deki ton tercihi. Ayrıca bu, TTS prompt'una doğrudan giriyor — yani kullanıcı gerçekten farkı duyacak.

---

## 7. BÖLÜM F — Üretim ve teslim (4 ekran)

> Akışın zirvesi burası. Kullanıcı 3 dakikadır soru cevaplıyor; şimdi karşılığını görmesi lazım.

### F1 — Üretim ekranı

Cal AI'ın plan hesaplama ekranı muhtemelen kısmen performatif ama akışın temasını sürdürüyor: bu anket, uygulamayı sadece bu kullanıcı için kişiselleştirmek içindi.

Bizde **performatif değil, gerçek** — path üretimi cidden 10–20 saniye sürüyor. O yüzden adımları göstererek bekleyişi değere çeviriyoruz:

```
✓ Yazdıklarını okudum
✓ Sana uygun adımları seçtim
◐ Yolu sıraya diziyorum...
○ Sesini hazırlıyorum
```

Her satır tamamlandıkça işaretleniyor. Espri yok — kullanıcı az önce derdini anlattı, bu an ciddi (PRD-Ek 3.3).

### F2 — ⭐ Kişiselleştirilmiş sonuç ekranı

**Akışın en önemli ekranı.** Bazı uygulamalar quiz'de sadece cevap toplamıyor; o cevapların neyi açtığını gösteriyor. Kullanıcı ürünü henüz kullanmadı ama şimdiden işe yarayacakmış gibi hissediyor. BitePal quiz'den sonra kişisel planı kuruyor ve hedefe tam olarak ne zaman ulaşılacağını söylüyor.

```
        Yolun hazır.

  ┌─────────────────────────────────┐
  │  Zihni akşam yavaşlatma         │
  │  21 adım · günde 10 dakika      │
  └─────────────────────────────────┘

  Gün 1–3    Rahatlama
             Zihni yavaşlatan temel teknikler

  Gün 4–7    Farkındalık
             Zihnini ne hızlandırıyor, birlikte bakacağız

  ⭐ Gün 7   İlk ölçüm
             Ne değiştiğini rakamla göreceksin

  Gün 8–14   Beceri
  Gün 15–20  Kaçınmayla yüzleşme
  Gün 21     Kapanış ve son ölçüm

        [Yola çık]
```

**Neden çalışır:** Kullanıcı (a) somut bir plan görüyor, (b) 7. günde bir ödül noktası olduğunu biliyor, (c) fazların isimleri onun cevaplarından türetilmiş.

### F3 — Yol haritası önizleme

F2'den kaydırınca gerçek path haritasına geçiş. **Tüm 21 adımın başlıkları okunur** (PRD 7.5), sadece 1. adım açık.

> `Gün 12 — Kaçınmayla yüzleşme` gibi başlıklar merak üretir. Kullanıcı neyi bırakacağını görmüş olur.

#### Eski karar: burada paywall yok (24 Eylül 2026'da değiştirildi)

**Güncel akış:** F4 ayrı fiyat ekranı ve gün 7 ödeme noktası kaldırıldı.
İlk kişisel oturum gerçekten tamamlanıp G2 özeti geçildiğinde RevenueCat
paywall gösterilir; hesap bağlama sonra isteğe bağlıdır. Yarım oturumda ödeme
istenmez. Kullanıcı paywall'ı kapatıp ücretsiz içeriğe geçebilir ve aynı
patikayı Yolum'dan sonra alabilir. Aşağıdaki gerekçeler eski karar günlüğüdür;
`docs/monetization.md` geçerlidir.

İncelenen uygulamaların %22'si onboarding sırasında paywall gösteriyor ve bu, kısa vadeli gelir için işe yarıyor. Biz bilerek yapmıyoruz. Gerekçeler:

1. **Konumlandırmayla çelişir.** Ürünün tüm iddiası "işe yaradığını gördükten sonra öde." Onboarding'de ödeme istemek bu iddiayı ilk 4 dakikada çürütür.
2. **Kova C sözünü imkânsızlaştırır.** "İlerleme yoksa devam ücretsiz" (PRD 7.9) taahhüdü, önden para almış bir üründe anlamsızdır.
3. **Sürpriz yok = 7. gün dönüşümü yüksek.** Fiyatı baştan bilen kullanıcı 7. günde şok yaşamaz. Sürprizler dönüşüm öldürür.
4. **Kategori riski.** Ruh sağlığı alanında agresif önden satış, mağaza incelemesinde ve basında ciddi risk.

**Kabul ettiğimiz bedel:** İlk 6 günde para kazanmıyoruz ve edinme maliyetini geri kazanma süresi uzuyor. Bu, bilinçli bir LTV-üstü-CAC bahsi. Bölüm 11'de bunun A/B testi tanımlı.

---

## 8. BÖLÜM G — İlk değer / Aha momenti (2 ekran)

> Duolingo'nun akışında kullanıcı ilk dersini **kayıt olmadan önce** yapıyor ve tamamlama tatminini yaşıyor. Kayıt ondan sonra geliyor. Biz de aynısını yapıyoruz.

### G1 — İlk oturum, hemen

3–4 dakikalık kısaltılmış 1. adım. **Ve içinde kullanıcının kendi kelimeleri var.**

Rehber ses şöyle başlıyor:

> _"Akşamları zihnin durmuyor demiştin. Şimdi birlikte onu biraz yavaşlatacağız..."_

**Bu tek cümle, tüm onboarding'in karşılığı.** Kullanıcı hiçbir uygulamada duymadığı bir şey duyuyor: kendi cümlesi, kendisine geri okunuyor. Rakiplerin hiçbiri (Calm, Headspace, hatta ELYND/StillMind) bunu onboarding içinde yapmıyor.

**Teknik not:** Kayıtsız kullanıcı için bir TTS üretimi ≈ €0.02. Kötüye kullanım riski cihaz kimliğiyle sınırlanır (cihaz başına 1 ücretsiz üretim). Bu maliyet, aha momentinin karşılığında önemsiz.

### G2 — Oturum sonu

> **"İlk adım tamam."**
>
> Yolunda 20 adım daha var. Yarın 22:30'da buradayız.
>
> `[Devam]`

Kutlama şiddeti 1/5 (PRD-Ek Bölüm 6). Konfeti yok.

---

## 9. BÖLÜM H — Hesap ve izinler (3 ekran)

### H1 — Kayıt

> **"İlerlemeni kaydedelim mi?"**
>
> Yolun, ölçümlerin ve yazdıkların bu cihazda duruyor. Hesap açarsan kaybolmaz.
>
> `[Apple ile devam et]`
> `[Google ile devam et]`
> `[E-posta ile]`
>
> `Şimdilik geç`

**Neden en sonda:** Kullanıcı artık bir şey kazandı — kişisel bir yol ve dinlediği bir oturum. Kaydetmek istemesi için sebebi var. Başta sorsaydık, hiçbir şey karşılığında kimlik istemiş olurduk.

**"Şimdilik geç" gerçekten çalışır.** Kullanıcı 3 gün cihazda devam edebilir, 4. günde tekrar sorulur.

### H2 — Bildirim ön hazırlığı _(OS penceresinden ÖNCE)_

Birçok uygulama bildirim izni penceresinden önce kendi ekranını gösteriyor ve bu, kabul oranlarını belirgin şekilde artırıyor. Bazıları bir adım daha ileri gidip izin verilirse gelecek bildirimi önizletiyor.

```
        Sana hatırlatalım mı?

  ┌──────────────────────────────┐
  │  🔔  Patika                  │
  │      Bugünün adımı hazır.    │
  │                        22:30 │
  └──────────────────────────────┘

  Bildirimlerimiz böyle görünüyor. Kısa,
  günde en fazla bir tane — ve neyle
  uğraştığın asla yazmaz.

  Kaçırırsan hiçbir şey sıfırlanmaz.

    [Hatırlatmaları aç]
    [Şimdilik istemiyorum]
```

**Üç ikna unsuru bir arada:** gerçek bildirim önizlemesi, gizlilik güvencesi (PRD-Ek 5.2), ve suçluluk yokluğu vaadi.

### H3 — OS izin penceresi

Sadece H2'de "aç" seçilirse `UNUserNotificationCenter.requestAuthorization` çağrılır. Reddedilirse tekrar sorulmaz; 7. gün ölçüm ekranında bir kez daha nazikçe önerilir (bu sefer Ayarlar'a derin bağlantıyla).

**İstenen yetkiler:** `[.alert, .sound, .badge]` — `.provisional` **kullanılmıyor**. Sessiz bildirim izni teknik olarak cazip ama kullanıcıyı bilgilendirmeden bildirim göndermek bu üründe güven ihlali olur; H2'de zaten açıkça soruyoruz.

> **Diğer izinler burada İSTENMEZ.** İzinleri açılışta toplu istemek en kötü kalıplardan biri — kullanıcı "daha içeri girmedim, niye bu kadar şey istiyorsun" diye düşünüyor. İzinler akışta gerçekten ihtiyaç duyulduğu anda istenmeli. Bizde başka izin zaten yok.

---

## 10. Akış diyagramı ve çıkış noktaları

```
A1 Animasyon
 └→ A2 Neden buradasın? (çoklu)
     └→ B1 Serbest metin ──[KRİZ SİNYALİ]──→ 🔴 Kriz ekranı → AKIŞ SONU
         └→ B2 Süre
             └→ B3 Zamanlama
                 └→ B4 Kaçınma
                     └→ B5 Ne denedin?
                         └→ B6 Şu an nasılsın?
                             └→ C1 Aynalama
                                 └→ C2 Yalnız değilsin
                                     └→ C3 Kütüphane vs yol ⟨koşullu⟩
                                         └→ C4 Dürüst beklenti
                                             └→ D0 Ölçüm girişi
                                                 └→ D1…D8
                                                     └→ E1 Saat
                                                         └→ E2 Süre
                                                             └→ E3 Ton
                                                                 └→ F1 Üretim
                                                                     └→ F2 ⭐ Plan
                                                                         └→ F3 Harita
                                                                             └→ F4 Fiyat
                                                                                 └→ G1 İlk oturum
                                                                                     └→ G2 Kapanış
                                                                                         └→ H1 Kayıt
                                                                                             └→ H2 Bildirim
                                                                                                 └→ H3 OS
                                                                                                     └→ 🏠 Ana ekran
```

**Kaçış kapıları (No Escape Room kuralı):**

| Ekran      | Atlanabilir mi   | Sonuç                                               |
| ---------- | ---------------- | --------------------------------------------------- |
| A2         | ❌               | Path tipi buradan belirleniyor                      |
| B1 (metin) | ✅               | Kişiselleştirme zayıflar, jenerik şablon kullanılır |
| B2–B4      | ✅ tek tek       | Eksik veri varsayılanla doldurulur                  |
| B5, B6     | ✅               | —                                                   |
| C1–C4      | ✅ (hızlı geç)   | —                                                   |
| D1–D8      | ⚠️ **Atlanamaz** | Baseline olmadan ürünün çekirdek vaadi çalışmaz     |
| E1–E3      | ✅               | Varsayılanlar uygulanır                             |
| G1         | ✅               | Ama atlama oranı >%20 ise ciddi sorun sinyali       |
| H1         | ✅               | Cihazda devam                                       |
| H2         | ✅               | —                                                   |

**D bölümü neden atlanamaz:** Ölçüm, bizim üründe "isteğe bağlı anket" değil, ürünün kendisi. Atlayan kullanıcı 7. günde karşılaştırma göremez, Kova sistemi çalışmaz, ücretsiz devam sözü anlamsızlaşır. Bunun yerine D0'da neden gerekli olduğunu iyi anlatıyoruz.

---

## 11. Segmentasyon → farklılaştırılmış teklif

Medaxa'nın uyguladığı yöntem: sorularla kullanıcı segmentlere ayrılıyor (örneğin business/uzun kullanım vs personal/kısa kullanım gibi 4 segment), her segmente ayrı paywall, ayrı fiyat, bazılarında deneme var bazılarında yok. Bu, en iyi optimize ettikleri kaldıraçlardan biri olmuş.

Grammarly de quiz cevaplarına göre uyarlanmış fiyat planları öneriyor ve bu tek başına plan yükseltmelerinde neredeyse %20 artış getirmiş.

**Bizim segmentasyonumuz** (onboarding verisinden otomatik):

| Segment                 | Sinyal                                  | 7. gün teklifi                                                                 |
| ----------------------- | --------------------------------------- | ------------------------------------------------------------------------------ |
| **S1 — Akut**           | B2: "birkaç gün/hafta" + D8 yüksek etki | Tek path öne çıkar (€14.99). Hızlı çözüm arıyor, aboneliğe hazır değil         |
| **S2 — Kronik**         | B2: "aylardır/yıllardır"                | Abonelik öne çıkar (€12.99/ay). Bu bir maraton, süreklilik vurgusu             |
| **S3 — Deneyimli**      | B5: başka uygulama denemiş              | Yıllık plan öne çıkar (€79). Kategoriyi biliyor, fiyat karşılaştırması yapıyor |
| **S4 — Terapi altında** | B5: "terapi devam ediyor"               | Tek path. Tamamlayıcı konumlandırma, asla "terapi yerine" değil                |
| **S5 — Belirsiz**       | A2: "adını koyamıyorum"                 | Hazır path'ler öne çıkar, ücretsiz katmanda tutulur                            |

**Not:** Bu farklılaştırma **fiyatta değil, vurguda.** Aynı kullanıcıya farklı fiyat göstermek (gizli fiyat ayrımcılığı) hem etik hem de yasal olarak sorunlu. Farklılaşan şey hangi planın öne çıktığı.

---

## 12. Ölçüm — ekran bazında funnel

Kurulumdan sonra kaç kişinin paywall'ı gördüğü çoğu uygulamada şaşırtıcı derecede düşük — kalabalık pazarlarda tek haneli oranlar görülebiliyor, çünkü kullanıcılar aynı anda 10 uygulama indirip ilk memnun edeni kullanıyor.

Bu yüzden **her ekran ayrı ayrı ölçülür.**

| Ekran         | Metrik                        | Hedef     | Kırmızı çizgi    |
| ------------- | ----------------------------- | --------- | ---------------- |
| A1 → A2       | Devam                         | ≥92%      | <85%             |
| A2 → B1       | Devam                         | ≥88%      | <80%             |
| B1            | **Metin doldurma oranı**      | **≥55%**  | **<40%**         |
| B1 → B6       | Bölüm tamamlama               | ≥80%      | <70%             |
| C bölümü      | Ekran başına ortalama süre    | 5–9 sn    | <3 sn (okumuyor) |
| D0 → D8       | **Ölçüm tamamlama**           | **≥80%**  | **<65%**         |
| E → F1        | Devam                         | ≥95%      | —                |
| F2            | **Ekranda geçen süre**        | **≥8 sn** | <4 sn            |
| F4 → G1       | Devam (fiyat gördükten sonra) | ≥85%      | <75%             |
| G1            | **İlk oturum tamamlama**      | **≥70%**  | **<55%**         |
| H1            | Kayıt oranı                   | ≥65%      | <50%             |
| H2 → H3       | Bildirim kabul                | ≥60%      | <45%             |
| **Uçtan uca** | **Kurulum → G1 tamam**        | **≥45%**  | **<30%**         |

**En kritik üç metrik:** B1 doldurma, D tamamlama, G1 tamamlama. Bu üçü ürünün çekirdek vaadinin çalışıp çalışmadığını söylüyor; diğerleri UI sorunu.

> Sadece App Store Connect verisi yeterli değil — ne olup bittiğini görmek için uygulama içi analitik şart, aksi halde yanlış yere ateş edilir.

---

## 13. A/B test yol haritası

> Test yapmadan değiştirmeyin, ama test yapacağım diye de test yapmayın. Veriden çıkmamış bir teoriyle yapılan test, mevcut iyi çalışan bir akışı bozup ciddi kayıp yaratabilir. Ayrıca istatistiksel anlamlılık şart: günde 100 kurulum alan bir uygulamada yapılan test güvenilir değil, tek bir kurulum sonucu değiştirebiliyor.

**Bu yüzden:** Testlere ancak **günlük 300+ kurulum** varken başlanır ve **tek ülkede** yürütülür (veriyi tek yerde biriktirmek için). Testler **simültane** (aynı anda bölünmüş kitle) olmalı — bu hafta A, gelecek hafta B karşılaştırması geçerli bir test değil.

| #   | Öncelik | Test                                                     | Hipotez                                                                                                 |
| --- | ------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| 1   | 🔴      | **F4 fiyat şeffaflığı ekranı: var / yok**                | Var olan versiyon 7. gün dönüşümünü artırır ama onboarding tamamlamayı düşürür. Net etki pozitif olmalı |
| 2   | 🔴      | **Ücretsiz adım sayısı: 3 / 6 / tüm path**               | 6, faydanın hissedildiği ana denk geliyor (PRD açık soru #6)                                            |
| 3   | 🔴      | **G1 ilk oturum: onboarding içinde / sonrasında**        | İçinde olan versiyon D30 retention'ı artırır                                                            |
| 4   | 🟠      | B1 serbest metin: zorunlu / atlanabilir                  | Zorunlu, doldurma oranını artırır ama terk oranını da                                                   |
| 5   | 🟠      | C4 dürüst beklenti ekranı: var / yok                     | Var olan, 3. gün churn'ünü düşürür                                                                      |
| 6   | 🟠      | A2: çoklu seçim / tek seçim                              | Çoklu kazanır (Headspace +%10)                                                                          |
| 7   | 🟡      | D soruları: 8 / 5                                        | 5 tamamlamayı artırır ama ölçüm güvenilirliğini düşürür                                                 |
| 8   | 🟡      | F2 plan ekranı: faz detayı var / sadece özet             | Detay merak ve güven üretir                                                                             |
| 9   | 🟡      | Onboarding sonu opsiyonel "kurucu üyelik" yıllık teklifi | Konumlandırmaya zarar vermeden ek gelir yaratır mı                                                      |

---

## 14. Yerelleştirme

Paywall ve onboarding metinleri tek dilde yazılıp tüm ülkelere aynı gösterilmemeli; kültüre uygun yerelleştirme dönüşümde gerçek fark yaratıyor. Küçük görünen kelime tercihleri bile ("ücretsiz deneme" mi "bedava deneyin" mi) A/B testine tabi tutulmalı.

**Bizim için özel dikkat noktaları:**

| Bölge     | Ayarlama                                                                                                                                                                         |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **TR**    | Ruh sağlığı dili damgalayıcı olabilir. "Terapi", "psikolojik destek" kelimelerinden çok "zorlanmak", "kendine iyi bakmak" tercih edilir. Fiyat TL cinsinden ve ayrı bir seviyede |
| **DE**    | Gizlilik en güçlü ikna argümanı. C2'de "verilerin Almanya'da saklanıyor" tipi bir güvence, sosyal kanıttan daha etkili olabilir                                                  |
| **EN/US** | Sosyal kanıt ve sayısal iddia daha iyi çalışıyor. Ama abartılı vaat kategoride risk                                                                                              |

**Teknik:** Metinleri remote config üzerinden yönet. Bir kelime değişikliği için mağaza incelemesi beklemek kabul edilemez — özellikle promosyon dönemlerinde anında müdahale gerekir.

---

## 15. Reddedilen kalıplar

| Kalıp                                            | Neden reddedildi                                                                                                   |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ |
| Özellik karuseli (4 ekran kaydırma)              | Kullanıcı "next next" yapacaksa hiç koymamak daha iyi                                                              |
| App Store ekran görüntülerinin tekrarı           | Kullanıcı zaten gördü; tekrarlamak yormak demek                                                                    |
| "AI destekli" vurgusu                            | Kullanıcı için hiçbir şey ifade etmiyor; "AI" öneki bir fayda değil. Biz sonuçtan bahsediyoruz, teknolojiden değil |
| Açılışta toplu izin isteme                       | En kötü kalıplardan biri; kullanıcı savunmaya geçer                                                                |
| Onboarding'de paywall                            | Bölüm 7'deki dört gerekçe                                                                                          |
| Sahte aciliyet / geri sayım sayacı               | Kaygı ürününde aciliyet üretmek etik dışı                                                                          |
| Uydurma sosyal kanıt                             | Veri yokken sayı yazmıyoruz                                                                                        |
| Renk/tema seçtirme                               | Bu kişiselleştirme değil; hiçbir ürün davranışını değiştirmiyor                                                    |
| "Değerlendirme yaz" istemi onboarding'de         | Henüz değer görmedi; erken istem tek yıldız getirir                                                                |
| Onboarding'de vaat edilip üründe olmayan özellik | Sonradan öfkeye dönüşür                                                                                            |

---

## 16. Uygulama kontrol listesi

**Faz 1 (MVP) — zorunlu:**

- [ ] 31 ekranın tamamı, TR + EN (SwiftUI, iOS 18+)
- [ ] B1 kriz sınıflandırıcı entegrasyonu **(bloklayıcı)**
- [ ] C1 aynalama metni üretimi (kısıtlı LLM şablonu)
- [ ] F2 kişiselleştirilmiş plan ekranı
- [ ] G1 kullanıcının kelimelerini içeren ilk oturum
- [ ] Ekran bazında analitik olayları
- [ ] Tüm metinler remote config'te (`String Catalog` + sunucu override)
- [ ] Dynamic Type AX5'te tüm 31 ekran kırılmıyor
- [ ] Kayıt: Sign in with Apple birincil buton
- [ ] C2'de sayı YOK (veri gelene kadar)

**Faz 2:**

- [ ] Segmentasyon → 7. gün teklif farklılaştırması
- [ ] C2 gerçek veri versiyonu
- [ ] İlk 3 A/B testi (300+ günlük kurulum sonrası)
- [ ] DE yerelleştirmesi

---

## 17. Karar günlüğü

| #   | Karar                                        | Alternatif                              | Gerekçe                                                                                               |
| --- | -------------------------------------------- | --------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| 1   | 31 ekran                                     | 8–10 ekranlık kısa akış                 | Uzunluk değil, ilgisizlik terk ettirir; kategori ortalaması zaten 25                                  |
| 2   | Onboarding'de paywall yok                    | %22'nin yaptığı gibi paywall            | Konumlandırma ve Kova C sözüyle çelişir                                                               |
| 3   | Fiyat şeffaflığı ekranı (F4)                 | Fiyatı hiç söylememek                   | 7. günde sürpriz olmaması dönüşümü artırır                                                            |
| 4   | Kayıt en sonda                               | Başta kayıt                             | Duolingo modeli; değer görmeden kimlik istememek                                                      |
| 4b  | Sign in with Apple birincil                  | E-posta birincil                        | Tek dokunuş + e-posta gizleme; ruh sağlığı ürününde gizlilik satış argümanı                           |
| 5   | İlk oturum onboarding içinde                 | Kayıttan sonra                          | Aha momenti = kendi kelimelerini duymak                                                               |
| 6   | A2 çoklu seçim                               | Tek seçim                               | Headspace'te +%10 trial dönüşümü                                                                      |
| 7   | D8 soru, her biri ayrı ekran                 | Tek ekranda 8 soru                      | Houzz'da bölme +%15 dönüşüm                                                                           |
| 8   | Ölçüm atlanamaz                              | İsteğe bağlı                            | Baseline olmadan ürünün çekirdek vaadi çöker                                                          |
| 9   | C4 dürüst beklenti ekranı                    | Pozitif vaat                            | Cal AI modeli; erken churn ve iade azaltır                                                            |
| 10  | Bildirim öncesi kendi ekranımız              | Doğrudan OS penceresi                   | Kabul oranını belirgin artırıyor                                                                      |
| 10b | `.provisional` bildirim izni kullanılmıyor   | Sessiz izinle başlamak                  | Bilgilendirmeden bildirim göndermek güven ihlali                                                      |
| 11  | Segmentasyon fiyatta değil vurguda           | Segment bazlı farklı fiyat              | Gizli fiyat ayrımcılığı etik ve yasal risk                                                            |
| 12  | C2'de lansmanda sayı yok                     | Jenerik "binlerce kullanıcı"            | Uydurma sosyal kanıt bu kategoride ölümcül                                                            |
| 13  | **B6 emoji değil SF Symbols**                | 5'li emoji ölçek (§3.6'da tarif edilen) | Emoji hiçbir yerde kullanılmıyor: çok renkli, platforma göre değişken, tek mürekkepli sistemi bozuyor |
| 14  | **B2/B3/B6'da dokunmak cevaptır**            | Seçim + "Devam" onayı                   | 31 ekranlık akışta ekran başına fazladan dokunuş; seçim 240ms görünür kalıyor                         |
| 15  | **B2/B3'te ayrı "geç" bağlantısı yok**       | Her ekranda görünür atlama              | "Emin değilim" dürüst bir cevap ve atlamadan daha iyi veri                                            |
| 16  | **Kriz taraması B4'te de var**               | Yalnızca B1 (§3.1)                      | B4 de serbest metin; "her serbest metin taranır" kuralı istisnasız                                    |
| 17  | **Serbest metinde otomatik düzeltme kapalı** | Sistem varsayılanı                      | Kullanıcının kelimeleri F2'de yansıtılıp G1'de seslendiriliyor; düzeltilen cümle onun cümlesi değil   |
