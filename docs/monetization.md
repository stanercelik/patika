# Patika monetization — lansman karar kaynağı

**Karar:** 24 Eylül 2026. **İlk pazar:** İngilizce MVP; USD baz fiyat, kullanıcıya App Store'un yerel fiyatı. Bu belge eski gün 7 paywall'ı, F4 fiyat ekranını ve lansman aboneliği önerilerini geçersiz kılar.

## Ücretsiz değer ve satın alınan hak

İlk **tamamlanmış** kişisel oturum ücretsizdir. Tamamlanma, ilk adımın sunucuda kaydedilmesi ve G2 özetinin geçilmesidir. Yarım bırakılan oturum paywall tetiklemez. Akış **G2 → RevenueCat paywall → isteğe bağlı hesap bağlama → Yolum** şeklindedir. Paywall hemen kapatılabilir; kullanıcı hazır patikalara ve ücretsiz içeriğe geçip aynı kişisel patikayı sonra Yolum'dan satın alabilir.

Tek ödeme yalnız **o etkin kişisel patikanın** kalan adımlarını, ara ölçümlerini ve kullanıcının kendi başlangıcıyla karşılaştırmasını açar. Başka patikayı açmaz. İade sonrası ücretli erişim yeniden değerlendirilir; not ve ölçümler silinmez. Kova C ücretsiz devam hakkı ücretsiz kalır. Lansmanda abonelik, otomatik deneme, geri sayım, ikinci çıkış teklifi veya önceden seçilmiş plan yoktur.

| Uzunluk | App Store consumable ürün | ABD baz fiyat | RevenueCat offering |
| --- | --- | ---: | --- |
| 7 gün | `path.unlock.7d` | $7.99 | `path_7d` |
| 14 gün | `path.unlock.14d` | $11.99 | `path_14d` |
| 21 gün | `path.unlock.21d` | $14.99 | `path_21d` |
| 28 gün | `path.unlock.28d` | $18.99 | `path_28d` |

Her offering'de tek paket ve aynı tasarımın ilgili ürüne bağlı paywall'ı bulunur. Consumable ürünler genel bir `premium` entitlement'a bağlanmaz: böyle bir hak sonraki patikaları yanlışlıkla açabilir. RevenueCat işlem bilgisini, Patika sunucusu patikaya özgü hakkı yönetir.

## Paywall tasarımı ve metni

Satın alma ekranı RevenueCat editöründe yönetilir. `assets/illustrations/paywall/forest-path-after-first-step.png` yüklenir: ilk taşın ardından devam eden guaj orman patikası, koyu teal ve adaçayı, az sıcak kayısı ışığı. Görsel üstte; metin ve fiyat düz koyu zeminde, satın alma düğmesi krem renktedir. Kilit, kapı, bitiş çizgisi, video, hareketli satış efekti, uydurma sosyal kanıt ve sonuç vaadi yoktur. Uygulama içindeki teklif kabuğu da aynı görseli kullanır.

- Başlık: **Your path can continue.**
- Gövde: **The remaining {remaining_sessions} sessions, brief check-ins along the way, and a comparison with your own starting point.**
- Ana eylem: **Continue this path · {localized store price}**
- Alt açıklama: **One payment for this path. No subscription.**
- İlk ekrandan erişilebilir: kapatma, **Not now**, **Restore purchases**; gizlilik, koşullar ve destek bağlantıları App Store kaydıyla aynı olmalı.
- Güvenli değişkenler: `path_days`, `remaining_sessions`. Fiyat yalnız StoreKit ürününden gelir. Sorun metni, patika adı, ölçüm sonucu ve kriz bilgisi RevenueCat'e veya analitiğe gönderilmez.

Normal ve büyük Dynamic Type, VoiceOver, Reduce Motion ve Reduce Transparency ile gözden geçirilir. İllüstrasyon gizlense de tüm metin okunmalıdır. Satın alma dönüşünde sunucu hakkı yazana kadar **Checking your payment** gösterilir; bekleyen veya başarısız işlem kilidi açmaz ve tekrar deneme sunar.

## Kimlik, doğrulama ve geri getirme

RevenueCat Purchases ve RevenueCatUI uygulama açılışında mevcut Supabase UUID'siyle, anonim kullanıcı için de, yapılandırılır. Hesap bağlama aynı UUID'yi korur. Anonim satın alma açıktır. H1, yeni cihazda güvenilir erişim için hesabın bağlanmasını açıkça önerir: consumable alım yeni cihazda App Store makbuzundan kendiliğinden geri yüklenmez. Aynı hesaba bağlı sunucu hakkı geri getirilebilir. Bağlanmamış anonim kullanıcıya cihazlar arası geri getirme sözü verilmez.

