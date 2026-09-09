# Patika Supabase Backend, Auth ve Gozlemlenebilirlik Tasarimi

**Tarih:** 2026-09-09  
**Durum:** Onaylandi
**Kapsam:** Supabase backend, anonim hesap yasam dongusu, Apple/Google hesap baglama,
Gemini ve FAL/ElevenLabs adaptörleri, PostHog ve Sentry gizlilik sinirlari

## 1. Amac

Patika, kullanicidan onboarding basinda hesap istemeden veri sahipligi ve sunucu
yetkilendirmesi saglayacak. Yeni kullanici `Baslayalim` dediginde Supabase anonim
oturumu acilacak. Onboarding sonundaki H1 ekraninda kullanici yalnizca Apple veya
Google kimligini mevcut anonim hesaba baglayabilecek. Basarili baglamada Supabase
kullanici UUID'si degismeyecek; dolayisiyla program, olcum ve ses kayitlari
tasima islemi olmadan ayni hesabin altinda kalacak.

Geri donen kullanici A1'deki `Zaten hesabim var` baglantisindan Apple veya Google
ile oturum acacak. E-posta/sifre, magic link ve telefonla giris urunde
sunulmayacak.

## 2. Degismeyen urun kararlari

- Yeni kullanicidan ilk degeri gormeden kalici hesap istenmez.
- A1 tek animasyonlu kanca olarak kalir; yeni bir karsilama veya ozellik ekrani
  eklenmez.
- `Zaten hesabim var` yalnizca geri donen kullanici icin ikincil bir baglantidir.
- H1, ilk oturumdan sonra kalici hesap baglama ekranidir ve `Simdilik gec`
  gercekten calisir.
- E-posta/sifre veya magic-link girisi yoktur.
- Apple birincil, Google ikincil kimlik saglayicidir.
- Onboarding taslagi `OnboardingDraft` olarak gecici kalir. B1/B4 serbest
  metinleri ve baseline cevaplari F1'deki guvenlik kapisi gecilmeden kalici domain
  tablolarina yazilmaz.
- Kriz sinyalinde path, olcum, hesap veya odeme kaydi uretilmez.

## 3. Kullanici ve oturum akislari

### 3.1 Yeni kullanici

1. A1 acilir; henuz uzak hesap olusturulmaz.
2. Kullanici `Baslayalim` der.
3. Uygulama `signInAnonymously()` ile Supabase oturumu acar.
4. Anonim UUID uygulamanin butun sunucu kayitlarinin `user_id` degeridir.
5. Onboarding verisi cihazdaki `OnboardingDraft` icinde kalir.
6. F1 baslarken istemci kriz on filtresi tekrar kontrol edilir; sunucu kriz
   siniflandirmasi gecilirse path isi anonim UUID altinda olusturulur.
7. Ilk oturumdan sonra H1 acilir.
8. Apple veya Google secilirse `linkIdentity(provider:)` mevcut anonim hesaba
   kimlik ekler. UUID degismez ve tum veriler ayni yerde kalir.
9. `Simdilik gec` secilirse anonim oturum devam eder; kullanici uygulamayi
   kullanabilir ve daha sonra Ayarlar'dan hesabini baglayabilir.

Anonim hesap uygulama silinir, cihaz degisir veya oturum anahtarlari kaybolursa
geri getirilemez. H1 bunu tehdit veya aciliyet dili kullanmadan aciklar.

### 3.2 Geri donen kullanici

1. A1'de `Zaten hesabim var` secilir.
2. `Hesabina don` auth sheet'i acilir.
3. Kullanici Apple veya Google ile normal oturum acar.
4. Sunucudaki `profiles.onboarding_completed_at` doluysa uygulama kabuguna
   gecilir ve aktif path yuklenir.
5. Saglayici oturumu gecerli olsa da tamamlanmis Patika profili yoksa kullaniciya
   bu hesapta kayitli bir yol bulunmadigi soylenir. Olusan kalici oturum korunur;
   kullanici A1'den yeni kullanici akisina devam edebilir. Bu durum sessizce
   uygulama kabuguna gecmis bir hesap gibi sunulmaz.

