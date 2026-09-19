# "Ben" sekmesi — tasarım spesifikasyonu

Durum: **onaylandı ve uygulandı** (ürün sahibi, 2026-09-12). Uygulama notları
ve yazılamayan parçalar §18'de, görsel prompt'ları §19'da. Tarih: 2026-09-12.
Önceki çalışma: `docs/PRD-Ek-Profil-Sayfasi.md` (2026-09-09, onaylı iskelet). Bu
belge o iskeleti **ekran seviyesinde tasarıma** çeviriyor. Üç yerde ondan ayrılıyor
ve bunları §13'te gerekçesiyle listeliyor. En önemlisi şu: **abonelik satırı
kalkıyor**, çünkü `docs/monetization.md` (2026-09-09) lansmanda abonelik yerine tek
seferlik path satın alımına geçti.

Kaynaklar: Mobbin üzerinde Ahead, Fabulous, Ladder, Yazio (istenen dört uygulama)
ve karşılaştırma için Oura, Stoic, How We Feel, Headspace, Calm, Apple Health,
Co–Star, Equinox+, Flo incelendi. Apple HIG kuralları (`ios-design-guidelines`)
ve Superwall tasarım kontrol listesi (`superwall-editor/references/design.md`)
uygulandı. İlgili PRD bölümleri: §6, §7.9, §7.13, §8, §10. İlgili ekler: Ton eki
§3–§4, monetization §3–§5.

---

## İçindekiler

1. Tek cümlelik fikir
2. Referans incelemesi — kim ne yapıyor
3. Ahead derinlemesine: etkileşim döngüsü ve bizim cevabımız
4. Tasarım ilkeleri (bu ekrana özgü)
5. Bilgi mimarisi
6. Ekran — bölüm bölüm
7. Durumlar (state matrisi)
8. Alt ekranlar: değişim ayrıntısı, defter, yol arşivi, ayarlar
9. Görsel dil: yüzey, tipografi, ızgara, renk
10. Hareket ve haptik
11. Erişilebilirlik
12. Mikrometin
13. Önceki taslaktan ayrılan kararlar
14. Uygulama haritası (MVVM, bileşenler, veri)
15. Kalite kapısı — "Apple Design Award" kontrol listesi
16. Onay bekleyen kararlar
17. Karar günlüğü

---

## 1. Tek cümlelik fikir

> **"Yolum" ileriye bakan haritadır, "Ben" geriye bakan defterdir.**

Patika'nın bütün görsel dili bir yol metaforu üzerine kurulu: A1'in yol animasyonu,
onboarding'in ilerleme izi, F2'nin yol haritası, "Yolum"un kesintisiz izi. Profil
sayfası bu metaforun eksik yarısı. Harita *nereye gideceğini* gösterir. Yolcunun
defteri ise *nereden geçtiğini, yolda ne söylediğini ve neyin değiştiğini* tutar.

Rakiplerin profil sayfaları üç şeyden biri oluyor: bir **skor tablosu** (Headspace,
Calm: dakika, seri, paylaş), bir **vitrin** (Ladder: kapak fotoğrafı, rozet duvarı,
takipçi) ya da bir **ayar listesi** (Yazio, Stoic). Hiçbiri kullanıcıya
*"sen buraya geldiğinden beri ne oldu?"* sorusunun dürüst cevabını vermiyor. Bizim
ürünümüz tam olarak bu soruyu satıyor. Bu yüzden profil sayfası bir hesap ekranı
değil, **ürün vaadinin kanıt sayfası**.

Bu fikirden türeyen dört tasarım kararı var. Ekranı başka bir uygulamanın profilinden
ayıran şeyler bunlar:

| # | Karar | Kısaca |
|---|---|---|
| 1 | **Konum, puan değil** | Değişim, kullanıcının kendi başlangıç çizgisine göre bir noktanın yeriyle gösterilir. Sayı yok, yüzde yok, mutlak skor yok. |
| 2 | **İki ses** | Kullanıcının kendi cümleleri serif (New York), ürünün sesi sans (SF Pro). Göz, kimin konuştuğunu fontan anlar. |
| 3 | **Rozet, yolun kendi çizimidir** | Madalyon ya da kupa yok. Tamamlanan her path'in gerçek rota geometrisi küçük, tek mürekkepli bir mühre dönüşür. Koleksiyon zamanla kişinin kendi haritası olur (PRD §10). |
| 4 | **Her ayarın bir kaynağı var** | "Hatırlatma 22:30" yazmakla kalınmaz; altında *"'Yatağa girince' dediğin için"* yazar. Sorduğumuz her şeyin karşılığı görünür. |

---

## 2. Referans incelemesi — kim ne yapıyor

### 2.1 Özet tablo

| Uygulama | Profil neyin ekranı? | En güçlü fikri | Bize uyan | Bize uymayan |
|---|---|---|---|---|
| **Ahead** | Beceri + kendini tanıma | Kullanıcının fark ettiği işaretlerin listesi | Bilgi mimarisi | XP, seri, kilit, maskot, arkadaş testi |
| **Fabulous** | Yolculuk özeti | "Şu anki yolculuğun" kartı en üstte | Hiyerarşi | Yüzde başlık, "Not yet unlocked", katalog |
| **Ladder** | Sosyal vitrin | Kimlik → sayılar → sekmeli içerik iskeleti, ayrı ayar yüzeyi | İskelet, "Dangerous Area" dürüstlüğü | Kapak, rozet duvarı, Cheers |
| **Yazio** | Hedef + hesap | Uygulamanın senin hakkında bildiklerini özetleyen çipler; abonelik bitiş tarihi | Kaynağı gösterme, tarih dürüstlüğü | Buddies, uzun ayar listesi |
| **Oura** | Sağlık yorumu | Önce insan diliyle cümle, sonra kişisel başlangıca göre grafik | **Ölçüm anlatımının kalıbı** | Skor sayıları ("79 GOOD") |
| **Stoic** | Ayar sayfası (sheet) | Gruplu sheet; **"Show Streak" anahtarı**, yani seriyi kapatılabilir yapmışlar | Gruplu ayar yapısı | Rozet listesi, topluluk bağlantıları |
| **How We Feel** | Güvenlik ve veri | Face ID kilidi, "Delete all my data" ve altında tek cümlelik açıklama | Uygulama kilidi, açık silme | — |
| **Headspace / Calm** | İstatistik + seri | — | — | Seri, "Share My Stats", takvimde işaretli günler |
| **Co–Star** | Kaydedilenler | Serif ile basılmış kişisel metinler, "Saved today" | Kişisel metnin editoryal sunumu | Astroloji jargonu |
| **Equinox+** | Program geçmişi | "2 of 12 sessions completed · Completed Jun 12" | Arşiv kartı yapısı | **"0 of 16" yazması**: yapılmayanı sayıyor |
| **Apple Health** | Özet | Veri yoksa kartta dürüstçe "No Data" yazması | Dürüst boş durum | Renkli çoklu kategori |

### 2.2 Uygulama uygulama — ne gördük, ne alıyoruz

#### Ahead
Ayrıntılı analiz §3'te. Kısaca: Ahead'in **içeriği** (kendini tanıma kaydı) bizim
ürünümüze en yakın olanı. **Mekaniği** (XP, seri, kilit) ise bizim yasak listemizle
birebir örtüşüyor.

