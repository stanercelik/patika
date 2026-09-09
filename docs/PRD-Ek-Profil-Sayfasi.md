# PRD Eki — "Ben" sekmesi (profil) tasarımı

Durum: **onaylandı, sıraya alındı** (ürün sahibi, 2026-09-09). Kod henüz
yazılmadı; `MeTab` hâlâ `ScreenPlaceholder`. Sıra: **G2 (bitti) → ölçüm
skorlama servisi → profil.**
Tarih: 2026-09-09. Kaynak: Mobbin üzerinde Ahead, Fabulous, Ladder, Yazio profil
ekranlarının incelenmesi (ürün sahibi isteği).

---

## 1. Neden bu dört uygulama

| Uygulama | Neden bakıldı | Bize mesafesi |
|---|---|---|
| **Ahead** | Aynı kategori: duygu düzenleme, ölçülen beceriler | En yakın akraba, **en uzak ton**. Maskot, pastel, XP. |
| **Fabulous** | "Yolculuk" metaforu, dikey yol haritası | Metafor birebir bizim iz dilimiz |
| **Ladder** | Profil ekranının görsel hiyerarşisi en net olanı | Fitness/sosyal; ton uyuşmuyor, **iskelet uyuşuyor** |
| **Yazio** | Dördü içinde en sakin, en "profesyonel" duran | Bize tavır olarak en yakını |

---

## 2. Ahead — ne alıyoruz, ne almıyoruz

