-- Oturum manifestleri türetilmiş artefakttır: blok/kişisel ses satırlarından ve
-- şemadan yeniden kurulur. Tempo düzeltmesiyle şema değişti (manifest-v2), eski
-- manifestlerin bekleme süreleri de yanlıştı; hepsi silinir, ilk açılışta yeniden kurulur.
--
-- block_audio ve audio_assets'e DOKUNULMAZ: ses dosyaları aynı kalıyor.
--
-- Dağıtım sırası: fonksiyonlar (manifest-v2 + TTS_POLICY_VERSION) ÖNCE, bu dosya
-- SONRA. Ters sırada ilk istek eski kodla yeniden kurar. Yeniden çalıştırılabilir.
delete from public.session_manifests;

-- PathSessionViewModel yalnızca `pending` durumda ses istiyor; yalnızca manifest
-- silmek yetmez. Tamamlanmış adımlar bir daha çalınmadığı için dokunulmaz.
update public.path_steps set audio_status = 'pending'
 where audio_status in ('ready', 'failed') and completed_at is null;
