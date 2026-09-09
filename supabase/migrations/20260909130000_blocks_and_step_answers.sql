-- Oturum motorunun veri katmanı — PRD-Ek Oturum Motoru ve JIT §1, §6, §7.
--
-- Üç iş: (1) blok kütüphanesini sunucuya taşımak, (2) adım sonu sorusu ve
-- cevabı için yer açmak, (3) kullanıcının 7. gün ölçümünü yazabilmesi.

-- ---------------------------------------------------------------------------
-- 1 · Blok kütüphanesi
-- ---------------------------------------------------------------------------
--
-- "Modelin kalitesi değil, bu kütüphanenin kalitesi ürünün kalitesidir"
-- (PRD-Ek Path Üretimi §2). LLM buradan **seçer**, buraya yazmaz.
--
-- `script` üç tipten oluşur ve dördüncü bir tip yoktur:
--   fixed   — insan yazımı, klinik gözden geçirmeden geçmiş metin. Önceden
--             render edilir, oturumun ~%70'i budur.
--   silence — TTS'e hiç gitmez, istemcide zamanlanır. `breaths` alanı nefes
--             döngüsü sayar; saniye yerine döngü, çünkü arka plan 10 saniyelik
--             döngüyle soluyor ve saniyeyle yazılmış sessizlik döngünün
--             ortasında bitip sesi nefes verme evresine sokuyordu.
--   slot    — LLM'in doldurabileceği tek yer. Adı şemada yazılı.
create table public.blocks (
  id text primary key check (id ~ '^[a-z][a-zA-Z0-9_.]{2,60}$'),
  -- Metin değişirse artar → ses yeniden render edilir. Ses dosyası adı
  -- (id, version) ikilisine bağlı; bu yüzden `id` **asla** değişmez.
  version integer not null default 1 check (version > 0),
  locale text not null default 'tr' check (char_length(locale) between 2 and 10),
  category text not null check (char_length(category) between 1 and 40),
  technique text not null check (char_length(technique) between 1 and 80),
  goals text[] not null default '{}',
  phases text[] not null check (
    cardinality(phases) between 1 and 5
    and phases <@ array['relief','awareness','skill','behavior','closing']
  ),
  difficulty integer not null check (difficulty between 1 and 3),
  min_duration_sec integer not null check (min_duration_sec > 0),
  max_duration_sec integer not null check (max_duration_sec >= min_duration_sec),
  prerequisites text[] not null default '{}',
  contraindications text[] not null default '{}',
  -- Bloğun kendi nefes ritmi: {"inhale":4,"hold":0.5,"exhale":5.5,"rest":0}.
  -- Null ise arka planın varsayılan döngüsü (4 / 0.5 / 5.5) kullanılır.
  --
  -- Bu sütun bir çelişkiyi kapatıyor: arka plan varsayılan döngüyle solurken
  -- ses "dörde kadar tut" diyen bir teknik anlatırsa kullanıcı iki ayrı ritim
  -- arasında kalıyor ve ikisine de uyamıyor. Blok kendi ritmini getiriyorsa
  -- arka plan o bloğun süresince ona geçer ve blok bitince yumuşakça geri döner.
  breath_pattern jsonb check (
    breath_pattern is null or (
      jsonb_typeof(breath_pattern) = 'object'
      and (breath_pattern->>'inhale')::numeric between 1 and 12
      and (breath_pattern->>'exhale')::numeric between 1 and 15
    )
  ),
  script jsonb not null check (jsonb_typeof(script) = 'array' and jsonb_array_length(script) > 0),
  -- Klinik gözden geçirme (PRD-Ek Path Üretimi §2.3). LLM taslak yazabilir ama
  -- **insan onayı olmadan** kütüphaneye giren metin sese dönüşmemeli. Bu sütun
  -- o süreç kurulana kadar boş kalır ve boş olması bilinçli bir uyarıdır.
  reviewed_at timestamptz,
  reviewed_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, version)
);

create index blocks_phase_idx on public.blocks using gin (phases);
create index blocks_locale_difficulty_idx on public.blocks (locale, difficulty);

create trigger blocks_set_updated_at before update on public.blocks
for each row execute function private.set_updated_at();

