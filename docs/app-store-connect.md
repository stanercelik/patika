# App Store Connect — Patika 1.0 (yalnız İngilizce MVP)

**Hazırlandı:** 26 Eylül 2026. **ASC'ye yazıldı ve geri okundu:** 26 Eylül 2026
(uygulama `6815598258`, en-GB ana dil + en-US aynı metin). İncelemeye **gönderilmedi**;
yayın türü Manual. Metinlerin kaynağı `fastlane/metadata/` (en-US).
Burada her ASC sayfası alan alan var; `[API]` alanlar `fastlane deliver` veya ASC
API ile yazılır, `[ELLE]` alanların public API'si yok. Anahtar kelime seçimi
26 Eylül'de **Astro (ABD)** popülerlik/zorluk verisiyle güncellendi.

## 1. App Information

| Alan | Değer | |
|---|---|---|
| Name | `Guided Meditation Plan: Patika` (30/30) | [API] |
| Subtitle | `Insomnia, Grief & Breakup Help` (30/30) | [API] |
| Bundle ID | `com.tanercelik.patika` | — |
| SKU | `patika-ios-001` | yalnız uygulama oluşturulurken |
| Primary language | English (U.S.) | — |
| Primary category | Health & Fitness | [API] |
| Secondary category | Lifestyle | [API] |
| Content rights | "Does not contain, show, or access third-party content" | [API] |
| Age rating | Aşağıda §5 | [API] + [ELLE] |
| Regulated medical device | **No** | [ELLE] (Health & Fitness sorusu) |
| License agreement | Apple standart EULA | varsayılan |

## 2. Version 1.0 — App Store sekmesi

| Alan | Değer |
|---|---|
| Promotional text (165/170) | `fastlane/metadata/en-US/promotional_text.txt` |
| Description (2503/4000) | `fastlane/metadata/en-US/description.txt` |
| Keywords (99/100) | `anxiety,stress,sleep,calm,daily,mindfulness,overthinking,clarity,ai,mental health,therapy,therapist` |
| Support URL | `https://stanercelik.github.io/patika-legal/support/` |
| Marketing URL | boş (site yok) |
| Privacy Policy URL | `https://stanercelik.github.io/patika-legal/privacy/` |
| Copyright | `2026 Taner Çelik` |
| Version | 1.0 |
| Release | Manually release this version (Shipaton tarihine göre) |
| Phased release | Kapalı (ilk sürüm) |

### Anahtar kelime tablosu (Astro, ABD, 26 Eylül 2026; popülerlik / zorluk)

