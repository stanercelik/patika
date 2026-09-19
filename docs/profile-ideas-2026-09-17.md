# "Ben" sekmesi — yaratıcı fikir panosu (beyin fırtınası)

Durum: **tartışma taslağı** (2026-09-17). Bu belge bir karar değildir; ürün
sahibiyle akıl yürütme oturumunun çıktısıdır. Temel: `docs/profile-design.md`
(onaylı, uygulanmış) ve `docs/PRD-Ek-Profil-Sayfasi.md` (onaylı iskelet).

**Uygulama durumu (2026-09-18):** F2, F6, F7 ve F13 yazıldı — ayrıntı §8'de.

İki tür fikir var: **§2** mevcut iskeletin üstüne eklenenler, **§3** mevcut
onaylı kararları değiştiren revizyonlar. Revizyon fikirleri hangi kararı
(PD/P numarasıyla) bozduğunu açıkça söyler; ürün sahibi onaylamadan hiçbiri
uygulanmaz. Değiştirilemez güvenlik/ölçüm/ticari kurallar (seri yasağı, mutlak
skor yasağı, Destek al konumu, kriz protokolü vb.) bu panoda da pazarlık
konusu değildir — §7'deki liste bunları hatırlatır.

---

## 1. Nereden başlıyoruz — mevcut iskelet (özet)

Onaylı sayfa zaten şunları taşıyor:

| Bölüm | Fikir |
|---|---|
| Başlık | Ad + path adı + "Faz · N. adım". Avatar yok, konum var. |
| Ne değişti | Sayısız, başlangıca göre konum; önce cümle, sonra iz. |
| Defter | Kullanıcının kendi cümleleri, serif, iki ses tipografisi. |
| Yürüdüğün yollar | **Mühür = yolun rota çizimi.** Klasik rozet zaten reddedildi. |
| Sana göre ayarlananlar | Her ayarın kaynağı görünür. |
| Destek al | Her zaman görünür, erişimin üstünde. |

Yani "rozet olsun mu" sorusunun cevabı zaten verildi: **var, ama bizim
dilimizde** — madalyon değil, kişinin kendi yolunun geometrisi. Aşağıdaki
fikirler bu iskeleti bir tasarım ödülü adayına taşıyacak katmanlar.

---

## 2. Fikir kümeleri

### 2.1 Defter derinleşmesi — "kendi sesinle büyümek"

**F1 · Zaman kapsülü.** Path sonunda kullanıcıya tek bir isteğe bağlı soru:
*"Bu yolu bitiren kendine bir cümle bırakmak ister misin?"* Cümle kilitlenir ve
**bir sonraki yolun aynı adımında** defterde belirir: *"Bir yol önceki sen ·
3 Ekim"*. Seri değil, hatırlatma değil, beklenti yaratmaz; kişinin kendi
geçmişiyle tek seferlik bir buluşma. Ahead'in kilitli kartlarının tam zıttı:
içerik davranışa değil, zamana bağlı ve içeriği yazan ürün değil, kullanıcı.

**F2 · İlk cümle ↔ son cümle yan yanalığı.** Defter zaten B1'i sabit tutuyor.
Path sonu raporunda (yol ayrıntısında) iki cümle **tek ekranda, araya tek
kelime girmeden** alt alta basılabilir: ilk gün yazdığın / son adımda yazdığın.
Arayüz yorum yapmaz (PD8 korunur). Kova C'de bile yalan söylemez çünkü konuşan
ürün değil, kullanıcının kendisi. Bu, ürün vaadinin en güçlü kanıt yüzeyi
olabilir.

**F3 · Defterde arama (Faz 2+).** Arşiv büyüyünce kronolojik liste yetmez.
Arama yalnızca cihazda, analitiksiz. Arama kutusunun placeholder'ı bile ton
kuralından geçer: *"Cümlelerinde ara"* — öneri, etiket, "popüler aramalar" yok.