A1'de giris anonim oturum acilmadan once sunuldugu icin, geri donen kullanicinin
bos bir anonim hesabi ve veri birlestirme sorunu olusmaz.

### 3.3 Kimlik cakismasi

H1'de secilen Apple/Google kimligi baska bir Patika hesabina zaten bagliysa iki
hesap otomatik birlestirilmez. Mevcut anonim oturum ve verileri korunur; kullanici
mevcut hesaba gecmek isterse acik bir onay akisi kullanilir. v1'de iki ayri aktif
path'in otomatik birlestirilmesi kapsam disidir.

## 4. Ekran ve metin degisiklikleri

### A1

- Birincil eylem: mevcut `Baslayalim`
- Ikincil metin baglantisi: `Zaten hesabim var`
- Baglanti auth sheet'ini acar; onboarding adimi sayisini artirmaz.

### Geri donen kullanici auth sheet'i

- Baslik: `Hesabina don`
- Aciklama: `Apple veya Google ile devam edebilirsin.`
- Birincil: `Apple ile devam et`
- Ikincil: `Google ile devam et`
- Kapatma: `Simdilik degil`

### H1

- Kalici hesap baglamanin ilerlemeyi farkli cihazda geri getirebilmek icin
  kullanildigi sade bicimde anlatilir.
- `Apple ile devam et`, `Google ile devam et`, `Simdilik gec` eylemleri bulunur.
- E-posta alani veya parola yoktur.

Tum metinler `Copy` katmaninda TR/EN yerellestirmesine hazir tutulur. Auth
hatalari kullaniciyi suclamaz ve mevcut ilerlemenin kaybolmadigini belirtir.

## 5. Supabase topolojisi

- Yeni proje adi: `Patika`
- Organizasyon: kullanici tarafindan dogrulanacak
- Bolge: `eu-central-1` (Frankfurt)
- Auth: anonymous, Apple, Google
- Database: PostgreSQL 17
- Storage: tum ses bucket'lari private
- Server: Supabase Edge Functions
- Asenkron durum: `generation_jobs` tablosu ve FAL webhook; ihtiyac halinde
  Supabase Queues

Mobil uygulamaya yalnizca Supabase proje URL'si ve `sb_publishable_...` anahtari
konur. Supabase secret key, Gemini anahtari, FAL anahtari, Sentry auth token'i ve
diger sunucu sirlarinin hicbiri uygulama paketine girmez.

## 6. Ilk veritabani semasi

### `profiles`

- `user_id uuid primary key references auth.users(id) on delete cascade`
- `locale text not null`
- `analytics_subject_id uuid not null unique`
- `name_ciphertext text null`
- `gender text null`
- `age_range text null`
- `onboarding_completed_at timestamptz null`
- `created_at`, `updated_at`

### `problem_statements`

- `id uuid primary key`
- `user_id uuid not null`
- `raw_text_ciphertext text null`
- `generation_summary text null`
- `created_at`

Ham metin saklanmasi zorunlu degilse `raw_text_ciphertext` bos kalir. Tercih
edilen davranis, ham metni yalnizca uretim istegi boyunca bellekte tutmak ve
veritabanina yalnizca guvenli ozeti yazmaktir.

### `measurements`

- `id uuid primary key`
- `user_id uuid not null`
- `variant text not null`
- `measurement_day integer not null`
- `raw_responses jsonb not null`
- `emotion_score`, `behavior_score`, `self_efficacy_score` sunucuda deterministik
  hesaplanir
- `created_at`

### `program_paths`

- `id uuid primary key`
- `user_id uuid not null`
- `length_days integer not null`
- `status text not null`
- `template_id text not null`
- `personalization_context jsonb not null`
- `created_at`, `completed_at`

### `path_steps`

- `id uuid primary key`
- `path_id uuid not null`
- `day integer not null`
- `block_ids text[] not null`
- `slot_copy jsonb not null`
- `audio_status text not null`
- `created_at`

### `generation_jobs`

- `id uuid primary key`
- `user_id uuid not null`
- `path_id uuid null`
- `kind text not null`
- `provider text not null`
- `provider_request_id text null`
- `status text not null`
- `attempt_count integer not null default 0`
- `idempotency_key text not null unique`
- `last_error_code text null`
- `created_at`, `updated_at`, `completed_at`

