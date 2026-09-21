-- Oturum tempo düzeltmesi: blok scriptlerindeki tek nefeslik bekleme (10 sn) artık
-- yazılan bir **vuruş**. K3: konuşma nefes sınırına yuvarlanmaz, bekleme yalnızca
-- yazıldığı yerde ve yazıldığı kadar.
--
-- Kural (eski seed'ler asla düzenlenmez, düzeltme yeni migrasyonla):
--   1. breaths >= 2                          -> değişmez (gerçek pratik duraklaması)
--   2. breaths = 1 ve landOn var             -> değişmez (bir fazda bitiyor: yerleşme)
--   3. breaths = 1, landOn yok, iki konuşma  -> {"ms": beat}   (açıklama -> yönerge)
--
-- ⚠ beat = 1500 ms GEÇİCİ. Ürün sahibinin dinleme testinden (800 / 1500 / 2500 ms)
-- sonra sabitlenir; sabitlenmeden bu migrasyon uygulanmaz.
--
-- `blocks.version` artırılmıyor: metin değişmiyor, yalnızca bekleme. `block_audio`
-- önbellek anahtarı blok metnine bağlı, ses yeniden render edilmiyor.

update public.blocks set script = $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"We will move attention from your feet upward. At each place, notice what is there without trying to change it."},
   {"type":"silence","ms":1500},
   {"type":"fixed","text":"Feet."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Legs and hips."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Belly and chest. You may notice the breath moving through here."},
   {"type":"silence","breaths":3},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"Shoulders, arms, and hands."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Neck, jaw, and face."},
   {"type":"silence","breaths":3,"landOn":"exhale"}
 ]$json$
 where id = 'body.scan.en.v1' and version = 1;

update public.blocks set script = $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Dikkatini ayaklarından başlatıp yukarı doğru gezdireceğiz. Her durakta bir şey düzeltmeye çalışma, sadece orada ne olduğunu fark et."},
   {"type":"silence","ms":1500},
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
 ]$json$
 where id = 'body.scan.v1' and version = 1;

update public.blocks set script = $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"This pattern has four equal parts. Breathe in for four, hold for four, breathe out for four, and wait for four. If holding feels uncomfortable, leave it out and simply breathe in and out."},
   {"type":"silence","ms":1500},
   {"type":"fixed","text":"Begin when you are ready. The movement on the screen will stay with the rhythm."},
   {"type":"silence","breaths":4},
   {"type":"slot","name":"mid_bridge"},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$
 where id = 'breath.box.en.v1' and version = 1;

update public.blocks set script = $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Bu teknikte dört eşit parça var. Dörde kadar al, dörde kadar tut, dörde kadar ver, dörde kadar bekle. Tutmak rahatsız gelirse tutma, sadece al ve ver."},
   {"type":"silence","ms":1500},
   {"type":"fixed","text":"Başlıyoruz. Ekrandaki hareket sana eşlik edecek."},
   {"type":"silence","breaths":4},
   {"type":"slot","name":"mid_bridge"},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$
 where id = 'breath.box.v1' and version = 1;

update public.blocks set script = $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"This time, we will let the out-breath last a little longer. Count to four as you breathe in and seven as you breathe out. The count can be approximate."},
   {"type":"silence","ms":1500},
   {"type":"fixed","text":"Breathe in now. One, two, three, four."},
   {"type":"silence","breaths":3,"landOn":"exhale"},
   {"type":"fixed","text":"Keep the next out-breath easy and unforced."},
   {"type":"silence","breaths":4,"landOn":"exhale"},
   {"type":"slot","name":"mid_bridge"},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$
 where id = 'breath.extendedExhale.en.v1' and version = 1;

update public.blocks set script = $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Bu sefer nefes vermeyi biraz uzatacağız. Alırken dörde kadar, verirken yediye kadar sayacağız. Sayıları tutturamazsan sorun değil, yaklaşık olması yeterli."},
   {"type":"silence","ms":1500},
   {"type":"fixed","text":"Şimdi al. Bir, iki, üç, dört."},
   {"type":"silence","breaths":3,"landOn":"exhale"},
   {"type":"fixed","text":"Uzun nefes vermek bedene yavaşlama sinyali gönderir. Yaptığın şey bu."},
   {"type":"silence","breaths":4,"landOn":"exhale"},
   {"type":"slot","name":"mid_bridge"},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$
 where id = 'breath.extendedExhale.v1' and version = 1;

update public.blocks set script = $json$[
   {"type":"slot","name":"step_opening"},
   {"type":"silence","ms":1500},
   {"type":"fixed","text":"Let yourself settle where you are sitting or lying down. If closing your eyes feels right, you can close them. Otherwise, rest your gaze on one point."},
   {"type":"silence","breaths":1,"landOn":"exhale"}
 ]$json$
 where id = 'opening.arrival.en.v1' and version = 1;

update public.blocks set script = $json$[
   {"type":"slot","name":"step_opening"},
   {"type":"silence","ms":1500},
   {"type":"fixed","text":"Oturduğun ya da uzandığın yerde biraz yerleş. Gözlerini kapatmak istersen kapat, istemezsen önünde bir noktaya bak."},
   {"type":"silence","breaths":1,"landOn":"exhale"}
 ]$json$
 where id = 'opening.arrival.v1' and version = 1;

-- Doğrulayıcı: silence yalnızca `ms` YA DA `breaths` taşır. update'ler CHECK'ten
-- ÖNCE çalışmalı; yoksa eski satırlar yeni kuralı ihlal ederdi.
create or replace function private.block_script_is_valid(script jsonb) returns boolean
language plpgsql immutable set search_path = '' as $$
declare entry jsonb;
begin
  if jsonb_typeof(script) <> 'array' then return false; end if;
  for entry in select value from jsonb_array_elements(script) loop
    case entry->>'type'
      when 'fixed' then
        if coalesce(entry->>'text','') = '' then return false; end if;
      when 'slot' then
        if coalesce(entry->>'name','') = '' then return false; end if;
      when 'silence' then
        if (entry ? 'ms') = (entry ? 'breaths') then return false; end if;
        if entry ? 'ms' and ((entry->>'ms')::int < 250 or (entry->>'ms')::int > 300000) then return false; end if;
        if entry ? 'breaths' and ((entry->>'breaths')::int < 1 or (entry->>'breaths')::int > 60) then return false; end if;
      else return false;
    end case;
  end loop;
  return true;
end $$;

alter table public.blocks
  add constraint blocks_script_shape check (private.block_script_is_valid(script));
