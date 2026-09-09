# Supabase Backend, Auth ve Gozlemlenebilirlik Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Patika'ya anonim Supabase oturumu, Apple/Google hesap baglama, RLS korumali veri modeli, guvenli Gemini/FAL sunucu adaptörleri ve gizlilik sinirli PostHog/Sentry katmani eklemek.

**Architecture:** iOS uygulamasi yalnizca Supabase publishable key ile konusur; hassas servis anahtarlari Supabase Edge Function secret'larinda kalir. Yeni kullanici A1'de anonim UUID alir, F1'de sunucu guvenlik kapisindan gecen taslak kaydedilir ve H1'de Apple/Google kimligi ayni UUID'ye baglanir. AI ve TTS cagrilari provider adaptörleri arkasindadir; anahtar veya bolge hazir degilse guvenli deterministik fallback kullanilir.

**Tech Stack:** SwiftUI, Observation, AuthenticationServices, URLSession tabanli Supabase/PostHog/Sentry istemcileri, PostgreSQL 17/RLS, Supabase Edge Functions (Deno/TypeScript), Gemini REST API ve fal.ai REST API.

**Spec:** `docs/superpowers/specs/2026-09-09-supabase-backend-auth-observability-design.md`

## Global Constraints

- Deployment target iOS 26.0'dir.
- E-posta, parola, magic-link ve telefonla giris yoktur.
- A1 tek kanca olarak kalir; `Zaten hesabim var` ayni ekranda ikincil eylemdir.
- B1/B4 ham metni ve olcum cevaplari sunucu kriz kapisi gecilmeden kalici domain tablolarina yazilmaz.
- Kriz sinyali tek yonludur; istemci sinyali sunucuda indirilemez.
- Mobil pakette Supabase secret, Gemini, FAL veya Sentry auth token'i bulunmaz.
- Analitige problem metni, kacinma metni, olcum cevabi, path ozeti veya ses URL'si gonderilmez.
- Tum public tablolar RLS ile korunur; anonim kullanici da `authenticated` rolundedir ve sahiplik `auth.uid()` ile kontrol edilir.
- Kullaniciya gorunen metinler `Copy` katmaninda `LocalizedStringResource` olarak tutulur.

---

### Task 1: Supabase veritabani ve RLS

**Files:**
- Create: `supabase/migrations/20260909070000_initial_backend.sql`
- Create: `supabase/seed.sql`
- Test: Supabase SQL sorgulari ve security/performance advisor

**Interfaces:**
- Consumes: `auth.users(id)` ve JWT `auth.uid()`.
- Produces: `profiles`, `problem_statements`, `measurements`, `program_paths`, `path_steps`, `generation_jobs`, `audio_assets`; `private_audio` bucket'i.

- [x] **Step 1: Bos projenin tablolarini incele**

Run: Supabase `list_tables` with `schemas: ["public", "storage"]`, `verbose: true`.
Expected: Patika domain tablolarinin bulunmamasi.

- [x] **Step 2: Semayi migration olarak yaz**

Migration; UUID PK, FK, CHECK, sahiplik indeksleri, `updated_at` trigger'i, RLS ve `TO authenticated` sahiplik politikalarini tanimlar. `profiles` insert politikasi `user_id = (select auth.uid())`; tum update politikalari hem `USING` hem `WITH CHECK` kullanir. Yeni Supabase davranisi icin `GRANT SELECT, INSERT, UPDATE, DELETE` izinleri acikca verilir.

- [x] **Step 3: Migration'i uzak projeye uygula**

Run: Supabase `apply_migration(name: "initial_backend", query: <file>)`.
Expected: Migration basarili ve tum public tablolarda RLS etkin.

- [x] **Step 4: Guvenlik dogrulamasi yap**

Run: `list_tables`, ardindan security ve performance advisor.
Expected: Public tabloda RLS-off veya sahipsiz veri politikasi bulunmamasi.

### Task 2: Edge Function guvenlik kapisi ve provider adaptörleri

**Files:**
- Create: `supabase/functions/_shared/auth.ts`
- Create: `supabase/functions/_shared/cors.ts`
- Create: `supabase/functions/_shared/providers.ts`
- Create: `supabase/functions/_shared/schema.ts`
- Create: `supabase/functions/generate-path/index.ts`
- Create: `supabase/functions/generate-audio/index.ts`
- Create: `supabase/functions/fal-webhook/index.ts`
- Test: `supabase/functions/tests/provider_contract_test.ts`

