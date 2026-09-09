# Ses örnekleri

`voice-preview-<feminine|masculine>-<tr|en>.mp3` dosyaları buraya gelir ve
onboarding E4 ekranında çalınır. Depoda tutulmuyorlar (ikili dosya, ~40 KB × 4);
üretmek için:

```bash
ELEVENLABS_API_KEY=sk_... ./scripts/render-voice-previews.sh
```

Örnek metni ve ses ayarları sunucudaki üretimle **birebir aynı** — örnekte
duyulan ses oturumda duyulacak sesten farklı olursa seçim anlamını yitirir.
