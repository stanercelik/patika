# PostHog olcum sozlesmesi

## Durum (25 Eylul 2026)

**Hedef proje: ABD bulutu, [Patika](https://us.posthog.com/project/624242) (624242)**,
hesap `tnrclk2001hd@gmail.com`. Urun sahibi AB projesinden (282221) ABD'ye gecisi
secti: PostHog MCP'si yalniz ABD bolgesini gorebiliyor ve panolar oradan yonetilecek.
Eski AB projesi 282221, 88885 ve PolyNap projeleri bu entegrasyonun hedefi degildir.
Gizlilik bildirimi guncellendi (PostHog, Amerika Birlesik Devletleri).

Proje ayarlari (MCP ile, 25 Eylul): IP adresi atilir (`anonymize_ips`), autocapture,
web vitals, konsol, performans, isi haritasi, dead click ve session replay kapali.

**Token uygulamaya nasil ulasir.** Karar `AnalyticsDeployment.resolveToken` icinde:

| Durum | Sonuc |
| --- | --- |
| Debug | Gonderim yok. Dogrulama icin `-patika-analytics-staging` baslatma argumani. |
| Release, `POSTHOG_*` derleme ayarlari dolu | Ayarlar kazanir. `production` yalniz `POSTHOG_RELEASE_APPROVED=YES` ile. |
| Release, derleme ayari yok (varsayilan Archive/TestFlight) | 624242'ye gonderir; token `AppConfiguration.postHogProjectToken`. |

Uc nokta `https://us.i.posthog.com/i/v0/e/`. Proje tokeni (`phc_…`) yalnizca olay
gondermeye yarar, okuma yetkisi yoktur; istemcide ve depoda gorunmesi sizinti degildir.
25 Eylul'de `flags` ucunda gecerli oldugu ve `synthetic_verification=true` isaretli
tek bir `app_screen_viewed` olayinin projeye ulastigi dogrulandi.

Kapi: ayri bir Production projesi, App Store veri beyanlari ve PostHog veri isleme
sozlesmesi onaylanmadan `production` + `RELEASE_APPROVED=YES` verilmez. O zamana kadar
TestFlight ve yayin derlemeleri bu tek projeye gider.

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
icerik veya hesap kimligi tasimaz.

**Paywall hunisi (24 Eylul 2026, `docs/paywall-stratejisi.md`).** Tek alan
`context=first/return`; fiyat, urun, patika ve sorun gonderilmez.

| Olay | Ne zaman |
| --- | --- |
| `paywall_shown` | RevenueCat paywall'i ekranda (G2 → taahhut sonrasi `first`; Yolum, Ben, 1. adim tekrari `return`) |
| `paywall_closed` | Satin almadan kapatildi |
| `purchase_started` | Sunucu niyeti onayladi, StoreKit aciliyor |
| `purchase_verified` | Sunucu hakki yazdi (webhook + RevenueCat API dogrulamasi) |

## PostHog panolari (624242)

Hepsi 30 gunluk pencere, `synthetic_verification` olaylarini disarida birakir. Payda
**oturum**dur (uygulama acilisinda degisen `distinct_id`), kisi degil.

- [Patika · Onboarding](https://us.posthog.com/project/624242/dashboard/2133792):
  adim goruntulenme ve tamamlama (`step` kirilimli), B1 yazma orani (`written`).
- [Patika · Ilk deger ve satin alma](https://us.posthog.com/project/624242/dashboard/2133793):
  ilk deger hunisi (F1 → patika hazir → ilk oturum basladi → tamamlandi, 1 gun);
  paywall hunisi (G2 → taahhut → `paywall_shown context=first` → `purchase_started` →
  `purchase_verified`, 1 gun); baglama gore paywall ve dogrulanan satin alma;
  kapatma orani (`paywall_closed / paywall_shown`).
- [Patika · Kullanim](https://us.posthog.com/project/624242/dashboard/2133794):
  sekme kullanimi (`screen`), oturumlar (`source`), hatirlatma tercihi (`enabled`).

## Dogrulama

- `swiftc` ile AnalyticsContract testi: istek sekli, ABD host, profil
  olusturmama, allowlist, adim tekrarini onleme ve token cozumu (Debug kapali,
  Release varsayilan proje, Production onayli).
- Simulator build; Staging Release derlemesinde ornek akistan tekil olay
  sirasi. Test olayi Production'a dusmemeli.
- PostHog panolarinda sayilarin ornek akisla eslesmesi; IP kaydi ve kisi
  profili yoklugu; kriz ve serbest metin senaryolarinda yasak verinin yoklugu.

624242 projesine 25 Eylul'de tek bir sentetik olay gonderildi ve SQL ile
dogrulandi. `synthetic_verification=true` ozelligi tasiyan olaylar bu panolarin
hepsinde dislanir. Release uygulamasindan canli olay gonderimi henuz
dogrulanmadi. Eski 88885 ve 282221 projelerindeki sentetik veriler bu projeyi
ilgilendirmez.

Referanslar: [PostHog Capture API](https://posthog.com/docs/api/capture),
[anonim olaylar](https://posthog.com/docs/data/anonymous-vs-identified-events),
[IP kaydi kontrolu](https://posthog.com/docs/privacy/data-collection#ip-data-capture).
