# "Ben" sekmesi v2: kimlik kartı, defter sayfası, rozetler, bütünleşik ayarlar

## Bağlam

Ürün sahibi "Ben" sekmesini yeniden düzenlemek istiyor. Bugünkü sayfanın sorunları:
- Üstte "Ben" etiketi olan büyük krem kapak var, illüstrasyon yer kaplıyor.
- Defter alıntıları profil sayfasının ortasına dökülüyor.
- "Yürüdüğün yollar" ve "Sana göre ayarlananlar" sayfayı uzatıyor.
- Sürüm yazısı profilde duruyor.
- Ayarlar sistem List'i ve nötr renklerle çiziliyor; uygulamanın geri kalanından kopuk.

Hedef, kompakt bir profil:
- Kimlik kartı: fotoğraf, ad, yolculuğun hangi adımda olduğu.
- İllüstrasyonlu defter kartı. Kapağı açılarak ayrı bir defter sayfasına geçiyor; kullanıcı orada kendi notlarını da yazabiliyor.
- Kilometre taşı rozetleri ve nazik bir haftalık seri.
- Ayarlar Patika'nın koyu orman ve adaçayı diliyle çiziliyor.

Referanslar Mobbin'den (birebir kopyalanmıyor):
- Kimlik kartı: pliability'nin yolculuk kartı ([ekran](https://mobbin.com/screens/d660100c-22ff-4c88-8baa-86babdba16e1)).
- Defter kartı: Bears Gratitude'un illüstrasyonlu kartı ([ekran](https://mobbin.com/screens/1ba3d436-c16a-43f3-b42a-438715486936)) ve Tolan'ın defter sayfası ([ekran](https://mobbin.com/screens/f7a04ec5-9070-46fe-8931-b30e8065e5b6)).
- Rozetler: stoic.'in sade rozet rafı ([ekran](https://mobbin.com/screens/4f2d0d12-94b1-410a-b34c-e8f1d6f38dbb)) ve Fitbit'in kilitli/açık rozet listesi ([ekran](https://mobbin.com/screens/439e6107-d27c-443f-82eb-90ecc8c09346)).
- Ayarlar: Tide Guide ([ekran](https://mobbin.com/screens/cce4ab10-6d4a-4f25-a0a4-1b70483ca75c)) ve HYPE ([ekran](https://mobbin.com/screens/3cf1055e-d4d6-489e-9ecc-8930a2aecc76)), sürüm yazısı en altta.

## Onaylanan kararlar (2026-09-19)

| Konu | Karar |
|---|---|
| Üst başlık | "Ben" etiketi ve büyük kapak illüstrasyonu kalkıyor |
| Kimlik kartı | Fotoğraf, ad, yol adı, "N. adım · faz", mini iz ve haftalık ritim noktaları |
| Profil resmi | Supabase Storage, özel kova, sahibine RLS ile, imzalı URL |
| Defter | Ayrı sayfa. Mevcut cevaplar + kullanıcının kendi notları, sunucuda şifreli. Her not kriz sınıflandırıcısından geçiyor |
| Defter kartı | İllüstrasyonlu, bulanık önizleme. Basınca kapak 3D açılıyor, ardından zoom geçişi |
| Yürüdüğün yollar | Kalkıyor; yerine rozetler geliyor |
| Gamification | Serbest: kilometre taşı rozetleri, nazik seri, rozet kutlaması. **Yasak kalanlar:** toplam sayılar, lig/kıyas, sıfırlanan ilerleme, kayıp bildirimi, sahte aciliyet, can/enerji |
| Rozet animasyonu | Lottie ve özel damga animasyonu yok. Sade native beliriş + tek yumuşak haptik |
| Rozet seti | Yol, ölçüm, seri, defter |
| Ne değişti | Kalıyor; kompakt, daha aşağıda, guaj dilinde |
| Anonim hesap | Kompakt tek satır, kimlik kartının hemen altında |
| Destek al | Profilde kalıyor |
| Sana göre ayarlananlar | Ayarlara taşınıyor |
| Sürüm | Profilden kalkıyor, ayarlarda en altta ortada |
| Ayarlar görünümü | Koyu orman zemin + adaçayı kart grupları |
| Destek yerelleştirme | Numara cihaz bölgesinden, metin dili uygulama dilinden (TR/EN) |
| Arka plan | Koyu orman + üstte kısa bir guaj çayır şeridi, aşağı doğru koyuya karışıyor |

**Varsayımlar** (itiraz edilmezse bunlar uygulanır):
- Kullanıcının kendi notları düzenlenip silinebiliyor. Adım cevapları yine yalnızca siliniyor.
- Seri "bu hafta" demek: pazartesi–pazar arasında tamamlanan adım günleri. Seri kırılınca hiçbir mesaj gösterilmiyor. Haftada 0 gün varsa noktalar boş kalıyor, yanında metin yok.
- Kova C'de rozet yine veriliyor ama yol sonunda kutlama ekranı açılmıyor; rozet raf'ta sessizce beliriyor.
- Kriz modunda rozet, kutlama, illüstrasyon ve seri görünmüyor.

## Sayfa yapısı (yukarıdan aşağı)

```
[guaj çayır şeridi — kaydırmayla solar]
┌ Kimlik kartı ─────────────────── (⚙)┐
│ (foto)  Taner                        │
│         Uykuya dönüş yolu            │
│         12. adım · Farkındalık       │
│         ━━━━━━━━━░░░░░  ● ● ● ○ ○ ○ ○ │  ← iz + bu haftanın 7 noktası
└──────────────────────────────────────┘
[ Hesabını bağla, yolun kaybolmasın  ›  ✕ ]   ← yalnızca anonimse
┌ Defter kartı (guaj defter + bulanık son not) ┐
│ "İç dünyana ait notları burada biriktir."    │
└──────────────────────────────────────────────┘
Rozetler                                 Tümü ›
( ◉ )( ◉ )( ◉ )( ○ )  ← kazanılanlar + sıradaki kilitli
Ne değişti  (kompakt, 3 satır, küçük guaj ikon)  ›
Destek al                                         ›
```

Kriz modunda yalnızca kimlik kartı (görselsiz) ve en üstte "Destek al" görünüyor; hareket yok. Bugünkü `supportPlacement` mantığı korunuyor.

## Uygulama aşamaları

### Aşama 0: Kural ve doküman güncellemesi (kod yok)
1. **CLAUDE.md, "Gamification — kategorik olarak yasak":** yeni tarihli karara göre yeniden yazılıyor.
   - Serbest: rozet, nazik seri, kutlama.
   - Yasak kalanlar: yukarıdaki tablodaki liste.
   - Seri kuralları ayrıca yazılıyor: sıfırlanma mesajı yok, "kaybetmek üzeresin" yok, bildirimde seri yok.
2. **`docs/PRD.md` §19 karar günlüğü** ve **`docs/PRD-Ek-Ton-ve-Nudge.md`:** gerekçesiyle yeni satır. Kutlama kademesi rozet anı için 🟡 Sıcak; kriz ve Kova C'de 🔴.
3. **`docs/profile-design.md` yeni §21 "Ben v2":** bu planın tasarım kısmı ve durum matrisi. Eski §6.5 "Yürüdüğün yollar" ve §6.6 "Sana göre ayarlananlar" "geçersiz" olarak işaretleniyor.
4. **`assets/illustrations/me-v2/prompts.md`:** aşağıdaki "Görsel teslimatları" bölümünün tam prompt'ları. Bu dosya ilk iş olarak yazılıyor ki görseller sen üretirken kod ilerlesin.

### Aşama 1: Sunucu (Supabase)
Yeni migrasyonlar (`supabase/migrations/2026091912xxxx_*.sql`):
1. **`journal_notes`:** `id uuid pk`, `user_id` (auth.users'a cascade), `body_ciphertext`, `created_at`, `updated_at`.
   - İstemciye doğrudan RLS izni yok; yalnızca Edge Function erişiyor. `path_step_answers` ile aynı model.
2. **`earned_badges`:** `user_id`, `badge_id text`, `earned_at`, `unique(user_id, badge_id)`.
   - RLS: sahibi kendi satırlarını seçip ekleyebiliyor; güncelleme ve silme yok. Rozet geri alınmıyor.
3. **Storage kovası `avatars` (private):** yol `{user_id}/avatar.jpg`.
   - `storage.objects` politikaları: yalnızca sahibi `select/insert/update/delete` yapabiliyor, klasör adı `auth.uid()`.

Edge Function'lar (`supabase/functions/`):
4. **Yeni `save-note`:** oluşturma, güncelleme ve silme.
   - Önce sunucu kriz taraması: `complete-step`teki taramanın aynısı, `_shared/` altına çıkarılıyor. Sinyal varsa `status=crisis` dönüyor ve not yazılmıyor.
   - Metin `_shared/encryption.ts` ile şifreleniyor. Karakter sınırı 4000.
5. **`me-profile`:** çözülmüş `notes`, `earnedBadges`, `avatarURL` (1 saatlik imzalı URL) ve `completedSteps` içindeki `completed_at` tarihlerini döndürüyor. Tarihler seri için gerekli; zaten dönüyorsa değişiklik yok.
6. **`delete-journal`:** yeni hedefler `note(id)` ve `allNotes`. Mevcut `all`, notları da siliyor.
7. **`delete-account`:** `avatars/{uid}/` klasörünü de siliyor.
8. **Testler:** `supabase/functions/tests/` altına şunlar ekleniyor:
   - not şifreleme gidiş-dönüş testi,
   - kriz reddi testi,
   - başka kullanıcının notuna erişimin reddi (403) testi,
   - rozet tekilliği testi.

### Aşama 2: İstemci veri katmanı
Hepsi `MyApp/Models/` ve `MyApp/Infrastructure/Backend/` altında.
1. **`ProfileRecord`:** `notes: [JournalNote]`, `earnedBadges: [EarnedBadge]`, `avatarURL: URL?`, `completedStepDates: [Date]` alanları ekleniyor. `ProfileStore.apply(_:)` bunları sunucudan işliyor; cihaza ait alanlar yine korunuyor.
2. **`BackendClient`:** `saveNote` / `deleteNote`, `uploadAvatar(jpegData)` / `removeAvatar`, `recordBadges([BadgeID])` ekleniyor.
   - Rozetler REST üzerinden `on conflict do nothing` ile yazılıyor. Ölçümlerde 409'u başarı saymak gibi, çakışma burada da başarı sayılıyor.
3. **`BadgeCatalog`** (yeni, `Models/BadgeCatalog.swift`): saf ve deterministik. `static func earned(from: ProfileRecord, path: ActivePath?) -> Set<BadgeID>`.
   - Rozetler geri alınmıyor: istemci hesaplanan kümeyi sunucudakiyle birleştiriyor. Bir notu silmek "İlk not" rozetini götürmüyor.
   - Ölçüm rozetleri **katılımdan** veriliyor, sonuçtan değil.
4. **`WeeklyRhythm`** (yeni): `completedStepDates` içinden bu haftanın 7 günlük dizisini üretiyor. Pazartesi başlangıcı, `Calendar.current`.
5. **Rozet listesi (14 adet):**
   - Yol: `first-step`, `phase-relief`, `phase-awareness`, `phase-skill`, `phase-behavior`, `phase-closing`, `path-complete`.
   - Ölçüm: `measure-day7`, `measure-day14`.
   - Seri: `week-3`, `week-5`, `week-7`. Bir takvim haftasında bu kadar adım günü.
   - Defter: `note-first`, `note-10`.
6. **`AvatarStore`:** `PhotosPicker` ile gelen resim kare kırpılıp 512 px'e indiriliyor, JPEG %80. EXIF ve konum verisi siliniyor. Ekranda göstermek için yerel önbellek tutuluyor.

### Aşama 3: "Ben" sayfası (`MyApp/Features/Me/MeView.swift`, `MeViewModel.swift`)
1. **Kaldırılanlar:** `MeHeader` kapağı ve "Ben" eyebrow'u, `JournalSection`, `SealsSection`, `PreferencesSection`, profildeki sürüm yazısı.
   - `PathDetailView` ve `MeRoute.path` artık erişilmiyor, siliniyor. `RouteSeal` rozet sayfasındaki yol rozetinde kullanılabilir.
2. **Arka plan:** yeni `MeBackdrop`.
   - `WoodlandStyle.background` üstünde, en üstte ~260 pt'lik guaj çayır şeridi. İlk tercih mevcut `journey-world-continuous` görselinin üst kesiti; yeni görsel gerekmiyorsa kullanılmıyor.
   - Alt kenar `LinearGradient` maskesiyle koyuya karışıyor. Kaydırmayla en fazla 10 pt parallax ve solma.
   - Reduce Transparency'de ve kriz modunda düz koyu zemin.
3. **`ProfileIdentityCard`** (yeni bileşen): koyu adaçayı kart (`ProfileCard`).
   - Sol: 64 pt avatar. Fotoğraf yoksa krem daire içinde adın baş harfi; ad da yoksa `leaf` simgesi. Dokununca "Fotoğraf seç / Kaldır" `confirmationDialog`'u açılıyor.
   - Sağ: ad (`coverTitle` değil `screenTitle`), yol adı, "12. adım · Farkındalık" ve altında mini `SessionProgressTrail` benzeri iz.
   - Onun altında 7 haftalık nokta; tamamlanan gün dolu adaçayı, bugün halkalı.
   - Sağ üstte ⚙ ikonu (cam, 44 pt): Ayarlar'ı açıyor.
   - Yol yoksa adım satırı ve iz çizilmiyor. VoiceOver tek öğe: "Taner, Uykuya dönüş yolu, 12. adım, Farkındalık fazı, bu hafta 3 gün".
4. **`AnonymousLinkRow`:** tek satır (ikon + metin + chevron + kapat). Kapatma davranışı mevcut `hideAnonymousCard` ile aynı.
5. **`JournalCoverCard`** (yeni):
   - Arka plan `me-journal-cover` görseli. Üstünde son kaydın ilk ~120 karakteri `.blur(6)` ve `.privacySensitive()` ile, altında "İç dünyana ait notları burada biriktirebilirsin." cümlesi.
   - Hiç kayıt yoksa bulanık alan yerine davet metni ve "İlk notunu yaz" gösteriliyor.
   - `hidesJournal` açıksa bulanık önizleme de gösterilmiyor.
   - **Kapak açılma efekti:** karttaki kapak katmanı `rotation3DEffect(.degrees(-100), axis: y, anchor: .leading, perspective: 0.6)` ile ~420 ms'de açılıyor ve alttan krem sayfa dokusu görünüyor. Ardından `NavigationLink` + `.navigationTransition(.zoom(sourceID:in:))` ile defter sayfası karttan büyüyor.
   - Reduce Motion'da kapak dönmüyor, yalnızca geçiş oluyor. Süre 800 ms bütçesinin içinde.
6. **`BadgeShelf`:** yatay sıra; kazanılanlar yeniden eskiye, en sonda sıradaki tek kilitli rozet soluk kontur hâlinde.
   - "Tümü" → `BadgesView` ızgarası (kazanılan tam renk, kilitli soluk). Kilitli rozetin altında nasıl kazanılacağı tek cümleyle yazıyor; sayı ya da ilerleme çubuğu yok.
   - Hiç rozet yoksa ilk kilitli rozet ve "İlk adımı attığında burada" yazıyor.
7. **Ne değişti (kompakt):** yeni `CompactChangeCard`.
   - Başlık cümlesi + üç katman tek satırda "kelime + ok", solda küçük `me-change` guaj ikonu. `BaselineTrack` çubukları karttan kalkıyor ve yalnızca `ChangeDetailSheet`'te kalıyor.
   - Klinik feragat altında duruyor. Mevcut ortaya çıkma animasyonu ve haptik korunuyor.
8. **Destek al:** mevcut `MeEntryRow` satırı.
9. **Sıra ve ritim:** `woodlandReveal` indeksleri yeniden sıralanıyor. Sekme çubuğu için alt pay 120 pt olarak kalıyor.

### Aşama 4: Defter sayfası (`JournalView.swift` yeniden yazım)
1. **Zemin:** koyu orman + `me-journal-paper` krem kâğıt dokusu, içerik sütununda kâğıt yaprak gibi.
2. **Başlık:** "Defter" + sağ üstte "Yeni not" (`square.and.pencil`).
3. **Liste:** ay başlıklı gruplar (mevcut `journalGroups`).
   - Kullanıcının notu: serif (`Theme.Voice.user`), köşede küçük kalem işareti.
   - Adım cevabı: soru küçük üst satırda, cevap serif.
   - Kaydırarak silme, bağlam menüsünden düzenleme (yalnızca kendi notları).
4. **`NoteComposerSheet`:** `TextEditor`, "Bende kalsın" / "Şimdilik değil". Karakter sayacı yok.
   - Kaydederken önce cihazdaki `CrisisClassifier`, sonra sunucu kontrolü. Sinyal gelirse `CrisisView` açılıyor, `markCrisisSignal` çağrılıyor ve not yazılmıyor.
   - Ağ hatasında "Yazdığın kaybolmadı…" metni ve taslak korunuyor (yerel `UserDefaults` taslağı, kaydedilince siliniyor).
5. **Gizlilik:** `hidesJournal` ve uygulama kilidi davranışı aynı kalıyor (`isJournalObscured`).

### Aşama 5: Rozet kutlaması
1. Rozet kontrolü şu anlarda yapılıyor: `PathSessionViewModel` adım tamamlandığında, ölçüm kaydında ve not kaydında. `BadgeCatalog` farkı hesaplıyor.
2. Yeni rozet varsa oturumun "finished" ekranında ya da defterde **sade bir yaprak** (`BadgeEarnedSheet`, `.medium`) açılıyor:
   - rozet görseli `scale 0.85 → 1` ve solma (~500 ms),
   - tek `Theme.softHaptic`,
   - rozet adı ve tek cümle ("İlk fazı geride bıraktın."),
   - "Bende kalsın" butonu.
   - Konfeti ve ses yok. Aynı anda birden fazla rozet kazanıldıysa tek yaprakta yan yana.
3. Kriz modunda ve Kova C'deki yol sonunda yaprak açılmıyor.

### Aşama 6: Ayarlar (`SettingsSheet.swift` yeniden yazım)
1. **Yeni bileşenler** (`DesignSystem/Components/PatikaSettings.swift`): `SettingsGroup` (başlık + koyu adaçayı kart + ayırıcılar), `SettingsRow` (ikon, etiket, değer, chevron), `SettingsToggleRow` (toggle tint `WoodlandStyle.sage`) ve `SettingsDestructiveRow`.
   - `List` yerine `ScrollView` + `VStack`. Zemin `WoodlandStyle.background`.
   - Satırlar en az 52 pt. AX boyutlarında etiket ve değer alt alta.
2. **Bölüm sırası:**
   1. Hesap: profil fotoğrafı, ad, hesap bağlama.
   2. Sana göre ayarlananlar: hatırlatma (düzenlenebilir), adım uzunluğu, ton, ses (salt okunur, "…dediğin için" açıklamasıyla).
   3. Gizlilik: kilit, defteri gizle, analitik.
   4. Veri: dışa aktar, defteri sil.
   5. Hakkında: nasıl ölçüyoruz, Destek al.
   6. Geri alınamaz: hesabı sil.
   7. En altta ortada soluk "Patika 1.0 (42)".
3. Alt sayfalar (`ReminderEditor`, `NameEditor`, `MeasurementMethodView`) aynı zemin ve kart diline geçiriliyor. `Form` kalıyor ama `scrollContentBackground(.hidden)` ve kart arka planları ekleniyor.
4. `ReminderSheet` ve profildeki hatırlatma kısayolu kalkıyor; hatırlatma yalnızca Ayarlar'da.

### Aşama 7: Destek al yerelleştirmesi
1. `MyApp/Content/Support.xcstrings` (TR kaynak + EN). `Copy.Support.*` `table: "Support"` ile bu kataloğa bağlanıyor. Discover kataloğu da aynı yöntemi kullanıyor.
2. Numara seçimi `Locale.current.region` üzerinden kalıyor (bugünkü `SupportResources.lines(regionCode:)`); metin dili uygulama dilinden geliyor. Ayrıca bir iş gerekmiyor, yalnızca katalog.
3. ⚠️ Numaraların resmî kaynaktan doğrulanması yayından önceki yapılacaklar listesinde kalıyor.

### Aşama 8: DEBUG ve önizleme
`MeDebugSeed`'e şu durumlar ekleniyor: `-patika-debug-me v2full|v2empty|v2crisis|v2badges`, `-patika-debug-me-sheet badge|note|settings`. Bunlar örnek not, rozet, avatar ve hafta verisi üretiyor.

## Görsel teslimatları (prompt'lar `assets/illustrations/me-v2/prompts.md`'ye yazılacak)

Hepsi mevcut guaj stil bloğuyla (`assets/illustrations/gouache/prompts.json`) ve `Assets.xcassets/Me/` altına.

| Varlık | Boyut | Tarif |
|---|---|---|
| `me-journal-cover` | 1536×1024, opak | Kartın tamamını kaplayan kapalı guaj defter: koyu teal kumaş kapak, krem cilt bandı, kayısı kurdele, kenarda birkaç adaçayı yaprağı. Sağ yarı sade, üstüne metin gelecek |
| `me-journal-paper` | 1024×1024, döşenebilir | Kırık krem, hafif lifli kâğıt dokusu, çok düşük kontrast, dikişsiz |
| `me-change` | 512×512, alfa | Küçük pusula/filiz ikonu: ölçümün sonuç değil yön olduğunu anlatan sade sembol |
| `badge-*` ×14 | 512×512, alfa | Yuvarlak guaj madalyon: krem disk, koyu teal kenar, ortada tek sembol. Yol: filiz, yaprak, göl, köprü, patika, fener, ev. Ölçüm: pusula ×2 (7/14 farkı noktalı halkayla). Seri: 3/5/7 taş dizisi. Defter: kalem ucu ve kurdeleli defter. Sayı ve harf yok |
| (opsiyonel) `me-backdrop` | 1536×768, opak | `journey-world-continuous` kesiti yeterli olmazsa: yukarıdan çayır, alt %40'ı düz adaçayına kararan |

Kilitli rozetler görsel gerektirmiyor: aynı görsel, kodda gri tona çevrilip %30 opaklıkla çiziliyor.

## Dokunulacak başlıca dosyalar
- `MyApp/Features/Me/`: `MeView.swift`, `MeViewModel.swift`, `JournalView.swift`, `SettingsSheet.swift`, `MeDebugSeed.swift`. Yeni: `BadgesView.swift`, `NoteComposerSheet.swift`, `BadgeEarnedSheet.swift`, `ProfileIdentityCard.swift`, `JournalCoverCard.swift`.
- `MyApp/Models/`: `ProfileRecord.swift`. Yeni: `BadgeCatalog.swift`, `WeeklyRhythm.swift`.
- `MyApp/Infrastructure/Backend/BackendClient.swift`, `ProfileStore`
- `MyApp/Features/Path/PathSessionViewModel.swift` (rozet kontrolü)
- `MyApp/Content/Copy.swift`, yeni `MyApp/Content/Support.xcstrings`
- `MyApp/DesignSystem/Components/`: yeni `PatikaSettings.swift`, `MeBackdrop.swift`
- `supabase/migrations/*`, `supabase/functions/{save-note,me-profile,delete-journal,delete-account,_shared}`
- `CLAUDE.md`, `docs/PRD.md`, `docs/PRD-Ek-Ton-ve-Nudge.md`, `docs/profile-design.md`

Yeniden kullanılacak parçalar:
- Yüzey ve kart: `ProfileCard`, `WoodlandStyle`, `WoodlandGlassSurface`, `woodlandReveal`, `Theme.TypeFace`.
- Defter: `UserQuote`, `journalGroups`, `isJournalObscured`, `ChangeDetailSheet`.
- Güvenlik ve silme: `CrisisClassifier`, `CrisisView`, `markCrisisSignal`, `hideAnonymousCard`, `deleteJournal`.
- Sunucu: `_shared/encryption.ts`.

## Doğrulama
1. `xcodebuild … build` geçmeli.
2. Deno testleri: `npx --yes deno test --allow-read --allow-env --allow-net supabase/functions/tests/` tamamen geçmeli, yeni testler dahil.
3. Canlı duman testi (anonim kullanıcı):
   - not kaydet → `me-profile`'da çözülmüş görünmeli;
   - kriz cümlesi → `crisis` dönmeli;
   - avatar yükle → imzalı URL gelmeli;
   - hesap sil → avatar klasörü ve notlar gitmeli;
   - rozet iki kez yazılınca tek satır kalmalı.
4. Simülatör ekran görüntüleri (`MeDebugSeed` durumları): dolu profil, boş profil, kriz, anonim, rozet yaprağı, not yazma, ayarlar. Her biri varsayılan boyutta ve AX5'te.
5. Reduce Motion (kapak dönmemeli), Reduce Transparency (düz zemin), VoiceOver (kimlik kartı tek öğe olarak okunmalı, bulanık önizleme okunmamalı).
6. Görseller eklenmeden de ekranlar kırılmamalı: varlık yoksa yer kaplamıyor ya da adaçayı düz kart çiziliyor.
7. CLAUDE.md'ye tarihli bölüm ekleniyor.