-- Kütüphane paylaşılan içeriktir, kullanıcı verisi değil: herkes okur, kimse
-- yazmaz. Yazma yalnızca migration ve servis anahtarıyla.
alter table public.blocks enable row level security;
create policy blocks_select_all on public.blocks
for select to authenticated using (true);
grant select on public.blocks to authenticated;

-- Yayına çıkmadan önce bu görünüm **boş olmalı**. Boş değilse, gözden
-- geçirilmemiş bir metin kullanıcıya seslendiriliyor demektir.
create view public.unreviewed_blocks as
select id, version, technique, created_at from public.blocks where reviewed_at is null;

-- ---------------------------------------------------------------------------
-- 2 · Adım sonu sorusu ve cevabı
-- ---------------------------------------------------------------------------

-- Soru adımın kendisiyle birlikte üretilir. TTS'e **gitmez** — ekranda okunur,
-- yani kişiselleştirmesi bedava (PRD-Ek Path Üretimi §2.2).
alter table public.path_steps
  add column step_question text check (step_question is null or char_length(step_question) between 1 and 200);

create table public.path_step_answers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  path_step_id uuid not null references public.path_steps(id) on delete cascade,
  question text not null check (char_length(question) between 1 and 200),
  -- Ham cevap şifreli ve ayrı sütunda (PRD §13.5). LLM'e giden bağlam
  -- `answer_summary`; ham metin değil.
  answer_ciphertext text,
  answer_summary text check (answer_summary is null or char_length(answer_summary) <= 400),
  -- Atlanabilir olması bir kural: kaçırılan gün hiçbir şeyi geri almaz.
  -- Atlayan kullanıcının sonraki adımı yine üretilir, yalnızca daha jenerik olur.
  skipped boolean not null default false,
  created_at timestamptz not null default now(),
  unique (path_step_id)
);

create index path_step_answers_user_id_idx on public.path_step_answers (user_id);

alter table public.path_step_answers enable row level security;
create policy path_step_answers_select_own on public.path_step_answers
for select to authenticated using ((select auth.uid()) = user_id);
create policy path_step_answers_insert_own on public.path_step_answers
for insert to authenticated with check ((select auth.uid()) = user_id);
grant select, insert on public.path_step_answers to authenticated;

-- ---------------------------------------------------------------------------
-- 3 · Kullanıcı kendi ölçümünü yazabilsin
-- ---------------------------------------------------------------------------
--
-- Baseline (gün 0) onboarding'de sunucu tarafından yazılıyor. Gün 1, 7, 14 ve
-- son ölçüm uygulamanın içinden geliyor, o yüzden istemcinin insert yetkisi
-- gerekiyor. Güncelleme **yok**: bir ölçüm yazıldıktan sonra değiştirilemez —
-- değiştirilebilir bir ölçüm, ölçüm değildir.
create policy measurements_insert_own on public.measurements
for insert to authenticated with check ((select auth.uid()) = user_id);
grant insert on public.measurements to authenticated;

-- Aynı gün iki kez ölçüm yazılmasın. Skorlama baseline'ı ilk iki noktanın
-- ortalaması olarak alıyor; mükerrer satır o ortalamayı sessizce bozardı.
--
-- Tekil dizin kurulmadan önce mevcut mükerrerler temizleniyor: `generate-path`
-- bugüne kadar her çağrıda bir gün-0 satırı yazıyordu ve aynı kullanıcı için
-- iki kez çağrıldığında (geliştirme sırasında olan tam olarak bu) ikinci bir
-- satır oluşuyordu.
--
-- **En eski satır korunur.** Baseline ilk ölçümdür; sonradan yazılanı tutmak,
-- kullanıcının ilk hâlini ikinci bir denemeyle değiştirmek olurdu.
delete from public.measurements m
using public.measurements keep
where m.user_id = keep.user_id
  and m.measurement_day = keep.measurement_day
  and (keep.created_at, keep.id) < (m.created_at, m.id);

create unique index measurements_user_day_idx
  on public.measurements (user_id, measurement_day);

-- Sunucunun gün-0 yazımı da artık mükerrer üretmemeli: aynı kullanıcı için
-- ikinci bir path üretimi baseline'ı yeniden yazmak yerine sessizce geçmeli.
-- (`generate-path` bu dizine güvenerek `on conflict do nothing` kullanıyor.)