**F4 · Yıl sonu defteri (yıllık derleme).** Spotify Wrapped'ın dürüst karşıtı:
paylaşım kartı yok, sayı yarışı yok, başkası yok. Aralık ayında defterin
başında tek bir bölüm: o yıl yazdığın cümlelerden **kronolojik bir seçki** ve
yürüdüğün yolların mühürleri. Başlık: *"Bu yıl kendine söylediklerin."*
Kova ve skor hiç geçmez. Kullanıcı isterse PDF olarak **Bende kalsın** ile
dışa aktarır (mevcut artifact mekanizmasının doğal uzantısı).

### 2.2 Mühür koleksiyonu — "biriken harita"

**F5 · Harita arşivi görünümü.** PRD §10 zaten söylüyor: "Biriken rozetler
zamanla kişinin kendi haritasını oluşturur." 4+ mühürden sonra "Tümünü
listele"nin yanına ikinci bir görünüm: bütün mühürlerin **tek bir büyük,
sessiz haritada** uç uca dizildiği bir ekran. Her yol kendi renginde değil
(tek mürekkep kuralı), kendi dokusunda; yollar kronolojik akar. Bu ekran
kaydırılabilir bir "ömür patikası" olur. Sayı yok, toplam yok, "X yol
tamamlandı" yazmaz — haritanın kendisi konuşur.

**F6 · Mühür çizimini izlemek.** Yeni mühür ilk kez göründüğünde rota `trim`
ile çiziliyor (onaylı). İyileştirme: çizim sırasında **tek yumuşak haptik
nabzı** rotanın eşiklerinde (faz geçişlerinde) hissedilir. Whimsy bütçesi
bozulmaz çünkü bu zaten o tek "fark edilir an"ın içinde.

**F7 · Yarım kalan yolun mührü solmaz.** Yarım yollar listede zaten "8 adım
yürüdün" diye yazıyor (PD12). Görsel olarak da aynı dürüstlük: yarım mühür
%25 opaklıkta değil, **tam opaklıkta ama açık uçlu** durur. Solukluk "eksik"
ima eder; açık uç "devam edebilir" der. (Küçük görsel revizyon, mevcut
kararla uyumlu.)

### 2.3 Sessiz ritüeller — gamification olmadan bağ kurmak

**F8 · "O gün bugün" (yılda birkaç kez).** Kullanıcının B1 cümlesini yazışının
yıldönümünde, defterin başında tek satır: *"Bu cümleyi bir yıl önce bugün
yazdın."* Açınca cümle serif hâliyle durur, yanında o günden bugüne yürünen
yolların mühürleri. **Bildirim yok** — kullanıcı uygulamayı açtığında görür.
Geri sayım yok, "kaçırdın" yok; gün geçerse satır sessizce kalkar. Streak'in
bütün psikolojik kaldıracını (dönüp bakma isteği) sıfır baskıyla verir.

**F9 · Dönüm noktası anları.** Ürün ilk kez **ölçülebilir bir değişim**
gördüğünde (ör. davranış katmanı ilk kez eşiği geçti) değişim kartındaki cümle
o akşam tek kelimeyle değil, iki cümleyle yazılır ve haptik bir kez çalışar.
Bu zaten §10'daki "tek fark edilir an" bütçesinin içinde; yenilik, anın
**kişiye özgü tetiklenmesi** (takvimsel değil, verisel).

**F10 · Gece paleti vardiyasının profilde hissedilmesi.** Gece modu paleti
zaten var. Profil gece açıldığında defter bölümünün zemini bir kademe daha
koyulaşır — "gece defteri" hissi. İşlevsel hiçbir fark yok; yalnızca o saatte
açan kişiye ürünün "orada" olduğunu hissettirir. (Görsel sistem kurallarına
tam uyumlu: palet sırası kategori → ruh hâli → gece.)

### 2.4 Şeffaflık ve güven — ödüllük kategori: Social Impact

