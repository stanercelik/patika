# Patika paywall görsel kılavuzu

> **Yerini aldı:** sayfa düzeni, metin ve RevenueCat kurulumu için [`paywall-stratejisi.md`](./paywall-stratejisi.md) geçerlidir. Bu belge yalnız mevcut görsellerin üretim promptları için saklanıyor.

**Durum:** 24 Eylül 2026 tasarım teslimi. RevenueCat ekranını ürün sahibi kuracak. Bu belge tasarım ve metin kaynağıdır; ürün, fiyat ve erişim kararlarında [`monetization.md`](./monetization.md) geçerlidir.

## Referanstan alınan yapı

Gönderilen örneğin güçlü tarafı, üstte sıcak bir illüstrasyon, altında tek bakışta okunan kısa fayda satırları ve en altta açık bir satın alma kararı sunması. Patika bu düzeni **tek gerçek paywall** içinde kullanır. Referanstaki beyaz/lila palet, meditasyon yapan kişi, yıllık/haftalık seçimler, “ücretsiz hafta”, yıldızlar, kullanıcı sayısı ve yüzdeli sonuç iddiaları kullanılmaz. Patika bir meditasyon kütüphanesi veya abonelik değildir; bu iddialar ürün kararına ve doğrulanmış verilere uymaz.

Önerilen akış: **G2 (ilk oturumun sakin kapanışı) → RevenueCat paywall → isterse hesap bağlama → Yolum.** G2’de bir satış vaadi veya ikinci “Continue” perdesi eklenmez. Uygulamadaki teklif kabuğu, RevenueCat yüklenirken veya paywall kapatıldıktan sonra görülebilir; ayrı bir zorunlu tanıtım adımı olmamalıdır.

## Görsel dosyalar

| Dosya | Görev | Kullanım |
| --- | --- | --- |
| [`first-stone-vignette-v1.png`](../assets/illustrations/paywall/first-stone-vignette-v1.png) | İlk taş ve devam eden orman yolunun şeffaf guaj vinyeti, 1122 × 1402 PNG | G2/teklif kabuğu gibi uygulama içi ekranlarda merkez illüstrasyonu; yaklaşık 210–260 pt yüksek, `contain`. RevenueCat ekranında ikinci büyük görsel olarak tekrarlama. |
| [`forest-canopy-v1.png`](../assets/illustrations/paywall/forest-canopy-v1.png) | Üst kenardan sarkan şeffaf orman örtüsü, 2172 × 724 PNG | RevenueCat paywall üstünde 115–155 pt yüksek dekoratif başlık; `contain` veya genişliğe göre ölçekle. Alt boşluğu kırpılabilir. |
| [`forest-path-after-first-step.png`](../assets/illustrations/paywall/forest-path-after-first-step.png) | Onaylı tam sayfa orman resmi, 941 × 1672 PNG | Uygulama içi teklif kabuğunda tam ekran alternatif. Yeni paywall’da canopy ile aynı anda kullanma; iki ayrıntılı görsel metni ezer. |

İlk iki yeni görsel gerçek saydam kenarlı PNG’dir. RevenueCat editöründe görüntü arkasına düz `#101918` yerleştir. Görsellerin içine metin veya fiyat gömülmedi; dört offering aynı görselleri kullanabilir.

## Renk ve tipografi

Kodda kullanılan `WoodlandStyle` ve `Theme` değerleri temel alınır:

| Rol | Renk | Nerede |
| --- | --- | --- |
| Ana zemin | `#101918` | Paywall’ın tamamı; düz renk, gradyan yok |
| İkincil yüzey | `#1B2928` | Tek ürün özeti kartı |
| Ana metin | `#F2EFE9` | Başlıklar ve temel açıklamalar |
| Sönük metin | `#B9C4BF` | Açıklama ve alt bilgi; minimum kontrastı cihazda doğrula |
| Adaçayı | `#9BAE9B` | Küçük çizgi/ikon vurguları |
| Kayısı | `#E9BA8F` | İllüstrasyonda hafif ışık; CTA veya fiyat rozeti için kullanma |
| Satın alma düğmesi | `#EDE7D9` | Tek açık, en güçlü eylem yüzeyi |
| Düğme metni | `#203C36` | Krem düğme üzerinde |