**Interfaces:**
- Consumes: `Authorization: Bearer <Supabase JWT>`, `GeneratePathRequest`.
- Produces: `GeneratePathResponse = { status: "ready" | "crisis" | "processing"; pathId?: string; title?: string; steps?: PathStepDTO[] }`.

- [x] **Step 1: Provider sozlesmesi testini yaz**

Test; eksik JWT'nin 401, istemci kriz sinyalinin AI cagirilmadan `crisis`, ayni idempotency anahtarinin ayni isi dondurmesi ve bilinmeyen block ID'nin reddedilmesini denetler.

- [x] **Step 2: Sabit request/response semalarini yaz**

`GeneratePathRequest` yalnizca gerekli onboarding enum'larini, baseline cevaplarini ve `clientCrisisSignal` degerini kabul eder. Metinler loglanmaz; `problemText` ve `avoidanceText` yalnizca istek omru boyunca bellekte tutulur.

- [x] **Step 3: Gemini adaptörünü guvenli modla uygula**

`GeminiProvider` JSON Schema cikti ister, timeout ve response validation uygular. `GEMINI_API_KEY` veya `PATIKA_AI_LIVE_ENABLED=true` yoksa dis servis cagrisi yapmaz; onayli blok ID'leriyle deterministik fallback plan dondurur. Kriz siniflandirma reddi kriz sinyali sayilir.

- [x] **Step 4: FAL adaptörünü uygula**

`FalProvider`, `fal-ai/elevenlabs/tts/multilingual-v2` endpoint'ine `X-Fal-Store-IO: 0` ile gider. `FAL_KEY` veya `PATIKA_TTS_LIVE_ENABLED=true` yoksa isi `provider_configuration_required` ile bitirir; gizlice sentetik basari donmez.

- [x] **Step 5: Edge Function'lari deploy et**

`generate-path` ve `generate-audio` JWT dogrular. `fal-webhook` kendi imza kontrolunu yaptigi icin platform JWT dogrulamasi kapali deploy edilir ve yanlis imzada 401 verir.

### Task 3: iOS Supabase istemcisi ve oturum yasam dongusu

**Files:**
- Create: `MyApp/Infrastructure/Configuration/AppConfiguration.swift`
- Create: `MyApp/Infrastructure/Auth/AuthClient.swift`
- Create: `MyApp/Infrastructure/Auth/SupabaseAuthClient.swift`
- Create: `MyApp/Infrastructure/Auth/AuthSessionStore.swift`
- Create: `MyApp/Infrastructure/Backend/BackendClient.swift`
- Create: `MyApp/Infrastructure/Backend/SupabaseBackendClient.swift`
- Modify: `MyApp/App/PatikaApp.swift`
- Test: build-time protocol fakes and simulator build