- Profil: [maskot + beceri çubukları](https://mobbin.com/screens/ec7ff4d8-ecff-4305-b6d2-3fbc5d082ef9), [istatistik kutuları + arkadaş testi](https://mobbin.com/screens/26e848ed-2272-470d-8a78-8444b98e79eb), [%84 "gizli özelliklerin"](https://mobbin.com/screens/de7ea7d0-a59c-4a7c-851b-1529b75370c0)
- Learnings: [My Signs of Insecurity + kilitli Mind Map](https://mobbin.com/screens/1c3965f7-62dd-400a-b1b5-561506f0ef57), [My Learnings (sol çizgili alıntı)](https://mobbin.com/screens/ccb2c0e5-545e-4e3b-a817-53d4fac6556a), [My Moments takvimi](https://mobbin.com/screens/95dcbac5-6179-472a-a034-100bf4ca2261), [Key discoveries, 7 günlük seriyle açılır](https://mobbin.com/screens/355909b5-1a41-4f79-98d5-41fcfe982004)
- Ayarlar: [davet kartı en üstte](https://mobbin.com/screens/a4745676-f82f-465f-aa3a-7cb8e358c58f), [sade liste + sürüm](https://mobbin.com/screens/bc4ce35f-bfc0-4707-b1ec-3d5565bbac6d), [hesap: silme en altta](https://mobbin.com/screens/3f771aed-ad5f-4ffa-8133-f3b90e9be1ac)
- Akış: [onboarding, 36 ekran](https://mobbin.com/flows/57e41d19-30db-4443-ab36-b19c8c20dfe4)

#### Fabulous
- [Profil](https://mobbin.com/screens/32f16772-6112-4e90-bb6b-53f37bf2fd78): görsel → "Your current journey" kartı (%3) → "All Journeys" çubuğu → davet → hesap → yardım.
- [Journey Roadmap](https://mobbin.com/screens/14760043-392c-4884-b002-c2fa9c5ae9e9): dikey iz, "Not yet unlocked".
- [Adım kartları](https://mobbin.com/screens/ea3ec089-19cb-4055-89ad-1895daf89812): Completed / In Progress / **Locked**.
- [Paylaşılabilir büyüme planı](https://mobbin.com/screens/1505ddb7-8779-4895-903e-2ba2c7ae257b): "Duke · %96 · 22M" sosyal kanıtı.

**Alınan:** ilk ekranda tek bir "şu an" fikri, altında sıradan liste.
**Alınmayan:** yüzde başlık, kilit dili, paylaşılabilir sonuç kartı. Sonuç kartı
gizlilik kuralına aykırı; kullanıcının derdi bir görsele basılıp dışarı çıkar.

#### Ladder
- [Profil](https://mobbin.com/screens/b3e5ddf6-f89e-4bec-91b3-864a586f1eff): kapak → avatar → ad + katılma tarihi → bio → dört halka → ikonlu sekmeler.
- [Rozetler](https://mobbin.com/screens/425ab22c-31d7-40cd-b4d4-36046abcf501), [kilometre taşları](https://mobbin.com/screens/60bc772a-da3f-43b1-96ac-061676306250), ["3 rozet kazandın" tostu](https://mobbin.com/screens/7b497200-e56e-41f8-a058-50683b2c590b).
- [Ayarlar](https://mobbin.com/screens/d8f21d0c-a1ba-4b94-ba1e-a3e0408168f3): iri yuvarlatılmış satırlar, sürüm, Terms · Privacy.

**Alınan:** üstten alta *kimlik → özet → içerik* ritmi, ayarların profilden ayrı
bir yüzeye taşınması, yıkıcı işlemlerin ayrı bir başlık altında toplanması.
**Alınmayan:** her şey sosyal. Kapak, bio, avatar, rozet duvarı.

**Ladder'dan alınan ince bir detay:** metrik halkaları (Workouts/Minutes) *kendi
içlerinde* görsel olarak farklı: biri çizgili, biri dalgalı, biri dolu. Tek renkle
çalışırken "farklı şeyleri farklı dokuyla ayırmak" bizim tek mürekkep kuralımızla
uyumlu. §9.4'teki mühürler bu fikri kullanıyor.

#### Yazio
- [Profil](https://mobbin.com/screens/0caf0bec-8116-4025-b458-e96f89979631): ad + çipler (30 years, Lose weight, Standard) → "My progress" + Analysis → "My Goals" + Edit.
- [Ayarlar](https://mobbin.com/screens/034a946d-2453-4c96-a4e9-acdb85f1be54), [Hesap](https://mobbin.com/screens/e67b739a-e8ef-460b-8400-c7bdf54b9e4e): *Subscription — until 10 May 2026*, Reset, Log Out.

**Alınan:** uygulamanın kullanıcı hakkında bildiğini ona geri söylemek; durumu rozet
yerine tarihle yazmak; veri sıfırlamayı saklamamak.

#### Oura — ölçüm bölümünün asıl referansı
- [Sleep Health](https://mobbin.com/screens/617fe7b4-c91a-427b-a0f2-184ee8deb1ed): küçük üst etiket "LOOKING GOOD" → serif başlık *"Sailing steady, with room to smooth the waters"* → bir cümle açıklama → grafik → "Key metric" konum çubuğu.
- [Trend detected](https://mobbin.com/screens/cc9ab49f-6e69-423c-bda9-07a86ae647fd): *"...trended down over the past 8 weeks but is still on par with your baseline."* Grafikte kesik çizgili bir kişisel ortalama var.
- [Stress — Needs care](https://mobbin.com/screens/d8c2b22f-d150-4e15-af39-7e93c510e8b2): kötü haberi de aynı sakin sesle veriyor.

**Alınan:** (1) **önce cümle, sonra görsel.** Kaygılı kullanıcı grafiği okumak
zorunda kalmadan ne olduğunu anlamalı. (2) **Kesik çizgili kişisel başlangıç.**
(3) **Kötüleşmenin aynı tonla söylenmesi.** Oura'nın "Needs care" ekranı paniğe
kaçmıyor; bizim Kova C dilimiz de öyle olmalı.
**Alınmayan:** mutlak skor ("79 GOOD"), eksenlerde sayı.

#### Stoic
- [Profil sheet'i](https://mobbin.com/screens/aa5298d8-b311-4b09-bcbc-224a2b317aa6): "your profile." başlığı, PERSONALIZE / ACCOUNT / COMMUNITY grupları.
- [Rozetler + "Show Streak" anahtarı](https://mobbin.com/screens/277836ad-5a94-4a9d-8e8b-9f35dfc135a3).

**Not:** Stoic seriyi bir *ayar* olarak kapatılabilir yapmış. Bu, serinin bazı
kullanıcılara zarar verdiğinin sessiz bir kabulü. Biz bir adım ileri gidiyoruz:
kapatılacak bir seri hiç yok.

#### How We Feel, Flo — gizlilik yüzeyi
- [How We Feel · Security & Data](https://mobbin.com/screens/0cc34b3f-9377-43e6-baac-23cf75ead256): Face ID / Passcode anahtarı, iCloud Sync, "Download my data", en altta çerçeveli **"Delete all my data"** ve altında *"...This cannot be undone."*
- [Flo · Manage my data](https://mobbin.com/screens/d32631ca-6238-41f7-b605-9f3e87e3e037): her satırın altında ne yaptığını anlatan açıklama.

**Alınan:** uygulama kilidi (bizde yok ve olmalı; §8.4), satır altı açıklamalı veri
işlemleri, silmenin ne sildiğini söyleyen tek cümle.

#### Equinox+, Headspace, Calm — kaçınılacak kalıplar
- [Equinox+ Program History](https://mobbin.com/screens/c4871e91-ef6b-4838-bf4f-b72993b014f5): "0 of 16 sessions completed". **Yapılmayanı saymak.** Bizim arşivimizde yarım kalan yol, *yürünen adım sayısıyla* yazılır (§8.3).
- [Headspace profil](https://mobbin.com/screens/bb0004ec-e553-4e4d-a10e-1e21e59c8781) ve [Calm profil](https://mobbin.com/screens/38edc186-e331-4d9b-8fec-3b1a5412c6b8): Mindful Days rozeti, Longest Streak, "Share My Stats". Dakika ve gün sayısı *tüketimi* ödüllendirir. Bizim sattığımız şey tüketim değil, değişim.

---

## 3. Ahead derinlemesine: etkileşim döngüsü ve bizim cevabımız

Ahead'i "samimi ama çok iyi" yapan şey ekranlar değil, ekranlar arasında kurduğu
**döngü**. Döngü dört halkadan oluşuyor:

```
  Onboarding            Ana ekran              Learnings              Profil
  "seni tanıyoruz"  →   "her gün bir şey"  →   "kendini topluyorsun" → "büyüyorsun"
        │                      │                       │                     │
  kişilik testi,        seri + gün noktaları,   işaret koleksiyonu,    XP çubukları,
  %eşleşme,             seviye kalesi,          kilitli Mind Map,      istatistik,
  söz verme imzası      maskot                  an kaydı               arkadaş testi
        └──────────────────────── seri kırılırsa: kilit geri kapanır ────────────┘
```

Motoru **merak + kayıp kaçınması**. Mind Map "7 günlük seriyle açılır", Key
discoveries "14 günlük seriyle". Kullanıcı öğrenmek istediği şeye erişmek için her
gün gelmek zorunda. Etkili bir mekanik; kaygılı bir kullanıcı için ise tam olarak
PRD'nin "üretilmiş kaygı" dediği şey.

Aşağıdaki tablo her taktiği tek tek ele alıyor. **Karar** sütununda üç değer var:
*Al* (olduğu gibi), *Dönüştür* (fikri al, mekaniği değiştir), *Alma*.

### 3.1 Onboarding taktikleri

| Ahead'de | Psikolojik kaldıraç | Karar | Patika'daki karşılığı |
|---|---|---|---|
| "Let's personalize Ahead for you — Your individual data will not be shared" | Güven + kişiselleştirme vaadi | **Al** (zaten var) | A2/B1 öncesi gizlilik cümleleri |
| Maskotun empatik sorusu: "Are you carrying pain…? You're not alone" | Normalleştirme | **Dönüştür** | C2 "Bu çok yaygın." Maskot yok, cümle var |
| "Halfway to your results!" | Hedefe yaklaşma etkisi (goal gradient) | **Dönüştür** | `PathProgressBar` izi; sayı değil, kat edilen yol |
| Kişilik testi → radar "Your mind map" + Superpower / Growth area | Kendini tanıma merakı | **Dönüştür** | C1 aynalama: kullanıcının kendi cümlesi, puan değil |
| Yolculuk kartlarında "79% match · 1.8M learners" | Sosyal kanıt + uydurma kesinlik | **Alma** | Veri yokken sayısal sosyal kanıt yasak |
| "Commit to yourself by drawing a checkmark — I promise myself" | Bağlılık aracı (commitment device) | **Dönüştür** | F2 "Yola çık" basılı tutma. Jest var, söz dili yok; söz, tutulamayınca suçluluğa döner |
| "Sign up to save progress", değerden sonra kayıt | Kayıp kaçınması, ama dürüst | **Al** (zaten var) | H1 en sonda |
| Pro paywall: "App of the day · 200k+ lives · 5 yıldız" | Otorite + sosyal kanıt | **Alma** | F4 fiyat şeffaflığı; sayı yok |

### 3.2 Günlük kullanım taktikleri

| Ahead'de | Kaldıraç | Karar | Patika'daki karşılığı |
|---|---|---|---|
| Sağ üstte alev + seri sayısı | Kayıp kaçınması | **Alma** | — |
| Hafta günleri noktaları (M T W…) | Boşluğu doldurma dürtüsü | **Alma** | Boş nokta, kaçırılan günü görünür yapar |
| "LEVEL 1" kalesi, seviye | İlerleme hissi | **Dönüştür** | Faz adları (Rahatlama → Kapanış), yolun gerçek yapısı |
| Nehir üstünde numaralı adımlar ([harita](https://mobbin.com/screens/48f4c2bf-ee74-4da8-bf5b-74858f3b9cc2)) | Mekânsal ilerleme | **Al** (zaten var) | "Yolum" kıvrımlı rota |
| Kilitli Mind Map: "Streak days logged: 1/7" | Merak + kayıp | **Dönüştür** | "İlk karşılaştırma 7. adımda." Seriye değil, adıma bağlı; kaçırılan gün sayacı geri almaz (§6.3) |
| My Signs: "Criticizing myself · Noticed 2 times" + Add | Öz-izleme (BDT'de meşru bir teknik) | **Dönüştür** | "Defter": kullanıcının kendi cümleleri. Sayaç yok (§6.4) |
| "Save to worries / new moment" — egzersiz sırasında not alma ([ekran](https://mobbin.com/screens/9e12f6e6-b2e5-422e-8649-07f9ffe490d7)) | Bağlam içinde yakalama | **Dönüştür** | Oturum sonu `AdaptiveQuestionView` cevabı defterde birikir |
| My Moments takvimi | Geriye dönük kayıt | **Alma** (v1) | Takvim, boş günleri gösteren bir ızgara; defter kronolojik ve boşluksuz |
| "Great start to your collection!" | Koleksiyon tamamlama | **Dönüştür** | Mühürler (§6.5): yalnızca tamamlanan yol eklenir, "tamamla" çağrısı yok |

### 3.3 Profil ve ayar taktikleri

| Ahead'de | Kaldıraç | Karar | Patika'daki karşılığı |
|---|---|---|---|
| Ad + o anki odak: "Alex — Confidence" | Kimlik = şu an üzerinde çalışılan şey | **Al** | Başlık: ad + path adı (§6.1) |
| Üç beceri × XP çubuğu | Ustalık hissi | **Dönüştür** | Üç ölçüm katmanı × başlangıca göre konum (§6.2) |
| "Do activities to collect XP!" | Aktivite = puan | **Alma** | Değişim aktiviteyle değil ölçümle görünür |
| "4/33 daily activities · 2 streak · 37m" | Tüketim metrikleri | **Alma** | — |
| "Test your self-awareness — compare with friends" | Sosyal merak | **Alma** | Kullanıcılar arası kıyas yasak |
| Ayarların başında "Sharing is caring" davet kartı | Viral döngü | **Alma** | Ruh sağlığı ürününde davet teşviki, kullanıcının derdini bir pazarlama kanalına çevirir |
| Silme hesap sayfasının dibinde, kırmızı | Dürüst ama gizli | **Dönüştür** | "Geri alınamaz" başlıklı ayrı grup (§8.4) |

### 3.4 Özet: Ahead'den ne öğrendik

Ahead'in doğru bulduğu şey: **insanlar kendileri hakkında biriktirdikleri şeye geri
dönüyor.** Mind Map'i merak ettiren radar değil, *"senin hakkında"* olması.

Yanlış bulduğu şey (bizim için): o birikime erişimi davranışa (seriye) bağlamak.
Bizde erişim hiçbir zaman davranışa bağlı değil. **Birikim, zamanı geldiğinde
kendiliğinden görünür.** Ölçüm 7. adımda yapılır ve sonucu o anda sayfaya düşer;
arada kaç gün geçtiği hiçbir şeyi değiştirmez.

> Etkileşim hedefi "her gün aç" değil, **"açtığında bir şey öğren"**. Bir kullanıcı
> "Ben"i haftada bir açıp her seferinde kendisi hakkında gerçek bir şey görüyorsa,
> ekran işini yapıyor demektir.

---

## 4. Tasarım ilkeleri (bu ekrana özgü)

Genel kurallar `CLAUDE.md`de. Bunlar yalnızca bu ekrana ait yorumlar.

**İ1 — Geriye bakar, ileri itmez.** "Ben"de birincil CTA yok. "Sıradaki adıma
başla" butonu burada değil, "Yolum"da. Profil bir huni (funnel) değil. İki
sekmede aynı butonun bulunması, iki sekmenin aynı işi yaptığı izlenimi verir.

**İ2 — Yapılanı say, yapılmayanı sayma.** "8 adım yürüdün" yazılır, "13 adım kaldı"
ya da "8/21" yazılmaz. İstisna yok. Ayrıntı ekranında da yok.

**İ3 — Veri yoksa yer tutulur, yer uydurulmaz.** Bir bölümün verisi *gelecekse*
bölüm tek satırlık bir beklenti cümlesiyle görünür (Apple Health'in "No Data"
dürüstlüğü). Veri bu kullanıcı için *hiç gelmeyecekse* bölüm hiç çizilmez. Örnek:
hazır patikada kişisel cevap yok, dolayısıyla defterin cevap kısmı da yok.

**İ4 — Bölüm sırası sabittir.** Veri geldikçe bölümler büyür ya da küçülür ama yer
değiştirmez. Tanıma, hatırlamadan iyidir (HIG 2.7): kullanıcı "Ne değişti"nin hep
en üstte olduğunu bilir.

**İ5 — Kötüleşme gizlenmez, yüceltilmez de.** Oura'nın "Needs care" tonu. Kelime
nötr ("ağırlaştı"), renk yok, ikon aynı ağırlıkta.

**İ6 — Kullanıcının cümlesi kutsaldır.** Düzeltilmez, özetlenmez, kırpılmaz,
yorumlanmaz. Yalnızca silinebilir.

**İ7 — Omuz üstünden bakılabilir.** Ekranda kişinin derdi yazıyor. Telefon masada
açık kalabilir, uygulama değiştiricide görünebilir. Gizlilik tasarımın bir parçası,
sonradan eklenen bir ayar değil (§6.4, §8.4).

---

## 5. Bilgi mimarisi

```
Ben (sekme kökü, kaydırmalı tek sayfa)
│
├─ 1  Başlık                 kimlik + şu anki yol
├─ 2  Ne değişti             üç katman × başlangıca göre konum        → sheet: Değişim ayrıntısı
├─ 3  Defter                 kendi cümlelerin (son 3)                 → push: Defter (tümü)
├─ 4  Yürüdüğün yollar       mühürler + aktif yolun yarım mührü       → push: Yol ayrıntısı
├─ 5  Sana göre ayarlananlar hatırlatma · uzunluk · ton · ses          → sheet: tek ayar
├─ 6  Destek al              her zaman görünür                        → fullScreen: Destek
├─ 7  Yol erişimi            satın alma durumu (satış değil)          → sheet: durum / geri yükle
├─ 8  Uygulama               Ayarlar ve gizlilik                      → sheet: Ayarlar
└─    Alt bilgi              sürüm · Gizlilik · Koşullar · klinik feragat

SOS: sağ üstte sabit (RootView overlay), bu sayfanın parçası değil.
```

**Neden tek sayfa, sekmeli değil (Ladder'dan ayrılış):** Ladder'ın dört sekmesi
dört ayrı içerik türünü (liste/rozet/favori/günlük) ayırıyor. Bizim bölümlerimiz
birbirini anlatıyor: ölçüm değişimi söyler, defter onu kullanıcının sesiyle
tekrarlar, mühür o yolun kalıcı izidir. Sekmeye bölmek bu okumayı keser. Sayfa
standart boyutta **~2,3 ekran boyu**; sekme gerektirecek uzunlukta değil.

**Neden dişli ikonu yok:** SOS sağ üstte sabit. Altına ya da yanına bir dişli
koymak, sağ üst köşeyi bir araç çubuğuna çevirir ve SOS'un tekilliğini bozar. Ayar
sıklığı düşük, sayfa kısa; ayarlar son grupta bir satır olarak duruyor. HIG 8.6'nın
"profilden erişilebilir ayarlar" kuralı böylece yine karşılanıyor.

---

## 6. Ekran — bölüm bölüm

Aşağıdaki çizimler iPhone 17 Pro (402 pt) varsayılan metin boyutunu gösterir.
Kenar boşluğu 24 pt (`Theme.Spacing.screenMargin`). Bölümler arası 40 pt.

### 6.0 Tüm sayfa — 2. durum (7. adım ölçümünden sonra)

```
┌──────────────────────────────────────────┐
│                                   [SOS]  │  RootView overlay
│                                          │
│  Taner                                   │  1 · Başlık
│  Zihni akşam yavaşlatma                  │
│  Farkındalık · 9. adım                   │
│                                          │
│  Ne değişti                              │  2 · Değişim
│ ╭──────────────────────────────────────╮ │
│ │ Kaçınman azalıyor. Duygunun şiddeti  │ │    cümle önce
│ │ başladığın yerde.                    │ │
│ │                                      │ │
│ │ Duygu         ─────┆●─────   aynı    │ │    konum + kelime
│ │ Davranış      ─────┆───●─   azaldı ↗ │ │
│ │ Öz-yeterlik   ─────┆──●──   arttı  ↗ │ │
│ │                                      │ │
│ │ ┆ Başlangıcın · 7. adımda ölçüldü    │ │
│ ╰──────────────────────────────────────╯ │
│  Bu bir klinik değerlendirme değildir.   │
│                                          │
│  Defter                           Tümü › │  3 · Defter
│  ┃ Akşamları yatağa girince zihnim       │    serif = kullanıcının sesi
│  ┃ durmuyor, ertesi günü düşünüp         │
│  ┃ duruyorum.                            │
│    Başlangıçta · 8 Eylül                 │
│                                          │
│  ┃ Telefonu bıraktığımda ilk kez         │
│  ┃ sessizlik rahatsız etmedi.            │
│    8. adımdan sonra · Dün                │
│                                          │
│  Yürüdüğün yollar                        │  4 · Mühürler
│  ╭───╮                                   │
│  │ ∿ │  Zihni akşam yavaşlatma           │    yarım çizili mühür
│  ╰───╯  Yoldasın · 9 adım                │
│                                          │
│  Sana göre ayarlananlar                  │  5 · Kaynaklı ayarlar
│ ╭──────────────────────────────────────╮ │
│ │ Hatırlatma                  22:30  › │ │
│ │ "Yatağa girince" dediğin için        │ │
│ │──────────────────────────────────────│ │
│ │ Adım uzunluğu            10 dakika › │ │
│ │──────────────────────────────────────│ │
│ │ Anlatım                Sakin, kısa › │ │
│ │──────────────────────────────────────│ │
│ │ Rehber sesi                  Ses B › │ │
│ ╰──────────────────────────────────────╯ │
│                                          │
│ ╭──────────────────────────────────────╮ │  6 · Destek al
│ │ ◎  Destek al                       › │ │
│ │    Konuşabileceğin biri, şimdi       │ │
│ ╰──────────────────────────────────────╯ │
│                                          │
│ ╭──────────────────────────────────────╮ │  7 · Yol erişimi
│ │ Yol erişimi              21 adım açık│ │
│ │──────────────────────────────────────│ │
│ │ Satın alımları geri yükle            │ │
│ ╰──────────────────────────────────────╯ │
│                                          │
│ ╭──────────────────────────────────────╮ │  8 · Uygulama
│ │ Ayarlar ve gizlilik                › │ │
│ ╰──────────────────────────────────────╯ │
│                                          │
│   1.0 (42) · Gizlilik · Koşullar         │  Alt bilgi
│                                          │
├──────────────────────────────────────────┤
│   Yolum        Keşfet        [Ben]       │  tab bar (sistem, Liquid Glass)
└──────────────────────────────────────────┘
```

### 6.1 Başlık

**İçerik:**

| Satır | Kaynak | Stil |
|---|---|---|
| Ad | `UserProfile.displayName` | `DisplayText`, `.largeTitle`, `Theme.Weight.display` |
| Path adı | `ActivePath.title` (sunucudan; yedek `ProblemCategory.provisionalPathTitle`) | `.title3`, `Theme.Weight.title`, `textPrimary` |
| Faz · adım | `PathPhase.label` + "N. adım" (sıradaki adımın günü) | `.subheadline`, `Theme.Weight.body`, `textSecondary` |

**Kurallar:**
- **Ad yoksa ad satırı hiç yoktur.** Yerine "Sen" ya da "Misafir" yazılmaz. Path adı
  büyüyüp başlık rolünü alır (`DisplayText`'e yükselir). İsimsiz sürüm eksik sürüm
  değildir (kimlik bloğu kuralı).
- **Avatar, fotoğraf, baş harf dairesi yok** (P3). Ladder, Yazio ve Apple Health'in
  hepsinde var; hepsinin de bir sosyal ya da çok kullanıcılı katmanı var. Bizde yok.
- **"9. adım" konumdur, sayaç değil.** "9/21" yazılmaz (İ2). Kaç adım kaldığı
  "Yolum"da haritanın kendisinden okunur.
- Kategori ikonu **yok**. Başlıkta bir ikon, ekranın ilk nesnesini bir kategori
  etiketine çevirir. Kişi bir kategori değil.
- Aktif path yoksa üçüncü satır: *"Şu an bir yolda değilsin."* (§7).
- SOS sağ üstte sabit olduğu için başlık 48 pt aşağıdan başlar (`MyPathView` ile
  aynı ölçü).

**Kaydırma davranışı:** Başlık kaydırmayla birlikte yukarı çıkar. Sabit bir gezinme
çubuğu yok. Üst kenarda `scrollEdgeEffectStyle(.soft, for: .top)`, "Yolum" ile
aynı. Ad ekrandan çıktığında inline başlığa dönüşmez: bu bir gezinme hiyerarşisi
değil, tek sayfa.

### 6.2 Ne değişti — sayfanın kalbi

Ahead'in beceri çubuklarının, Oura'nın "önce cümle" kalıbıyla birleşmiş hâli.

#### Anatomi

```
╭────────────────────────────────────────────╮
│ [A] Kaçınman azalıyor. Duygunun şiddeti    │
│     başladığın yerde.                      │
│                                            │
│ [B] Duygu        [C] ─────┆●─────  [D] aynı│
│     Davranış         ─────┆───●─   azaldı ↗│
│     Öz-yeterlik      ─────┆──●──   arttı  ↗│
│                                            │
│ [E] ┆ Başlangıcın · 7. adımda ölçüldü      │
╰────────────────────────────────────────────╯
[F] Bu bir klinik değerlendirme değildir.
```

| Parça | Ne | Kural |
|---|---|---|
| **A · Cümle** | Deterministik şablondan üretilen 1–2 cümle | Model yok, `MeasurementScoring` çıktısından seçilir (§12.2). Kötüleşen katman varsa cümlede **mutlaka** geçer. |
| **B · Katman adı** | Duygu / Davranış / Öz-yeterlik | Sıra sabit (İ4). En çok değişene göre sıralanmaz; sıralama bir yargı ima eder. |
| **C · Başlangıç izi** | Yatay 2 pt çizgi, ortada kesik dikey başlangıç işareti, üstünde nokta | Nokta, başlangıca göre **iyi yönde sağa** kayar. Sayı yok. |
| **D · Yön** | Kelime + SF Symbol (`arrow.up.right` / `arrow.right` / `arrow.down.right`) | Renk yok. Anlam üç kanaldan gelir: kelime, ok, konum. |
| **E · Gösterge** | Kesik çizgi örneği + "Başlangıcın" + ölçüm adımı | Oura'nın kişisel ortalama çizgisi |
| **F · Feragat** | `Copy.clinicalDisclaimer` | Kartın dışında, `.footnote`, `textSecondary` (PRD §8.1) |

#### Başlangıç izinin geometrisi

- İz genişliği: satırın kalan alanı. Varsayılan boyutta ~132 pt.
- Başlangıç işareti izin **tam ortasında**, 1 pt × 14 pt, kesik (2–2).
- Nokta: 9 pt dolu daire, `textPrimary`.
- Kayma miktarı: `clamp(Δ / 25, -1, 1) × (izGenişliği / 2 − 6)`. Buradaki Δ
  zorlanma skorundaki değişim; işareti "iyi yön = pozitif" olacak şekilde
  çevrilmiş hâli kullanılır.
- `MeasurementScoring`in katman eşiğinin altındaki değişim **kaydırılmaz**. Nokta
  işaretin tam üstünde durur, yön kelimesi "aynı" olur. Gürültüyü hareket gibi
  göstermek sahte ilerleme üretir.
- Tavan (±25 puan) görsel bir sınır, yorum değil. 25 puanın üstündeki değişim
  kenarda durur.

**Neden sağ = iyi yön:** Patika'daki bütün ilerleme dilleri (onboarding izi, F2
rotasının okuma yönü, "Yolum" izi) soldan sağa ya da yukarıdan aşağıya "ileri"
okunuyor. Burada zorlanmanın azalmasının sola gitmesi, "geri gitti" diye okunurdu.

**Neden sayı yok, ama konumun büyüklüğü var:** PRD §8.1 skorların mutlak
yorumlanmasını yasaklıyor ve yalnızca kişinin kendi geçmişiyle karşılaştırmaya izin
veriyor. Konum tam olarak bu: yalnızca kendi başlangıcına göre anlamı var ve
başka biriyle karşılaştırılamaz. Yüzde ise ("%23 azaldı") bir kesinlik iddia eder.
Faz 0 kalibrasyonu yapılmamış bir ölçekte o kesinlik yok. **Sayılar yalnızca path
sonu raporunda ve Kova A/B mührünün ayrıntısında** yer alır (PRD §7.9, Ton eki
§3.5); orada dört ölçüm noktası vardır.

#### Yön kelimeleri

Her katman kendi fiilini kullanır, çünkü "arttı" duyguda kötü, öz-yeterlikte iyi
bir haber:

| Katman | İyi yönde | Eşik altında | Kötü yönde |
|---|---|---|---|
| Duygu (şiddet) | hafifledi | aynı | ağırlaştı |
| Davranış (kaçınma) | azaldı | aynı | arttı |
| Öz-yeterlik | güçlendi | aynı | zayıfladı |

"Kötüleşti", "geriledi", "düştü" gibi yargı taşıyan kelimeler kullanılmaz. Olan şey
söylenir, değerlendirmesi yapılmaz.

#### Geçici başlangıç

`baselineIsProvisional == true` iken (ilk iki ölçümün ortalaması henüz yok) gösterge
satırı şöyle olur: *"┆ Başlangıcın tek ölçüme dayanıyor · biraz oynayabilir"*.
Ortalamaya dönüş etkisini kullanıcıya sonuç diye satmamanın arayüzdeki karşılığı bu.

#### Etkileşim

Kartın tamamı tek bir düğme: dokununca **Değişim ayrıntısı** sheet'i açılır (§8.1).
Satır satır dokunma yok. Üç ayrı hedef, kullanıcıyı "hangisine bakmalıyım" diye
düşündürür; ayrıntı ekranı zaten üçünü birlikte gösteriyor.

### 6.3 Ne değişti — 7. adımdan önce (beklenti durumu)

Ahead'in kilitli Mind Map'inin dürüst sürümü:

```
  Ne değişti
 ╭──────────────────────────────────────╮
 │ İlk karşılaştırma 7. adımda.         │
 │ O güne kadar ölçecek bir fark yok.   │
 │                                      │
 │ Duygu         ─────┆─────            │
 │ Davranış      ─────┆─────            │
 │ Öz-yeterlik   ─────┆─────            │
 │                                      │
 │ ┆ Başlangıcın · 8 Eylül'de ölçüldü   │
 ╰──────────────────────────────────────╯
```

- İz ve başlangıç işareti **görünür**, nokta **yok**. Yapı gösterilir, sonuç
  gösterilmez. Kullanıcı neyin ölçüleceğini şimdiden bilir.
- **Bulanıklık, kilit ikonu, ilerleme halkası (1/7) yok.** Ahead'in "Achieve a 7-day
  streak to unlock" kartı içeriği saklıyormuş gibi yapar. Burada saklanan bir şey
  yok; henüz ortada olmayan bir şey var.
- Karşılaştırma **adıma** bağlı, takvime değil. 7. adım üç gün sonra da yapılsa üç
  hafta sonra da yapılsa aynı şey olur. Kaçırılan gün hiçbir şeyi geri almaz.
- Dokunulamaz: ayrıntı ekranında gösterilecek bir şey yok.

### 6.4 Defter

Ahead'in "My Signs" ve "My Learnings" ekranlarının birleşimi; malzemesi
kullanıcının kendi cümleleri.

#### İçerik ve sıra

| Kaynak | Ne zaman var | Üst yazı |
|---|---|---|
| B1 serbest metin (`ProblemStatement.rawText`) | Onboarding'de yazıldıysa | *Başlangıçta · 8 Eylül* |
| B4 kaçınma cevabı (`avoidanceText`) | Yazıldıysa | *Başlangıçta, kaçındığın şey · 8 Eylül* |
| Oturum sonu cevapları (`AdaptiveQuestionView`) | Yalnızca `personalized` patikada | *N. adımdan sonra · tarih* |

**Sabitleme:** B1 cümlesi her zaman **ilk sırada** durur. Altında en yeni iki kayıt
listelenir. Böylece kullanıcı ekranda, hiçbir yorum yapılmadan, *ilk gün ne
yazdığını* ve *dün ne yazdığını* alt alta görür. Değişimin sayısız, kelimelerle
kurulan kanıtı bu yan yanalık. **Arayüz bu iki cümle hakkında tek kelime
söylemez.** "Bak ne kadar değişmişsin" demek, Kova C'deki kullanıcıya yalan
söylemek olurdu.

**Ahead'den bilinçli olarak alınmayan:** "Noticed 3 times" sayacı. Sayaç, insanı
kendi belirtisini toplamaya yöneltir. "Add" butonu da v1'de yok, çünkü defter
yalnızca oturum akışının içinde yazılır. Bağımsız bir günlük, bir "ödev" yüzeyi
açar (`AdaptiveQuestionView` kararı: zorunlu günlük meditasyona ödev eklemektir).

#### Görsel

```
┃ Akşamları yatağa girince zihnim
┃ durmuyor, ertesi günü düşünüp
┃ duruyorum.
  Başlangıçta · 8 Eylül
```

- Soldaki dikey çizgi: 2 pt, `textPrimary` %35 opaklık. Ahead'in
  [My Learnings](https://mobbin.com/screens/ccb2c0e5-545e-4e3b-a817-53d4fac6556a)
  ekranındaki alıntı çizgisi. Tırnak işareti yerine kullanılıyor, çünkü tırnak
  metne bir "söz" ağırlığı yükler.
- Cümle: **New York** (`.fontDesign(.serif)`), `.body`, `Theme.Weight.body`,
  `textPrimary`. En fazla 4 satır, sonrası kısaltılmaz; "Tümü" ekranında tam
  metin. Ana sayfada 4 satırı aşan cümle **son kelimede değil, son tam
  cümlede** kesilir ve sonuna "…" konur. Kelime ortasından kesmek kullanıcının
  cümlesini bozar (İ6).
- Üst yazı: SF Pro, `.footnote`, `textSecondary`.
- Kart yok. Defter doğrudan zemine yazılır; kağıda yazılmış bir not gibi.

#### İki ses tipografisi (onay bekliyor, §16)

| Kim konuşuyor | Font | Neden |
|---|---|---|
| Ürün | SF Pro, bir kademe kalın (`Theme.Weight`) | Net, sakin, kurumsal |
| Kullanıcı | New York, `medium` | Daha insani; el yazısına en yakın sistem fontu |

Bu kural yalnızca "Ben"de değil, kullanıcının kendi cümlesinin geri yansıtıldığı
**her yerde** geçerli olmalı: C1 aynalama, G1'in ikinci sahnesi, defter. Kullanıcı
kendi cümlesini hangi ekranda görürse görsün aynı yüzü tanır. Uygulama sistem fontu
olduğu için ek varlık getirmez, Dynamic Type ve Bold Text ile otomatik uyumlu.

#### Gizlilik (İ7)

- Uygulama `scenePhase != .active` olduğunda defter ve değişim cümlesi
  `.redacted(reason: .privacy)` + bulanıklık ile örtülür. Uygulama değiştiricideki
  anlık görüntüde kişinin cümlesi görünmez.
- Ayarlar → Gizlilik'te **"Cümlelerimi Ben sekmesinde gizle"** anahtarı. Varsayılan
  kapalı. Açıkken satır *"Gizli · göstermek için dokun"* olur ve dokunulunca 30 sn
  açık kalır.
- **Uygulama kilidi** (Face ID / parola) açıksa ek bir örtü gerekmez.

#### Etkileşim

- "Tümü" → Defter ekranı (§8.2).
- Satırda uzun basış → bağlam menüsü: **Sil**. Aynı işlem Defter ekranında sola
  kaydırmayla da yapılabilir (HIG 7.7: bağlam menüsü tek erişim yolu olamaz).
- **Düzenleme yok** (İ6). Cümle yazıldığı an path'i şekillendirdi. Sonradan
  düzenlemek, geçmişi yeniden yazmak olurdu; silmek ise kişinin veri üzerindeki
  hakkı.

### 6.5 Yürüdüğün yollar — mühürler

> **GEÇERSİZ — 2026-09-19, Ben v2 (§21).** "Yürüdüğün yollar" bölümü kalkıyor;
> yerine kilometre taşı rozetleri (`BadgeShelf`) geliyor. Aşağıdaki metin tarihsel
> kayıt olarak duruyor. `RouteSeal` rozet sayfasındaki yol rozetinde yeniden
> kullanılabilir.

PRD §10'daki "Rozet + Koleksiyon" satırının tasarımı.

#### Fikir: rozet, yolun kendi çizimi

Her path'in "Yolum"da ve F2'de gerçek bir rota geometrisi var
(`JourneyRoutePattern`, `JourneyRouteLayout`): kaç adım, hangi fazda ne kadar
kıvrım, eşikler nerede. Bu geometri deterministik ve **kişiye özgü**. Mühür, bu
rotanın 56 × 56 pt'lik bir çerçeveye sığdırılmış, tek çizgili, kapalı bir
çizimidir.

```
  ╭─────╮
  │ ╭╮  │   tamamlanmış yol:   rota tam, çerçeve tam, uçta dolu düğüm
  │ │╰╮ │
  │ ╰─● │
  ╰─────╯

  ╭ ─ ─ ╮
  │ ╭╮  │   aktif yol:         rota yürünen yere kadar dolu, gerisi %25
  ╎ │╰┄ ╎                      çerçeve kesikli (henüz kapanmadı)
  │ ╰┄┄ │
  ╰ ─ ─ ╯
```

**Neden madalyon değil:** Ladder'ın rozetleri gümüş, dokulu, çok katmanlı; bizim tek
mürekkep sistemimizde yabancı durur. Daha önemlisi, Ladder'ın rozeti **herkese
aynı**: "Weekly Streaks" rozeti her kullanıcıda aynı görünür. Bizim mührümüz o
kişinin yolunun şeklidir ve başka kimsede aynısı yoktur. Koleksiyon büyüdükçe
kullanıcı küçük bir harita arşivi biriktirir. PRD'nin "Biriken rozetler zamanla
kişinin kendi haritasını oluşturur" cümlesi burada tam olarak gerçekleşir.

**Kova farkı mühürde görünmez.** A, B ve C mühürleri aynı çizimdir: emek tanınır,
sonuç çizime işlenmez. Fark, mührün yanındaki metinde (Ton eki §6):

| Kova | Mührün yanında |
|---|---|
| A · belirgin | *Zihni akşam yavaşlatma* · *Uykuya dalma süren belirgin kısaldı* · 3 Ekim |
| B · kısmi | *Zihni akşam yavaşlatma* · *Bazı şeyler değişti* · 3 Ekim |
| C · ilerleme yok | *Zihni akşam yavaşlatma* · *21 gün* · 3 Ekim |
| Yarım kalan | *Zihni akşam yavaşlatma* · *8 adım yürüdün* · 14 Eylül |
| Aktif | *Zihni akşam yavaşlatma* · *Yoldasın · 9 adım* |

Ana sayfada **sayı yok** (İ2 ve §6.2). Kova A/B'nin sayısal başlığı
(`BadgeArtifact.headlineChange`) yol ayrıntısında görünür. Kova C'de o alan zaten
`nil` (`badgeShowsNumbers`).

#### Yerleşim

- 1–3 yol: dikey liste (mühür + iki satır metin).
- 4 ve üzeri yol: mühürler 4 kolonlu ızgaraya geçer, metin ayrıntıya taşınır.
  Izgaranın altında *"Tümünü listele"*.
- Aktif yol **her zaman ilk** sırada; ardından tamamlananlar, en yeniden eskiye.

#### Boş durum

İlk path aktifken koleksiyon boş değildir, çünkü aktif yolun yarım mührü orada.
Hiç path yoksa (hazır içerik kullanıcısı): `Copy.Empty.noBadges`, yani *"İlk
patikanı bitirdiğinde burada bir şey olacak. Acelesi yok."*

#### Kalıcı kayıt (artifact)

Tamamlanan yolun kişiye özel 3 dakikalık kaydı (PRD §7.9) yol ayrıntısında durur:
oynat + **Bende kalsın** (Dosyalar'a kaydet, `ShareLink`). Ana sayfada yok. Yolların
en fazla bir satırı olur; oynatıcı satırı sayfayı bir medya kütüphanesine çevirir.

### 6.6 Sana göre ayarlananlar

> **GEÇERSİZ — 2026-09-19, Ben v2 (§21).** "Sana göre ayarlananlar" profilden
> kalkıp Ayarlar sayfasına taşınıyor. Aşağıdaki metin tarihsel kayıt olarak duruyor.

Yazio'nun çiplerinden fikir, ama her satırda **kaynak** var.

| Satır | Değer | Kaynak satırı (varsa) | Düzenleyici |
|---|---|---|---|
| Hatırlatma | `22:30` ya da `Kapalı` | *"Yatağa girince" dediğin için* (B3 → `ProblemTiming.reminderReason` kısa sürümü) | Sheet: saat tekerleği + kapat anahtarı |
| Adım uzunluğu | `10 dakika` | — | Sheet: 5 / 10 / 15 |
| Anlatım | `Sakin ve kısa` | — | Sheet: üç seçenek |
| Rehber sesi | `Ses A` / `Ses B` | — | Sheet: iki örnek, oynatılabilir (E4 bileşeni) |

**Kaynak satırı ne zaman görünür:** yalnızca değer hâlâ onboarding cevabından
geliyorsa. Kullanıcı saati değiştirdiyse kaynak satırı kalkar. Artık o, kullanıcının
kendi seçimidir ve öyle görünmelidir.

**Değişikliğin ne zaman geçerli olduğu söylenir.** Adım uzunluğu, anlatım ve ses
için sheet'in altında şu cümle durur: *"Bir sonraki hazırlanan adımdan itibaren.
Sıradaki adımın sesi hazırlanmış olabilir."* JIT üretimde N+1 önceden render
ediliyor. Bunu söylemeden değişiklik yapan kullanıcı, bir sonraki oturumda eski sesi
duyunca ayarın çalışmadığını düşünür.

**Gösterilmeyenler:** cinsiyet ve yaş, hiçbir yerde (P7). Dil satırı da yok, çünkü
`AppLocale` cihazdan geliyor; uygulama içinde değiştirilecek bir şey değil (HIG 8.6:
sistem düzeyi ayarlar kopyalanmaz).

### 6.7 Destek al

- **Ayrı bir kart**, liste satırı değil. Yanındaki satırlarla karışmaz.
- İkon: `hand.raised`. Başlık: *Destek al*. Alt satır: *Konuşabileceğin biri,
  şimdi.*
- Dokununca tam ekran Destek sayfası: ülkeye göre yardım hatları, **numara**
  (harita değil), arama butonları. Ton kademesi Nötr, hareket yok
  (`BreathAmplitude.crisis`).
- **Yol erişiminin üstünde** (P6). Destek hiçbir zaman paranın arkasında durmaz;
  sayfada da onun altında durmaz.
- Kaynak göstergesi: analitiğe yalnızca `support_opened {source: "me"}` gider.

### 6.8 Yol erişimi (abonelik satırının yerine)

`docs/monetization.md` lansmanda aboneliği reddetti; path tek seferlik satın
alınıyor. Bu satır bir **durum göstergesi**, satış yüzeyi değil.

| Durum | Satır metni | Dokununca |
|---|---|---|
| İlk adım ücretsiz, satın alınmamış | *İlk adım açık* | Sheet: yolun kalanı ve fiyatı, **kullanıcı isterse** "Kalan 20 adımı aç" |
| Satın alınmış | *21 adım açık* | Sheet: satın alma tarihi, "Satın alımları geri yükle" |
| Kova C devam yolu | *Devam yolu · ücretsiz* | Sheet: bilgi |
| Hazır path (ücretsiz) | *Ücretsiz yol* | — (dokunulamaz) |

**Kurallar:**
- **Fiyat ana sayfada yazılmaz.** Profilde fiyat görmek, kullanıcının kendisine
  bakarken bir teklifle karşılaşması demek.
- Satın alma sheet'i yalnızca kullanıcının dokunmasıyla açılır. Rozet, nokta,
  "yeni" etiketi, parlama yok.
- `OutcomeBucket.allowsSelling == false` ise satın alma butonu **hiç çizilmez**.
  Satır yalnızca durumu gösterir.
- "Satın alımları geri yükle" her durumda erişilebilir. Consumable IAP'lerde geri
  yükleme sunucudaki hak kaydından gelir (monetization §5.2).
- Sheet'teki satın alma yüzeyi Superwall tasarım kontrol listesine uyar (§15):
  tek güçlü CTA, toplam fiyat ve "tek sefer, abonelik yok" güven cümlesi CTA'nın
  hemen altında, en fazla bir seçenek. Projede Superwall entegre değil; ileride
  kullanılırsa bu giriş noktası `me_path_access` adlı bir placement olur ve
  kampanya kuralında `allowsSelling` koşulu zorunlu tutulur.

### 6.9 Uygulama ve alt bilgi

- Tek satır: **Ayarlar ve gizlilik** → sheet (§8.4).
- Alt bilgi (kartsız, ortalı, `.caption`, `textSecondary`):
  `1.0 (42) · Gizlilik · Koşullar`. Bağlantılar 44 pt dokunma alanıyla.
- Sekme çubuğunun altında kalmaması için 120 pt alt boşluk (`MyPathView` ile aynı).

---

## 7. Durumlar (state matrisi)

| # | Durum | Başlık 3. satır | Ne değişti | Defter | Yollar | Erişim |
|---|---|---|---|---|---|---|
| S0 | Onboarding bitti, G1 tamamlanmadı | *Rahatlama · 1. adım* | Beklenti (§6.3) | B1 (varsa) | Aktif, boş mühür | İlk adım açık |
| S1 | 1–6. adım | *Faz · N. adım* | Beklenti | B1 + cevaplar | Aktif, yarım | Duruma göre |
| S2 | 7. ölçüm sonrası | aynı | Konum + cümle | aynı | aynı | aynı |
| S3 | 14. ölçüm sonrası | aynı | Konum + cümle; ayrıntıda 3 nokta | aynı | aynı | aynı |
| S4 | Path bitti | *Şu an bir yolda değilsin.* | Son yolun sonucu, gösterge: *"Zihni akşam yavaşlatma · son ölçüm"* | Son yolun cümleleri | Tamamlanan mühür başta | Son yol |
| S5 | Hazır path (`prepared`) | *Hazır yol · N. adım* | Ölçüm yoksa **bölüm yok** (İ3) | Yalnızca B1 (varsa); cevap bölümü yok | Aktif | *Ücretsiz yol* |
| S6 | Anonim hesap | normal | normal | normal | normal | normal + ek kart ↓ |
| S7 | Çevrimdışı | normal | Son okunan veri, gösterge satırına *"· son güncelleme 2 sa önce"* | yerel | yerel | *Bağlantı gelince güncellenecek* |
| S8 | Kriz sinyali aktif | ad yalnızca | **Gizli** | **Gizli** | Gizli | Gizli |

**S6 · Anonim hesap.** Başlığın hemen altında sade bir kart:

```
╭──────────────────────────────────────╮
│ Bu kayıt şimdilik yalnızca bu        │
│ telefonda.                           │
│ Hesaba bağlarsan telefon değişince   │
│ kaybolmaz.                           │
│                                      │
│ [ Apple ile devam et ]               │
│   Şimdilik değil                     │
╰──────────────────────────────────────╯
```

"Şimdilik değil" kartı 30 gün kapatır; kalıcı "bir daha gösterme" de sunulur.
**Korkutma yok:** "İlerlemeni kaybedebilirsin!" yazılmaz. Olan şey söylenir.

**S8 · Kriz.** `ProblemStatement.crisisFlag` ya da sunucunun kriz durumu aktifken
sayfada yalnızca ad, **Destek al** kartı (en üste taşınır, hareketsiz) ve Ayarlar
satırı kalır. Ölçüm, defter ve satın alma görünmez. Kriz anında kişiye kendi
cümlelerini ya da bir değişim grafiğini göstermek, o ana ait değildir.

**S4'te yeni yol çağrısı yok.** "Sırada ne var?" sorusu path sonu raporunun işi
(PRD §7.9) ve "Keşfet"in yeri. Profil geriye bakar (İ1).

---

## 8. Alt ekranlar

### 8.1 Değişim ayrıntısı (sheet, `.medium` → `.large`)

Oura'nın [Sleep Health](https://mobbin.com/screens/617fe7b4-c91a-427b-a0f2-184ee8deb1ed)
ekranının iskeleti; sayısız.

```
┌──────────────────────────────────────────┐
│                ───                       │
│                                   Kapat  │
│  Ne değişti                              │
│                                          │
│  Kaçınman azalıyor. Duygunun şiddeti     │  cümle (tekrar)
│  başladığın yerde.                       │
│                                          │
│  Davranış                                │  katman seçici: segment
│  [ Duygu | Davranış | Öz-yeterlik ]      │  (Picker .segmented)
│                                          │
│   hafif ┆                                │
│         ┆              ●                 │  çizgi grafik
│         ┆        ●───╱                   │  (ölçüm noktaları)
│  ┄┄┄┄┄┄┄●┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄ başlangıcın  │  kesik başlangıç
│   ağır  ┆                                │
│      Başlangıç   7. adım   14. adım      │  eksen: yalnızca adlar
│                                          │
│  En çok değişen                          │
│  ┃ Yatmadan önce telefona uzanmak        │  madde metni
│    azaldı ↗                              │
│                                          │
│  En az değişen                           │
│  ┃ Uyandığında ilk düşünce               │
│    aynı →                                │
│                                          │
│  Nasıl ölçüyoruz ›                       │  açıklama sayfası
│  Bu bir klinik değerlendirme değildir.   │
└──────────────────────────────────────────┘
```

- **Eksenlerde sayı yok** (C4 grafiği kuralı). Dikey eksende yalnızca "hafif / ağır"
  (katmana göre "az / çok", "zayıf / güçlü"), yatayda ölçüm noktası adları.
- Grafik Swift Charts: `LineMark` + `PointMark`, başlangıç `RuleMark` kesik.
- **"En çok / en az değişen"**: PRD §7.9 raporunun sayısız, madde düzeyindeki
  karşılığı. Madde metni `MeasurementLibrary`den, **o ölçümde kullanılan
  varyantın** ifadesiyle gelir. İfade değişse de `MeasurementItem.id` sabit
  olduğundan bağ kopmaz.
- Segment seçimi `@SceneStorage` ile hatırlanır (HIG 2.6).
- "Nasıl ölçüyoruz": üç katman, ağırlıklar (%30/%40/%30 yazılabilir; bu bir yöntem
  bilgisi, sonuç değil), madde rotasyonu ve neden klinik ölçek kullanmadığımız.
  Güvenin kaynağı gizemden değil şeffaflıktan gelir.

### 8.2 Defter (push)

- Kronolojik, **en yeni üstte**. B1 sabit değil, en altta kendi tarihiyle durur
  (burada zaman sırası esas).
- Tarih başlıkları: *Bu hafta*, *Geçen hafta*, sonra ay adları. Gün gün başlık yok;
  boş günler arada boşluk olarak da görünmez.
- Satır: aynı alıntı stili, tam metin, adımın başlığı üst yazıda
  (*"9. adım · Düşünceden ayrışma · 11 Eylül"*). Adımda sorulan soru satır altında
  küçük ve soluk: *"Soru: Bugün zihnin nereye kaçtı?"* Cevap bağlamsız kalmasın.
- Sola kaydır → **Sil** (`role: .destructive`) → onay uyarısı:
  *"Bu cümle silinsin mi? Bu cümle hem buradan hem sunucudan silinir. Yolun
  değişmez."*
- Boş durum (kişisel patika, henüz cevap yok): *"Adımların sonunda yazdıkların
  burada birikecek. Yazmak zorunda değilsin."*

### 8.3 Yol ayrıntısı (push)

```
  ╭───────╮
  │  ╭╮   │   büyük mühür (120 pt), ilk açılışta çizilir
  │  │╰╮  │
  │  ╰─●  │
  ╰───────╯
  Zihni akşam yavaşlatma
  8 Eylül – 3 Ekim · 21 adım

  Uykuya dalma süren %41 kısaldı.           Kova A/B: headlineChange
                                            Kova C: bu satır yok

  Değişim                                   §8.1'in dört noktalı hâli
  [ grafik ]

  Sana ait kayıt
  ▶  Gece protokolün · 3 dk                 oynat
     Bende kalsın                           ShareLink → Dosyalar

  Bu yolda yazdıkların ›                    filtrelenmiş Defter
```

- Yarım kalan yol: *"8 adım yürüdün. Yol kayıtlı duruyor."* ve **Kaldığın yerden**
  bağlantısı (yalnızca `status == .paused`). "13 adım kaldı" yazılmaz (İ2).
- Sayı bu ekranda serbest, çünkü bu, PRD §7.9'un path sonu raporunun kalıcı kopyası
  ve Kova kuralları `BadgeArtifact.init` içinde zaten uygulanıyor.

### 8.4 Ayarlar ve gizlilik (sheet, `.large`, `NavigationStack`)

Stoic'in gruplu sheet'i, How We Feel'in gizlilik bölümü, Flo'nun açıklamalı
satırları. `List` + `.insetGrouped`. Sheet sistem Liquid Glass zeminini kullanır.

```
Ayarlar ve gizlilik                        Kapat
─────────────────────────────────────────────────
HATIRLATMA
  Günlük hatırlatma                   22:30  ›
  Bildirim metni hiçbir zaman yolunun adını
  ya da derdini içermez.

GİZLİLİK
  Uygulama kilidi                         [  ]
  Açılırken Face ID ister.
  Cümlelerimi Ben sekmesinde gizle        [  ]
  Kullanım verisi paylaş                  [  ]
  Hangi dokunuşların işe yaradığını anlamamıza
  yardım eder. Yazdıkların ve ölçümlerin hiçbir
  zaman buna dahil değildir.

VERİM
  Verimi indir                               ›
  Cümlelerin, ölçümlerin ve kayıtların tek bir
  dosyada.
  Cümlelerimi sil                            ›
  Defterdeki bütün cümleler silinir. Yolun ve
  ölçümlerin kalır.

HESAP
  Sana nasıl hitap edelim           Taner    ›
  Bağlı hesap                       Apple
  Çıkış yap

HAKKINDA
  Nasıl ölçüyoruz                            ›
  Gizlilik                                   ›
  Koşullar                                   ›
  Bu bir klinik değerlendirme değildir.

GERİ ALINAMAZ
  Hesabı ve bütün verileri sil               ›
─────────────────────────────────────────────────
```

**Kararlar:**

- **"Geri alınamaz"** Ladder'ın "Dangerous Area"sının karşılığı. Uyarı değil tarif:
  ne olacağını söylüyor.
- **Uygulama kilidi** yeni bir özellik ve ruh sağlığı ürününde varsayılan bir
  beklenti (How We Feel, Day One, Bearable). `LocalAuthentication`,
  `.deviceOwnerAuthentication` (Face ID yoksa parola). Kilit, arka plana geçişten
  30 sn sonra devreye girer. **SOS kilidin arkasında değil**: kilit ekranında da
  SOS görünür ve kimlik doğrulama istemeden açılır. "Destek al" hiçbir duvarın
  arkasına konmaz; kilit de bir duvar.
- **Hesap silme akışı:** satır → açıklama ekranı (neler silinir: cümleler, ölçümler,
  kayıtlar, satın alma hakları; iadelerin Apple üzerinden yapıldığı; işlemin
  sunucuda en fazla 30 gün sürdüğü) → `role: .destructive` buton → sistem
  uyarısı (HIG 7.2). App Store 5.1.1(v) uygulama içi silme istiyor. Basılı tutma
  jesti (`HoldToStartButton`) burada **kullanılmaz**: o jest ürünün "başla"
  hareketi, "sil"e ödünç verilirse anlamı bulanıklaşır.
- **Verimi indir:** KVKK Madde 11 / GDPR Madde 15, 20. JSON + ses dosyaları, zip,
  `ShareLink`. Hazırlanırken satır içinde ilerleme gösterilir (HIG 8.8).
- **"Kullanım verisi paylaş"** `consentAnalytics` ile bağlı. Açıklamasında ölçüm ve
  metnin hiçbir zaman dahil olmadığı yazıyor, çünkü bu değiştirilemez bir kural ve
  kullanıcı bunu bilmeyi hak ediyor.
- **Yok:** görünüm (uygulama koyu moda sabit), dil (cihazdan), arkadaş davet kartı,
  "App Store'da değerlendir" (bir ruh sağlığı ürünü bunu ayarlarda istememeli;
  değerlendirme isteği `SKStoreReviewController` ile yalnızca Kova A path sonunda
  ve sistem sınırlarıyla yapılır; ayrı karar).

---

## 9. Görsel dil

### 9.1 Zemin

- `BreathingMeshBackground(palette: palette.current, …)`. "Yolum" ile **aynı
  kategori paleti**. Placeholder'daki nötr palet kalkıyor: iki sekme arasında
  geçerken rengin değişmesi, "başka bir uygulamaya geçtim" hissi veriyor. Profil
  kişinin kendisi; onun rengi.
- Nefes genliği `BreathAmplitude.measurement` (%35). Okuma ekranı, oturum ekranı
  değil.
- `safeY` 0.12. Metin bandı üstte yoğun olduğu için scrim oraya çekilir.

### 9.2 Yüzey

> **BU NOT GEÇERSİZ — §20 bu alanı zaten karara bağlamıştı.**
>
> Aşağıdaki "her şey kâğıt" yönü §20 okunmadan yazıldı ve uygulandığında sayfa
> kimliğini kaybetti (ürün sahibi geri bildirimi, 2026-09-17). Geçerli karar
> §20'dedir: **krem kâğıt kapak + guaj defter çizimi, altında opak koyu adaçayı
> kartlar.** Kapak ancak altındaki yüzey ondan farklıysa kapak gibi okunuyor.
>
> Tarihsel kayıt olarak bırakıldı:
>
> Gerekçe: üç sekme üç ayrı malzemeden yapılmış gibi duruyordu. "Yolum" guaj
> manzaranın üstünde açık kâğıt tabelalar kullanıyor; "Ben" koyu kartlar
> kullanınca aynı uygulamanın parçası hissi kayboluyordu. Ortak yüzey dili
> `MyApp/DesignSystem/Components/PatikaSurface.swift` içinde (`paperSurface`,
> `PatikaRow`, `PatikaSectionLabel`).
>
> **Aşağıdaki iki kuraldan biri duruyor, biri düştü:**
>
> - **Duruyor:** kartlar Liquid Glass değil. Cam gezinme ve kontrol katmanının
>   dili; sekme çubuğu, yüzen başlık ve sheet'ler sistem camını kullanır, içerik
>   yüzeyi kullanmaz. Kâğıt cam değildir — çelişki yüzeyin **renginde**ydi,
>   malzeme kuralında değil.
> - **Düştü:** "gölge yok". O kuralın gerekçesi "koyu zeminde gölge görünmez,
>   yalnızca kirletir"di. Gölge artık koyu zeminde değil, **açık kâğıdın altında**
>   ve kâğıdı zeminden ayıran şeyin kendisi. Ölçüler `PatikaSurfaceMetrics`te.
>
> **Zemin değişmedi:** §9.1'deki nefes alan mesh yerinde kalıyor. "Ben" guaj
> manzara almadı — profil kişinin kendisi, onun rengi. Kâğıt + mesh, "Yolum" ile
> aynı hissi verir ama aynı sayfa olmaz.

Aşağıdaki bölüm kararın **öncesini** kaydeder (tarihsel):

Kartlar Liquid Glass **değil**. Apple'ın iOS 26 yönergesi camı gezinme ve kontrol
katmanına ayırıyor; içerik kartlarında cam, içerikle kontrolün ayrımını
bulanıklaştırıyor. Sekme çubuğu ve sheet'ler sistem camını kullanıyor, kartlar
sade bir koyu yüzey:

```swift
// Theme.Surface — önerilen, henüz yok
enum Surface {
    /// Mesh üstünde okunur içerik kartı.
    static let cardFill = RGB(hex: 0x000000)          // opaklık 0.22
    static let cardStroke = Theme.textPrimary         // opaklık 0.08, 1 pt
    static let cardRadius: CGFloat = 24               // .continuous
    static let cardPadding: CGFloat = 20
    /// Increase Contrast: dolgu 0.34, çizgi 0.20.
    /// Reduce Transparency: mesh düz renge döndüğü için dolgu 0.12'ye iner.
}
```

- ~~Gölge yok. Koyu zeminde gölge görünmez, yalnızca kirletir.~~ (2026-09-17'de
  düştü — yukarıdaki nota bak.)
- Kart içi ayırıcı: 1 pt, `textPrimary` %8, satır iç kenarından başlar. Kâğıt
  yüzeyde karşılığı `PaperRowDivider`: `secondaryInk` %16.

### 9.3 Tipografi

| Rol | Stil | Ağırlık (`Theme.Weight`) | Renk |
|---|---|---|---|
| Ad | `.largeTitle` | `display` (.heavy) | primary |
| Path adı | `.title3` | `title` (.bold) | primary |
| Bölüm başlığı | `.title3` | `title` | primary |
| Değişim cümlesi | `.title3` | `title` | primary |
| Satır etiketi | `.body` | `emphasis` (.semibold) | primary |
| Satır değeri | `.body` | `body` (.medium) | secondary |
| Kaynak / üst yazı | `.footnote` | `body` | secondary |
| **Kullanıcı cümlesi** | `.body`, **serif** | `body` | primary |
| Feragat, alt bilgi | `.footnote` / `.caption` | `body` | secondary |
| Buton / bağlantı | `.body` | `action` (.bold) | primary |

- **Büyük harfli üst etiket yok** (Oura'nın "LOOKING GOOD"u). Türkçede büyük harf
  dönüşümü yerel ayar ister (i → İ) ve büyük harfli etiket sakin bir ekranda bağırır.
  İstisna: Ayarlar sheet'inin `List` bölüm başlıkları. Onlar sistemin kendi stili ve
  `Locale` ile doğru çevriliyor.
- Hiçbir yerde satır içi `.weight(...)` yazılmaz (tipografi kuralı).

### 9.4 Izgara ve ritim

| Ölçü | Değer |
|---|---|
| Kenar boşluğu | 24 |
| Başlık üst boşluğu (SOS altı) | 48 |
| Bölümler arası | 40 |
| Bölüm başlığı → içerik | 12 |
| Kart iç boşluğu | 20 |
| Kart içi satırlar | 14 (değişim), 0 + ayırıcı (ayar listesi) |
| Liste satırı min. yükseklik | 52 (iki satırlı), 44 (tek satır) |
| Defter kayıtları arası | 24 |
| Mühür | 56 (liste), 120 (ayrıntı) |
| Alt boşluk (sekme çubuğu) | 120 |

8 pt ızgara; 12, 14, 20 ince ayar ara değerleri (HIG 1.5).

### 9.5 Renk

- Tek mürekkep: `textPrimary` (#F2EFE9) ve `textSecondary`. **Yeşil/kırmızı yok**,
  değişim satırlarında bile.
- Mühürlerde farklı durumlar dokuyla ayrılır (Ladder'dan): tamamlanan düz çizgi,
  aktif kesik çizgi, yarım kalan düz çizgi ama açık uçlu.
- Kategori rengi yalnızca zeminde yaşar. Hiçbir metin ya da ikon kategori rengi
  almaz.

---

## 10. Hareket ve haptik

**Whimsy bütçesi: sayfa başına en fazla 1 fark edilir an** (Ton eki §4).

| An | Hareket | Süre | Ne zaman |
|---|---|---|---|
| **Yeni ölçüm geldi** (tek fark edilir an) | Noktalar başlangıç işaretinden yeni konumlarına kayar, katmanlar arası 0.12 sn aralıkla; ardından cümle solarak belirir | 0.80 sn (`Theme.Motion.measurementBar`) + 0.30 | **Yalnızca** o ölçüm sonucu ilk kez görüldüğünde. Sonraki açılışlarda statik. |
| Yeni mühür | Rota `trim` ile çizilir, çerçeve en son kapanır | 0.44 sn (`journeyRouteDraw`) | Yalnızca yol tamamlandıktan sonraki ilk açılış. Yeni ölçümle aynı açılışa denk gelirse **yalnızca biri** çalışır (ölçüm önceliklidir). |
| Bölümler | `listReveal` | 0.11 sn aralık | Sekme ilk kez açıldığında, oturum başına bir kez |
| Kart basımı | `.calm` (0.98 ölçek) | 0.12 sn | Her dokunuş |
| Haptik | `Theme.softHaptic(intensity: 0.55)` | — | Yalnızca yeni ölçüm anımasyonu bittiğinde, bir kez |

- **Sayı sayma animasyonu yok** (sayı yok zaten), parıltı yok, konfeti yok.
- Aktif mührün uç düğümü nefes döngüsüyle hafifçe solar (0.55 ↔ 0.85 opaklık). Bu
  "fark edilir an" sayılmaz; "Yolum"daki aktif düğümle aynı sürekli taban hareketi.
  Düşük güç modunda, termal baskıda ve Reduce Motion'da durur
  (`JourneyMotionPolicy`).
- **Reduce Motion:** noktalar doğrudan yerinde, mühür çizili gelir, `listReveal`
  yalnızca solma.
- Bütün durum geçişleri 800 ms altında.

---

## 11. Erişilebilirlik

### 11.1 VoiceOver

| Öğe | Etiket | Not |
|---|---|---|
| Değişim kartı | *"Ne değişti. Kaçınman azalıyor. Duygunun şiddeti başladığın yerde."* | Tek öğe, `.isButton`, ipucu: *"Ayrıntıyı açar"* |
| Katman satırı (kart içinde, rotor ile) | *"Davranış: azaldı, başlangıcına göre"* | Konum görseli `accessibilityHidden` |
| Beklenti durumu | *"Ne değişti. İlk karşılaştırma 7. adımda."* | Buton değil |
| Defter kaydı | *"Başlangıçta, 8 Eylül. Senin cümlen: Akşamları yatağa…"* | Özel eylem: *Sil* |
| Mühür | *"Zihni akşam yavaşlatma yolu, 21 adım, 3 Ekim'de tamamlandı"* | Çizim gizli |
| Aktif mühür | *"Zihni akşam yavaşlatma yolu, yoldasın, 9. adım"* | |
| Ayar satırı | *"Hatırlatma, 22:30. Yatağa girince dediğin için seçildi."* | `.isButton` |
| Destek al | *"Destek al. Konuşabileceğin biri, şimdi."* | `accessibilitySortPriority` yüksek değil; sayfa sırası korunur |

Okuma sırası görsel sırayla aynı. Özel sıralama gerekmiyor.

### 11.2 Dynamic Type — AX5'e kadar

**Değişim satırları** (`dynamicTypeSize.isAccessibilitySize`):

```
 Davranış
 azaldı ↗
 ─────────┆───●──────
```

Etiket, yön ve iz üst üste diziliyor; iz tam genişliğe çıkıyor.

- Değişim cümlesi ve defter kısaltılmaz; tam metin akar.
- Mühür ızgarası tek kolona döner, mühür 44 pt'ye iner.
- Ayar satırlarında değer, etiketin **altına** iner (sağa sıkışmaz).
- Başlıktaki path adı 4 satıra kadar serbest.
- Değişim ayrıntısındaki grafik AX boyutlarında **gizlenir**. Yerine her ölçüm
  noktası için bir satır gelir: *"7. adım: azaldı"*. Grafik okunamayacak kadar
  küçülür, metin okunur.

### 11.3 Diğer

- **Reduce Motion:** §10.
- **Reduce Transparency:** mesh düz koyu renge döner (mevcut kural). Kart dolgusu
  0.12.
- **Increase Contrast:** kart çizgisi 0.20, `textSecondary` yerine `textPrimary`
  %88, başlangıç işareti düz çizgi.
- **Bold Text:** sistem stilleri otomatik; serif de dahil.
- **Renk tek başına anlam taşımaz:** zaten renk kullanılmıyor. Yön = kelime + ok +
  konum.
- **Dokunma alanları:** kart, satır, "Tümü", alt bilgi bağlantıları en az 44 × 44.
- **Kontrast testi:** "Ben" ekranı `ImageRenderer` kontrast testine eklenir. Mesh
  hareket ettiği için döngü boyunca birden fazla `t` noktası örneklenir. Test hem
  kartlı hem kartsız bölgeyi (defter doğrudan zeminde) kapsar.

---

## 12. Mikrometin

Ton kademesi: sayfa **Sakin**, Destek al **Nötr**, mühür satırları Kova A/B'de
**Sıcak**, Kova C'de **Nötr**. Ünlem yok. `BannedPhrases.check` bütün metinlerden
geçer.

### 12.1 Sabit metinler

| Anahtar (`Copy.Me.*`) | Metin |
|---|---|
| `changeTitle` | Ne değişti |
| `changePending` | İlk karşılaştırma 7. adımda. O güne kadar ölçecek bir fark yok. |
| `baselineLegend(step:)` | Başlangıcın · {7}. adımda ölçüldü |
| `baselineLegendDate(date:)` | Başlangıcın · {8 Eylül}'de ölçüldü |
| `baselineProvisional` | Başlangıcın tek ölçüme dayanıyor · biraz oynayabilir |
| `journalTitle` | Defter |
| `journalAll` | Tümü |
| `journalOrigin(date:)` | Başlangıçta · {tarih} |
| `journalAvoidance(date:)` | Başlangıçta, kaçındığın şey · {tarih} |
| `journalAfterStep(n:date:)` | {n}. adımdan sonra · {tarih} |
| `journalEmpty` | Adımların sonunda yazdıkların burada birikecek. Yazmak zorunda değilsin. |
| `journalHidden` | Gizli · göstermek için dokun |
| `journalDeleteTitle` | Bu cümle silinsin mi? |
| `journalDeleteBody` | Bu cümle hem buradan hem sunucudan silinir. Yolun değişmez. |
| `pathsTitle` | Yürüdüğün yollar |
| `pathActive(step:)` | Yoldasın · {n} adım |
| `pathStopped(steps:)` | {n} adım yürüdün |
| `pathStoppedDetail` | Yol kayıtlı duruyor. |
| `pathPartial` | Bazı şeyler değişti |
| `noActivePath` | Şu an bir yolda değilsin. |
| `preferencesTitle` | Sana göre ayarlananlar |
| `reminderSource(answer:)` | "{Yatağa girince}" dediğin için |
| `appliesFromNextStep` | Bir sonraki hazırlanan adımdan itibaren. Sıradaki adımın sesi hazırlanmış olabilir. |
| `supportTitle` | Destek al |
| `supportSubtitle` | Konuşabileceğin biri, şimdi. |
| `accessTitle` | Yol erişimi |
| `accessPreview` | İlk adım açık |
| `accessOwned(steps:)` | {21} adım açık |
| `accessContinuation` | Devam yolu · ücretsiz |
| `accessFree` | Ücretsiz yol |
| `restorePurchases` | Satın alımları geri yükle |
| `settingsRow` | Ayarlar ve gizlilik |
| `anonymousTitle` | Bu kayıt şimdilik yalnızca bu telefonda. |
| `anonymousBody` | Hesaba bağlarsan telefon değişince kaybolmaz. |
| `irreversibleHeader` | Geri alınamaz |
| `analyticsFootnote` | Hangi dokunuşların işe yaradığını anlamamıza yardım eder. Yazdıkların ve ölçümlerin hiçbir zaman buna dahil değildir. |
| `notificationPrivacyFootnote` | Bildirim metni hiçbir zaman yolunun adını ya da derdini içermez. |

### 12.2 Değişim cümlesi — deterministik şablon

Model yok. Girdi: üç katmanın yönü (`better` / `same` / `worse`). Çıktı: en fazla
iki cümle.

**Parçalar:**

| Katman | better | same | worse |
|---|---|---|---|
| Duygu | Duygunun şiddeti hafifliyor. | Duygunun şiddeti başladığın yerde. | Duygunun şiddeti başlangıcından ağır. |
| Davranış | Kaçınman azalıyor. | Kaçınman başladığın yerde. | Kaçınman başlangıcından fazla. |
| Öz-yeterlik | Baş edebileceğine dair inancın güçleniyor. | Baş edebileceğine dair inancın başladığın yerde. | Baş edebileceğine dair inancın başlangıcından zayıf. |

**Seçim kuralı:**
1. `worse` olan her katman cümleye girer (İ5, Kova C dürüstlüğü).
2. Kalan yer `better`, sonra `same` katmanlarıyla doldurulur. Eşitlikte davranış
   önce gelir (en ağır ve en sağlam katman, %40).
3. Üçü de aynı yöndeyse tek bir birleşik cümle kullanılır:
   - üçü `better`: *"Üç katmanda da başladığın yerden farklı bir yerdesin."*
   - üçü `same`: *"Şimdilik üç katman da başladığın yerde. Bu, yolun ortasında sık görülür."*
   - üçü `worse`: *"Üç katmanda da başlangıcından ağır bir yerdesin. Bunu konuşmak istersen Destek al burada."*
     Bu durumda Destek al kartı sayfada **değişim kartının hemen altına** taşınır.
     S8 değil, çünkü bu bir kriz sinyali değil; ama yalnız bırakılmamalı.
4. "Hafifliyor / azalıyor" gibi süreç kipi kullanılır. "Hafifledi" bir sonuç iddia
   eder, "hafifliyor" ise yolun ortasındaki bir gözlemi söyler. Path bittikten sonra
   (S4) geçmiş kipe geçilir: *"hafifledi"*.

"Harika", "tebrikler", "bravo", "devam et", "aşacaksın" gibi ifadeler şablonda yok
ve lint ile yasak.

---

## 13. Önceki taslaktan ayrılan kararlar

`PRD-Ek-Profil-Sayfasi.md` §6'ya göre:

| Önceki | Şimdi | Gerekçe |
|---|---|---|
| "Şu anki patikan" kartı (iz + "8/21 adım" + sonraki ölçüm) | **Kaldırıldı.** Başlıkta yalnızca path adı + "Faz · N. adım" | "Yolum" zaten tam olarak bu. İki sekmenin aynı kartı taşıması, sekmeleri ayırt edilemez yapıyordu. "8/21" ise İ2'ye aykırı. |
| Ölçüm satırları: yön oku + kelime | + **başlangıç izi üzerinde konum** + **önce cümle** | Oura incelemesi: kelime tek başına büyüklük söylemiyor; cümle olmadan üç satır "okunacak tablo" gibi duruyor. |
| "Fark ettiklerin" (B1 + B4, salt okunur) | **Defter**: + oturum sonu cevapları, B1 sabit ilk sırada, silinebilir | Kişisel patikada `AdaptiveQuestionView` cevapları artık var (2026-09-09 sonrası). Silme hakkı KVKK/GDPR gereği. |
| Ton satırı | Anlatım + **Rehber sesi** | E4 sonradan eklendi. |
| **Abonelik** · "14 Ekim 2026'ya kadar" | **Yol erişimi** · durum; fiyat ana sayfada yok | `monetization.md`: lansmanda abonelik yok, consumable path satın alımı var. |
| Rozet (tanımsız) | **Mühür = yolun rota çizimi** | Tek mürekkep kuralı + kişiye özgülük + PRD §10 "kendi haritası". |
| Ayarlar sheet (içerik listesi) | + **Uygulama kilidi**, **cümleleri gizle**, **cümleleri sil**, SOS kilit dışında | How We Feel / Flo incelemesi; İ7. |
| Bölümlerin sırası: kimlik, patika, ölçüm, fark ettiklerin, ayarlar, destek, abonelik | Kimlik, **ölçüm, defter, yollar**, ayarlar, destek, erişim, uygulama | Patika kartı kalktı; mühürler eklendi. Geriye bakan üç bölüm üstte toplandı. |

Önceki taslağın **korunan** bütün kararları (P1–P8): profil bir kendini tanıma
kaydı, Ahead'in motivasyon mekaniği yok, avatar yok, yüzde yok, 7. adımdan önce sayı
yok, Destek al erişimin üstünde, cinsiyet/yaş hiçbir yerde yok, ayarlar ayrı sheet.

---

## 14. Uygulama haritası

### 14.1 Dosyalar (`MyApp/Features/Me/`)

| Dosya | Rol |
|---|---|
| `MeView.swift` | Yerleşim ve bağlama. İş kuralı yok. |
| `MeViewModel.swift` | `@Observable @MainActor final class`. Bölüm durumları, cümle seçimi, gizlilik örtüsü, sheet yönlendirmesi. `SwiftUI` import etmez. |
| `MeSections.swift` | Saf değer tipleri: `ChangeSummary`, `JournalEntry`, `PathSeal`, `PreferenceItem`, `PathAccessState`. |
| `ChangeSentence.swift` | §12.2 şablonu. Saf fonksiyon; test hedefi eklendiğinde vaka tablosu. |
| `ChangeDetailSheet.swift` | §8.1 |
| `JournalView.swift` | §8.2 |
| `PathDetailView.swift` | §8.3 |
| `SettingsSheet.swift` + `AccountDeletionView.swift` | §8.4 |
| `AppLockController.swift` | `LocalAuthentication`, arka plan zamanlayıcısı, SOS istisnası |

### 14.2 Yeni bileşenler (`DesignSystem/Components/`)

| Bileşen | Yeniden kullanım |
|---|---|
| `BaselineTrack` | Değişim satırı; ileride 7. adım ölçüm ekranı |
| `UserQuote` | Serif alıntı; C1, G1 ve Defter aynı bileşeni kullanmalı |
| `RouteSeal` | `JourneyRoutePattern`ten geometri alır; F2 sonu ve path sonu raporu |
| `ProfileCard` | `Theme.Surface` uygulaması |
| `SectionHeader` | Başlık + isteğe bağlı "Tümü" |
| `PreferenceRow` | Etiket / değer / kaynak |

ViewModel kararları hazır özellik olarak sunar. View `if` ile hesaplamaz:
`showsChangeSection`, `changeIsPending`, `showsJournalSection`,
`supportPlacement` (`.standard` / `.belowChange` / `.top`), `canOfferPurchase`
(içinde `allowsSelling`), `isContentObscured`.

### 14.3 Veri — bugün nerede, ne gerekiyor

| Veri | Bugün | Gereken |
|---|---|---|
| Ad | `UserProfile.displayName` (SwiftData) | Sunucuda `profiles.display_name` (cihaz değişimi) |
| Path + adımlar + faz | `ActivePath` / `PathStepRecord` | Geçmiş path'ler için `listPaths()` uç noktası |
| Ölçüm yönü | `MeasurementScoring` (istemci) + `measurements` tablosu | 7/14/son ölçüm yazımı; istemci–sunucu skor sürüklenmesi riski duruyor (CLAUDE.md) |
| Madde bazlı en çok/en az değişen | `MeasurementScoring` katman düzeyinde | Madde düzeyinde fark çıktısı eklenmeli |
| B1, B4 metni | `ProblemStatement` şifreli tablo | Sahibine çözülmüş okuma uç noktası ya da yerel şifreli kopya |
| Oturum sonu cevapları | `complete-step` şifreleyip yazıyor | `listReflections()` (sahibine çözülmüş) + `deleteReflection(id)` |
| Hatırlatma / uzunluk / ton / ses | `UserProfile` (yerel) + `generate-path` payload | Değişikliğin N+2'den itibaren üretime yansıması |
| Kova + headline | `BadgeArtifact`, `OutcomeBucket` | Path sonu servisi |
| Yol erişimi | Yok | StoreKit 2 + sunucu hak kaydı (monetization §5.2) |
| Veri dışa aktarma / hesap silme | Yok | Edge Function: `export-user-data`, `delete-account` |

**Sıra önerisi:** Ekranın ilk sürümü, bugün var olan verilerle (başlık, beklenti
durumu, B1, ayarlar, Destek al, Ayarlar sheet'i) yazılabilir. Bu, önceki taslağın
"profil ölçüm servisinden sonra" sırasını gevşetiyor: beklenti durumu (§6.3)
tasarımın zaten bir parçası, geçici bir boşluk değil. Değişim kartı ölçüm yazımı
gelince, mühürler path sonu servisi gelince dolar. Bölüm sırası sabit olduğu için
(İ4) bu kademeli doluş kullanıcıya bir yeniden tasarım gibi görünmez.

### 14.4 Analitik

Olaylar yalnızca yapı taşır, **içerik taşımaz** (değiştirilemez gizlilik kuralı):

```
me_viewed                    {state: S0…S8}
me_change_detail_opened      {layer}
me_journal_opened
me_journal_entry_deleted
me_path_detail_opened        {bucket?}
me_preference_changed        {key: reminder|length|tone|voice}
me_path_access_opened        {state}
support_opened               {source: "me"}
app_lock_toggled             {enabled}
data_export_requested
account_deletion_requested
```

Cümle metni, ölçüm değeri, yön ve path adı hiçbir olaya yazılmaz.
`me_change_detail_opened` yalnızca katman adını taşır, yönü değil.

---

## 15. Kalite kapısı

### 15.1 Ekran görüntüsü incelemesi

Superwall editörünün inceleme adımından uyarlandı. Her durum için (S0–S8) standart
boyut, AX3 ve AX5'te simülatör görüntüsü alınır; her madde tek satırlık bir hükümle
yazılır:

- **Aralık:** eşit olmayan boşluk, sıkışık grup, istemsiz boş alan var mı?
- **Tipografi:** hiyerarşi okunuyor mu? Kullanıcı sesi ürün sesinden ayrılıyor mu?
- **Kontrast:** mesh'in en parlak anında `textSecondary` okunuyor mu?
- **Hiza:** değişim satırlarının izleri aynı kolonda başlıyor mu?
- **Kırpılma:** hiçbir kullanıcı cümlesi kelime ortasından kesilmiyor mu?
- **CTA netliği:** *bu ekranda* en güçlü görsel ağırlık bir satın alma ya da
  başlatma butonunda **olmamalı**. Ağırlık değişim cümlesinde olmalı.

### 15.2 HIG kontrol listesi (ekrana özel)

- [ ] Bütün dokunma alanları ≥ 44 pt
- [ ] SOS dahil hiçbir öğe Dynamic Island / ev göstergesi altında değil
- [ ] Sekme çubuğu alt ekranlarda gizlenmiyor (push'larda da görünür)
- [ ] Sheet'lerde hem kaydırarak kapatma hem "Kapat" butonu
- [ ] Sheet üstünde sheet yok (Ayarlar → Silme bir push, sheet değil)
- [ ] Bağlam menüsündeki Sil, kaydırma eylemiyle de erişilebilir
- [ ] Yıkıcı işlemler `role: .destructive` + sistem uyarısı
- [ ] Face ID izni bağlamında isteniyor (anahtar açılırken), açılışta değil
- [ ] Tam ekran engelleyici yükleme yok; bölüm iskeletleri `.redacted(reason: .placeholder)`
- [ ] Sekme değişiminde kaydırma konumu korunuyor
- [ ] AX5'te hiçbir metin kırpılmıyor
- [ ] Reduce Motion, Reduce Transparency, Increase Contrast ve Bold Text ayrı ayrı denendi
- [ ] Uygulama değiştiricide kullanıcı cümlesi görünmüyor

### 15.3 Ürün kuralı kontrol listesi

- [ ] Ekranda seri, XP, seviye, sıralama, yüzde, "N/M" yok
- [ ] Mutlak skor hiçbir yerde yok; ana sayfada hiç sayı yok (tarih ve adım konumu hariç)
- [ ] 7. adımdan önce değişim noktası yok
- [ ] Kötüleşen katman cümlede geçiyor
- [ ] Destek al, yol erişiminin üstünde ve kriz durumunda en üstte
- [ ] `allowsSelling == false` iken satın alma butonu çizilmiyor
- [ ] Cinsiyet ve yaş hiçbir yerde yok
- [ ] Emoji yok; bütün ikonlar SF Symbols
- [ ] Bütün metinler `BannedPhrases.check`ten geçiyor
- [ ] Analitik olaylarında içerik yok

### 15.4 Neden bu ekran bir tasarım ödülüne aday olabilir

Apple Design Award kategorileri *Delight and Fun*, *Inclusivity*, *Innovation*,
*Interaction*, *Social Impact* ve *Visuals and Graphics*. Bu ekranın iddiası dördünde:

- **Innovation:** Kategorideki her profil ekranı ya aktiviteyi ya puanı gösteriyor.
  Bu ekran *kişisel başlangıca göre konum* ve *kullanıcının kendi sesi* ile değişimi
  sayısız gösteriyor. Mühürler kişiye özgü ve üretken (generative), ama tamamen
  deterministik.
- **Social Impact:** Kaygı ürünlerindeki bağımlılık mekaniklerinin (seri, kilit,
  kıyas) bilinçli olarak reddedilmesi ve yerine dürüst ölçümün konması. Kova C'de
  bile yalan söylemeyen bir sonuç dili.
- **Inclusivity:** AX5'te grafiğin metne dönüşmesi, üç kanallı yön bilgisi, uygulama
  kilidi, omuz üstü gizlilik, isimsiz kullanıcının eksiksiz deneyimi.
- **Visuals and Graphics:** Tek mürekkep, nefes alan zemin, iki ses tipografisi ve
  ürünün yol dilini profil sayfasına kadar taşıyan mühürler.

---

## 16. Onay bekleyen kararlar

Aşağıdakiler tasarımın içinde varsayılmış ama ürün sahibinin kararı gerektiriyor:

| # | Soru | Önerilen | Neden soruluyor |
|---|---|---|---|
| O1 | **İki ses tipografisi** (kullanıcı cümlesi New York serif) | Evet, ve C1 + G1'e de yayılsın | Tipografi kararı tek kaynaklı (`Theme.Weight`); yeni bir font ailesi rolü ekliyor |
| O2 | **Mühür = rota çizimi** (klasik rozet yerine) | Evet | PRD §10 ve Ton eki "rozet"i tanımlıyor ama biçimini değil; Rive rozet brief'i varsa çelişir |
| O3 | Ana sayfada **hiç yüzde yok**, sayı yalnızca path sonu raporu ve yol ayrıntısında | Evet | PRD §8.1 "7 gün öncesine göre %30 düşük" örneğine izin veriyor; bu belge daha sıkı |
| O4 | **Uygulama kilidi** + cümleleri gizle | Evet, v1 | Yeni özellik, PRD'de yok |
| O5 | Yol erişimi satırından **kullanıcı isteğiyle satın alma** açılabilsin mi? | Evet, fiyat ana sayfada yazmadan | Monetization paywall'ı yalnızca ilk oturum sonrasında tanımlıyor; profil girişi ek bir satış yüzeyi |
| O6 | **Dişli ikonu yok**, ayarlar son satırda | Evet | HIG alışkanlığından sapma; gerekçe SOS'un tekilliği |
| O7 | Profil zemininde **kategori paleti** (nötr yerine) | Evet | `MeTab` placeholder'ı nötr palet kullanıyor; Keşfet nötr kalır |
| O8 | Defterde **düzenleme yok, yalnızca silme** | Evet | Kullanıcı yazım hatasını düzeltmek isteyebilir; ama cümle zaten üretime girdi |
| O9 | Profilin **ölçüm servisini beklemeden** kademeli yazılması | Evet (§14.3) | Önceki taslağın sırasını değiştiriyor |

---

## 17. Karar günlüğü

| # | Karar | Gerekçe |
|---|---|---|
| PD1 | "Ben" geriye bakan defter, "Yolum" ileriye bakan harita | İki sekmenin işini ayırmak; profil kartının "Yolum"u tekrar etmesini bitirmek |
| PD2 | Birincil CTA yok | Profil bir huni değil; başlatma "Yolum"un işi |
| PD3 | Değişim = başlangıç izi üzerinde konum + kelime + ok, sayı yok | PRD §8.1 mutlak skor yasağı; Faz 0 öncesi kesinlik iddiası yok; renk tek başına anlam taşımaz |
| PD4 | Önce cümle, sonra görsel | Oura incelemesi; kaygılı kullanıcı grafiği okumak zorunda kalmamalı |
| PD5 | Kötüleşen katman cümlede mutlaka geçer | Yalnızca iyileşmeyi göstermek ölçümü reklama çevirir |
| PD6 | 7. adımdan önce yapı görünür, nokta yok; kilit/bulanıklık yok | Ahead'in kilitli kartının dürüst sürümü; erişim davranışa bağlı değil |
| PD7 | Kullanıcı cümlesi serif, ürün sans | Kimin konuştuğu fontan okunur; kullanıcının cümlesine ayrı bir yüz |
| PD8 | Defterde B1 sabit ilk sırada, yorum yok | İlk ve son cümlenin yan yanalığı kanıt olur; yorum Kova C'de yalan olurdu |
| PD9 | Defterde sayaç ve bağımsız "Ekle" yok | Belirti biriktirmeye teşvik etmemek; günlüğü ödeve çevirmemek |
| PD10 | Düzenleme yok, silme var | Geçmiş yeniden yazılmaz; kişinin silme hakkı korunur |
| PD11 | Mühür = yolun rota çizimi, kova farkı çizimde yok | Tek mürekkep; kişiye özgülük; emek tanınır, sonuç çizime işlenmez |
| PD12 | Yarım kalan yol yürünen adımla yazılır | Equinox+'ın "0 of 16"sı; yapılmayanı saymak suçluluk üretir |
| PD13 | Ayarlarda kaynak satırı | Sorduğumuz her şeyin karşılığı görünür olmalı (Yazio çiplerinin dürüst sürümü) |
| PD14 | Abonelik satırı → Yol erişimi, fiyat ana sayfada yok | `monetization.md` (abonelik yok); profilde teklif görmemek |
| PD15 | Uygulama kilidi, SOS kilidin dışında | Ruh sağlığı verisi; destek hiçbir duvarın arkasında değil |
| PD16 | Kriz durumunda ölçüm ve defter gizli | O anda kişiye grafik ya da kendi cümlesi gösterilmez |
| PD17 | Dişli ikonu yok | SOS sağ üstte tekil kalmalı |
| PD18 | Kartlar Liquid Glass değil | iOS 26 yönergesi: cam gezinme/kontrol katmanı içindir |
| PD19 | Büyük harfli üst etiket yok | Türkçe büyük harf dönüşümü ve sakin ton |
| PD20 | Sayfada tek fark edilir hareket anı: yeni ölçüm | Ton eki whimsy bütçesi; tekrar eden animasyon anlamını yitirir |
| PD21 | Davet kartı, "değerlendir" satırı, paylaşılabilir sonuç kartı yok | Kullanıcının derdi bir pazarlama kanalına çevrilmez |
| PD22 | Karşılaştırma yalnızca iki ölçümde de cevaplanmış **ortak maddeler** üzerinden (2026-09-12) | 14. gün kısa form (6 madde); 8 maddelik baseline ile karşılaştırıldığında hiçbir cevap değişmemişken duygu katmanı "ağırlaştı" görünüyordu — simülatörde yakalandı |
| PD23 | İz ölçeği 25 değil **40 puan** | Dört kovalı maddelerde tek kova değişimi bile ucu buluyordu; noktalar kenarda toplanıyordu |
| PD24 | Anonim hesap kartı başlığın altında değil, **ayarların hemen üstünde** ve kompakt; sağlayıcı butonları ayrı yaprakta | İlk ekranın yarısını kaplayıp "Ne değişti"yi aşağı itiyordu |
| PD25 | Adım uzunluğu, anlatım ve ses **salt okunur**, altında nedeni yazıyor | Üçü de path üretilirken sunucuya gidiyor; sonradan değiştirmenin bir karşılığı yok. Çalışmayan bir düğme "kişiselleştirme tiyatrosu" olurdu |

---

## 18. Uygulama durumu (2026-09-12)

Ürün sahibi §16'daki kararların tamamını onayladı ("tam olarak yap"). Sayfa
`MyApp/Features/Me/` altında yazıldı ve simülatörde altı senaryoda doğrulandı
(beklenti, karşılaştırma, kötüleşme, bitmiş yol, kriz, AX5).

**Yazılanlar**

| Parça | Dosya |
|---|---|
| Cihazdaki kişisel kayıt (ad, ilk cümle, baseline, tercihler, defter, arşiv) | `Models/ProfileRecord.swift`, `Infrastructure/Persistence/ProfileStore.swift` |
| Sayfa, bölümler, alt ekranlar | `Features/Me/MeView.swift`, `MeViewModel.swift`, `ChangeAnalysis.swift`, `ChangeDetailSheet.swift`, `JournalView.swift`, `PathDetailView.swift`, `SettingsSheet.swift` |
| Bileşenler | `ProfileCard`, `BaselineTrack`, `UserQuote`, `RouteSeal` |
| Günlük hatırlatma (cihazda, `.active`, ses yok, izin bağlamında) | `Infrastructure/Notifications/ReminderScheduler.swift` |
| Uygulama kilidi + arka plan perdesi (SOS ikisinin de dışında) | `Infrastructure/Security/AppLockController.swift`, `Features/Security/AppLockView.swift` |
| Destek al (TR/DE/US/GB hatları) | `Features/Support/SupportView.swift`, `Models/SupportResources.swift` |
| DEBUG senaryoları | `Features/Me/MeDebugSeed.swift` |

**Bu iş sırasında düzeltilen mevcut hatalar**

- Onboarding bittikten sonra cihazda hiçbir şey kalmıyordu (ad, B1 cümlesi,
  baseline, tercihler yalnızca bellekteki taslaktaydı).
- "Yolum" oturumu kullanıcının seçtiği adım uzunluğunu değil sabit 10 dakikayı
  kullanıyordu.
- Palet uygulama yeniden açıldığında nötre düşüyordu.

**Tasarımda olup yazılmayanlar — ve neden**

| Tasarımda | Durum | Engel |
|---|---|---|
| §6.8 Yol erişimi satırı | Yok | StoreKit 2 ve sunucu hak kaydı yok; olmayan bir satın alma durumunu göstermek yanlış bilgi olurdu |
| §8.4 Hesabı ve bütün verileri sil | Yalnızca **bu cihazdaki kayıt** silinebiliyor | Sunucuda `delete-account` uç noktası yok. App Store 5.1.1(v) uygulama içi hesap silmeyi zorunlu tutuyor — **yayından önce bloklayıcı** |
| §8.2 Cümle silme "sunucudan da" | Yalnızca cihazdan | Sunucudaki şifreli cevap için silme uç noktası yok; metin buna göre dürüstçe yazıldı |
| §6.6 Uzunluk / ton / ses düzenleme | Salt okunur (PD25) | Sunucuda path tercihlerini güncelleyen bir uç nokta yok |
| §6.3–6.2 dolu değişim kartı | Gerçek kullanıcıda hep beklenti durumu | 7. ve 14. adım ölçüm akışı henüz yok; kart DEBUG senaryolarıyla doğrulandı |
| §6.5 arşiv mühürleri | Gerçek kullanıcıda yalnızca aktif yol | Path sonu servisi (`pathArchive`i dolduracak) henüz yok |

**Güncelleme — yalnızca gerçek veri (2026-09-12, ürün sahibi kararı)**

Ürün sahibi "olmayan veri gözükmesin, not eklenmesin, her şey çalışsın" dedi.
Bu, §6.3 beklenti durumunu ve §6.4–6.5 boş durumlarını **geçersiz kılar**:

| Önceki karar | Şimdi |
|---|---|
| §6.3 7. adımdan önce yapı görünür, nokta yok | Kart hiç çizilmez; ilk gerçek karşılaştırmayla belirir |
| §6.4 defter boş durum metni | Bölüm çizilmez |
| §6.5 `me-paths-empty` boş durumu | Bölüm çizilmez; görsel kullanılmıyor |
| §6.6 tercih dipnotu, "Henüz açık değil" | Kaldırıldı; hatırlatma değeri "Kapalı" |
| Ayarlarda açıklama dipnotları | Yalnızca analitik izni açıklaması kaldı (bilgilendirilmiş izin) |

Yukarıdaki "yazılmayanlar" tablosunun güncel hâli:

| Parça | Durum |
|---|---|
| Hesap silme | **Yazıldı** — `delete-account` |
| Cümle silme sunucudan | **Yazıldı** — `delete-journal` |
| Dolu değişim kartı | **Gerçek veriyle çalışıyor** — yol içi ölçüm akışı yazıldı |
| Ad sunucuda | **Yazıldı** — `update-profile`, şifreli |
| Yol erişimi satırı | Hâlâ yok (StoreKit) |
| Arşiv mühürleri ve kova | **Yazıldı** — `complete-step` son adımda yolu tamamlar; kova baseline ↔ son ölçümden hesaplanır |
| İkinci yolda ölçüm çakışması | **Kapandı** — ölçümler `path_id` taşır, tekillik yol başına (20260912120000) |
| Migrasyon defteri | **Onarıldı** |
| Sunucu testleri | **Koşuyor** — 21/21 |
| Uzunluk / ton / ses düzenleme | Salt okunur, dipnotsuz |

**Doğrulama komutları**

```bash
xcrun simctl launch booted devplaceholder.X9RQKIJ8.MyApp \
  -patika-debug-step yolum -patika-debug-tab ben \
  -patika-debug-me compared            # pending | compared | worse | finished | crisis | empty
  # -patika-debug-me-anchor paths      # change | journal | paths | preferences | settings
  # -patika-debug-me-sheet change      # change | settings | reminder | support
```

---

## 19. Görsel prompt'ları

"Ben" sekmesinde yalnızca **iki** raster görsel var ve ikisi de isteğe bağlı:
varlık eklenmediyse yer kaplamazlar, sayfa görselsiz de eksiksiz çalışır.
Mühürler, başlangıç izi ve grafik kodla çiziliyor — onlar için görsel üretilmez.

Yuvalar hazır: `MyApp/Assets.xcassets/Me/`. Kaynak dosyalar
`assets/illustrations/me/` altına konur.

### Ortak kurallar (her iki prompt'a da uygulanır)

- **Transparan zemin.** Görsel kullanıcının kategori paletine göre değişen bir
  gradyanın üstünde duruyor; kendi zeminiyle gelirse kutu gibi görünür.
- **Yalnızca sıcak kırık beyaz (#F2EFE9) ve soğuk gri öz gölgeler.** Kendi rengini
  getiren görsel on paletten bir kısmıyla çakışır.
- Mevcut `journey-*` ve C1/C2 ailesiyle aynı dil: ince keçe-kâğıt dokusu, yumuşak
  kabartma, heykelsi boşluk.
- **Yasak:** insan, yüz, el, metin, harf, rakam, ikon, emoji, yıldız, kupa, madalya,
  rozet, ok, merdiven, zirve, grafik, onay işareti, konfeti, parıltı.
- Ekranda %18–20 opaklıkla duracaklar; ince detay kaybolur, **silüet** okunmalı.
- 1024×1024 üret, çevresindeki boşluğu kırp, 2x yuvaya en az 512 px uzun kenar.

### 1 · `me-header-notebook` — başlığın sağındaki sessiz işaret

Nerede: "Ben" başlığının sağında, adın arkasında, %20 opaklık, ~128×104 pt.
Anlamı: sayfanın fikri — *geriye bakan defter*. Harita değil, not.

```
A single sculptural paper relief object on a fully transparent background: an
open, slightly curved notebook seen from a low three-quarter angle, its two pages
made of thick soft felt-paper. Across both pages runs one continuous, gently
winding groove, like a quiet path pressed into the paper, starting near the lower
left corner of the left page and fading out before reaching the right edge of the
right page. The groove is debossed, not drawn: it is visible only through soft
self-shadow. Palette strictly limited to warm off-white (#F2EFE9) with cool grey
self-shadows; no other colors, no color cast. Subtle fine fibrous paper texture,
matte, soft diffuse light from the upper left, very gentle ambient occlusion. Calm,
minimal, premium, quiet. Generous empty space around the object. No people, no
hands, no faces, no text, no letters, no numbers, no lines of writing on the pages,
no icons, no emoji, no stars, no trophies, no medals, no badges, no arrows, no
stairs, no mountains, no charts, no checkmarks, no sparkles, no confetti, no
background, no ground shadow plane, no frame.
```

Kontrol: %20 opaklıkta ve 128 pt'de defter + tek yol silüeti okunuyor mu? Sayfalarda
yazıya benzeyen çizgi var mı (olmamalı — kullanıcının cümleleri zaten ekranda)?

### 2 · `me-paths-empty` — "Yürüdüğün yollar" boş durumu

Nerede: kullanıcının hiç yolu yokken (hazır içerik kullanıcısı), boş durum
cümlesinin ("İlk patikanı bitirdiğinde burada bir şey olacak. Acelesi yok.")
üstünde, ~112 pt yükseklik, tam opaklık ama zaten soluk tonlarda.
Anlamı: henüz yürünmemiş ama orada duran bir yol — **eksiklik değil, bekleyen alan**.
Boş bir rozet yuvası, kırık bir çizgi ya da "kilitli" hissi vermemeli.

```
A single small sculptural paper relief on a fully transparent background: a short
soft ribbon of thick felt-paper lying flat and curving gently like an unwalked
footpath, beginning as a slightly raised strip in the lower left and softly
flattening into the surface toward the upper right until it disappears, leaving
open calm space. Next to the start of the ribbon, a single small smooth rounded
pebble-like paper form rests quietly. Palette strictly limited to warm off-white
(#F2EFE9) with cool grey self-shadows; no other colors. Very pale, low contrast,
matte fine fibrous paper texture, soft diffuse light from the upper left, gentle
ambient occlusion only where the ribbon touches the surface. Mood: patient,
unhurried, nothing missing. Minimal, premium, lots of negative space. No people, no
footprints, no hands, no faces, no text, no numbers, no icons, no emoji, no stars,
no trophies, no medals, no badge outlines, no empty slots, no locks, no dashed
lines, no arrows, no flags, no signposts, no stairs, no mountains, no charts, no
checkmarks, no sparkles, no background, no frame.
```

Kontrol: bir **kilit**, **boş yuva** ya da **yarım kalmış bir şey** gibi okunuyor mu
(okunmamalı)? Ayak izi ya da bayrak gibi bir "hedef" imgesi var mı (olmamalı —
hedefe varma dili bu ekranın tonuna aykırı)?

### Eklemek için

1. Prompt'u **aynen** yapıştır (her görsel ayrı sohbet).
2. Arka planı sil, şeffaf PNG olarak kaydet:
   `assets/illustrations/me/me-header-notebook-source.png`,
   `assets/illustrations/me/me-paths-empty-source.png`.
3. Uzun kenarı 512 px'e küçült ve Xcode'da `Assets.xcassets → Me` altındaki aynı
   adlı yuvanın **2x** kutusuna sürükle.
4. `-patika-debug-me compared` ile başlığı, `-patika-debug-me empty` ile boş
   durumu simülatörde kontrol et.

## 20. Guaj defter revizyonu — 17 Eylül 2026

Ürün sahibi Yolum ve Ben'in onaylı guaj illüstrasyonlarla aynı dili taşımasını
istedi. Mobbin MCP ile Ahead'in kişisel kayıt ekranları ve Finch'in gruplu profil
alanları görsel olarak incelendi:
- https://mobbin.com/screens/b9227303-6f15-4e41-9447-6008d98cb635
- https://mobbin.com/screens/ff6cc7d1-5257-48da-8101-4039b2152975

Krem kâğıt kapak, koyu yeşil metin ve mevcut şeffaf guaj defter çizimi; altında
opak koyu adaçayı kartlar. Günlük alıntıları ve geçmiş yollar ayrı yuvarlak
yüzeyler alır. İşlevler ve gerçek veri koşulları korunur. Eski §19 monokrom
raster brief'i bu görsel karar için geçersizdir.

Defter görselinde en fazla 10 pt, Yolum sahnesinde en fazla 24 pt kaydırma
parallax'ı bulunur. Görsel efektler yerleşim durumuna yazmaz. Profil girişleri
360 ms, en fazla 225 ms sıra gecikmesi; başlangıç opaklığı %65 olduğundan
kontroller görünmez bir bekleme dönemine girmez. Reduce Motion kaymayı kaldırır.
Kriz durumunda kapak, parallax ve giriş hareketleri yoktur. Mevcut anonim hesap
bağlama kartı kriz durumunda artık gösterilmez; Destek al öndedir.

Doğrulama: Simulator build başarılı; iPhone 16e normal profil/ayar grupları/kriz
ve iPhone 18 Pro AX5 başlık incelendi. Test target yok. Device Hub CUA bağlantısı
`timeoutReached` döndürdü; parmakla etkileşim, VoiceOver ve Instruments kare
süresi ölçümü tamamlanmış değildir. RM/RT dalları kodda incelendi; OS seçenekleri
ile bu revizyonun etkileşimli kontrolü yapılmadı.

## 21. Ben v2 — 19 Eylül 2026

Ürün sahibi "Ben" sekmesinin yeniden tasarımını onayladı. Bu bölüm planın **tasarım
kararlarını** ve **durum matrisini** kaydeder. Uygulama aşamaları (sunucu, veri
katmanı, ekranlar) ve görsel prompt'ları: `docs/profile-v2-plan.md` ve
`assets/illustrations/me-v2/prompts.md`.

### 21.1 Neden yeniden tasarım

- Üstteki "Ben" etiketli büyük krem kapak ve illüstrasyon ilk ekranın önemli bir
  bölümünü kaplıyor.
- Defter alıntıları profil sayfasının ortasına dökülüyor; defter kendi sayfasını
  hak ediyor.
- "Yürüdüğün yollar" ve "Sana göre ayarlananlar" sayfayı uzatıyor.
- Sürüm yazısı profilde duruyor; ayarların en altına ait.
- Ayarlar sistem `List`'i ve nötr renklerle çiziliyor; uygulamanın koyu orman ve
  adaçayı dilinden kopuk.

Hedef kompakt bir profil: kimlik kartı, illüstrasyonlu defter kartı, rozetler ve
bütünleşik ayarlar. **"Ne değişti" ve "Destek al" kalıyor.**

### 21.2 Onaylanan kararlar (2026-09-19)

| Konu | Karar |
|---|---|
| Üst başlık | "Ben" etiketi ve büyük kapak illüstrasyonu kalkıyor |
| Kimlik kartı | Fotoğraf, ad, yol adı, "N. adım · faz", mini iz ve haftalık ritim noktaları |
| Profil resmi | Supabase Storage, özel kova, sahibine RLS ile, imzalı URL |
| Defter | Ayrı sayfa. Mevcut cevaplar + kullanıcının kendi notları, sunucuda şifreli. Her not kriz sınıflandırıcısından geçiyor |
| Defter kartı | İllüstrasyonlu, bulanık önizleme. Basınca kapak 3D açılıyor, ardından zoom geçişi |
| Yürüdüğün yollar | Kalkıyor; yerine rozetler geliyor |
| Gamification | Serbest: kilometre taşı rozetleri, nazik seri, rozet kutlaması. **Yasak kalanlar:** toplam sayılar, lig/kıyas, sıfırlanan ilerleme, kayıp bildirimi, sahte aciliyet, can/enerji |
| Rozet animasyonu | Lottie ve özel damga animasyonu yok. Sade native beliriş + tek yumuşak haptik |
| Rozet seti | Yol, ölçüm, seri, defter |
| Ne değişti | Kalıyor; kompakt, daha aşağıda, guaj dilinde |
| Anonim hesap | Kompakt tek satır, kimlik kartının hemen altında |
| Destek al | Profilde kalıyor |
| Sana göre ayarlananlar | Ayarlara taşınıyor |
| Sürüm | Profilden kalkıyor, ayarlarda en altta ortada |
| Ayarlar görünümü | Koyu orman zemin + adaçayı kart grupları |
| Destek yerelleştirme | Numara cihaz bölgesinden, metin dili uygulama dilinden (TR/EN) |
| Arka plan | Koyu orman + üstte kısa bir guaj çayır şeridi, aşağı doğru koyuya karışıyor |

**Varsayımlar** (itiraz edilmediği sürece geçerli):

- Kullanıcının kendi notları düzenlenip silinebiliyor. Adım cevapları yine yalnızca
  siliniyor.
- Seri "bu hafta" demek: pazartesi–pazar arasında tamamlanan adım günleri. Seri
  kırılınca hiçbir mesaj gösterilmiyor. Haftada 0 gün varsa noktalar boş kalıyor,
  yanında metin yok.
- Kova C'de rozet yine veriliyor ama yol sonunda kutlama ekranı açılmıyor; rozet
  raf'ta sessizce beliriyor.
- Kriz modunda rozet, kutlama, illüstrasyon ve seri görünmüyor.

### 21.3 Sayfa yapısı (yukarıdan aşağı)

```
[guaj çayır şeridi — kaydırmayla solar]
┌ Kimlik kartı ─────────────────── (⚙)┐
│ (foto)  Taner                        │
│         Uykuya dönüş yolu            │
│         12. adım · Farkındalık       │
│         ━━━━━━━━━░░░░░  ● ● ● ○ ○ ○ ○ │  ← iz + bu haftanın 7 noktası
└──────────────────────────────────────┘
[ Hesabını bağla, yolun kaybolmasın  ›  ✕ ]   ← yalnızca anonimse
┌ Defter kartı (guaj defter + bulanık son not) ┐
│ "İç dünyana ait notları burada biriktir."    │
└──────────────────────────────────────────────┘
Rozetler                                 Tümü ›
( ◉ )( ◉ )( ◉ )( ○ )  ← kazanılanlar + sıradaki kilitli
Ne değişti  (kompakt, 3 satır, küçük guaj ikon)  ›
Destek al                                         ›
```

Kriz modunda yalnızca kimlik kartı (görselsiz) ve en üstte "Destek al" görünüyor;
hareket yok. Bugünkü `supportPlacement` mantığı korunuyor.

Bölüm bazlı tasarım kararları:

- **Kimlik kartı** (`ProfileIdentityCard`): koyu adaçayı kart. Solda 64 pt avatar;
  fotoğraf yoksa krem daire içinde adın baş harfi, ad da yoksa `leaf` simgesi.
  Dokununca "Fotoğraf seç / Kaldır" `confirmationDialog`'u. Sağda ad (`screenTitle`,
  `coverTitle` değil), yol adı, "N. adım · faz" ve altında mini iz; onun altında
  haftanın 7 noktası (tamamlanan gün dolu adaçayı, bugün halkalı). Sağ üstte ⚙
  (cam, 44 pt) Ayarlar'ı açıyor. Yol yoksa adım satırı ve iz çizilmiyor.
  VoiceOver tek öğe: "Taner, Uykuya dönüş yolu, 12. adım, Farkındalık fazı, bu
  hafta 3 gün".
- **Defter kartı** (`JournalCoverCard`): zemin `me-journal-cover` görseli; üstünde
  son kaydın ilk ~120 karakteri `.blur(6)` ve `.privacySensitive()` ile. Kayıt yoksa
  davet metni ve "İlk notunu yaz". `hidesJournal` açıksa bulanık önizleme de yok.
  Kapak `rotation3DEffect(.degrees(-100), axis: y, anchor: .leading, perspective:
  0.6)` ile ~420 ms'de açılıp alttan krem sayfa dokusunu gösteriyor, ardından
  `.navigationTransition(.zoom)` ile defter sayfası karttan büyüyor. Reduce
  Motion'da kapak dönmüyor, yalnızca geçiş oluyor.
- **Rozet rafı** (`BadgeShelf`): yatay sıra; kazanılanlar yeniden eskiye, en sonda
  sıradaki tek kilitli rozet soluk kontur hâlinde. "Tümü" → `BadgesView` ızgarası;
  kilitli rozetin altında nasıl kazanılacağı tek cümleyle yazıyor; sayı ya da
  ilerleme çubuğu yok. Hiç rozet yoksa ilk kilitli rozet ve "İlk adımı attığında
  burada" yazıyor.
- **Ne değişti** (`CompactChangeCard`): başlık cümlesi + üç katman tek satırda
  "kelime + ok", solda küçük `me-change` guaj ikonu. `BaselineTrack` çubukları
  karttan kalkıyor, yalnızca `ChangeDetailSheet`'te kalıyor. Klinik feragat altında
  duruyor; ortaya çıkma animasyonu ve haptik korunuyor.
- **Destek al**: mevcut `MeEntryRow` satırı.
- **Defter sayfası** (`JournalView` yeniden yazım): koyu orman + krem kâğıt yaprak
  (`me-journal-paper`); ay başlıklı gruplar; kullanıcının notu serif
  (`Theme.Voice.user`) ve köşede kalem işareti, adım cevabı soru üstte + cevap
  serif. Kendi notları kaydırarak silinir ve bağlam menüsünden düzenlenir;
  `NoteComposerSheet` kaydederken önce cihazdaki `CrisisClassifier`, sonra sunucu
  kontrolü yapar — sinyal varsa `CrisisView` açılır, not yazılmaz. `hidesJournal`
  ve uygulama kilidi davranışı değişmiyor.
- **Rozet kutlaması** (`BadgeEarnedSheet`, `.medium`): rozet görseli `scale 0.85 →
  1` ve solma (~500 ms), tek `Theme.softHaptic`, rozet adı ve tek cümle, "Bende
  kalsın". Konfeti ve ses yok; birden fazla rozet tek yaprakta yan yana. Kriz
  modunda ve Kova C yol sonunda açılmıyor.
- **Ayarlar** (`SettingsSheet` yeniden yazım): `List` yerine `ScrollView` +
  `SettingsGroup` / `SettingsRow` / `SettingsToggleRow` / `SettingsDestructiveRow`
  bileşenleri; zemin koyu orman, kartlar adaçayı; toggle tint adaçayı. Satırlar en
  az 52 pt, AX boyutlarında etiket ve değer alt alta. Bölüm sırası: Hesap (foto,
  ad, bağlama) → Sana göre ayarlananlar (hatırlatma, adım uzunluğu, ton, ses —
  salt okunur, "…dediğin için" açıklamasıyla) → Gizlilik (kilit, defteri gizle,
  analitik) → Veri (dışa aktar, defteri sil) → Hakkında (nasıl ölçüyoruz, Destek
  al) → Geri alınamaz (hesabı sil) → en altta ortada soluk "Patika 1.0 (42)".
  `ReminderSheet` ve profildeki hatırlatma kısayolu kalkıyor; hatırlatma yalnızca
  Ayarlar'da.
- **Rozet kataloğu** (14): Yol: `first-step`, `phase-relief`, `phase-awareness`,
  `phase-skill`, `phase-behavior`, `phase-closing`, `path-complete`. Ölçüm:
  `measure-day7`, `measure-day14` — **katılımdan** verilir, sonuçtan değil. Seri:
  `week-3`, `week-5`, `week-7` (bir takvim haftasında tamamlanan adım günü).
  Defter: `note-first`, `note-10`. Rozetler geri alınmaz; istemci hesaplanan
  kümeyi sunucudakiyle birleştirir (bir notu silmek "İlk not" rozetini götürmez).

### 21.4 Durum matrisi

| # | Durum | Kimlik kartı | Defter kartı | Rozetler | Haftalık ritim |
|---|---|---|---|---|---|
| B0 | Yol yok | Ad + avatar; adım satırı ve iz çizilmez | Davet metni + "İlk notunu yaz" | İlk kilitli rozet + "İlk adımı attığında burada" | Noktalar boş, yanında metin yok |
| B1 | Yol aktif, ölçüm öncesi | Ad, yol adı, "N. adım · faz", iz | Son kaydın bulanık önizlemesi (varsa) | Kazanılanlar + sıradaki kilitli | Tamamlanan günler dolu adaçayı, bugün halkalı |
| B2 | Yol aktif, 7/14. ölçüm yapıldı | aynı | aynı | Ölçüm rozeti (katılımdan) eklendi | aynı |
| B3 | Yol tamamlandı (Kova A/B) | Adım satırı ve iz kalır | aynı | Yol sonu rozetleri; kutlama yaprağı Sıcak | aynı |
| B4 | Yol tamamlandı (Kova C) | aynı | aynı | Rozet raf'ta sessizce; kutlama yaprağı yok (Nötr) | aynı |
| B5 | Defter boş | normal | Bulanık önizleme yok; davet + "İlk notunu yaz" | normal | normal |
| B6 | `hidesJournal` açık | normal | Bulanık önizleme de yok; davet kalır | normal | normal |
| B7 | Anonim hesap | normal | normal | normal | normal; kimlik kartının hemen altında "Hesabını bağla" tek satırı |
| B8 | Kriz sinyali aktif | Yalnızca kimlik kartı, görselsiz, hareketsiz; en üstte Destek al | Yok | Yok | Yok |

Seri kuralları (B1–B4 ortak): hafta pazartesi–pazar; kırılınca mesaj yok, 0 tamamlanan
gün varsa noktalar boş kalır ve yanında metin olmaz; bildirimlerde seriden hiç söz
edilmez.

### 21.5 Geçersiz kılınan ve taşınan bölümler

| Eski | Durum |
|---|---|
| §6.5 Yürüdüğün yollar | **Geçersiz** — yerine rozet rafı (§21.3); `RouteSeal` yol rozetinde yeniden kullanılabilir |
| §6.6 Sana göre ayarlananlar | **Geçersiz** — Ayarlar sayfasına taşındı (§21.3) |
| §6.2–6.3 Ne değişti | Kalıyor — kompakt `CompactChangeCard`, daha aşağıda, `BaselineTrack` yalnızca ayrıntı sayfasında |
| §6.4 Defter | Kart `JournalCoverCard` oluyor; liste ayrı `JournalView` sayfasına taşınıyor; kullanıcının kendi notları eklendi |
| §6.9 Sürüm alt bilgisi | Profilden kalkıyor; Ayarlar'ın en altında ortada |
| §7 S6 Anonim kart | Kompakt tek satır, kimlik kartının hemen altında; kapatma davranışı aynı |
| §6.7 Destek al | Profilde kalıyor; krizde en üstte |
| §1 başlık/yolculuk kimliği | "Ben" etiketli büyük kapak kalkıyor; kimlik kartı compakt karşılığı |

### 21.6 Görsel varlıkları

Defter kapağı (`me-journal-cover`), kâğıt dokusu (`me-journal-paper`), "Ne değişti"
ikonu (`me-change`), 14 rozet (`badge-*`) ve opsionel `me-backdrop`. Kilitli rozet
görsel istemez: aynı görsel kodda gri tona çevrilip %30 opaklıkla çizilir. Tam
prompt'lar: `assets/illustrations/me-v2/prompts.md`.

### 21.7 Uygulama durumu (2026-09-19)

Aşama 0–8 kodda bitti; ayrıntı, sapmalar ve sıradaki iş `docs/profile-v2-plan.md`
başındaki "Uygulama durumu" tablosunda. Sunucu tarafı (migrasyon + Edge Function'lar)
**henüz uzak projeye dağıtılmadı**. Simülatörde doğrulanan durumlar: B0 (boş), B1
(dolu), B8 (kriz), AX5'te kimlik kartı, defter kartı, rozet başlığı, anonim satır
ve ayarlar. Doğrulanmayanlar: gerçek fotoğraf seçimi, kapak açılış animasyonunun
zamanlaması (yalnızca kod incelemesi), VoiceOver turu.