| Kelime | Veri | Yüzey | Gerekçe |
|---|---|---|---|
| meditation | 58 / 80 | ad | Ana terim, kısa vadede kazanılmaz; uzun vadeli bahis. |
| guided meditation | 19 / 69 | ad | Aynı. "plan" arama değeri taşımıyor (meditation plan 5/41), yalnız ürünü anlatıyor. |
| insomnia | 40 / 43 | alt başlık | Listede kazanılabilir en yüksek hacim. |
| grief | 17 / 11 | alt başlık | Hacim var, rakip zayıf. |
| breakup | 13 / 13 | alt başlık | Aynı. |
| sleep | 63 / 81 | alan | Büyük, zor; "sleep meditation" birleşimini açar. |
| calm | 68 / 70 | alan | Büyük, zor; 4 karakterlik bahis. |
| mental health (+ clarity) | 55 / 74 · mental clarity 16 / 40 | alan | "mental clarity" kazanılabilir birleşim. |
| mindfulness | 46 / 75 | alan | Kategori terimi. |
| daily | daily meditation 18 / 54 | alan | Adla birleşir. |
| anxiety, stress | 9 / 67 · 6 / 68 | alan | Beklenenden düşük hacim; alt başlıktan indirildi. |
| overthinking, ai | 5 / 9 · ai meditation 5 / 5 | alan | Taban hacim ama rakipsiz, niyet birebir. |
| therapy, therapist | ai therapy 22 / 53 · therapy ai 21 / 53 · therapist free 16 / 46 | alan | 26 Eylül ürün sahibi kararı. Uygulama "terapinin yanında" konumlanıyor (onboarding'de terapi seçeneği). "ai" ile birleşir. |

Elenenler: self compassion 5/15 (therapy'ye yer açmak için), "free" (ilk oturumdan sonra paywall var; "free therapy" arayanı yanıltır), focus 62/58 (odak zamanlayıcısı niyeti), relax 6/69, self care 6/64, breathing 6/53, personalized 5/46, burnout 6/41, heartbreak 5/21, sleep meditation 9/75, stress relief 8/65. Rakip marka adları (youper, lyra, betterme, insight timer, endel…) Apple 2.3.7 gereği, cbt klinik yöntem iddiası olduğu için kullanılmaz.

## 3. Pricing and Availability

| Alan | Değer |
|---|---|
| Price | Free (uygulama indirmesi; ilk kişisel oturum ücretsiz, sonrası IAP) |
| Availability | **Tüm ülkeler (175)**, yeni ülkelere otomatik açık |
| Pre-order | Yok |

Kriz hatları 24 ülkede tanımlı (TR, DE, US, GB + 26 Eylül'de CA, AU, NZ, IE, FR, ES, IT, NL, AT, CH, SE, NO, DK, FI, BR, MX, JP, SG, ZA, IN). Diğer ülkeler 112 + "Other helplines in your country" dizinine düşer.

Çin anakarası: üretken yapay zekâ içeren uygulamalar orada yerel izin ister; Apple Çin mağazasında tutabilir. İzin alınmayacaksa CHN kapatılmalı.

## 4. In-App Purchases (4 × Consumable)

| Product ID | Reference name | Display name (≤30) | Description (≤45) | US price |
|---|---|---|---|---:|
| `path.unlock.7d` | Path unlock 7 days | Continue a 7-day path | Unlock the rest of this 7-day path. | $7.99 |
| `path.unlock.14d` | Path unlock 14 days | Continue a 14-day path | Unlock the rest of this 14-day path. | $11.99 |
| `path.unlock.21d` | Path unlock 21 days | Continue a 21-day path | Unlock the rest of this 21-day path. | $14.99 |
| `path.unlock.28d` | Path unlock 28 days | Continue a 28-day path | Unlock the rest of this 28-day path. | $18.99 |

Fiyat (26 Eylül 2026, ürün sahibi kararı): **Netflix index + maliyet tabanı, tavan yok.** Ülke oranı = Netflix Standard yerel fiyatının USD karşılığı / ABD $19.99 (worldpriceindex.org, help.netflix.com'dan Mayıs 2026 gözlemi). Hedef = Apple'ın ABD fiyatını o ülkeye eşitlediği yerel fiyat × oran; ülkenin fiyat biçimine uyan en yakın basamak seçilir (en büyük sapma %11). Taban: hiçbir ülkede USD karşılığı 7g $1.99 / 14g $3.99 / 21g $5.99 / 28g $7.99 altına inmez (kişisel TTS maliyeti tahmini ~$0.20/oturum, ölçülmedi). Netflix olmayan CHN/RUS/XKS komşu ülke medyanı. İsviçre ×1.47 ile ABD'nin üstünde. Dört ürün × 175 ülke ASC'ye yazıldı ve geri okundu; tam tablo `docs/iap-prices-netflix-index.csv`. **Uyarı:** ABD taban fiyatı değiştirilirse yeni otomatik takvim tüm ülke fiyatlarını siler; önce taban, sonra bu tablo yeniden uygulanır. Ad, açıklama (en-GB + en-US), ABD fiyatı, 175 ülke ve review note ASC'de. 7 günlüğün review screenshot'ı var; **14/21/28 günlükler görsel bekliyor** (MISSING_METADATA). Review note:

> One-time purchase that unlocks the remaining sessions of the user's current personally generated path. Shown after the first free session is completed. Not a subscription.

İlk sürümde dört ürün **version sayfasından elle** "In-App Purchases and Subscriptions" bölümüne eklenmeli.

## 5. Age Rating — 18+

PRD: v1 18 yaş altına kapalı ("18 yaş altı → v1'de kapalı"). Anket cevapları hepsi **None / No**; sonra **Override → 18+**.

| Soru | Cevap |
|---|---|
| Parental controls, age assurance | No |
| Unrestricted web access | No |
| User-generated content (başkalarına görünen) | No — yazılan metin yalnız kullanıcıya görünür |
| Messaging and chat | No |
| Advertising | No |
| Medical or treatment information | None |
| Health or wellness topics | **Yes** |
| Mature or suggestive themes, horror, violence (tüm çeşitler) | None |
| Profanity, sexual content, nudity | None |
| Alcohol, tobacco, drugs; gambling; contests; loot boxes | None / No |
| Age rating override | **18+** |

## 6. App Privacy (yalnız ASC arayüzü, sonra Publish)

Tracking: **No** (ATT yok, reklam yok, veri satılmıyor).

| Veri türü | Toplanıyor mu | Kullanıcıya bağlı | Amaç | Kaynak |
|---|---|---|---|---|
| Contact Info → Email Address | Evet | Evet | App Functionality | Apple/Google ile hesap bağlama (Supabase Auth) |
| Contact Info → Name | Evet | Evet | App Functionality | İsteğe bağlı isim, şifreli |
| Health & Fitness → Health | Evet | Evet | App Functionality | Derdin kategorisi, ölçüm cevapları |
| User Content → Photos | Evet | Evet | App Functionality | İsteğe bağlı profil fotoğrafı (`avatars`) |
| User Content → Other User Content | Evet | Evet | App Functionality | Serbest metin (şifreli) ve notlar; commitment işareti cihazda kalır |
| Identifiers → User ID | Evet | Evet | App Functionality | Supabase UUID, RevenueCat app user ID |
| Purchases → Purchase History | Evet | Evet | App Functionality | RevenueCat + sunucu hakkı |
| Usage Data → Product Interaction | Evet | **Hayır** | Analytics | PostHog; diske yazılmayan oturum UUID'si, IP atılıyor |
| Other Data → Other Data Types | Evet | Evet | App Functionality | Cinsiyet, yaş aralığı (isteğe bağlı) |
| Diagnostics | **Hayır** | — | — | `SENTRY_DSN` yapılandırılmadı; yapılandırılırsa Crash Data eklenir |

Privacy policy bu listeyle aynı olmalı (`docs/legal-draft/privacy.md`).

## 7. App Review Information

| Alan | Değer |
|---|---|
| Sign-in required | **No** (anonim hesap) |
| Contact | Taner Çelik · tanercelik2001@gmail.com · +491606633348 |
| Notes | `fastlane/metadata/review_information/notes.txt` |
| Attachment | Önerilir: 60–90 sn ekran kaydı (onboarding → ilk oturum → paywall) |

## 8. Build ve uyumluluk

| Alan | Değer |
|---|---|
| Cihaz | Yalnız iPhone (`TARGETED_DEVICE_FAMILY = 1`, 26 Eylül) |
| Minimum iOS | 26.0 |
| Export compliance | `ITSAppUsesNonExemptEncryption = NO` (yalnız HTTPS + sistem kripto) |
| Sign in with Apple | Entitlement var; Google girişi yanında zorunlu, mevcut |
| Account deletion | Settings → Delete account (5.1.1(v) karşılanıyor) |
| Face ID izin metni | "So only you can open your notes and progress." |

## 9. Ekran görüntüleri (iPhone 6.9", 1320 × 2868, en az 3, en çok 10)

| # | Başlık | Ekran |
|---|---|---|
| 1 | A meditation plan built from your words | F2 yol özeti |
| 2 | Say what's weighing on you | B1/B4 serbest metin |
| 3 | One short audio step a day | G1 oturum |
| 4 | See how far you've come | Ben — ölçüm karşılaştırması |
| 5 | Ten prepared paths, offline | Keşfet |
| 6 | Support is always one tap away | Destek al |

Ekran görüntülerinde fiyat, "free", uydurma puan veya kullanıcı sayısı yok. Uygulama önizleme videosu isteğe bağlı.

## 10. Yayın öncesi engeller (listeden bağımsız)

1. `patika-legal` GitHub Pages yayında değil: Privacy/Support URL'leri 404 verirse inceleme reddedilir. Taslakta ad ve e-posta dolduruldu; yürürlük tarihi, saklama süresi, işleyici listesi ve koşulların hukuki incelemesi eksik.
2. Supabase `ELEVENLABS_API_KEY` geçerliliği doğrulanmalı; aksi halde incelemeci ilk oturumu sessiz duyar.
3. Kriz hattı numaraları resmî kaynaklardan doğrulanmalı (CLAUDE.md).
4. `unreviewed_blocks` boş dönmeli (klinik gözden geçirme).
5. RevenueCat: dört offering + Apple sandbox'ta gerçek cihaz satın alma.