**Interfaces:**
- Produces: `AuthClient.signInAnonymously()`, `signIn(provider:)`, `link(provider:)`, `signOut()`; `BackendClient.generatePath(from:)`.
- Consumes: `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from Info.plist build settings.

- [x] **Step 1: Sistem API'leriyle Supabase istemcisini ekle**

Yeni ucuncu taraf bagimlilik eklemeden `URLSession`, `AuthenticationServices`, `CryptoKit` ve `Security` ile gerekli Auth/PostgREST/Functions yuzeyi uygulanir.

- [x] **Step 2: Configuration fail-closed davranisini yaz**

URL/key yoksa uygulama crash olmaz; auth eylemi `configurationMissing` verir ve kullaniciya ilerlemesinin cihazda durdugunu soyleyen hata gosterilir.

- [x] **Step 3: Auth protokolu ve store'u uygula**

`AuthSessionStore.ensureAnonymousSession()` yalnizca aktif oturum yoksa `signInAnonymously()` cagirir. `link(provider:)` mevcut anonim UUID'yi korur; normal `signIn(provider:)` geri donen kullanici akisidir.

- [x] **Step 4: Backend DTO ve istemciyi uygula**

DTO'lar yalnizca allowlist alanlari encode eder. `SupabaseBackendClient.generatePath` Edge Function'i cagirir ve kriz cevabini hata degil ayri domain sonucu olarak dondurur.

- [x] **Step 5: Uygulama kokune dependency injection ekle**

`PatikaApp` tek `AuthSessionStore` ve `BackendClient` olusturup environment'a verir. `AppState` tamamlanmis profili hem cihaz hem sunucu durumuyla ayirt eder.

### Task 4: A1, F1 ve H1 akislari

**Files:**
- Modify: `MyApp/Content/Copy.swift`
- Modify: `MyApp/Features/Onboarding/A1Welcome/WelcomeView.swift`
- Modify: `MyApp/Features/Onboarding/A1Welcome/WelcomeViewModel.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingFlowViewModel.swift`
- Modify: `MyApp/Features/Onboarding/OnboardingContainerView.swift`
- Modify: `MyApp/Features/Onboarding/FDelivery/GenerationViewModel.swift`
- Create: `MyApp/Features/Auth/AuthProviderButtons.swift`
- Create: `MyApp/Features/Auth/ReturningUserAuthView.swift`
- Create: `MyApp/Features/Onboarding/HAccount/AccountLinkView.swift`
- Test: simulator accessibility pass

**Interfaces:**
- Consumes: `AuthSessionStore`, `BackendClient`, `OnboardingDraft`.
- Produces: A1 anonymous start/returning sign-in, real F1 generation, H1 Apple/Google link/skip.

- [x] **Step 1: Auth ve hata metinlerini Copy'ye ekle**

`Zaten hesabim var`, `Hesabina don`, `Apple ile devam et`, `Google ile devam et`, `Simdilik gec` ve kayip olmadigini aciklayan hata metinleri eklenir.

- [x] **Step 2: A1 baslangicini anonim auth'a bagla**

Birincil buton session olustururken bekleme durumu gosterir; basarisizsa onboarding taslagi kaybolmadan tekrar denenebilir. Ikincil baglanti auth sheet acar.

- [x] **Step 3: F1 zamanlayicisini gercek backend state'ine bagla**

Ekran request surerken asamalari ilerletir; `ready` F2'ye, `crisis` hareketi sifir kriz ekranina, hata ayni ekranda tekrar denemeye gider. Basarisiz ag cagrisi otomatik olarak sahte path uretmez.

- [x] **Step 4: H1 adimini ekle**

G1 tamamlaninca H1 acilir. Apple/Google mevcut anonim hesaba baglanir; `Simdilik gec` anonim oturumu koruyarak app shell'e gecer.

- [x] **Step 5: Dynamic Type ve Reduce Motion kontrolu yap**

A1 ve auth sheet'i normal boyut, AX5, Reduce Motion ve Reduce Transparency ile kontrol edilir; buton hedefleri en az 44 pt olur.

### Task 5: Gizlilik sinirli PostHog ve Sentry

**Files:**
- Create: `MyApp/Infrastructure/Observability/AnalyticsClient.swift`
- Create: `MyApp/Infrastructure/Observability/ErrorReporter.swift`
- Create: `MyApp/Infrastructure/Observability/Observability.swift`
- Modify: `MyApp/App/PatikaApp.swift`
- Test: payload allowlist self-tests and simulator build

**Interfaces:**
- Produces: allowlisted `AnalyticsEvent`; redacted `ErrorContext`.
- Consumes: kullanici riza bayragi ve `analytics_subject_id`; Supabase UUID kullanmaz.

- [x] **Step 1: Event allowlist'ini yaz**

Yalnizca ekran/akis durumu, sonuc kodu ve yuvarlanmis sure bucket'i gonderilir. Serbest metin, olcum cevabi, kategori, path basligi ve URL tipleri API'de kabul edilmez.

- [x] **Step 2: PostHog adapter'ini ekle**

EU host kullanilir; autocapture, session replay ve lifecycle capture kapali baslar. Riza yoksa noop adapter kullanilir.

- [x] **Step 3: Sentry adapter'ini ekle**

PII, screenshot, view hierarchy ve replay kapali; `beforeSend` request body, Authorization ve URL query'lerini temizler. DSN yoksa noop adapter kullanilir.

- [x] **Step 4: Uctan uca dogrula**

Run: `xcodebuild -project patika.xcodeproj -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`.
Expected: `BUILD SUCCEEDED`. Test target bulunmadigi ayrica raporlanir; migration ve advisor sonuclari teslim notuna eklenir.
