-- Türkçe blok kütüphanesi — v1 taslağı.
--
-- ⚠️  BU METİNLER KLİNİK GÖZDEN GEÇİRMEDEN GEÇMEDİ.
--
-- `reviewed_at` bilerek NULL. PRD-Ek Path Üretimi §2.3: "Blok yazımı LLM'e
-- verilmez — bunlar klinik gözden geçirmeden geçmesi gereken metinlerdir. LLM
-- bir taslak üretmekte kullanılabilir ama üretilen metin insan onayı olmadan
-- kütüphaneye girmez ve bu bir süreç kuralıdır."
--
-- Bu satırlar tam olarak o taslaktır. Yayına çıkmadan önce
-- `select * from public.unreviewed_blocks` **boş dönmelidir**.
--
-- Ton kuralları (Ton eki §3, Sakin kademe):
--   · Emir yok, kaçış payı var ("istersen", "yapabiliyorsan").
--   · Garanti yok ("geçecek", "rahatlayacaksın" yasak).
--   · Teşhis ve tedavi iması yok.
--   · Ünlem yok. Emoji yok.
--
-- Metinler tam Türkçe yazılır: bunlar hem ekranda okunuyor hem seslendiriliyor.
-- Aksansız yazım ("gozlerini") TTS telaffuzunu bozar ve ekranda kırık görünür.
-- Kaçış sorunu yok — script alanları $json$ ile dolar-tırnak içinde, yani
-- kesme işareti de Türkçe harfler de olduğu gibi geçiyor.

insert into public.blocks
  (id, version, locale, category, technique, goals, phases, difficulty,
   min_duration_sec, max_duration_sec, prerequisites, contraindications,
   breath_pattern, script)
values

-- ---------------------------------------------------------------------------
-- Açılış · her adımın başında. Kişiselleştirmenin en yoğun olduğu yer.
-- ---------------------------------------------------------------------------
('opening.arrival.v1', 1, 'tr', 'cerceve', 'Varış', array['baslangic'],
 array['relief','awareness','skill','behavior','closing'], 1, 50, 110,
 '{}', '{}', null,
 $json$[
   {"type":"slot","name":"step_opening"},
   {"type":"silence","breaths":1},
   {"type":"fixed","text":"Oturduğun ya da uzandığın yerde biraz yerleş. Gözlerini kapatmak istersen kapat, istemezsen önünde bir noktaya bak."},
   {"type":"silence","breaths":1,"landOn":"exhale"}
 ]$json$),

-- ---------------------------------------------------------------------------
-- Nefes · en temel blok. Ritmi arka planin varsayilan dongusuyle ayni.
-- ---------------------------------------------------------------------------
('breath.awareness.v1', 1, 'tr', 'temel', 'Nefes farkındalığı',
 array['akut_gerginlik','uyku_oncesi','baslangic'],
 array['relief','awareness'], 1, 170, 280, '{}', '{}', null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Nefesini değiştirmeye çalışma. Şu an nasıl geliyorsa öyle bıraksan yeter."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Nerede hissettiğini fark et. Burnunda mı, göğsünde mi, karnında mı."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Şimdi ekrandaki hareketi takip et. Genişlerken al, daralırken bırak."},
   {"type":"silence","breaths":4,"landOn":"exhale"},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"Verirken biraz daha uzat. Acele yok."},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$),

-- ---------------------------------------------------------------------------
-- Uzun nefes verme · parasempatik. Kendi ritmi var: 4 al, 7 ver.
-- ---------------------------------------------------------------------------
('breath.extendedExhale.v1', 1, 'tr', 'temel', 'Uzatılmış nefes verme',
 array['akut_gerginlik','uyku_oncesi'],
 array['relief'], 1, 180, 300, array['breath.awareness.v1'], '{}',
 $json${"inhale":4,"hold":0.5,"exhale":7,"rest":0}$json$,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Bu sefer nefes vermeyi biraz uzatacağız. Alırken dörde kadar, verirken yediye kadar sayacağız. Sayıları tutturamazsan sorun değil, yaklaşık olması yeterli."},
   {"type":"silence","breaths":1},
   {"type":"fixed","text":"Şimdi al. Bir, iki, üç, dört."},
   {"type":"silence","breaths":3,"landOn":"exhale"},
   {"type":"fixed","text":"Uzun nefes vermek bedene yavaşlama sinyali gönderir. Yaptığın şey bu."},
   {"type":"silence","breaths":4,"landOn":"exhale"},
   {"type":"slot","name":"mid_bridge"},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$),

-- ---------------------------------------------------------------------------
-- Kutu nefesi · 4-4-4-4. Kendi ritmi olmasi zorunlu.
-- ---------------------------------------------------------------------------
('breath.box.v1', 1, 'tr', 'temel', 'Kutu nefesi',
 array['akut_gerginlik','odaklanma'],
 array['relief','skill'], 2, 230, 400, array['breath.awareness.v1'],
 array['panik_atak_gecmisi'],
 $json${"inhale":4,"hold":4,"exhale":4,"rest":4}$json$,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Bu teknikte dört eşit parça var. Dörde kadar al, dörde kadar tut, dörde kadar ver, dörde kadar bekle. Tutmak rahatsız gelirse tutma, sadece al ve ver."},
   {"type":"silence","breaths":1},
   {"type":"fixed","text":"Başlıyoruz. Ekrandaki hareket sana eşlik edecek."},
   {"type":"silence","breaths":4},
   {"type":"slot","name":"mid_bridge"},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$),