Metin ailesi uygulamadaki yuvarlatılmış SF sistem yazısıdır. Editör yalnız standart sistem fontu sunuyorsa SF Pro kullan; ayrı bir gösterişli font yükleme. Başlık ilk ekranda yaklaşık 30–34 pt semibold/bold; fayda başlıkları 16–17 pt semibold; açıklamalar 14–15 pt medium; düğme 16–17 pt bold. Bunlar başlangıç değerleri, sabit boyut sözleşmesi değil: büyük yazı boyutunda metin büyümeli ve sayfa kaymalıdır. Satır aralığı ferah, harf aralığı doğal olsun. Başlık sola hizalı; merkez hizası yalnız üst görselde.

## RevenueCat ekranı: yukarıdan aşağıya

393 pt genişliğinde telefon için başlangıç şablonu. Yatay güvenli boşluk **24 pt**. Satın alma alanı dar ekranda kaydırma içinde kalsa bile ekran açıldığında düğmeye ulaşmak kolay olmalı; hiçbir metin görselin üstüne binmemeli.

1. **Üst dekor:** `forest-canopy-v1.png`, tam genişlikte, yaklaşık 125–145 pt görünür yüksek. Durum çubuğu ve kapatma düğmesi için boşluk bırak. Bu yalnız dekor; VoiceOver’dan gizle.
2. **Kapatma:** sağ üstte en az 44 × 44 pt dokunma alanlı `×`, ekran açıldığı anda etkin. Sol üst de olabilir, fakat tüm dört paywall’da aynı yerde kalsın. VoiceOver etiketi: “Close offer”.
3. **Başlık:** `Your path can continue.` Başlığın ilk satırı üst örtüden sonra başlar; iki satırı geçmez. Yaklaşık 20–24 pt üst aralık.
4. **Kısa giriş:** `One payment opens the rest of this path.` Başlık altında 8–10 pt. Bu cümle, dört fayda satırı eklemeye gerek bırakmaz.
5. **Üç fayda satırı:** 16 pt dikey aralık. Solda tek renk adaçayı çizgi simgesi veya sadece ince bir işaret; sağda kısa başlık + bir satırlık açıklama. Satırları kart içine hapsetme.
   - **More sessions on your path** — `The remaining {remaining_sessions} personal sessions.`
   - **Brief check-ins** — `Make room to notice how things shift along the way.`
   - **Your own comparison** — `Later, look back at where you started.`
6. **Tek ürün özeti:** `#1B2928` düz yüzey, 1 pt `#60716B` kenarlık, 18–20 pt köşe yarıçapı, 16 pt iç boşluk. Sol üst: `Your {path_days}-day path`. Altına `One-time purchase`. Sağda **mağazadan gelen yerel fiyat**. Radyo düğmesi, “selected”, “best value” veya başka plan kartı yok. 12–16 pt sonra CTA.
7. **Satın alma düğmesi:** tam genişlik, en az 56 pt yükseklik, krem `#EDE7D9` yüzey; metin `Continue this path · {localized store price}`. Fiyat, Apple/RevenueCat ürün fiyatı değişkeninden gelir; dolar simgesi ve fiyatı metne elle yazma.
8. **Dürüst alt satır:** düğmenin hemen altında `One payment for this path. No subscription.` Bu satır 14 pt civarında, okunur kontrastla.
9. **Çıkış ve yardımcı eylemler:** `Not now` ayrı, en az 44 pt dokunma alanlı metin düğmesi. `Restore purchases` görünür ve çalışır. Bunlar ilk anda erişilebilir; kaydırma veya zamanlayıcı arkasına saklanmaz. Restore ekranının başka cihazdaki anonim consumable alımı otomatik bulacağı söylenmez.
10. **Yasal alt satır:** `Privacy Policy · Terms of Use · Support`; her biri gerçek herkese açık URL’ye gider. Alt güvenli alanda sıkışmasın.

