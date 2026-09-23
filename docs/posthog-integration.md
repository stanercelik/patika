# PostHog olcum sozlesmesi

## Durum ve yayin kapisi

**Hedef hesap:** `tnrclk2001hd@gmail.com`. Bu hesapta AB bolgesinde
[Patika Staging](https://eu.posthog.com/project/282221/) projesi (282221)
kuruldu. IP kaydini atma ayari acik, autocapture ve session replay kapali.
Codex PostHog baglantisi 23 Eylul 2026 kontrolunde hedef e-posta adresini
dogruladi, ancak ABD bolgesindeki `Default project` (624242) projesini
gosteriyor. AB bolgesindeki 282221 projesi MCP'de listelenmiyor. AB projesi
ayni hesapla acik olan PostHog arayuzunde dogrulandi ve panolar orada kuruldu.
MCP uzerinden yazma islemleri bu projeye yonlendirilmemelidir. Eski hesaptaki
88885 ve yeni hesaptaki 624242 projeleri bu entegrasyonun hedefi degildir.

Bu olcum, urun sahibinin istedigi gibi varsayilan aciktir; kullaniciya izin
ekrani veya Ayarlar anahtari gostermez. **Uretim gonderimi varsayilan olarak
kapalidir.** AB pazarlarinda hukuki dayanak, PostHog veri isleme sozlesmesi,
saklama suresi, gizlilik bildirimi ve App Store veri beyanlari onaylanmadan
`POSTHOG_RELEASE_APPROVED=YES` verilmez. TestFlight ve yerel Debug derlemeleri
uretim projesine veri gondermez.

Patika Production henuz kurulamadı: hedef hesabin mevcut ucretsiz plani tek
projeye izin veriyor ve ikinci proje icin odeme bilgisi istiyor. Hedef Staging
projesine 18 sentetik, hassas veri icermeyen olay gonderildi; PostHog arayuzunde
olaylar ve pano sorgulari dogrulandi. Gercek kullanici verisiyle dogrulama
henüz yapilmadi. Production projesi kurulunca bolgesi ve tokeni ayrica
dogrulanmalidir.
Patika Production acildiginda onun IP ayari da kapatilmali. Session replay, autocapture,
feature flags ve kisi profilleri kullanilmaz. Proje tokenlari baska sistemlerin
kimlikleriyle eslestirilmez.

Release derlemesinde `Config/Info.plist` su build settings degerlerini alir.
Hedef Staging anahtari `Config/PostHogStaging.xcconfig` icindedir; bu anahtar
yalnizca olay gondermeye yarayan, mobil uygulamada da gorunecek public proje
anahtaridir. Staging derlemesi icin `xcodebuild -configuration Release -xcconfig
Config/PostHogStaging.xcconfig ... build` kullanilir. Bu dosya varsayilan
Release veya Debug derlemesine kendiliginden uygulanmaz:

| Ayar | Staging | Production |
| --- | --- | --- |
| `POSTHOG_ENVIRONMENT` | `staging` | `production` |
| `POSTHOG_PROJECT_TOKEN` | Patika Staging proje tokeni | Patika Production proje tokeni |
| `POSTHOG_RELEASE_APPROVED` | gerekmez | hukuki kapidan sonra `YES` |

Eksik konfigurasyonda uygulama olay gondermez. Tokenin gercek proje/bolgesi
derleme sirasinda otomatik dogrulanamaz; CI'da Staging ve Production tokenlari
ayri tutulmali ve yayin kontrolunde eslesmeleri onaylanmali. iOS
Debug her zaman NoOp kullanir. Proje tokeni yalnizca build sisteminden gelir;
PolyNap anahtari kullanilmaz. Staging dogrulamasi icin Debug yerine
Release konfigürasyonlu test derlemesi kullanilir.

## Veri siniri

PostHog kimligi uygulama acilisinda rastgele olusan ve diske yazilmayan bir
oturum UUID'sidir. Supabase, hesap veya path kimligiyle birlestirilmez. Olaylar
olustuklari anin zaman damgasi ve `$process_person_profile=false` ile
gonderilir. Ag hatasinda olay dusurulur;
disk kuyrugu ve tekrar deneme yoktur. Bu nedenle sayilar **benzersiz kisi**
degil, bu uygulama acilisindaki oturum/surec sayilaridir. Bir kullanici farkli
gunlerde veya uygulamayi yeniden actiginda birden fazla oturum sayilir.

Serbest metin, isim, kategori, ruh hali, olcum cevabi/skoru, path adi, kriz
sonucu, ses, URL, hata aciklamasi ve saglayici istek kimligi yasaktir. Yeni olay
yalnizca `AnalyticsEvent` enumuna sabit, gozden gecirilmis alanlarla eklenir.
PostHog SDK'si eklenmez; mevcut dar HTTP istemcisi kullanilir.

## Olaylar

| Olay | Alanlar | Ne zaman |
| --- | --- | --- |
| `onboarding_step_viewed` | `step` | A1 dahil, adim basina oturumda ilk gorunme |
| `onboarding_step_completed` | `step` | Ileri gecis, adim basina bir kez |
| `problem_text_submitted` | `written=yes/no` | B1 devam veya gec; metin ve uzunluk yok |
| `path_generation_started` | yok | Ilk F1 uretim cagrisi |
| `path_generation_finished` | `result=succeeded/failed` | Teknik sonuc; kriz sonucu gonderilmez |
| `session_started/completed` | `source=first/personal/prepared` | Gercek oturum baslangici; tamamlanma yalnizca tam oturumda |
| `account_choice` | `choice=apple/google/later` | H1 ilk secim |
| `app_screen_viewed` | `screen=path/discover/me` | Kok sekme acilisi veya degisimi |
| `prepared_path_selected` | yok | Hazir patikaya katilim |
| `reminder_preference_changed` | `enabled=yes/no` | H2 ve sonradan Ayarlar kaydi |

Kimlik dogrulama ve hesap baglama teknik sonuc olaylari devam eder; hassas
icerik veya hesap kimligi tasimaz. Gun 7 paywall ve RevenueCat akisi kodda
olustugunda odeme olaylari ayrica tasarlanir; su anda sahte olay eklenmez.

## PostHog panolari

Hedef Staging projesinde uc pano ve dokuz grafik kuruldu:
[Onboarding gecisleri](https://eu.posthog.com/project/282221/dashboard/971298),
[Ilk deger](https://eu.posthog.com/project/282221/dashboard/971303),
[Ekran kullanimi](https://eu.posthog.com/project/282221/dashboard/971308).
Grafikler 30 gunluk pencereyi ve gecici oturum kimligini kullanir; Ilk deger
hunisinin donusum penceresi bir gundur. PostHog funnel sonucunda
gorunen `person count` etiketi bu projede
**kisi** degil, uygulama acilisinda degisen `distinct_id` sayisidir.
Proje saat dilimi raporlarda acikca gosterilir; ekran hedefleri eski PRD
sirasindan degil mevcut A1 → kimlik → A2 → B/C → D → E1 → H2 → F1/F2 →
commitment → G1/G2 → fiyat → H1 akisindan kurulur.

1. **Onboarding gecisleri (3 grafik):** `onboarding_step_viewed` ve
   `onboarding_step_completed` icin `step` kirilimli sayilar; B1 icin
   `problem_text_submitted` olayinin `written=yes/no` kirilimli sayilari.
   B1 grafigi oran degil sayi gosterir. D0 → D8 adimlari ayni `step`
   kiriliminda izlenir. Adim sayilari tekrar gorunmeyle sismez.
2. **Ilk deger (1 grafik):** F1 baslama → basarili bitis → F2 gorulme → G1
   `session_started` → G1 `session_completed`. Tekil `distinct_id`
   oturumlari uzerinden funnel. Kriz sonucu raporlanmaz.
3. **Ekran kullanimi (5 grafik):** `app_screen_viewed` icin `screen` kirilimi;
   `session_started` ve `session_completed` icin ayri `source` kirilimlari;
   hazir patika secimi sayisi ve `reminder_preference_changed` icin
   `enabled=yes/no` kirilimli sayilar.

Panolardaki payda **oturum**dur. Bir adimin gorulmesi ile sonraki adimin
gorulmesi arasindaki fark ag kaybi, kapanma ve baska cikislari da icerir; kesin
"terk eden kisi" olarak adlandirilmaz. Haftalik gorusmede once veri kalitesi
(bos, beklenmeyen property, Debug olayi, bolge) incelenir, sonra funnel karari
verilir.

## Dogrulama

- `swiftc` ile AnalyticsContract testi: istek sekli, AB host, profil
  olusturmama, allowlist, adim tekrarini onleme ve Debug/uretim kapisi.
- Simulator build; Staging Release derlemesinde ornek akistan tekil olay
  sirasi. Test olayi Production'a dusmemeli.
- PostHog panolarinda sayilarin ornek akisla eslesmesi; IP kaydi ve kisi
  profili yoklugu; kriz ve serbest metin senaryolarinda yasak verinin yoklugu.

Onceki hesaptaki 88885 projesine gonderilmis sentetik veriler ve panolar
hedef hesap icin dogrulama sayilmaz. 282221 projesindeki 18 sentetik olay,
PostHog arayuzunde ve huni sorgusunda dogrulandi. Bu olaylar
`synthetic_verification=true` ozelligiyle isaretlidir ve gercek kullanim
raporlanirken dislanmalidir. Staging Release uygulamasindan canli olay
gonderimi henüz dogrulanmadi.

Referanslar: [PostHog Capture API](https://posthog.com/docs/api/capture),
[anonim olaylar](https://posthog.com/docs/data/anonymous-vs-identified-events),
[IP kaydi kontrolu](https://posthog.com/docs/privacy/data-collection#ip-data-capture).