**F11 · "Nasıl ölçüyoruz" etkileşimli sayfası.** Şu an bir metin sayfası.
Fikir: üç katmanı (duygu %30 / davranış %40 / öz-yeterlik %30) **kullanıcının
kendi son ölçümünden** anonimleştirilmiş tek bir maddeyle gösteren küçük bir
interaktif şema. "Senin cevabın burada hangi katmana gitti" canlı gösterilir.
Güvenin kaynağı gizem değil şeffaflık (§8.1 kararı) — bu onun görsel hâli.

**F12 · Veri hikâyesi satırı.** Ayarlar → Verim bölümüne tek satır:
*"Şu an bu cihazda 14 cümle, 3 ölçüm ve 1 kayıt duruyor. Sunucuda şifreli
kopyaları var."* Sayı burada serbest çünkü ilerleme değil, envanter. KVKK/GDPR
şeffaflığının insan dilinde hâli. (§15.3'teki "ana sayfada sayı yok" kuralı
bu yüzeyi kapsamıyor; yine de ürün sahibi onayı ister.)

**F13 · Omuz üstü gizliliğin görünür işareti.** "Cümlelerimi gizle" açıkken
defter bölüm başlığının yanında küçük bir `eye.slash` simgesi durur. Kullanıcı
gizliliğin **aktif** olduğunu sayfayı her açışında görür; ayar bir köşede
unutulmaz. (İ7'nin uzantısı.)

### 2.5 Kişiselleştirme — davranışı gerçekten değiştirenler

**F14 · "Sana göre ayarlananlar" bölümüne tek ek satır: ses hızı.** E bölümü
tercihleri zaten davranışı değiştiriyor. TTS motoru (JIT) devredeyken anlatım
hızı (sakin / standart) da gerçek bir tercih olabilir. Engel: sunucuda path
tercihi güncelleme uç noktası hâlâ yok (PD25 tablosu) — bu satır o uç noktayla
birlikte gelir.

**F15 · Hitap biçimi.** Ayarlar → Hesap'taki "Sana nasıl hitap edelim" zaten
var. İnce fikir: hitap **yalnızca** profil başlığında ve oturum sonu
ekranında kullanılır; bildirimlerde ve destek ekranında asla (bildirim gizlilik
kuralı zaten yasaklıyor). Bu sınırın kendisi tasarım kararı olarak belgelenir.

### 2.6 Ufuk fikirler (Faz 2 ve ötesi — şimdi karar verilmez)

**F16 · Sesli defter.** Yazmak istemeyen için oturum sonunda 30 saniyelik ses
kaydı; defterde transkript serif, kayıt dokununca oynatılır. Sorular:
transkript cihazda mı? Ham ses şifreli mi? Gizlilik modeli yazılmadan kod
yazılmaz.

**F17 · Baskıya hazır defter.** F4'ün fiziksel karşılığı: yıl sonu defterinin
tipografisi özenilmiş PDF'si. Kullanıcının kendi cümleleri, New York serif,
mühür çizimleriyle. Hiçbir sunucuya gitmeden cihazda üretilir. "Bende kalsın"
felsefesinin en somut hâli.

**F18 · Apple Health / uyku verisi.** "Akşamı yavaşlatma" yolundaki kullanıcıya
uyku süresi bağlamı. **Riskli:** klinik ima sınırına yakın ve "ölçüm üç
katmanlıdır" kuralına dördüncü veri sokar. Şimdilik yalnızca soru olarak
park edildi (§5).

---

## 3. Revizyon fikirleri — mevcut onaylı tasarımı değiştirenler

Bunlar §2'deki "ekleme" fikirlerden farklı: uygulanırsa `profile-design.md`'deki
onaylı bir karar değişir. Her satırda bozulan karar ve bedeli yazıyor.

### 3.1 Kimlik ve başlık

**R1 · Kişisel sembol başlıkta.** Avatar yasağı (P3) korunarak, adın yanına
kullanıcının **aktif yolunun minik rota çizimi** kişisel işaret olarak gelir.
"Fotoğraf kurulmamış yakınlık iddiasıdır" gerekçesi hâlâ geçerli; ama rota
çizimi bir yüz değil, kişinin kendi ürettiği şey. Bedel: başlık şu an kasıtlı
olarak çıplak; her görsel eklenmesi metnin ağırlığını azaltır.
*Değiştirir: §6.1 "kategori ikonu yok, görsel yok" sadeliği.*

**R2 · Başlıkta yol adı yerine kendi cümlen.** İlk satır ad, ikinci satır path
adı yerine kullanıcının B1 cümlesinden kısa bir alıntı (serif). Kimlik = neden
burada olduğun. Güçlü, cesur; ama cümle her açılışta tepede durmak için fazla
ağır olabilir ve omuz üstü gizlilik riskini başlığa taşır.
*Değiştirir: §6.1 başlık yapısı, İ7'nin yorumu.*

### 3.2 Bölüm sırası ve yapı

**R3 · Defter en üste.** Şu an "Ne değişti" sayfanın kalbi (§6.2). Ters yön:
kullanıcının kendi sesi ilk görülen şey olur, ölçüm ikinci. Gerekçe: insanlar
kendileri hakkında biriktirdikleri şeye geri dönüyor (§3.4 Ahead bulgusu) —
o şey sayı değil cümle. Bedel: ürün vaadinin kanıtı (ölçülen değişim) ikinci
sıraya iner; "ürün mü satıyoruz, günlük mü" sorusu doğar.
*Değiştirir: PD1'in sıralama mantığı, İ4 sabit sıra kuralının içeriği.*

**R4 · Mühürler sayfanın görsel kahramanı.** "Yürüdüğün yollar" şu an 4.
bölümde liste/ızgara. Revizyon: başlığın hemen altında yatay kaydırmalı mühür
şeridi — koleksiyon büyüdükçe sayfanın en kişisel, en görsel bandı olur.
Bedel: ilk yolundaki kullanıcıda tek yarım mühür tepede zayıf durur; boşluk
hissi. *Değiştirir: bölüm sırası (İ4), §6.5 yerleşimi.*

**R5 · İki görünümlü sayfa: Defter / Harika.** Ladder'ın sekmeli iskeletinin
bizim dilimizde hâli: üstte segment kontrolü yok, bunun yerine kaydırdıkça
kapanan bir "kapak" (§20 krem kâğıt kapak zaten var) ve altında tek liste.
Kapak tamamen kapanınca sayfa saf defter olur. Bu aslında sekme değil,
**kaydırma davranışıyla açılan ikinci hâl**. Bedel: §5'teki "neden tek sayfa"
gerekçesi (bölümler birbirini anlatıyor) zayıflar.
*Değiştirir: §5 tek sayfa kararı.*

### 3.3 Değişim kartı

**R6 · Değişim kartı kaydırmalı hikâye.** Tek kart yerine yatay sayfalanan üç
kart: cümle → üç katman izi → "en çok / en az değişen". Ayrıntı sheet'i ana
sayfaya iner. Bedel: sayfa göstergesi (noktalar) "ilerleme" çağrışımı yapar;
üç ekran boyu kuralıyla gerilim. Ve "önce cümle" (PD4) ilk sayfada kalır ama
iz ikinci sayfaya düşer — kaygılı kullanıcı kaydırmazsa izi hiç görmez.
*Değiştirir: §6.2 tek kart anatomisi.*

**R7 · Kötüleşmede kartın dokusu değişir.** Şu an kötüleşme yalnızca kelimeyle
söylenir (İ5). Revizyon: üç katman da kötü yöndeyse kart çerçevesi kesik
çizgiye döner — durum, renk olmadan dokuyla da hissedilir. Bedel: İ5
"yüceltilmez de" diyor; doku farkı bir yargı katmanı ekler mi, tartışılır.
*Değiştirir: İ5'in yorumu, §9.5 doku kuralları.*

### 3.4 Ayarlar ve davranış

**R8 · Dişli ikonu geri gelir.** PD17'nin gerekçesi SOS'un tekilliği. Karşı
görüş: SOS artık renk/biçim olarak yeterince ayrışıyorsa dişli ona zarar
vermez ve ayarlara erişim HIG alışkanlığına döner. Bedel: sağ üst köşe araç
çubuğuna döner; §5'teki gerekçe hâlâ güçlü. **Önerim: hayır** — ama ürün
sahibi görmek isterse prototip karşılaştırması yapılır.
*Değiştirir: PD17, O6.*

**R9 · Uzunluk/ton/ses düzenlenebilir olur.** PD25 bunları salt okunur yaptı
çünkü sunucu uç noktası yok. Revizyon fikri değil, **engelin kaldırılması**:
`update-path-preferences` uç noktası yazılırsa bu satırlar sheet ile
düzenlenebilir olur ve "Sana göre ayarlananlar" gerçekten ayarlanır hâle gelir.
Kişiselleştirme tiyatrosu eleştirisi (PD25) ancak uç nokta varsa geçerliliğini
yitirir. *Değiştirir: PD25 — ama ancak backend ile birlikte.*

### 3.5 Radikal alternatif: "Ben" tek kartlık bir kapak

**R10 · Sayfa = kapak + tek kaydırma.** En cesur yön: profil, açılışta yalnızca
bir kapak — ad, aktif mühür, tek cümle (son defter kaydı ya da değişim cümlesi,
hangisi yeniyse). Geri kalan her şey kapağın altında, kaydırınca açılan tek
listedir. "Yolum" nasıl haritaysa "Ben" de bir kitap kapağı olur: kapatıp
cebe koyduğun şey. Ödül jürisinin hatırlayacağı ekran bu olur. Bedel: bölüm
görünürlüğü düşer; Destek al ve erişim satırları ilk ekrandan iner (Destek al
kuralı yalnızca "her zaman görünür" diyor, ilk ekran demiyor — ama yorum
değişir). *Değiştirir: §5 bilgi mimarisi, §6.0 tüm sayfa düzeni.*

---

## 4. Öncelik önerisi

| Sıra | Fikir | Neden önce |
|---|---|---|
| 1 | F2 (ilk ↔ son cümle) | Mevcut veriyle çalışır, sunucu gerektirmez, vaadin kanıtı |
| 2 | F6 (mühür haptiği) | Onaylı animasyonun içinde küçük iyileştirme |
| 3 | F1 (zaman kapsülü) | İkinci yol akışı yazılırken doğal girer |
| 4 | F5 (harita arşivi) | 4+ mühür gerektirir; erken kullanıcıda görünmez |
| 5 | F4 (yıl sonu defteri) | Takvime bağlı; Aralık'a yetişirse anlamlı |
| 6 | F11 (interaktif ölçüm sayfası) | Bağımsız yüzey, sayfayı riske atmaz |

F16–F18 bu çeyrekte karar istemez.

**Revizyonlar (§3) için öneri:** R9 (tercih uç noktası) gerçek bir eksiklik;
R3 (defter en üste) ve R10 (kapak konsepti) prototip yapmaya değer iki yön.
R8'i önermiyorum. R1–R2 ve R6–R7 ancak R10 seçilirse anlamlı — mevcut sayfa
düzeninde maliyeti faydasından büyük.

---

## 5. ADA merceğinden — hangi fikir hangi kategoriyi güçlendiriyor

- **Innovation:** F5 (üretken ama deterministik kişisel harita), F11 (ölçüm
  şeffaflığının interaktif anlatımı).
- **Social Impact:** F1, F8 (bağlılık mekaniği yerine zamana bağlı buluşma),
  F12 (veri şeffaflığı insan dilinde).
- **Inclusivity:** F13 (gizlilik durumunun görünürlüğü), F16 (yazamayan için
  sesli defter).
- **Visuals & Graphics:** F5, F7, F10, R10 (kapak konsepti).
- **Delight & Fun:** F6, F9 — whimsy bütçesi içinde kalarak.

---

## 6. Ürün sahibine sorular

1. **F1 zaman kapsülü** defterin "yalnızca oturum akışında yazılır" kuralını
   (PD9) esnetiyor — path sonu tek seferlik istisna kabul mü?
2. **F4 yıl sonu derlemesi** "paylaşılabilir sonuç kartı yok" (PD21) ile
   çelişmez mi? (Öneri: PDF paylaşımı `ShareLink` ile kullanıcı isteğine bağlı,
   uygulama içinde paylaşım çağrısı yok.)
3. **F12 veri envanteri** sayı içeriyor; "ana sayfada sayı yok" kuralının
   kapsamı ayarlar sheet'ini de içeriyor mu?
4. **F18 sağlık verisi** Faz 2'de konuşulacak mı, yoksa kategorik olarak
   kapsam dışı mı?
5. **R3 mü, R10 mu, yoksa mevcut sıra mı?** Defterin ve kapağın sayfadaki
   yeri, bu panodaki en büyük stratejik karar. İki yön de prototiplenebilir.

---

## 7. Kesinlikle olmayacaklar (hatırlatma)

Bu panoda hiçbir fikir şunları içermez ve içermeyecek: seri/sayaç, XP/seviye,
lig/sıralama, kullanıcılar arası kıyas, kilitli içerik, bulanık kart, tamamlanma
yüzdesi, mutlak skor, konfeti, emoji, "seni özledik", geri sayım, sahte
aciliyet, davet kartı, paylaşılabilir sonuç kartı, profil fotoğrafı, bio,
sosyal akış. Rozet duvarı yerine mühür kararı (PD11) değişmez.

---

## 8. Uygulama kaydı (2026-09-18)

Ürün sahibi "olabilecekleri yap" dedi; backend ya da yeni veri modeli
gerektirmeyen dört fikir uygulandı:

| Fikir | Değişiklik | Dosya |
|---|---|---|
| **F2** İlk ↔ son cümle | Tamamlanan yolun ayrıntısında ilk ve son defter kaydı araya tek kelime girmeden alt alta; ortadaki kayıtlar "Bu yolda yazdıkların" başlığıyla altta | `Features/Me/PathDetailView.swift` |
| **F6** Mühür haptiği | Çizim animasyonu bittiğinde tek yumuşak nabız (0.4); Reduce Motion'da yok | `DesignSystem/Components/RouteSeal.swift` |
| **F7** Yarım mühür | Yarım kalan yolda yürünmemiş kısmın soluk önizlemesi kalktı — "kaçırdığın şey" diye okunuyordu. Önizleme yalnızca aktif yolda kalıyor; yarım mühür yalnızca yürüneni çizer, çerçeve açık uçlu | `DesignSystem/Components/RouteSeal.swift` |
| **F13** Gizlilik göstergesi | "Cümlelerimi gizle" açıkken Defter başlığının yanında küçük `eye.slash` | `Features/Me/MeView.swift` |

**Yazılmayanlar ve nedeni:** F1 (PD9 istisnası + sunucu kaydı ister), F3/F4/F5
(yeni yüzey, ayrı karar), F9 (ölçüm tetikleyicisi ister), F10 (gece paleti
bağlantısı ister), F11 (ayrı interaktif sayfa), F12 (ürün sahibi sorusu §5.3),
F14 (sunucu uç noktası yok, PD25), F16–F18 (ufuk). Revizyonlar (R1–R10) ürün
sahibi seçimi bekliyor.

**Doğrulama:** `swiftc -typecheck` (DEBUG, MainActor varsayılan izolasyon,
iOS 26 simulator SDK) tüm kaynakta 0 hata. Tam `xcodebuild` bu oturumda
tamamlanamadı: makinedeki `actool` **boş bir katalogda bile** kilitleniyor
(0% CPU, sistem genelinde takılma — kodla ilgisiz; Xcode servislerinin
yeniden başlatılması ya da makine yeniden başlatma gerekiyor). Simülatörde
görsel doğrulama (normal/AX5/Reduce Motion) henüz yapılmadı.