### RevenueCat metin alanlarına yapıştırılacak İngilizce kopya

RevenueCat’te `path_days` ve `remaining_sessions` adlarıyla **Number** türünde iki custom variable aç. Önizleme varsayılanları sırasıyla `7` ve `6` olabilir; uygulama canlı değerleri zaten gönderir. Fiyat için ürün değişkenini kullan. [RevenueCat değişken sözdizimi](https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/variables) bunu destekler.

| Bileşen | Tam metin |
| --- | --- |
| Başlık | `Your path can continue.` |
| Giriş | `One payment opens the rest of this path.` |
| Fayda 1 başlık | `More sessions on your path` |
| Fayda 1 açıklama | `The remaining {{ custom.remaining_sessions }} personal sessions.` |
| Fayda 2 başlık | `Brief check-ins` |
| Fayda 2 açıklama | `Make room to notice how things shift along the way.` |
| Fayda 3 başlık | `Your own comparison` |
| Fayda 3 açıklama | `Later, look back at where you started.` |
| Ürün kartı başlığı | `Your {{ custom.path_days }}-day path` |
| Ürün kartı alt satır | `One-time purchase` |
| Ürün kartı fiyatı | `{{ product.price }}` |
| Satın alma düğmesi | `Continue this path · {{ product.price }}` |
| Düğme altı | `One payment for this path. No subscription.` |
| İkincil eylemler | `Not now` · `Restore purchases` |
| Bağlantılar | `Privacy Policy` · `Terms of Use` · `Support` |

RevenueCat editör önizlemesi yeni Apple ürünlerinde örnek fiyat gösterebilir; canlı cihaz mağazanın yerel fiyatını alır. Uygulama paywall’ı **sheet** içinde gösterdiği için editörde hem sheet hem tam ekran önizlemesini kontrol et. [RevenueCat editör ve önizleme açıklaması](https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls)

### Düzenin kısa çizimi

```text
┌─────────────────────────────────────┐
│  orman örtüsü                  [ × ]  │
│                                     │
│  Your path can continue.            │
│  One payment opens the rest ...     │
│                                     │
│  ─  More sessions on your path      │
│     The remaining {n} ...           │
│  ─  Brief check-ins                 │
│     Make room to notice ...         │
│  ─  Your own comparison             │
│     Later, look back ...            │
│                                     │
│  ┌ Your {days}-day path   {price} ┐ │
│  │ One-time purchase             │ │
│  └───────────────────────────────┘ │
│  [ Continue this path · {price}   ] │
│  One payment ... No subscription.   │
│  Not now · Restore purchases        │
│  Privacy · Terms · Support           │
└─────────────────────────────────────┘
```

Bu çizim hiyerarşiyi anlatır; küçük ekran veya büyük Dynamic Type’ta sabit yükseklik zorlanmaz. Gerekirse fayda açıklamaları iki satıra geçer ve sayfa kayar. Kapatma ve “Not now” her zaman erişilebilir kalır.

## G2 ve teklif kabuğu için metin

Örnekteki ilk iki ekranın görsel ritmi istenirse **mevcut** ekranlara uygulanır; araya yeni zorunlu sayfa konmaz.

**G2, ücretsiz ilk oturumun kapanışı:** `Your first step is complete.` / `This first session is yours. You can pause here.` Alt eylem: `Continue` (mevcut akışa ilerler). `first-stone-vignette-v1.png` 210–240 pt civarında, görsel kutu merkezinde kullanılabilir. Bu ekranda fiyat, yıldız, sosyal kanıt, sonuç yüzdesi ve aciliyet yoktur.

**Uygulama içi teklif kabuğu, yalnız paywall kapatılıp teklif daha sonra yeniden açıldığında veya yüklenirken:** `The path is still here.` / `You can return to the remaining sessions when you’re ready.` Eylem: `View this path’s offer`; ikincil: `Not now`. Buradaki resim `first-stone-vignette-v1.png` olabilir. Gerçek fiyat ve satın alma düğmesi RevenueCat ekranında kalır; iki ayrı ödeme kararı gibi görünmemeli.