-- ---------------------------------------------------------------------------
-- Zeminleme · bedene donus, en guvenli blok.
-- ---------------------------------------------------------------------------
('body.grounding.v1', 1, 'tr', 'beden', 'Zeminleme',
 array['akut_gerginlik','disosiyasyon'],
 array['relief','awareness'], 1, 140, 250, '{}', '{}', null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Ayaklarının zeminle, sırtının arkandaki yüzeyle temas ettiği yeri fark et."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Omuzlarına gel. Kalkıksa bırak. Bırakmıyorsa zorlama, fark etmek de yeterli."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Çene ve alın. Sıkılıysa gevşesin."},
   {"type":"silence","breaths":2,"landOn":"exhale"},
   {"type":"fixed","text":"Bir an için bedenini bütün olarak hisset. Bir yeri düzeltmen gerekmiyor."},
   {"type":"silence","breaths":3,"landOn":"exhale"}
 ]$json$),

-- ---------------------------------------------------------------------------
-- Beden taramasi · daha uzun, dikkat gerektirir.
-- ---------------------------------------------------------------------------
('body.scan.v1', 1, 'tr', 'beden', 'Beden taraması',
 array['uyku_oncesi','gerginlik'],
 array['awareness'], 2, 290, 470, array['body.grounding.v1'], '{}', null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Dikkatini ayaklarından başlatıp yukarı doğru gezdireceğiz. Her durakta bir şey düzeltmeye çalışma, sadece orada ne olduğunu fark et."},
   {"type":"silence","breaths":1},
   {"type":"fixed","text":"Ayaklar."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Bacaklar ve kalça."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Karın ve göğüs. Nefesin buradan geçişini fark edebilirsin."},
   {"type":"silence","breaths":3},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"Omuzlar, kollar, eller."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Boyun, çene, yüz."},
   {"type":"silence","breaths":3,"landOn":"exhale"}
 ]$json$),

-- ---------------------------------------------------------------------------
-- Adlandirma · duyguyu adlandirmak, degistirmeye calismadan.
-- ---------------------------------------------------------------------------
('reflection.notice.v1', 1, 'tr', 'farkindalik', 'Adlandırma',
 array['duygu_duzenleme'],
 array['awareness','skill'], 2, 170, 290, '{}', '{}', null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Şu an içeride ne varsa ona bir ad ver. Gerginlik, yorgunluk, huzursuzluk, boşluk. Hangisiyse."},
   {"type":"silence","breaths":3},
   {"type":"fixed","text":"Adını koyduğun şeyi değiştirmeye çalışma. Bugünlük fark etmiş olmak yeterli."},
   {"type":"silence","breaths":3},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"Dikkatin dağıldıysa sorun değil. Dağılması normal. Nefese geri dön."},
   {"type":"silence","breaths":3,"landOn":"exhale"}
 ]$json$),

-- ---------------------------------------------------------------------------
-- Dusunceden mesafe · daha ileri, ruminasyon icin.
-- ---------------------------------------------------------------------------
('reflection.distance.v1', 1, 'tr', 'farkindalik', 'Düşünceden mesafe',
 array['ruminasyon','uyku_oncesi'],
 array['skill'], 3, 230, 350,
 array['reflection.notice.v1'], array['akut_kriz'], null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Bir düşünce geldiğinde onu itmeye çalışmayacağız. Onun yerine başına şu üç kelimeyi ekleyeceğiz: bir düşünce var."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"“Yarın yetiştiremeyeceğim” yerine, “yarın yetiştiremeyeceğim diye bir düşünce var”. Aynı cümle, ama artık senin içinde değil, önünde."},
   {"type":"silence","breaths":3},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"Bir sonraki düşünce geldiğinde aynı şeyi dene. Çıkmazsa zorlama, nefese dön."},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$),

-- ---------------------------------------------------------------------------
-- Kucuk adim · davranis fazi. Kacinilan seye yaklasma.
-- ---------------------------------------------------------------------------
('behavior.smallStep.v1', 1, 'tr', 'davranis', 'Küçük adım',
 array['kacinma'],
 array['behavior'], 3, 190, 310,
 array['reflection.notice.v1'], array['akut_kriz'], null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Şimdi gözünün önüne ertelediğin şeyi getir. Tamamını değil, sadece ilk hareketini. Kapıyı açmak, dosyayı açmak, telefonu eline almak."},
   {"type":"silence","breaths":3},
   {"type":"fixed","text":"O ilk hareketi yaptığını hayal et ve bedeninde ne olduğunu fark et. Bir şey sıkılırsa orada kal, kaçma."},
   {"type":"silence","breaths":4},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"Bugün yapman gereken bir şey yok. Sadece o ilk hareketin nasıl hissettirdiğine baktık."},
   {"type":"silence","breaths":3,"landOn":"exhale"}
 ]$json$),

-- ---------------------------------------------------------------------------
-- Kapanis · her adimin sonunda.
-- ---------------------------------------------------------------------------
('closing.day.v1', 1, 'tr', 'cerceve', 'Kapanış', array['bitis'],
 array['relief','awareness','skill','behavior','closing'], 1, 55, 110,
 '{}', '{}', null,
 $json$[
   {"type":"fixed","text":"Yavaş yavaş bitiriyoruz. Nefesini birkaç kez daha kendi hâlinde bırak."},
   {"type":"silence","breaths":2,"landOn":"exhale"},
   {"type":"slot","name":"step_closing"},
   {"type":"silence","breaths":1,"landOn":"exhale"},
   {"type":"fixed","text":"Gözlerini açtığında acele etme."}
 ]$json$);
