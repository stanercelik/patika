# Patika: RevenueCat, App Store ve Shipaton kurulum rehberi

**Durum: 24 Eylül 2026.** Bu rehber hesap sahipliği gerektiren işleri sıraya koyar. Kod tarafındaki satın alma akışı ve sunucu koruması yerel olarak hazır; **canlı Apple/RevenueCat kurulumu, yasal URL'ler, canlı sunucu dağıtımı ve gerçek cihaz satın alma testi henüz tamamlanmadı.** Kaynak kararlar: [monetization.md](monetization.md) ve [teknik yayın kontrol listesi](revenuecat-release-checklist.md).

Her kutuyu ancak altındaki **Bitti sayılır** koşulu sağlandığında işaretle. İlk canlı satın alma testine kadar yeni erişim migration'ını yayına alma; diğer sunucu fonksiyonlarıyla birlikte devreye alınmalı.

## 1. Apple hesabındaki satış engellerini kaldır

- [ ] [App Store Connect](https://appstoreconnect.apple.com/) → **Business → Agreements** bölümünde **Paid Apps Agreement** durumunu kontrol et. Kabul gerekiyorsa hesabın **Account Holder** kişisi kabul etmeli.
- [ ] Aynı bölümde banka ve vergi bilgilerinin tamamlandığını doğrula.
- [ ] **Apps** içinde Patika uygulaması var mı bak. Yoksa iOS uygulama kaydı oluştur; bundle ID **`com.tanercelik.patika`** olmalı. Var olan farklı bir bundle ID'li kaydı bu iş için kullanma.

**Bitti sayılır:** ücretli uygulama içi satın alma oluşturabiliyorsun; uygulama kaydındaki bundle ID yukarıdakiyle aynı. [Apple: ücretli uygulama anlaşması](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements)

## 2. Dört Apple ürününü oluştur

App Store Connect → **Apps → Patika → Monetization → In-App Purchases → +**. Her satır için **Consumable** seç. **Subscription** veya **Non-Consumable** seçme. Reference Name sadece yönetim panelinde görünür; Product ID tam eşleşmeli.

| Product ID | Reference Name / English Display Name | English Description | ABD baz fiyatı |
| --- | --- | --- | ---: |
| `path.unlock.7d` | Continue a 7-day path | Unlock the rest of this 7-day path. | $7.99 |
| `path.unlock.14d` | Continue a 14-day path | Unlock the rest of this 14-day path. | $11.99 |
| `path.unlock.21d` | Continue a 21-day path | Unlock the rest of this 21-day path. | $14.99 |
| `path.unlock.28d` | Continue a 28-day path | Unlock the rest of this 28-day path. | $18.99 |

- [ ] Her ürünün **English (U.S.)** yerelleştirmesine tablodaki Display Name ve Description'ı gir. Apple'ın açıklama sınırı 45 karakter; tablodaki metinler buna uyar.
- [ ] **Price Schedule → Add Pricing** altında baz ülkeyi **United States** seç, ilgili USD fiyatı ayarla. Diğer mağazaların yerel fiyatını Apple hesaplasın.
- [ ] **Availability** içinde en az **United States** açık olsun; lansman ülkelerini ayrıca seç.
- [ ] Her ürünün App Review screenshot ve inceleme notu alanını belirle; gerçek paywall çalışınca bunları **8. adımda** doldur. İlk kez gönderilen consumable ürünler uygulamanın ilk sürümüyle birlikte incelemeye gitmeli.

**Bitti sayılır:** dört ürünün ID, tür, USD fiyatı ve bölgesi doğru; inceleme görseli için ürünler hazır. Sandbox'a metaveri yansıması bir saate kadar sürebilir. [Apple: ürün oluşturma](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases), [fiyat](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase), [ilk IAP başvurusu](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)

## 3. Apple satın alma anahtarını RevenueCat'e bağla

- [ ] App Store Connect → **Users and Access → Integrations → In-App Purchase** içinde **In-App Purchase Key** oluştur. `.p8` dosyası yalnız bir kez indirilebilir; güvenli yerde sakla.
- [ ] Aynı sayfadaki **Key ID** ve **Issuer ID** değerlerini kaydet. Issuer ID görünmüyorsa RevenueCat'in [anahtar rehberindeki](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/in-app-purchase-key-configuration) adımları izle.
- [ ] RevenueCat'te Patika iOS uygulamasının **In-app purchase key configuration** bölümüne `.p8`, Key ID ve Issuer ID'yi yükle; **Valid credentials** sonucunu gör.
- [ ] Ürünleri otomatik içe aktarmak istersen ayrıca RevenueCat'in **App Store Connect API Key** bağlantısını kur. Bu, yukarıdaki satın alma anahtarından farklı bir bağlantıdır.
- [ ] RevenueCat'in Patika iOS uygulama ayarlarında **Apple Server to Server Notifications** için **Apply in App Store Connect** kullan. Otomatik kurulum olmazsa orada verilen URL'yi App Store Connect → **App Information → App Store Server Notifications** içindeki **Production** ve **Sandbox** alanlarına gir; Version 2 seç. Apple bildirim URL'si **RevenueCat URL'sidir**, aşağıdaki Supabase webhook URL'si değildir.

**Bitti sayılır:** RevenueCat Apple kimlik bilgilerini geçerli gösteriyor; Apple'ın production ve sandbox bildirimleri RevenueCat'e yönleniyor. [RevenueCat: satın alma anahtarı](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/in-app-purchase-key-configuration), [Apple bildirimleri](https://www.revenuecat.com/docs/platform-resources/server-notifications/apple-server-notifications)

## 4. RevenueCat projesini, ürünleri ve paywall'ları kur

- [ ] [RevenueCat Dashboard](https://app.revenuecat.com/) içinde mevcut Patika projesi varsa **onu** seç; yoksa yeni proje oluştur. **Apps** altında App Store uygulamasını bundle ID **`com.tanercelik.patika`** ile ekle.
- [ ] Dört App Store ürününü **Product catalog → Products** içine al. Türleri **consumable** olmalı.
- [ ] **Product catalog → Offerings** altında şu dört offering'i oluştur. **Offering Identifier** alanına tablodaki `path_...` değerini gir; `lifetime` yazma. Her offering'e **tam bir** paket ekle. Paket ekleme ekranında **Identifier** açılır listesinden **Custom** seç (örneğin `path_unlock_7d`); `Lifetime` seçme. Ardından karşısındaki **tek** ürünü bağla:

| Offering ID | Custom package ID | Tek ürün |
| --- | --- | --- |
| `path_7d` | `path_unlock_7d` | `path.unlock.7d` |
| `path_14d` | `path_unlock_14d` | `path.unlock.14d` |
| `path_21d` | `path_unlock_21d` | `path.unlock.21d` |
| `path_28d` | `path_unlock_28d` | `path.unlock.28d` |

- [ ] Bu dört consumable ürüne genel `premium` entitlement'ı bağlama. Patika erişimi sunucuda tek `path_id` için verilir; genel kalıcı entitlement başka patikaları yanlışlıkla açar.
- [ ] **Paywalls → Create paywall** ile ilk offering'e tek ekranlı paywall oluştur. [Guaj orman görselini](../assets/illustrations/paywall/forest-path-after-first-step.png) üstte kullan. Alt alan düz koyu teal/orman tonu; yazı kırık beyaz; ana düğme krem olsun. Gradyan, video, geri sayım, kilit ve ikinci çıkış teklifi ekleme.
- [ ] Metinleri birebir gir: **“Your path can continue.”** / **“The remaining {{ custom.remaining_sessions }} sessions, brief check-ins along the way, and a comparison with your own starting point.”** / **“Continue this path · {{ product.price }}”** / **“One payment for this path. No subscription.”** RevenueCat editörü değişken eklerken kendi seçicisini kullan; fiyatı sabit `$` metnine dönüştürme.
- [ ] Editörde **Paywall logic → Variables** altında sadece `path_days` ve `remaining_sessions` özel değişkenlerini oluştur. İkisi de sayı olsun. Sorun metni, patika adı, ölçüm skoru veya kriz bilgisi ekleme.
- [ ] İlk görünümde **Close**, **Not now**, **Restore purchases** ve gizlilik, koşullar, destek bağlantıları için alanı erişilebilir yerleştir. Yasal URL'leri 5. adımda yayınlandıktan sonra ekle. Her kontrolün en az 44×44 pt dokunma alanı ve okunur etiketi olsun.
- [ ] Paywall'ı diğer üç offering için kopyala ve doğru offering'e bağla. **Draft** olarak tut; yasal URL'ler eklenince 5. adımda yayınla. Fiyatı ve alt metni küçük ekran, büyük yazı ve VoiceOver ile gör.

**Bitti sayılır:** her offering'de tek paket ve beklenen ürün var; dört paywall taslağı doğru offering'e bağlı. Patika uygulaması, 5. adımda yayınlanmadan bu paywall'ları açmaz. [RevenueCat: tek seferlik ürünler](https://www.revenuecat.com/docs/platform-resources/non-subscriptions), [paywall yayınlama](https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls), [fiyat ve özel değişkenler](https://www.revenuecat.com/docs/tools/paywalls/creating-paywalls/variables)

**24 Eylül 2026 gerçekleşen durum:** Patika projesinde dört consumable ürün, dört tek ürünlü offering ve her offering'e bağlı birer **yayınlanmamış taslak** oluşturuldu. `path_days` ve `remaining_sessions` sayı değişkenleri tanımlı. Düğmedeki `{{ product.price }}` mağaza fiyatını kullanır; aşağıdaki statik görsel oluşturucu bu fiyatı göstermediğinden gerçek cihazda StoreKit fiyatı ayrıca doğrulanmalı.

| Offering | Paywall taslağı | Bağlı paket |
| --- | --- | --- |
| `path_7d` | [Patika · 7-day path](https://app.revenuecat.com/projects/898e5829/paywalls/pw90b35a2daa0f4be2/builder) | `path_unlock_7d` |
| `path_14d` | [Patika · 14-day path](https://app.revenuecat.com/projects/898e5829/paywalls/pwc3b073075134453b/builder) | `path_unlock_14d` |
| `path_21d` | [Patika · 21-day path](https://app.revenuecat.com/projects/898e5829/paywalls/pwa49e7bb0740e4852/builder) | `path_unlock_21d` |
| `path_28d` | [Patika · 28-day path](https://app.revenuecat.com/projects/898e5829/paywalls/pwef6ffd359de943b7/builder) | `path_unlock_28d` |

RevenueCat AI, onaylı önizlemeye yakın yeni bir guaj orman görseli oluşturdu; depodaki **asıl** illüstrasyon henüz RevenueCat medya kütüphanesine yüklenmedi. Tam görsel eşleşmesi için [asıl dosya](../assets/illustrations/paywall/forest-path-after-first-step.png) ile değiştirme adımı açık. Taslak editöründe Privacy ve Terms bağlantıları için iki URL eksikliği gösteriliyor; açık yasal sayfalar yayınlanmadan paywall'ları yayınlama. App Store Connect'te 7 günlük ürün `READY_TO_SUBMIT`, diğer üç ürün `MISSING_METADATA` durumunda; 14/21/28 günlük ürünlerin inceleme görselleri eksik ve 28 günlük ürünün mağaza görünen adı ürün ID'si olarak kalmış. ABD fiyatları dört üründe de planlanan tutarlarda.

## 5. Açık yasal sayfaları yayınla

- [ ] [Gizlilik](legal-draft/privacy.md), [koşullar](legal-draft/terms.md) ve [destek](legal-draft/support.md) taslaklarını gözden geçir. Gerçek **hukuki işletmeci adı**, **herkese açık destek e-postası**, **yayın tarihi**, **veri işleyicileri / bölgeleri** ve **silme sonrası saklama süresi** alanlarını doğrula. Köşeli parantezli hiçbir alan kalmasın.
- [ ] GitHub'da ayrı bir **public `patika-legal`** deposu oluştur. İncelenmiş sayfaları bu depoya yayınlanabilir web sayfaları olarak koy; **Settings → Pages → Deploy from a branch → main → /(root)** ayarını aç. GitHub oturumu erişilebilir olduğunda siteyi ben de hazırlayıp yayınlayabilirim.
- [ ] Üç URL'yi gizli pencereyle açıp herkesin erişebildiğini kontrol et. Aynı **Privacy**, **Terms** ve **Support** URL'leri uygulamaya, RevenueCat paywall'larına ve App Store Connect kaydına girilmeli.
- [ ] Bu URL'leri dört RevenueCat paywall taslağına ekle ve her birini **Publish Paywall** ile yayınla. Yayından sonra dört offering için paywall'ın mevcut olduğunu kontrol et.
- [ ] App Store Connect → **App Privacy** bölümünde Privacy Policy URL'yi gir ve gerçek veri işleme cevaplarını doldur. RevenueCat ile diğer gerçek hizmet sağlayıcılarını hesaba kat.

**Bitti sayılır:** üç sayfa halka açık, içerikte boş alan yok, bağlantılar uygulama/paywall/mağazada aynı. Apple iOS uygulaması için gizlilik URL'si zorunludur. [GitHub Pages yayın kaynağı](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site), [Apple App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)

## 6. Gizli anahtarları sunucuda sakla; canlı dağıtımı birlikte yapalım

RevenueCat **Project ID** (`proj...`) ve **public Apple SDK key** (`appl_...`) değerlerini not al. Public key uygulamanın `REVENUECAT_IOS_API_KEY` derleme ayarına girilecek. Project ID'yi ve public key'i bana iletebilirsin.

- [ ] RevenueCat → **Project settings → API keys** içinde v2 **Secret API Key** oluştur. Sadece satın alma okuma izni (`customer_information:purchases:read`) ver. Supabase **Edge Function Secrets** içine `REVENUECAT_SECRET_API_KEY` adıyla kaydet.
- [ ] Shipaton jürisi için süreli promosyon kullanacaksak RevenueCat v1 secret API key'i de `REVENUECAT_V1_SECRET_API_KEY` olarak Supabase'e kaydet; RevenueCat'te yalnız jüri için `shipaton_review` entitlement oluştur. Bu, dört ücretli ürüne bağlanmaz.
- [ ] Supabase projesi **`aapxqeqduphafisyaadk`** içinde `REVENUECAT_PROJECT_ID` değerini `proj...` olarak kaydet.
- [ ] RevenueCat → **Integrations → Webhooks → Add new configuration**: URL `https://aapxqeqduphafisyaadk.supabase.co/functions/v1/revenuecat-webhook`. **Production ve Sandbox** olaylarını gönder. **HMAC webhook signing** aç; bir kez gösterilen signing secret'ı `REVENUECAT_WEBHOOK_SIGNING_SECRET` adıyla Supabase'e kaydet. Satın alma, iade/cancellation ve refund reversal olaylarını dahil et.
- [ ] Gizli değerleri **sohbete, GitHub'a, Xcode'a veya ekran görüntüsüne koyma**. Supabase panelindeki secret değerleri olarak gir. Apple `.p8` dosyası da yalnız Apple ↔ RevenueCat bağlantısında kullanılmalı.
- [ ] Bunlar tamamlanınca bana “**Apple ürünleri, RevenueCat ve Supabase sırları hazır**” de. Ben migration ile `path-purchase-intent`, `path-purchase-status`, `revenuecat-webhook`, `complete-step` ve `generate-audio` fonksiyonlarını aynı yayın adımında devreye alıp canlı duman testi yapacağım. Webhook için Supabase platform JWT kontrolü **kapalı**; niyet/durum fonksiyonlarında **açık** olacak. Webhook kendi HMAC imzasını denetler.

**Bitti sayılır:** dört sunucu değeri Supabase'te, public key uygulamada, webhook doğru URL'ye gidiyor; canlı dağıtım sonrası istekler doğrulanıyor. [RevenueCat API anahtarları](https://www.revenuecat.com/docs/projects/authentication), [v2 satın alma okuma izni](https://www.revenuecat.com/docs/api-v2/purchase), [imzalı webhook](https://www.revenuecat.com/docs/integrations/webhooks), [Supabase fonksiyon ayarı](https://supabase.com/docs/guides/functions/function-configuration)

## 7. Gerçek cihazda Apple sandbox satın almasını doğrula

- [ ] App Store Connect → **Users and Access → Sandbox** altında test Apple hesabı oluştur. Kişisel Apple hesabını test satın alması için kullanma.
- [ ] Güncel uygulamayı gerçek iPhone'a TestFlight ya da geliştirme derlemesiyle yükle. İlk kişisel oturumu **tamamla** ve G2 özetini geç: paywall yalnız o anda görünmeli. G2'ye gelmeden kapat/aç ve paywall çıkmadığını doğrula.
- [ ] Dört patika uzunluğunun her birinde doğru ürün ve Apple satın alma sayfasındaki fiyatı kontrol et. **Not now** anında kapatmalı; ücretsiz hazır içerik, Destek al ve kriz desteği açık kalmalı.
- [ ] Bir sandbox satın alması yap. Satın alma başarılı olsa bile ücretli ikinci adım, sunucu doğrulaması tamamlanmadan açılmamalı. Daha sonra aynı patikanın ikinci adımını aç; başka patikayı açmamalı. Aynı patika tekrar ödeme istememeli.
- [ ] İptal, bekleyen işlem, çevrimdışı dönüş ve geri yükleme açıklamasını dene. Tüketilebilir ürün başka cihazda mağaza makbuzundan kendiliğinden geri gelmez; aynı Supabase hesabına bağlanan erişim geri gelir. Test kullanıcısının gerçek sorunu veya ölçümünü RevenueCat olaylarında arama; gönderilmemeli.
- [ ] İade ve çift webhook durumlarını birlikte doğrulayalım. Sandbox fiyat metaverisi bazen hatalıdır; paywall, Apple satın alma sayfası ve test hesabının mağaza bölgesini birlikte karşılaştır.

**Bitti sayılır:** gerçek cihazda uçtan uca satın alma ve sunucu hakkı çalışıyor; ücretsiz yollar açık; iade ücretli erişimi kapatıp kullanıcının not/ölçümünü koruyor. [RevenueCat Apple sandbox](https://www.revenuecat.com/docs/test-and-launch/sandbox/apple-app-store), [consumable geri getirme sınırı](https://www.revenuecat.com/docs/getting-started/restoring-purchases)

## 8. App Review ve Shipaton gönderimi

- [ ] Her IAP için gerçek uygulamadan **App Review screenshot** ve şu inceleme notunu ekle: “Complete the first personal session and pass the G2 summary to see this one-time, path-specific purchase. Not now closes it immediately.”
- [ ] App Store Connect sürüm kaydına uygulama ekran görüntülerini, destek ve gizlilik URL'lerini, App Privacy cevaplarını, yaş sınıflandırmasını ve inceleme notlarını ekle. İlgili **dört IAP'yi ilk uygulama sürümüyle beraber** incelemeye gönder.
- [ ] App Review notunda yolu açıkla: “Start a personal path → finish the first session → pass the G2 summary → paywall. Not now closes it; Restore purchases is visible. A purchase opens only this path.” Satın alma akışına erişmek için gereken test hesabı veya adımlar varsa Apple'a inceleme alanından ver.
- [ ] Onaydan sonra uygulamanın **ABD App Store'da canlı** olduğunu farklı bir cihazdan kontrol et. TestFlight, standart Shipaton başvurusu için yeterli değil.
- [ ] Jüri için ayrı test kullanıcısının gerçek RevenueCat App User ID'sini al. İlk oturumdan sonra `shipaton_review` promosyonunu **bitiş zamanı belirleyerek** verelim; sunucu yalnız o kullanıcı/patika için süreli erişim yazmalı. Jüri yolunu başvurmadan önce gerçekten dene.
- [ ] Herkese açık YouTube/Vimeo demo videosu, 1024×1024 ikon, en az bir 1179×2556 çerçevesiz ekran görüntüsü, RevenueCat Project ID, ABD App Store URL'si ve jüri ücretsiz erişim talimatını hazırla. Devpost taslağını erken aç; son başvuru **30 Eylül 2026, 23:45 PDT**. Mağaza incelemesi bundan **önce** tamamlanmış olmalı.

**Bitti sayılır:** canlı mağaza bağlantısı ve gerçek satın alma çalışıyor; jüri ücretsiz ücretli içeriği görebiliyor; Devpost başvurusu gönderilmiş. [RevenueCat Shipaton rehberi](https://www.revenuecat.com/blog/engineering/how-to-submit-your-app-for-shipaton)

## Bana iletmen yeterli olan bilgiler

Gizli anahtar göndermeden şu beş bilgiyi ilet: **(1)** mevcut RevenueCat projesinin ID'si (`proj...`) veya henüz yoksa “yeni proje”, **(2)** public Apple SDK key (`appl_...`), **(3)** yasal işletmeci adı, **(4)** herkese açık destek e-postası, **(5)** yayınlanmış Privacy/Terms/Support URL'leri. Supabase sırlarını kendi paneline kaydettiğinde yalnız **“sırlar girildi”** diye haber ver. Böylece uygulama bağlantıları, canlı sunucu dağıtımı ve gerçek cihaz doğrulamasını sırayla tamamlayabiliriz.