### `audio_assets`


- `id uuid primary key`
- `user_id uuid not null`
- `path_step_id uuid not null`
- `storage_path text not null`
- `content_type text not null`
- `duration_ms integer null`
- `created_at`, `expires_at`

Tablo degerleri icin CHECK kisitlari, sahiplik sorgulari icin `user_id` indeksleri
ve path gunu icin `(path_id, day)` unique kisiti kullanilir.

## 7. RLS ve veri erisimi

- `public` icindeki her tabloda RLS aciktir.
- Anonim Supabase kullanicilari da `authenticated` Postgres rolundedir.
- Bu nedenle hicbir politika yalnizca `TO authenticated` ile yetinmez; her zaman
  `(select auth.uid()) = user_id` sahiplik kosulu vardir.
- UPDATE politikalarinda hem `USING` hem `WITH CHECK` bulunur.
- Odeme, hesap silme ve disari aktarma gibi kalici hesap gerektiren islemlerde
  JWT `is_anonymous` claim'i restrictive policy veya sunucu kontroluyle reddedilir.
- `service_role`/secret key mobil istemcide kullanilmaz.
- Gerekmedikce `SECURITY DEFINER` fonksiyon yazilmaz. Zorunlu fonksiyonlar private
  semada, sabit `search_path`, acik `auth.uid()` kontrolu ve kisitli EXECUTE
  izinleriyle tanimlanir.
- Storage yollari tahmin edilemez UUID'lerden olusur; private bucket nesneleri
  yalnizca kisa omurlu signed URL ile teslim edilir.

## 8. AI ve TTS sunucu akisi

### `generate-path`

1. Supabase JWT dogrulanir.
2. Idempotency ve rate limit kontrol edilir.
3. Sunucu kriz siniflandirmasi ve problem siniflandirmasi paralel calisir.
4. Kriz sinyalinde ham girdi loglanmadan is durdurulur.
5. Gemini adaptoru sabit JSON Schema ile yapilandirilmis cikti ister.
6. Model cikisi blok ID, faz, sure, tekrar ve yasakli dil kurallariyla
   deterministik dogrulanir.
7. Gecerli plan yazilir ve yalnizca ilk adimin TTS isi baslatilir.

Gemini saglayicisi `PathGenerator`/`Classifier` arayuzlerinin arkasinda kalir.
Paylasilmis Gemini anahtari kullanilmaz; yeni anahtar Supabase secret olarak
eklenir. Gemini Developer API ve mevcut Gemini 3.x akislarinin global isleme
siniri nedeniyle gercek hassas veri, AB isleme karari dogrulanmadan Gemini'ye
gonderilmez.

### `generate-audio` ve `fal-webhook`

- Model endpoint'i `fal-ai/elevenlabs/tts/multilingual-v2` olarak sabitlenir.
- Ayarlar: stability `0.65`, similarity boost `0.80`, style `0`, speed `0.92`.
- FAL isteklerinde payload saklama kapatilir (`X-Fal-Store-IO: 0` /
  `store_payload: false`).
- FAL webhook imzasi ve zaman damgasi dogrulanir.
- Ses sonucu private Supabase Storage'a kopyalanir.
- FAL CDN sonucu icin kisa expiration kullanilir; mumkunse kopyalama sonrasinda
  provider payload/output silinir.
- FAL icin AB veri isleme ve DPA teyidi canliya cikis kapisidir. Saglanamazsa ayni
  `SpeechGenerator` arayuzu dogrudan ElevenLabs EU + Zero Retention adaptoru ile
  degistirilir.

## 9. PostHog ve Sentry sinirlari

### PostHog EU

- EU host kullanilir.
- Session replay ve autocapture kapali baslar.
- Yalnizca merkezi allowlist'teki olaylar gonderilir.
- Ham problem metni, isim, measurement cevaplari/skorlari, path metni, ses URL'si,
  provider request ID veya hata aciklamasi property olarak gonderilmez.
- Kimlik olarak Supabase UUID yerine profille birlikte rastgele uretilen ve baska
  sistemlerde kullanilmayan `analytics_subject_id` kullanilir.