Ahead'in profili bir **hesap ekranı değil, bir beceri ekranı**
([beceri ekranı](https://mobbin.com/screens/ec7ff4d8-ecff-4305-b6d2-3fbc5d082ef9)):
üstte kimlik (ad + o anki odak: "Alex — Confidence"), altında "Your emotion
management skills" başlığıyla üç boyut (Self-awareness / Self-control /
Resilience), her biri XP çubuğuyla. Aşağıda üç sayı: tamamlanan günlük aktivite,
günlük seri, harcanan süre
([istatistik satırı](https://mobbin.com/screens/26e848ed-2272-470d-8a78-8444b98e79eb)).

### Alınacak tek büyük fikir: profil = kendini tanıma kaydı

En güçlü ekranı "My Signs of Insecurity"
([Learnings sekmesi](https://mobbin.com/screens/f9a4a0b1-5f5c-459c-850d-7ff59c7163a8)):
kullanıcının **kendi fark ettiği** davranışların listesi — "Feeling
underperforming · Noticed 1 times", "Fake-laughing · Noticed 1 times" — ve
listeye ekleme yapabildiği bir "Add" bağlantısı.

Bu bizde birebir karşılığı olan bir fikir: profil sayfası puan tablosu değil,
**kullanıcının kendisi hakkında biriktirdiği şey** olmalı. Bizde başlangıç
malzemesi zaten var: B1'de yazdığı kendi cümlesi, B4'teki kaçınma cevabı,
D bölümündeki baseline. Ahead bunu kullanıcıya "senin gözlemin" diye geri
veriyor; sayı değil, cümle.

### Alınmayacaklar — ve neden

Ahead'in bağlanma (engagement) taktiklerinin çoğu bizim **değiştirilemez
kurallarımızın** tam olarak yasakladığı şeyler:

- **XP, seviye ("Visionary"), 2500 XP'ye kadar çubuk.** Gamification yasağı.
  Ayrıca ölçümümüz XP değil: skorlar mutlak yorumlanmıyor, yalnızca kullanıcının
  kendi geçmişiyle karşılaştırılıyor (PRD §8.2).
- **Seri (streak) ve seriye bağlı kilit.** "Achieve a 7-day streak to unlock"
  ([kilitli kart](https://mobbin.com/screens/355909b5-1a41-4f79-98d5-41fcfe982004))
  kaygı ürününde üretilmiş kaygıdır. Bizde kaçırılan gün hiçbir şeyi geri almaz.
- **Bulanıklaştırılmış kilitli içerik kartları.** "Kişilik örüntülerin var, aç"
  merak boşluğu tekniği; sattığımız şey merak değil, ölçülen değişim.
- **Arkadaş karşılaştırması** ("Compare how you see yourself with how your
  friends see you"). Kullanıcılar arası kıyaslama kategorik olarak yasak.
- **Maskot ve pastel palet.** Ahead samimi olmayı seçmiş; biz bir tık daha
  profesyonelizi seçtik. Tek mürekkep + kategori paleti kararı değişmiyor.

> Özet: Ahead'den **bilgi mimarisini** alıyoruz (profil = kendini tanıma),
> **motivasyon mekaniğini** almıyoruz (XP/seri/kilit).

---

## 3. Fabulous — yolculuk kartı ve dikey iz

Profil ekranı bir yolculuk özeti: üstte görsel, altında "Your current journey"
kartı (ad + alt başlık + %), sonra "All Journeys" toplam ilerleme çubuğu, sonra
düz liste hâlinde hesap ve yardım satırları
([profil](https://mobbin.com/screens/32f16772-6112-4e90-bb6b-53f37bf2fd78)).
Yol haritası ise dikey bir iz üzerinde düğümler
([Journey Roadmap](https://mobbin.com/screens/14760043-392c-4884-b002-c2fa9c5ae9e9)).

**Alınacak:** hiyerarşi. Önce *tek* bir "şu an neredesin" kartı, sonra ilerleme,
sonra sıradan liste. Profil sayfasının ilk ekranında iki fikirden fazlası yok.
Dikey iz metaforu zaten bizde (`TrailRow`, `PathProgressBar`, A1 animasyonu) —
Fabulous bunu doğruluyor, bize yeni bir şey öğretmiyor.

**Alınmayacak:**
- **"Not yet unlocked"** dili. Kilit, içeriğin saklandığını söyler; bizde
  sıradaki adım saklanmıyor, sırası gelmemiş. F2'de zaten tüm harita açık.
- **Yüzde başlık olarak.** "3% completion" bir tamamlanma yarışı kurar. Bizde
  ilerme sayı değil iz (karar, 2026-09-08) — profil de bu kuralın istisnası olamaz.
- **Yolculuk pazarı** (kart kart gezilen katalog,
  [katalog](https://mobbin.com/screens/901a55ce-0b99-48a1-8239-eb7e5e98e2ea)).
  Bu tam olarak C3'te "kütüphane değil, yol" diye reddettiğimiz şey.
- **Sosyal akış** (profilde paylaşımlar, beğeniler).

---

## 4. Ladder — iskelet buradan

Ladder'ın profili dördü içinde **görsel hiyerarşisi en net olanı**
([profil](https://mobbin.com/screens/b3e5ddf6-f89e-4bec-91b3-864a586f1eff)):

```
kapak görseli → avatar → ad + üyelik rozeti + katılma tarihi → bio
→ 4 halka: Workouts | Minutes | Calories | Cheers
→ ikonlu segment sekmeleri (liste · rozet · favori · günlük)
→ seçili sekmenin içeriği
```

Ayarlar **ayrı bir modal**, iri yuvarlatılmış satırlar, en altta sürüm numarası
ve Terms/Privacy
([ayarlar](https://mobbin.com/screens/93a44975-dc97-4d0a-ac8e-afe73826da93)).
Hesap ekranı üç bölüme ayrılmış: General / Membership Options / **"Dangerous
Area"**
([hesap](https://mobbin.com/screens/e217b46c-3be3-400e-90ca-538da71c3456)).

**Alınacak:**
- Tek ekranda **kimlik → birkaç sayı → sekmeli içerik** dizilimi.
- **Ayarlar profilin içine serpiştirilmez, ayrı yüzeye taşınır.** Profil "sen
  kimsin", ayarlar "uygulama nasıl davransın". İkisini karıştırmak profil
  sayfasını ayar listesine çeviriyor.
- **"Dangerous Area" dürüstlüğü.** Yıkıcı işlemi saklamak yerine ayrı başlık
  altında toplamak. Bizim tonumuzda başlık farklı olur ama fikir aynı.
- En altta sürüm + yasal bağlantılar.

**Alınmayacak:** kapak fotoğrafı, bio, avatar yükleme (sosyal katmanımız yok ve
olmayacak), rozet duvarı, "Cheers", "Share Proof", seri kalkanları.

---

## 5. Yazio — tona en yakın olanı

Yazio profili sakin ve bilgi odaklı
([profil](https://mobbin.com/screens/0fb61811-9e2c-42af-be47-5c2985b2ce56)):
ad + **uygulamanın senin hakkında bildiklerini özetleyen çipler** (30 years,
Lose weight, Standard, Menlo Park), tek bir ilerleme çubuğu ("You've lost
0.6 kg") ve yanında "Analysis" bağlantısı, sonra "My Goals" düz madde listesi +
"Edit". Ayarlar ikon+etiket listesi
([ayarlar](https://mobbin.com/screens/034a946d-2453-4c96-a4e9-acdb85f1be54)),
hesap ekranı etiket→değer satırları: User ID, E-mail, Password, **Subscription
until 10 May 2026**, Reset, Log Out
([hesap](https://mobbin.com/screens/e67b739a-e8ef-460b-8400-c7bdf54b9e4e)).

**Alınacak:**
- **Çipler = "sorduğumuz her şeyin karşılığı olmalı" kuralının profildeki
  karşılığı.** Kullanıcı onboarding'de sekiz soru cevapladı; profilde bunların
  ürünü nasıl değiştirdiğini görmeli.
- **Abonelik bir tarih olarak yazılır**, rozet olarak değil. "10 Mayıs 2026'ya
  kadar" tek satırda dürüst.
- **"Reset"in açıkça bulunması.** Veriyi silmek gizlenmiyor.
- Hatırlatmalar ekranının yapısı
  ([bildirimler](https://mobbin.com/screens/ceba01d2-f62f-4a12-85e1-c9cc77c80810)):
  her bildirim tipi ayrı anahtar, saatler görünür. Bizde tek bir günlük
  hatırlatma var ama saati burada görünmeli.

**Alınmayacak:** Buddies (sosyal), ayar listesinin uzunluğu.

---

## 6. Önerilen "Ben" ekranı

Sıra bilinçli. Üstte kullanıcının **kendisi**, ortada **ürünün ona göre
ayarlanmış hâli**, altta **hesap işleri**.

```
┌──────────────────────────────────────────┐
│  Taner                          [ayarlar]│   1 · Kimlik
│  Akşamı yavaşlatma yolu · 8. gün         │
├──────────────────────────────────────────┤
│  ▌ Şu anki patikan                       │   2 · Patika kartı
│  ──●──────────────────                   │      (iz, yüzde yok)
│  8 / 21 adım · sonraki ölçüm 14. günde   │
├──────────────────────────────────────────┤
│  Ne değişti                              │   3 · Ölçüm
│  Duygu     ↓ hafifledi                   │      (7. günden önce boş
│  Davranış  → aynı                        │       durum metni)
│  Öz-yeterlik ↑ arttı                     │
│  "Kendi başlangıcınla karşılaştırılıyor."│
├──────────────────────────────────────────┤
│  Fark ettiklerin                         │   4 · Kendi cümleleri
│  "Geceleri yatağa girince kafam          │
│   durmuyor."            — 9 Eylül        │
├──────────────────────────────────────────┤
│  Sana göre ayarlananlar                  │   5 · E1/E2/E3'ün karşılığı
│  Hatırlatma      22:30            >      │
│  Adım uzunluğu   10 dakika        >      │
│  Ton             Sakin ve kısa    >      │
├──────────────────────────────────────────┤
│  Destek al                        >      │   6 · Her zaman görünür
├──────────────────────────────────────────┤
│  Abonelik   14 Ekim 2026'ya kadar >      │   7
└──────────────────────────────────────────┘
   sürüm 1.0 · Gizlilik · Koşullar
   Bu bir klinik değerlendirme değildir.
```

### Bölüm bölüm gerekçe

**1 · Kimlik — fotoğraf yok, avatar yok.** Ladder ve Yazio'nun ikisinde de
avatar var; ikisinde de sosyal katman var. Bizde yok. Fotoğraf istemek
kurulmamış bir yakınlık iddiasıdır. Ad varsa ad, yoksa yalnızca patika adı —
"İsim vermek istemiyorum" akışın hiçbir yerini kapatmaz kuralı burada da geçerli.
Tek glif kategori ikonu (`ProblemCategory.icon`, SF Symbol).

**2 · Patika kartı — yüzde yok, iz var.** Fabulous "3% completion" yazıyor;
biz `PathProgressBar` kullanıyoruz. "8 / 21 adım" sayısı var çünkü bu bir
tamamlanma yüzdesi değil, konum. Sonraki ölçüm gününün yazılması F2'deki
sözün profilde tutulması.

**3 · Ne değişti — Ahead'in beceri çubuklarının bizdeki karşılığı.** Üç boyut
zaten var (duygu %30 / davranış %40 / öz-yeterlik %30, PRD §8.2). Farklar:
- **7. günden önce sayı yok, çubuk yok.** Boş durum: *"İlk karşılaştırma
  7. günde. O güne kadar ölçecek bir fark yok."* Veri yokken sayı yazmama
  kuralı burada da geçerli.
- **Mutlak skor gösterilmez.** Yalnızca kendi baseline'ına göre yön.
- **Renk tek başına anlam taşımaz**: ok + metin birlikte (erişilebilirlik kuralı).
- Kötüleşme de gösterilir. Yalnızca iyileşmeyi göstermek ölçümü reklama çevirir.

**4 · Fark ettiklerin — Ahead'in "My Signs"i, bizim malzememizle.** v1'de
salt okunur: B1 cümlesi ve varsa B4 kaçınma cevabı, tarihiyle. Sonraki
sürümde oturum sonrası not eklenebilir. Ahead'in "Noticed 3 times" sayacı
**alınmıyor** — sayaç, insanı kendi belirtisini biriktirmeye teşvik eder.

**5 · Sana göre ayarlananlar — Yazio'nun çipleri, satır hâlinde.** Üçü de
gerçekten davranış değiştiriyor (E bölümü kuralı) ve üçü de buradan
değiştirilebiliyor. **Cinsiyet ve yaş profilde hiç gösterilmiyor** (ürün sahibi kararı,
2026-09-09) — "sana göre ayarlananlar"da da değil, Ayarlar → Hesap altında da
değil. Bu iki cevap ürünün hiçbir davranışını değiştirmiyor; **yalnızca kohort
analizi için** toplandı ve kullanıcıya geri gösterilecek bir karşılıkları yok.
Profilde bir yere koymak, orada bir işlevleri varmış izlenimi verirdi.

**6 · Destek al — Ladder ve Yazio'da destek ayarların dibinde.** Bizde
abonelik satırının **üstünde** ve profilin görünür kısmında. Kural: her zaman
görünür, asla paraya çevrilmez, asla ödeme duvarının arkasında değil.

**7 · Abonelik — Yazio'nun tarih dürüstlüğü.** Rozet değil tarih.
`OutcomeBucket.allowsSelling == false` (Kova C) olan kullanıcıda bu satır
**satış içermez**, yalnızca durum gösterir.

**Ayarlar ayrı bir sheet** (Ladder kalıbı): bildirimler, analitik izni, dil,
veriyi indir, çıkış, ve ayrı başlık altında **hesabı kalıcı olarak sil**.
Ladder'ın "Dangerous Area" başlığı bizde *"Geri alınamaz"* olur — uyarı değil,
tarif.

### Ekranda olmayacaklar (karar)

Seri · rozet duvarı · XP/seviye · lig/sıralama · arkadaş · paylaş · kilitli
kart · konfeti · "seni özledik" · tamamlanma yüzdesi · mutlak skor.

---

## 7. Bunu yazabilmek için önce gereken

Ekranın yarısının verisi **bugün hiçbir yerde durmuyor**:

| Veri | Bugün nerede | Gereken |
|---|---|---|
| Ad, cinsiyet, yaş | `OnboardingDraft` (kalıcı değil) | `profiles` + yerel `UserProfile` |
| Hatırlatma / süre / ton | Yalnızca `generate-path` payload'ında | Ayrı sütun ya da yerel kayıt |
| Tamamlanan adım | `path_steps.completed_at` yazılmıyor | G2 yazıldığında yazılmalı |
| Ölçüm karşılaştırması | `measurements` yalnızca baseline | 7. gün ölçümü + skorlama servisi |
| Abonelik | Yok | StoreKit 2 |

Yani sıralama: **G2 (oturum sonu) → ölçüm servisi → profil.** Profil önce
yazılırsa ekranın yarısı boş durum olur ve boş durumların tasarımı gerçek
verinin tasarımından zor.

---

## Karar günlüğü

| # | Karar | Gerekçe |
|---|---|---|
| P1 | Profil bir "kendini tanıma kaydı", hesap ekranı değil | Ahead'in tek gerçekten iyi fikri; kategorimize uygun |
| P2 | Ahead'in tüm motivasyon mekaniği reddedildi | Gamification yasağı; kaygı ürününde kayıp kaçınması üretilmiş kaygı |
| P3 | Avatar/fotoğraf yok | Sosyal katman yok; fotoğraf kurulmamış bir yakınlık iddiası |
| P4 | Tamamlanma yüzdesi yok, iz var | 2026-09-08 iz kararının profildeki uzantısı |
| P5 | 7. günden önce ölçüm bölümünde sayı yok | Veri yokken sayı yazılmaz |
| P6 | "Destek al" abonelik satırının üstünde | Değiştirilemez kural: asla paranın arkasında değil |
| P7 | Cinsiyet/yaş profilde **hiç** gösterilmiyor (2026-09-09) | Ürünün hiçbir davranışını değiştirmiyorlar; yalnızca analiz için toplandılar. Profilde bir yere koymak orada işlevleri varmış izlenimi verirdi |
| P8 | Ayarlar ayrı sheet | Ladder kalıbı; profil "sen kimsin", ayarlar "uygulama nasıl davransın" |
