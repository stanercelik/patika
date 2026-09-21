-- Oturum tempo düzeltmesi: sağlayıcının konuşmanın başına ve sonuna bıraktığı
-- sessizlik. Oturum motoru 350 ms'lik bağlantı boşluğunu bunun **içinde** soğuruyor
-- (`joinLeadInMs`); önceden dolgu planlanan boşluğun üstüne biniyordu.
--
-- Nullable ve eklemeli: eski satırlarda değer yok ve 0 sayılıyor. Bu migrasyon
-- fonksiyon dağıtımından ÖNCE uygulanmalı (yeni kod bu sütunları seçiyor).
alter table public.block_audio
  add column lead_silence_ms integer check (lead_silence_ms is null or lead_silence_ms >= 0),
  add column tail_silence_ms integer check (tail_silence_ms is null or tail_silence_ms >= 0);

alter table public.audio_assets
  add column lead_silence_ms integer check (lead_silence_ms is null or lead_silence_ms >= 0),
  add column tail_silence_ms integer check (tail_silence_ms is null or tail_silence_ms >= 0);
