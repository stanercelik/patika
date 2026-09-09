-- Kullanıcı kendi adımını tamamlanmış işaretleyebilsin (G2, oturum sonu).
--
-- Yetki **sütun bazlı**: yalnızca `completed_at` yazılabiliyor. Tabloya tam
-- update yetkisi vermek, istemcinin `block_ids` ya da `slot_copy`yi — yani
-- sunucunun ürettiği planın kendisini — değiştirebilmesi demekti.
--
-- Alternatif bir Edge Function olurdu; tek sütunluk bir yazma için ikinci bir
-- dağıtım yüzeyi ve ikinci bir yetki kontrolü açmaya değmiyor. RLS zaten
-- "yalnızca kendi satırın" diyor.
--
-- Bilinen sınır: kullanıcı `completed_at`i istediği zaman damgasıyla yazabilir
-- ve tekrar yazabilir. Ölçüm skorlaması bu sütuna değil `measurements`a
-- dayandığı için bu, sonucu manipüle etmeye yaramıyor — yalnızca kendi
-- ilerleme görüntüsünü bozabilir.

create policy path_steps_update_own on public.path_steps
for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

grant update (completed_at) on public.path_steps to authenticated;