## Dört ürün için bağlama

Her paywall aynı düzeni ve görselleri kullanır. `path_7d`, `path_14d`, `path_21d`, `path_28d` offering’lerinin her birinde yalnız kendi tek consumable ürünü olmalı. `{path_days}` ve `{remaining_sessions}` yalnız sayıdır; kullanıcının sorun metni, patika adı, ölçüm puanı veya kriz bilgisi editöre/RevenueCat değişkenlerine gitmez. `{localized store price}` yalnız mağaza ürünü alanıdır. Örnek 7 gün/6 kalan oturum metni yalnız tasarım kontrolü içindir; canlı metne “6” ve `$7.99` yazılmaz.

## Editor ve inceleme kontrolü

- Üst görseli `contain` ile yerleştir; otomatik `cover` kırpması çiçekleri ve kapatma alanını kapatıyorsa görünür yüksekliği azalt. Görsel tıklanabilir öğe değildir.
- Kapatma, `Not now`, `Restore purchases`, Privacy, Terms ve Support bağlantılarını hem normal hem büyük yazıda dene. En az 44 pt hedef koru.
- VoiceOver sırası: kapatma → başlık → kısa giriş → üç fayda → ürün/fiyat → satın alma → ücret açıklaması → çıkış/geri yükleme → yasal bağlantılar. Dekoratif iki resmin alternatif metni boş olsun.
- Reduce Motion’da hareket ve parallax yok; Reduce Transparency’de bütün zeminler zaten düz renk. Gradyan, sayaç, titreşimli CTA ve otomatik kayan carousel yok.
- Fiyat görünmüyor veya mağaza ürünü yüklenemiyorsa satın alma düğmesinde sahte fiyat gösterme; hata/yeniden deneme ve ücretsiz çıkış erişilebilir kalsın.
- Satın alma sonrası “Checking your payment” durumu, sunucu hakkı doğrulanana kadar devam eder. İade, iptal veya bekleyen ödeme durumunda yanlış “unlocked” ifadesi gösterilmez.

## Üretim promptları

Yeni dosyalar yerleşik `image_gen` ile üretildi. Kullanılan tam promptlar:

**Taş vinyeti**

> Use case: illustration-story. Asset type: isolated gouache hero vignette for a premium iOS wellbeing app named Patika, to be placed on a solid dark forest-teal background. Create a painterly gouache illustration of a single broad, natural first stepping stone in the foreground and a gently winding forest footpath continuing into a quiet grove. Modest ferns, sage foliage, a few tiny cream wildflowers, warm apricot sunlight in the distance. Rich but restrained texture, handcrafted editorial book illustration, not vector art, not cartoon. Composition: compact centered organic silhouette, portrait 4:5; subject fills the middle 75%, generous genuinely transparent margin all around, especially top for UI text. Keep the far path open, no gate, lock, finish line, destination or person. Palette deep teal #172522, pine #263A35, sage #718276, muted ochre #B9955E, tiny apricot #D8A16F, warm cream #F2EFE9. Transparent background with real alpha outside the painted vignette; no square backdrop, no white halo, no hard rectangle, no vignette gradient. No text, no logos, no UI, no border, no watermark.

**Üst orman örtüsü**

> Use case: illustration-story. Asset type: decorative top-edge canopy overlay for the final purchase screen of the Patika iOS app; placed over solid deep teal #172522. A wide shallow garland of natural woodland foliage entering only from the very top edge and upper corners: fine sage and dark pine leaves, a few hanging seed pods, small cream woodland flowers, restrained muted ochre and warm apricot highlights. Hand painted gouache / editorial book illustration, organic irregular edges, sophisticated and quiet. No pastel lavender, no purple, no human figure. Composition wide landscape approximately 3:1, foliage confined mainly to top 35-40% and side edges, with the lower center completely empty transparent space for the title beneath. Genuinely transparent alpha everywhere outside the painted plants; no visible rectangular background, no soft glow, no gradient, no white halo. Detailed but not busy. No text, no UI, no device frame, no logo, no watermark.
