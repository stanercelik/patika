# Patika paywall stratejisi ve RevenueCat kurulum kılavuzu

**Karar:** 24 Eylül 2026, ürün sahibi. Model **patika başına tek ödeme** olarak kalır
(consumable, `monetization.md`'deki 4 ürün ve fiyat). Değişen iki şey var: paywall'ın
**yeri** ve **görünümü**. Önceki 3 sayfalık ve abonelikli taslaklar iptal edildi;
abonelik §9'da ileride denenecek bir seçenek olarak duruyor.

---

## 1. Strateji

**Aha anı ilk adım.** Tek ödemede deneme yok, fiyat hemen tahsil ediliyor. Ücretsiz
ilk kişisel oturum denemenin yerini tutuyor: kullanıcı kendi derdine göre hazırlanmış
oturumu kendi kulağıyla duyuyor. Paywall bu deneyimden **sonra** gelir. Böylece
gösterim başına dönüşüm yükselir, iade ve kötü yorum azalır.

**Commitment paywall'ın hemen önünde.** Kullanıcı "bu patikaya devam ediyorum" diye
basılı tutup işaretini bırakıyor; ardından gelen teklif, bu kararın doğal devamı gibi
okunuyor (tutarlılık etkisi). Commitment ekranı onboarding tasarımında olduğu için
paywall'ın "değer sayfası" işini de görüyor. Bu sayede **RevenueCat paywall'ı tek
sayfa** kalıyor.

**Paywall onboarding'in parçası gibi görünür.** Paywall da onboarding'deki üç katmanı
kullanır: tam ekran guaj sahne, %34 düz perde, koyu plaka. Düz koyu zemin kaldırıldı.

**Alınan taktikler.** Sonucu satmak, risk azaltan alt satır ("No subscription. Nothing
renews."), seans başına fiyat kırılımı, butonda ok (`›`), fiyatın buton içinde görünmesi,
kapatınca aynı teklifi dürüst dönüş noktalarında yeniden göstermek.

**Kullanılmayanlar ve nedenleri:**

| Taktik | Neden yok |
|---|---|
| Uydurma yorum, yıldız, kullanıcı sayısı | Apple yanıltıcı içerik sayıyor ve reddediyor; gerçek veri gelince eklenecek (§8). |
| Kriz sinyalinde paywall | Hiçbir koşulda gösterilmez; Destek al ücretsiz. |
| Exit indirim, geri sayım | Tek üründe indirim, insanlara "kapatırsam ucuzlar" diye öğretir. Deney listesinde, veri gelince (§7). |

---

## 2. Akış

```text
F2  "Your path is ready."  ── "Yola çık" basılı tut (1.4 sn) ──►  G1 (1. adım, ücretsiz)
                                                                   │
            ┌── tam dinlendi ──────────────────────────────────────┘
            ▼
G2  "First step done."  (kısa kapanış + isteğe bağlı soru) ── Continue ──►
Commitment  "One promise, to yourself."  (kendi sözü + işaret) ── basılı tut ──►
PAYWALL  (RevenueCat, tek sayfa, tam ekran, bg-prepare)
   ├─ satın aldı → "Checking your payment" → sunucu hakkı → H1 → Yolum (2. adım açık)
   └─ × / Not now → H1 → Yolum (2. adım kartı aynı paywall'ı açar)

G1 yarıda bırakıldıysa: G2 "tamam" demez → commitment ve paywall atlanır → H1 → Yolum.
```

**Paywall'ın açıldığı yerler** (aynı tasarım, `context` değişkeniyle başlık değişir):

| Nerede | Tetik | `context` |
|---|---|---|
| Onboarding | Commitment basılı tutma bitti | `first` |
| Yolum | Ödenmemiş 2. (veya sonraki) adım kartına dokunma | `return` |
| Ben | Etkin patika kartındaki "Continue this path" satırı | `return` |
| 1. adımı tekrar dinleme sonu | Oturum biter bitmez, günde en fazla bir kez | `return` |

**Asla gösterilmez:** kriz sinyali, Kova C (devam patikası zaten ücretsiz), oturum
ortası, ölçüm ekranları, zaten ödenmiş patika.

---

## 3. Akıştaki uygulama ekranları (native, değişen metinler)

Bu ekranlar RevenueCat'te değil, uygulamada durur. Mevcut bileşenlerle kurulur, sahneleri
değişmez. Özellikler bileşenden gelir; aşağıda neyin değiştiği yazılı.

### 3.1 F2: "Yola çık" buraya taşınır

| Öğe | Eski | Yeni | Bileşen / özellik |
|---|---|---|---|
| Birincil eylem | `Continue` (`onboarding.roadmapContinue`) | `HoldToStartButton`, metin `Press and hold to start your path` (`commitment.holdToStart` taşınır) | 1.4 sn basılı tutma, kırık beyaz dolgu, mevcut bileşen |
| Geçiş cümlesi | — | `Let's begin with day one.` (`commitment.dayOneTransition` taşınır) | Mevcut eşik cümlesi davranışı |

### 3.2 G2: kısa kalır, geleceğe söz vermez

Paywall'dan önce "yarın buradayız" demek, ödenmemiş bir adımı vaat etmek olur.

| Öğe | Metin | Özellik |
|---|---|---|
| Başlık | `First step done.` (değişmez) | `DisplayText` 32 pt, Rounded Bold, `#F2EFE9`, kerning −0.3 |
| Gövde (yeni, `session.completedBody`) | `You listened all the way through. %lld more steps are on your path.` | `BodyText`: Rounded 17 pt (`.body`) Medium, ikincil mürekkep, satır arası +3 |
| Soru | Mevcut `AdaptiveQuestionView`, isteğe bağlı | değişmez |
| Eylem | `Continue` | `PrimaryButton`: kapsül `#F2EFE9`, metin siyah 17 pt Bold, dikey iç boşluk 18 |

### 3.3 Commitment: "başlıyorum" yerine "devam ediyorum"

Kullanıcının kendi sözü (B4, yoksa B1) kartta aynen kalır. Kararı en çok o cümle
taşıyor.

| Öğe | Metin (EN) | Katalog anahtarı | Özellik |
|---|---|---|---|
| Başlık | `One promise, to yourself.` (değişmez) | `commitment.headline` | `OnboardingQuestionLayout` başlığı |
| Alıntı başlığı | `What you told me` / `What you said you keep putting off` (değişmez) | `commitment.leadProblem` / `leadAvoidance` | footnote, Semibold, ikincil mürekkep |
| Alıntı | kullanıcının kendi cümlesi | — | `Theme.Voice.user(.title3)` serif, birincil mürekkep |
| Gövde (**yeni**) | `You took the first step. The next %lld are yours to walk, one a day, at your own pace.` | `commitment.body` (yeniden yazılır, `remaining` parametresi alır) | `BodyText` |
| İşaret ipucu | `Leave a small mark for yourself.` (değişmez) | `commitment.drawHint` | footnote Medium, ikincil |
| İşaret alanı | `SignatureCanvas`, **isteğe bağlı**: boş bırakılsa da basılı tutma çalışır | — | Sürtünme en aza iner |
| Birincil eylem (**yeni**) | `Press and hold to keep going` | `commitment.holdToContinue` (yeni) | `HoldToStartButton`, 1.4 sn |
| Geçiş cümlesi (**yeni**) | `Let's keep your path open.` | `commitment.continueTransition` (yeni) | Mevcut eşik cümlesi, sonra paywall açılır |

---

## 4. Görsel sistem

### 4.1 Katmanlar: onboarding ile birebir

| Katman | Onboarding'deki kod | RevenueCat'teki karşılığı |
|---|---|---|
| 1. Sahne | Tam ekran opak guaj JPEG, `scaledToFill` | Kök Stack arka planı: Image, **Fill** |
| 2. Perde | `#101918` %34, düz | Image **Overlay**: Color `#101918`, opaklık %34 (gradyan değil) |
| 3. Plaka | `SceneContentPlate`: `#15211F` %94, kenar 2 pt `#60716B`, köşe 24, iç boşluk 20 | Stack: aynı değerler |

**Sahne: `bg-prepare`** (`MyApp/Assets.xcassets/Onboarding/bg-prepare.imageset/`,
887 × 1774 JPEG). Güneşe doğru açılan taşlı patika: "yol devam ediyor" anlamını görselin
kendisi taşıyor. Detay üst %55'te, alt %45 sakin çimen; plaka oraya oturur. Yeni görsel
üretmeye gerek yok. Commitment de zaten `bg-prepare` sahnesinde (`currentScene`), yani
G2'nin `bg-settle`'ından sonra sahne bir kez değişir, paywall açılırken **değişmez**:
paywall commitment'ın devamı gibi okunur.

`forest-canopy-v1.png`, `first-stone-vignette-v1.png` ve `forest-path-after-first-step.png`
bu paywall'da **kullanılmaz**: tam ekran sahnenin üstüne ikinci ayrıntılı görsel
koymak metni ezer. Dosyalar ileride başka yerlerde kullanılmak üzere saklanır.

### 4.2 Renk token'ları

| Token | Değer | Kullanım |
|---|---|---|
| `scrim` | `#101918` @ %34 | Sahne perdesi |
| `plate` | `#15211F` @ %94 | Plaka |
| `plateBorder` | `#60716B` | Plaka kenarı 2 pt, ürün kartı kenarı 1 pt |
| `surface` | `#1B2928` | Plaka içindeki ürün kartı |
| `textPrimary` | `#F2EFE9` | Başlık, fayda başlıkları, fiyat |
| `textSecondary` | `#B9C4BF` | Gövde, açıklamalar, alt satır |
| `sage` | `#9BAE9B` | Üst etiket, ikonlar |
| `apricot` | `#E9BA8F` | Kurulan sürümde kullanılmıyor (RevenueCat bir metnin içinde iki renk desteklemiyor); ileride tek başına bir rozet için ayrıldı |
| `ctaFill` | `#F2EFE9` | Birincil buton (uygulamadaki `PrimaryButton` ile aynı) |
| `ctaText` | `#000000` | Buton metni (`PrimaryButton` ile aynı) |
| `closeFill` | `#101918` @ %60 | Kapatma dairesi |
| `footer` | `#101918` @ %88 | Sabit footer zemini |

Kontrast (plaka zemini üstünde): `textPrimary` ~15:1, `textSecondary` ~10:1,
`sage` ~7.5:1, `apricot` ~9.5:1. Hepsi WCAG AA üstünde; cihazda doğrula.

### 4.3 Tipografi ve ölçüler

- **Font:** SF Pro Rounded, projeye yüklü custom font olarak (`rc fonts list`):
  Medium, Semibold, Bold dosyaları ayrı `font_name` ile bağlı. RevenueCat'in CLI
  önizlemesi özel fontu çizmiyor ve serif gösteriyor; cihazda SDK fontu indiriyor.
  Panel önizlemesinde ve cihazda doğrula.
- **Automatically scale font size: On** (Dynamic Type). RevenueCat metin bileşeninde
  satır yüksekliği ve harf aralığı özelliği **yok**; ikisi de sistem varsayılanında
  kalıyor.

| Ölçü | Değer |
|---|---|
| Ekran yan boşluğu (plaka dışı) | 16 pt |
| Plaka iç boşluğu / köşe / içerik aralığı | 20 pt / 24 pt / 12 pt |
| Ürün kartı iç boşluğu / köşe | 14×16 pt / 18 pt |
| CTA | kapsül, dikey iç boşluk 18 (≈56 pt), yatay 24, tam genişlik |
| Metin butonları | dikey iç boşluk 10 + metin ≈ 40–44 pt dokunma alanı |
| Kapatma | 44×44 kapsül (daire), üst 8, sağ 16 |

---

## 5. Paywall ekranı ve her metnin özellikleri

**Durum (25 Eylül 2026):** kuruldu ve yayında. **Tasarımın kaynağı RevenueCat panelindeki
28 günlük paywall** (ürün sahibi orada düzenliyor). `python3 scripts/revenuecat/sync_paywalls.py
--publish` onu okur, yalnız paket kimliğini değiştirip 7/14/21 günlüklere yazar ve yayınlar.
Diğer üç paywall'da panelden yapılan değişiklik bir sonraki eşitlemede ezilir.
Betik bir düzeltme de yapar: ✕ ikonu bir butona sarılı değilse `navigate_back` butonuna
sarar, çünkü işlevsiz bir ✕ kullanıcıyı paywall'a kilitler.

Ürün sahibinin 25 Eylül düzenlemesiyle §5.2–5.3'ten farklar: `Not now` ve `Get support`
kaldırıldı (çıkış yalnız ✕; destek, kapatınca uygulamadaki Destek al'dan). `Restore
purchases` yasal bağlantılar satırına taşındı. CTA'dan fiyat çıktı (`Continue my path ›`,
fiyat kartta), CTA altı 12 pt Medium oldu. Plaka ve footer zemini daha saydam.

Satın almaya yöneltmek için eklenenler (25 Eylül):

- **İlerleme izi** (`Progress trail`): plakanın en üstünde, gün sayısı kadar 4 pt'lik
  kapsül parça, aralarında 3 pt. İlki kayısı `#E9BA8F` (tamamlanan 1. adım), kalanlar
  `#60716B`. Kullanıcı yolun başladığını görür; başlanmış bir yolu yarım bırakmak
  istemez. Parça sayısını eşitleme betiği her paywall'da kurar (7/14/21/28).
- ~~Güvence satırı `Your first step and notes stay yours.`~~ Ürün sahibi 25 Eylül'de kaldırdı.

| Offering | Paket | Paywall |
|---|---|---|
| `path_7d` | `path_unlock_7d` → `path.unlock.7d` | `pw90b35a2daa0f4be2` |
| `path_14d` | `path_unlock_14d` → `path.unlock.14d` | `pwc3b073075134453b` |
| `path_21d` | `path_unlock_21d` → `path.unlock.21d` | `pwa49e7bb0740e4852` |
| `path_28d` | `path_unlock_28d` → `path.unlock.28d` | `pwef6ffd359de943b7` |

### 5.1 Değişkenler

| Değişken | Tür | Kaynak (uygulama) | Panelde tanımlanacak varsayılan |
|---|---|---|---|
| `custom.path_days` | Number | `path.steps.count` | `14` |
| `custom.remaining_sessions` | Number | `days - 1` | `13` |
| `custom.reminder_time` | String | E1 saati (`draft.reminderTimeText`); Yolum'dan boş | `10:30 PM` |
| `custom.price_per_session` | String | `StoreProduct.price / remaining`, ürünün `priceFormatter`'ı | `$0.92` |
| `custom.context` | String | `first` (onboarding) / `return` (Yolum) | `first` |
| `product.price` | ürün | StoreKit yerel fiyat | — |

Değişkenler API'dan tanımlanamıyor. Çalışma anında uygulama değerleri gönderdiği için
paywall doğru görünüyor. Ancak **panel önizlemesi ve yedek değer için** beşini bir kez
panelde tanımla: Paywall → Paywall logic → Variables → Create variable (proje genelinde
geçerli). Tanımlanmazsa önizlemede "STEP 1 OF · DONE" gibi boşluklar görünür.

Sorun metni, kategori, patika adı ve ölçüm RevenueCat'e **gönderilmez**.

### 5.2 Yerleşim (kurulan hâli)

```text
┌───────────────────────────────────────┐
│ [bg-prepare, Fill + #101918 %34]  (×) │  ← kapatma satırı
│   (sahne penceresi 40 pt + plaka      │
│    üstünde ağaçlar görünür)           │
│ ┌─ plaka #15211F %94, 2pt #60716B ──┐ │
│ │ STEP 1 OF 14 · DONE               │ │
│ │ Your path continues               │ │
│ │ tomorrow at 10:30 PM.             │ │
│ │ One payment opens the remaining   │ │
│ │ 13 sessions of your path.         │ │
│ │ (headphones) A session each day   │ │
│ │ (clipboard)  Brief check-ins      │ │
│ │ (history)    Your own before…     │ │
│ └───────────────────────────────────┘ │
│   (plaka altında sahne şeridi)        │
│ ┌ sticky footer #101918 %88 ────────┐ │
│ │ ┌ ürün kartı #1B2928 ───────────┐ │ │
│ │ │ Your 14-day path       $11.99 │ │ │
│ │ │ 13 sessions · about $0.92 each│ │ │
│ │ └───────────────────────────────┘ │ │
│ │ [ Continue my path · $11.99  ›  ] │ │
│ │ One payment. No subscription.     │ │
│ │ Nothing renews.                   │ │
│ │ Not now   ·   Restore purchases   │ │
│ │ Get support · Privacy · Terms     │ │
│ └───────────────────────────────────┘ │
└───────────────────────────────────────┘
```

İlk taslakta ürün kartı plakanın içindeydi. 393×852'de footer kartın üstüne biniyordu,
bu yüzden kart footer'a, CTA'nın hemen üstüne taşındı: fiyat, kart ve buton her ekran
boyunda ilk bakışta görünüyor. Plaka ve sahne yukarıda kayabilir.

### 5.3 Metinler

Kısaltmalar: **B** boyut (pt), **A** ağırlık. Font: SF Pro Rounded, ağırlığa göre dosya.

**Plaka**

| # | Öğe | Metin | B | A | Renk | Hiza | Boşluk / kural |
|---|---|---|---|---|---|---|---|
| 1 | Üst etiket | `STEP 1 OF {{ custom.path_days }} · DONE` | 12 | Semibold | `#9BAE9B` | Sol | Kural `context = return` → `YOUR PATH IS SAVED` |
| 2 | Başlık | `Your path continues tomorrow at {{ custom.reminder_time }}.` | 30 | Bold | `#F2EFE9` | Sol | Kural `context = return` → `Your path is still here.` |
| 3 | Gövde | `One payment opens the remaining {{ custom.remaining_sessions }} sessions of your path.` | 17 | Medium | `#B9C4BF` | Sol | alt 6 |
| 4 | Fayda 1 başlık | `A session each day` | 17 | Semibold | `#F2EFE9` | Sol | ikon `headphones` 20 pt `#9BAE9B`, metinle 12 pt aralık, üstten 1 |
| 5 | Fayda 1 açıklama | `Voiced, and built around what you shared.` | 15 | Medium | `#B9C4BF` | Sol | üst 2 |
| 6 | Fayda 2 başlık | `Brief check-ins` | 17 | Semibold | `#F2EFE9` | Sol | ikon `clipboard-check` |
| 7 | Fayda 2 açıklama | `Notice what is shifting along the way.` | 15 | Medium | `#B9C4BF` | Sol | üst 2 |
| 8 | Fayda 3 başlık | `Your own before and after` | 17 | Semibold | `#F2EFE9` | Sol | ikon `history` |
| 9 | Fayda 3 açıklama | `At the end, compare with where you started.` | 15 | Medium | `#B9C4BF` | Sol | üst 2. Faydalar arası 14 |

**Footer** (sabit; zemin `#101918E0`, iç boşluk üst 14 / yan 16)

| # | Öğe | Metin | B | A | Renk | Hiza | Not |
|---|---|---|---|---|---|---|---|
| 10 | Kart başlığı | `Your {{ custom.path_days }}-day path` | 17 | Semibold | `#F2EFE9` | Sol | Package bileşeni; kart `#1B2928`, 1 pt `#60716B`, köşe 18, alt 12. Tek paket, seçili stili yok. |
| 11 | Kart fiyatı | `{{ product.price }}` | 20 | Bold | `#F2EFE9` | Sağ | başlıkla aynı satır |
| 12 | Kart alt satırı | `{{ custom.remaining_sessions }} sessions · about {{ custom.price_per_session }} each` | 14 | Medium | `#B9C4BF` | Sol | üst 4. Kural `price_per_session = ""` → `… sessions · one-time purchase` |
| 13 | CTA | `Continue my path · {{ product.price }}` + `chevron-right` 15 pt | 17 | Bold | `#000000` | Orta | Purchase button, kapsül `#F2EFE9` |
| 14 | CTA altı | `One payment. No subscription. Nothing renews.` | 13 | Semibold | `#B9C4BF` | Orta | üst 8 |
| 15 | Çıkış | `Not now` | 15 | Semibold | `#B9C4BF` | Orta | eylem `navigate_back` (uygulamada `onRequestedDismissal`) |
| 16 | Geri yükleme | `Restore purchases` | 15 | Semibold | `#B9C4BF` | Orta | eylem `restore_purchases`; 15 ile aynı satır, 24 aralık. CLI önizlemesi bu butonu çizmez. |
| 17 | Destek | `Get support` | 12 | Semibold | `#B9C4BF` %80 | Orta | `navigate_to` url, **deep_link** `patika://support` → uygulama `CrisisView` açar |
| 18 | Yasal | `Privacy` · `Terms` | 12 | Semibold | `#B9C4BF` %80 | Orta | in-app browser. Privacy: `https://stanercelik.github.io/patika-legal/privacy` (**henüz yayında değil**); Terms: Apple standart EULA |
| 19 | Kapatma | ikon `x` 17 pt | — | — | `#F2EFE9` | — | 44×44, zemin `#10191899`, `navigate_back`. VoiceOver etiketini panelde "Close" olarak doğrula. |

---

## 6. Kurulum ve bakım

Kurulum RevenueCat CLI (`rc`, `brew install revenuecat`) ve API v2 ile yapıldı.

1. **Mevcut katalog** (değişmedi): 4 consumable ürün, 4 offering, her birinde tek paket
   (§5 tablosu). Entitlement yok.
2. **Görsel:** `bg-prepare` Media Gallery'de. Paywall arka planı `type: image`,
   `fit_mode: fill`, `color_overlay #10191857`.
3. **Tasarım değişikliği:** panelde 28 günlük paywall'ı düzenle ve yayınla, sonra
   `python3 scripts/revenuecat/sync_paywalls.py --publish`.
4. **Önizleme:** `rc paywalls edit <pw> --prompt "Do not change anything… Only render a
   preview."` ekran görüntüsünü `~/.config/revenuecat/paywalls/<proj>/<pw>/session.light.png`
   yoluna yazar. Özel fontu çizmez; panel önizlemesi ve cihaz esastır.
5. **Geri alma:** `rc paywalls unpublish <pw>`.

**Yasal sayfalar** (25 Eylül): herkese açık `stanercelik/patika-legal` deposu, GitHub
Pages'ten yayında. Paywall, uygulama ve App Store Connect bu URL'leri kullanır:

- Privacy: https://stanercelik.github.io/patika-legal/privacy/
- Terms: https://stanercelik.github.io/patika-legal/terms/
- Support: https://stanercelik.github.io/patika-legal/support/

İşletmeci Taner Çelik, iletişim tanercelik2001@gmail.com. Metin `docs/legal-draft/`
taslağından, koddaki gerçek veri akışıyla doğrulanarak yazıldı; hukukçu incelemesi yapılmadı.

**Anahtarlar:**

- Uygulama yalnız **public** `appl_…` anahtarını taşır (`AppConfiguration.revenueCatAPIKey`;
  `REVENUECAT_IOS_API_KEY` derleme ayarı tanımlanırsa o kazanır). `sk_…` kabul edilmez.
- Sunucu (Supabase Edge Function secrets): `REVENUECAT_PROJECT_ID`, `REVENUECAT_SECRET_API_KEY`
  (v2) ve `REVENUECAT_WEBHOOK_AUTH_TOKEN` tanımlı. Değerler yalnız sunucuda.

**Arka uç (25 Eylül, yayında):** `20260924120000_path_purchase_access` migration'ı uygulandı;
13 fonksiyon güncel kodla deploy edildi (`revenuecat-webhook` JWT doğrulaması kapalı).
RevenueCat webhook'u `whintgr3d9fb78ef0` → `/functions/v1/revenuecat-webhook`, gizli
`Authorization` başlığıyla. API HMAC imzalamayı açamadığı için fonksiyon iki yolu kabul
eder: `REVENUECAT_WEBHOOK_SIGNING_SECRET` tanımlanırsa HMAC zorunlu olur (panelden açılıp
secret'a yazılırsa), değilse başlık aranır (`_shared/webhook-auth.ts`, testli). Her
satın alma ayrıca RevenueCat v2 API'sinden doğrulanır.

**Açık kalanlar:**

- Test: Sandbox Apple ID ile gerçek cihaz (satın alma, iptal, Restore, `context = return`,
  AX5, VoiceOver, rounded font).

---

## 7. Kodda yapılanlar

| # | İş | Durum |
|---|---|---|
| 1 | Sıra `f2Roadmap → g1 → g2 → commitment → price → h1`; yarım G1'de `g2 → h1`; `price` sahnesi `.prepare` | yapıldı |
| 2 | `HoldToStartButton` F2'de; commitment'ta yeni metinler, işaret isteğe bağlı, eşik cümlesi | yapıldı |
| 3 | Katalog: `session.completedBody`, `commitment.body` yeniden; `commitment.holdToContinue`, `commitment.continueTransition` eklendi | yapıldı |
| 4 | Paywall ve Yolum'daki teklif kabuğu **tam ekran**; kabuk onboarding'in sahne + plakasıyla | yapıldı |
| 5 | Custom değişkenler `path_days`, `remaining_sessions`, `reminder_time`, `price_per_session`, `context` | yapıldı |
| 6 | `patika://support`: `OpenURLAction` ile paywall içinde yakalanır, paywall kapanır, `CrisisView` açılır (URL şeması gerekmez) | yapıldı |
| 7 | Dönüş noktaları: Yolum kilitli adım; Ben'de görselli `ContinuePathCard` (ilerleme izi, `me-continue-path` görseli, kayısı kenar + gölge) (1. adım bitmiş, ödenmemiş, kriz yok); 1. adım tekrarı bitince günde en fazla bir kez (kriz yok) | yapıldı |
| 8 | Analitik `paywall_shown`, `paywall_closed`, `purchase_started`, `purchase_verified` (`context` özelliğiyle) | yapıldı |
| 9 | Ara ekran yok: kabuk yüklenirken yalnız `bg-prepare` sahnesi + gösterge; RevenueCat paywall'ı animasyonsuz açılır ve kapanır. Plaka yalnız doğrulama/açık/yüklenemedi durumlarında. | yapıldı |

---

## 8. Ölçüm ve deneyler

**Huni:** F2 → G1 başladı → G1 tamamlandı → G2 → commitment tamamlandı → paywall
gösterildi → satın alma başladı → sunucu hakkı → 2. adım dinlendi → patika sonu.

| Oran | Ne söyler | Eşik |
|---|---|---|
| G1 tamamlama | Aha anına ulaşan pay; paywall görüntülenmesinin tavanı | < %70 ise önce ilk oturum düzeltilir |
| Commitment → paywall | Commitment'ın sürtünmesi | < %90 ise işaret alanı sadeleşir |
| Paywall → satın alma (`first`) | Asıl dönüşüm | — |
| `return` dönüşümü | Dönüş noktalarının değeri | — |
| İade oranı | Satışın kalitesi | — |

**Deney sırası** (~300 `first` gösterimden sonra; RevenueCat Experiments için offering'ler
placement'a taşınır: `offerings.currentOffering(forPlacement: "path_14d_first")` vb.):

1. **Fiyat noktası:** mevcut vs +%25. Tek ödemede en büyük kaldıraç.
2. **Commitment'lı vs commitment'sız:** G2'den doğrudan paywall'a geçmek.
3. **Başlık:** `Your path continues tomorrow at {time}.` vs `Your path can continue.`
4. **CTA:** `Continue my path · {price}` vs `Continue ›`.
5. **Seans başı fiyat satırı:** var vs yok.
6. **Exit offer** (yalnız veri gerektirirse): kapatınca bir kez, ayrı ve daha ucuz bir
   ürünle "%25 off this path". Kapatma alışkanlığı yaratıp yaratmadığı `return`
   dönüşümüyle izlenir.

---

## 9. Sonra: sosyal kanıt ve abonelik

- **Sosyal kanıt:** 20'den fazla gerçek App Store yorumu gelince plakanın altına tek
  gerçek alıntı. Ölçüm verisi birikince (Faz 0 kapısı), gerçek medyanla ve dipnotla
  "people who finished a path…" satırı.
- **Abonelik ("Patika Plus"):** tek ödemenin yanında denenecek bir seçenek. Değeri
  süreklilik: sınırsız kişisel patika (aynı anda 1 aktif), patikalar arası hafıza, uzun
  vadeli ilerleme, anlık kısa oturumlar (PRD §12.2). Paywall'a yalnız kodda **hazır
  olanlar** yazılır. Önerilen sunum: yıllık + 7 gün deneme (seçili) ile "yalnız bu
  patika" tek ödeme yan yana.