- Ilk event seti: onboarding adim tamamlama, F1 baslama/sonuc sinifi, G1 baslama/
  tamamlama, H1 secimi ve teknik basari/iptal durumlari.

### Sentry EU/Germany

- `sendDefaultPii = false`.
- Screenshot, view hierarchy ve session replay kapali.
- Request/response body, URL query, Authorization header ve kullanici metni
  `beforeSend` ile silinir.
- Hatalar yalnizca sabit hata kodu, ekran/akis kimligi, uygulama surumu, OS ve
  provider sinifi gibi guvenli etiketlerle kaydedilir.
- Debug build'ler production projesine event gondermez.

MetricKit ve App Store Connect, Sentry verisini bagimsiz olarak dogrulayan temel
iOS stabilite kaynaklari olarak kalir.

## 10. Hata ve fallback davranisi

- Anonim oturum acilamazsa A1'de kalinir; yeniden deneme ve `Burada duralim`
  secenekleri sunulur.
- Ağ kesilirse onboarding taslagi cihazda kalir; kayip olmadigi aciklanir.
- Gemini timeout/refusal krizde guvenli yone, uretimde jenerik onayli sablona
  duser.
- FAL timeout path'i bozmaz; ses isi yeniden denenebilir durumunda kalir.
- Ayni idempotency key ikinci bir ucretli Gemini/FAL isi baslatmaz.
- Auth saglayici iptalinde mevcut anonim oturum ve ilerleme korunur.

## 11. Test ve dogrulama

- Auth durum makinesi: oturumsuz -> anonim -> bagli kalici; geri donen kalici
  oturum; saglayici iptali ve cakisma.
- RLS testleri: iki ayri kullanici birbirinin hicbir satirini okuyamaz/yazamaz.
- Anonymous JWT'nin `authenticated` rolunde olmasina ragmen odeme gibi kalici
  hesap islemlerini yapamamasi.
- Kriz sinyalinde kalici tablo ve uretim isi olusmamasi.
- Idempotency tekrarinda tek provider isi olusmasi.
- FAL webhook sahte/imzasi gecersiz istegin reddedilmesi.
- Analitik ve hata payload'larinda yasakli alan taramasi.
- iOS build, auth iptali, offline baslatma ve geriye donen hesap UI kontrolleri.

## 12. Uygulama sirasi

1. Supabase projesi, yerel config ve migration altyapisi.
2. Auth ayarlari, anonymous session ve Apple/Google provider yapilandirmasi.
3. Ilk sema, RLS ve private Storage.
4. iOS Supabase istemcisi ve auth durum makinesi.
5. A1 geri donen kullanici girisi ve H1 hesap baglama ekrani.
6. Gemini sunucu adaptoru ve guvenlik kapisi.
7. FAL TTS submit/webhook/Storage akisi.
8. PostHog ve Sentry mahremiyet-kisitli kurulum.
9. Uctan uca guvenlik, hata ve erisilebilirlik dogrulamasi.

## 13. Canliya cikis kapilari

- Supabase DPA ve Frankfurt bolgesi dogrulanmis.
- Apple/Google provider production credentials tanimli.
- Gemini icin hassas veri isleme bolgesi/DPA karari verilmis.
- FAL veya dogrudan ElevenLabs icin DPA, AB isleme ve retention kosullari
  dogrulanmis.
- PostHog ve Sentry EU projeleri acilmis, veri allowlist testleri gecmis.
- Hesap silme ve veri indirme uctan uca calisiyor.
- Kriz vaka tablosu hem istemci hem sunucu katmaninda geciyor.

## 14. Kapsam disi

- E-posta/sifre, telefon veya magic-link auth.
- Chatbot veya serbest LLM sohbeti.
- Iki ayri kalici hesabin otomatik birlestirilmesi.
- Android istemci uygulamasi.
- Firebase Database, Firebase Auth veya Firebase Analytics.

## 15. Dis bagimliliklar

- Supabase organizasyonu ve proje olusturma maliyeti onayi.
- Apple Developer App ID/Sign in with Apple yetkisi.
- Google OAuth iOS ve web client ID'leri.
- Yeni Gemini server anahtari; sohbette paylasilan anahtar rotate edilmeli.
- FAL server API key.
- PostHog EU project token/host.
- Sentry Germany DSN.
