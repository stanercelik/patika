-- Ses mimarisi — PRD-Ek Oturum Motoru §3, PRD-Ek Path Üretimi §5.
--
-- Üç değişiklik:
--   1. Kullanıcının ses tercihi (kadın / erkek) ve dili.
--   2. Kişisel ses **slot başına** saklanır, adım başına tek dosya değil.
--   3. Blokların sabit metinleri ayrı ve **paylaşılan** bir depoda durur.

-- ---------------------------------------------------------------------------
-- 1 · Ses tercihi
-- ---------------------------------------------------------------------------
--
-- Sağlayıcının voice_id'si burada tutulmaz. Kimlik tercihi ürünün kararı
-- ("kadın sesi"), voice_id sağlayıcının uygulama detayı — sağlayıcı
-- değiştiğinde kullanıcı satırlarının değişmesi gerekmemeli.
alter table public.profiles
  add column voice_preference text
    check (voice_preference is null or voice_preference in ('feminine', 'masculine'));

-- ---------------------------------------------------------------------------
-- 2 · Kişisel ses: slot başına bir dosya
-- ---------------------------------------------------------------------------
--
-- Eski model adımın bütün slot metinlerini birleştirip tek dosya üretiyordu.
-- Yeni oturum motorunda slotlar sabit blok parçalarıyla ve sessizliklerle
-- **iç içe** çalıyor (§1.2); tek dosya bu sırayı imkânsız kılıyor.
alter table public.audio_assets
  add column slot_name text
    check (slot_name is null or slot_name in ('step_opening', 'technique_bridge', 'mid_bridge', 'step_closing')),
  add column model_id text,
  add column voice_preference text,
  add column locale text;

-- Eski tekil kısıt storage_path üzerindeydi; asıl kısıt bu.
create unique index audio_assets_step_slot_idx
  on public.audio_assets (path_step_id, slot_name)
  where slot_name is not null;

-- ---------------------------------------------------------------------------
-- 3 · Blok sesi: paylaşılan, kişisel veri değil
-- ---------------------------------------------------------------------------
--
-- Blokların `fixed` metinleri **her kullanıcı için aynı** ve kişisel veri
-- içermiyor. Bu yüzden:
--   · bir kez render edilir (oturumun ~%70'i, üretim maliyeti amortize),
--   · imzalı URL gerekmez → CDN cache'lenir, çevrimdışı saklanabilir,
--   · kullanıcının cümlesi buraya hiç girmez (GDPR sınırı `audio_assets`ta).
create table public.block_audio (
  id uuid primary key default gen_random_uuid(),
  block_id text not null,
  block_version integer not null check (block_version > 0),
  -- `script` dizisindeki konum. Yalnızca `fixed` girdileri render edilir;
  -- `silence` hiç TTS görmez, `slot` kişiseldir.
  segment_index integer not null check (segment_index >= 0),
  locale text not null check (char_length(locale) between 2 and 10),
  voice_preference text not null check (voice_preference in ('feminine', 'masculine')),
  storage_path text not null unique check (storage_path !~ '(^|/)\.\.(/|$)'),
  content_type text not null check (content_type in ('audio/mpeg', 'audio/wav', 'audio/mp4')),
  duration_ms integer check (duration_ms is null or duration_ms > 0),
  model_id text not null,
  created_at timestamptz not null default now(),
  foreign key (block_id, block_version) references public.blocks (id, version) on delete cascade,
  unique (block_id, block_version, segment_index, locale, voice_preference)
);

create index block_audio_lookup_idx
  on public.block_audio (block_id, block_version, locale, voice_preference);

alter table public.block_audio enable row level security;
create policy block_audio_select_all on public.block_audio
for select to authenticated using (true);
grant select on public.block_audio to authenticated;

-- Blok sesi herkese aynı: açık kova, imzasız, CDN dostu.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('block_audio', 'block_audio', true, 52428800, array['audio/mpeg', 'audio/wav', 'audio/mp4'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- 4 · Blok başına ses yönergesi
-- ---------------------------------------------------------------------------
--
-- Eleven v3 `[whispers]` gibi etiketleri destekliyor ama **sese göre değişken
-- çalışıyor** (ElevenLabs kendi dokümanında söylüyor: "The voice you choose and
-- its training samples will affect tag effectiveness"). Belgelenmemiş bir etiket
-- (`[meditative]` gibi) modelin etiketi **sesli okuması** riskini taşıyor —
-- meditasyonun ortasında duyulacak bir hata.
--
-- Bu yüzden etiket blok başına, isteğe bağlı ve **varsayılan olarak boş**.
-- Asıl tempo aracı noktalama (üç nokta duraklama üretir) ve bizim kendi
-- sessizlik enjeksiyonumuz; etiket ancak dinlenip doğrulandıktan sonra açılır.
alter table public.blocks
  add column audio_tag text check (audio_tag is null or audio_tag ~ '^\[[a-z ]{2,30}\]$');
