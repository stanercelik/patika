-- "Ben" v2 sunucu katmanı — docs/profile-v2-plan.md Aşama 1.
--
-- Üç iş: (1) kullanıcının kendi defter notları, (2) kilometre taşı rozetleri,
-- (3) profil fotoğrafı için özel kova.

-- ---------------------------------------------------------------------------
-- 1 · Defter notları
-- ---------------------------------------------------------------------------
--
-- Adım cevaplarından iki farkı var:
--
-- - İstemciye **hiç** doğrudan RLS izni yok. Adım cevabı istemciden de
--   okunabiliyordu; not öyle değil: her not sunucudaki kriz taramasından
--   geçmeden yazılamaz (`save-note`). Sinyal varsa not yazılmaz ve akış
--   `status=crisis` ile durur — istemci ön filtresi sinyal verdiyse sunucu
--   bunu geri alamaz, sunucu reddettiyse not hiç var olmamış olur.
-- - Ham metin düz durmaz ve satır tutulup boşaltılmaz: silmek satırı
--   kaldırır. Adım cevabında satır kalmak zorundaydı çünkü sonraki adımın
--   üretimi o satıra dayanıyor; notın hiçbir şeye dayandığı yok.
create table public.journal_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  body_ciphertext text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index journal_notes_user_id_idx on public.journal_notes (user_id);

create trigger journal_notes_set_updated_at before update on public.journal_notes
  for each row execute function private.set_updated_at();

alter table public.journal_notes enable row level security;

-- Bilerek hiç policy ve grant yok: anon/authenticated bu tabloyu göremez,
-- ekleyemez, değiştiremez. Tek yazma yolu `save-note`, tek okuma yolu
-- `me-profile` — ikisi de hizmet anahtarıyla ve sahiplik denetimiyle çalışır.
revoke all on public.journal_notes from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2 · Kazanılan rozetler
-- ---------------------------------------------------------------------------
--
-- Rozet geri **alınmaz**: güncelleme ve silme politikası bilerek yok. İstemci
-- kendi rozetini REST ile `on conflict do nothing` ile yazar; çakışma başarı
-- sayılır (ölçümlerdeki 409 dönüştürmesiyle aynı kural). Tekillik
-- veritabanında garanti altında — iki istemci aynı anda yazarsa tek satır
-- kalır. Ölçüm rozetleri katılımdan verilir, sonuçtan değil; kova farkı
-- burada bir rol oynamaz.
create table public.earned_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_id text not null check (badge_id ~ '^[a-z][a-z0-9-]{2,40}$'),
  earned_at timestamptz not null default now(),
  unique (user_id, badge_id)
);

create index earned_badges_user_id_idx on public.earned_badges (user_id);

alter table public.earned_badges enable row level security;
create policy earned_badges_select_own on public.earned_badges
  for select to authenticated using ((select auth.uid()) = user_id);
create policy earned_badges_insert_own on public.earned_badges
  for insert to authenticated with check ((select auth.uid()) = user_id);
grant select, insert on public.earned_badges to authenticated;

-- ---------------------------------------------------------------------------
-- 3 · Profil fotoğrafı kovası
-- ---------------------------------------------------------------------------
--
-- Özel (private) kova: yol `avatars/<user_id>/avatar.jpg`. Okuma 1 saatlik
-- imzalı URL ile (`me-profile`); genel URL yok. İstemci yalnızca kendi
-- klasörüne yazabilir, değiştirebilir, silebilir ve kendi dosyasını okuyabilir.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 5242880, array['image/jpeg'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy avatars_select_own on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy avatars_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy avatars_update_own on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy avatars_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