StoreKit öncesinde `path-purchase-intent` kullanıcıyı, etkin `path_id`'yi, ürünü ve süreyi kaydeder. İmzalı RevenueCat webhook'u ayrıca sunucu API'sindeki işlemle doğrulanır; işlem ve olay kimlikleri tekilleştirilir, yalnız ilgili patikaya hak yazılır. İstemci yalnız `path-purchase-status` sorgular; satın alma callback'i kendi başına içerik açmaz. İade hakkı iptal eder. Webhook ve sunucu API sırları yalnız sunucudadır. Apple sunucu bildirimleri uzlaştırma için yapılandırılır.

Aynı hak kuralı ikinci ve sonraki kişisel adımın manifest okuma, ses üretimi, imzalı ses URL'si, tamamlama ve özel depolama yollarını kapatır. `completed_at` alanına doğrudan istemci güncellemesi yoktur. Hazır içerik, ilk adım tekrarı, Destek al ve kriz desteği ödeme dışıdır. Shipaton jüri hesabı ayrı, sunucuda doğrulanan RevenueCat promosyon hakkı gerektirir; istemci geçişi olamaz.

## Gerçek sağlayıcı maliyetleri ve ölçüm

Canlı kod TTS için ElevenLabs `eleven_v3`, planlama için Gemini `gemini-3.5-flash` kullanır; eski fal.ai Multilingual v2 varsayımı geçersizdir. Planlama için yayınlanmış liste oranları yaklaşık ElevenLabs v3 **$0.10 / 1.000 karakter**, Gemini 3.5 Flash standart ücretli kullanım **$1.50 / milyon giriş tokeni ve $9 / milyon çıkış tokeni**. Bunlar gözlemlenmiş Patika maliyeti değildir; önbellek, tekrar deneme, ses uzunluğu, vergiler, Apple komisyonu ve kur ölçülmelidir. Sunucuda üretilen karakter, token, tekrar deneme, hak ve iadeler sayılır; hassas sorun metni veya ölçüm cevabı kaydedilmez.

Huni: uygun G2 tamamlanması → paywall görünmesi → yerel fiyat görünmesi → StoreKit başlaması → başarı/bekleme/iptal → sunucu hakkı → ikinci adım → patika sonu. Ücretsiz çıkış, Yolum'dan geri dönüş, doğrulama hatası, çift webhook ve iade ayrıca ölçülür. Kriz veya Kova C anı dönüşüm hedefi yapılmaz.

## Yayınlama kapıları

1. App Store Connect: `com.tanercelik.patika` için dört consumable ürün, ABD fiyatları, açıklamalar, inceleme görselleri, satın alma anahtarı ve sunucu bildirimleri.
2. RevenueCat: iOS uygulaması ve Apple bağlantısı, dört tek ürünlü offering ve editör paywall'ı, illüstrasyon, uygulama için public iOS API key, imzalı webhook, Supabase için proje/API sırları. Fiyat StoreKit'ten gelmeli.
3. Backend: satın alma migration'ı, intent/status/webhook ve korunan adım/ses fonksiyonları yayına alınmalı; mevcut kişisel ve hazır yollar RLS altında doğrulanmalı.
4. Legal: ayrı, herkese açık `patika-legal` GitHub Pages deposunda İngilizce gizlilik, koşullar ve destek. Uygulama, paywall ve App Store aynı URL'leri kullanmalı. Gerçek işleyiciler, silme/dışa aktarma ve anonim consumable geri getirme sınırı anlatılmalı.
5. Shipaton: ABD App Store'da canlı uygulama, çalışan RevenueCat satın alma, herkese açık demo videosu, ekran görüntüleri ve jürinin ücretli içeriğe ücretsiz erişimi. Son başvuru **30 Eylül 2026, 23:45 PDT**; mağaza incelemesi daha önce tamamlanmalı.

Kabul: dört offering ve yerel fiyat; yalnız G2 sonrası gösterim; iptal/bekleme/ağ kopması/tekrar; çift webhook/iade; ilk adım tekrarı ve ücretsiz yollar; aynı patikaya tekrar ödeme istememe; ödenmemiş ikinci adımın sunucuda reddi. RevenueCat Test Store sonrasında Apple sandbox ve gerçek cihaz doğrulaması gerekir. iPhone 17 Pro derlemesi satın alma uçtan uca testi değildir.

## Kaynaklar

- [RevenueCat non-subscription purchases](https://www.revenuecat.com/docs/platform-resources/non-subscriptions)
- [RevenueCat restoring purchases](https://www.revenuecat.com/docs/getting-started/restoring-purchases)
- [RevenueCat Apple sandbox notes](https://www.revenuecat.com/docs/test-and-launch/sandbox/apple-app-store)
- [Apple App Privacy](https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy)
- [RevenueCat Shipaton submission](https://www.revenuecat.com/blog/engineering/how-to-submit-your-app-for-shipaton)
- [ElevenLabs API pricing](https://elevenlabs.io/pricing/api)
- [Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing)
