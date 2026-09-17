# Patika guaj ailesi — 17 Eylül 2026

Kullanıcının onayladığı Keşfet görselleri stil referansıdır. Yerleşik image_gen
aracıyla altı özgün sahne üretildi. Tam prompt'lar `prompts.json` içindedir.

| Varlık | Kullanım |
| --- | --- |
| illustration-reflection | C1 aynalama |
| illustration-belonging | C2 ortak deneyim |
| illustration-shelter | Yolum başlangıç fazı |
| illustration-trail | F2 yolun hazır, Yolum pratik fazları ve boş durum |
| illustration-rest | Yolum kapanış, G2 oturum sonu |
| illustration-journal | Ben başlığı |

Uygulamaya giren dosyalar `MyApp/Assets.xcassets/Illustrations/` altındadır.
1536×1024 PNG, gerçek alfa kanalı, %40–67 tamamen şeffaf piksel. Görseller yeniden
renklendirilmez; kontrollü teal/sage/cream paletleri asıl pigment dokusunu korur.
Metin görsele gömülmez, illüstrasyonlar VoiceOver'dan gizlidir. C1/C2'nin sahne
boyutları korunur; erişilebilir boyutta 194 pt olur. Yolum yan sahneleri ve Ben/G2
dekorları erişilebilir büyük yazıda yer kaplamaz. Kriz durumunda Ben dekoru yoktur.

## Yolum referans araştırması

Kullanıcı kart listesi yaklaşımını reddetti; görsel rota istiyor. Son adaylar:
- Ahead manzara haritası: https://mobbin.com/screens/2f0ce7b1-a8cd-4839-bd45-37d505e08e3e
- Ahead nehir geçişi: https://mobbin.com/screens/4da94544-9404-47e7-9998-884d7d4f3781
- Noom rota: https://mobbin.com/screens/3ef3dce1-8f8e-416b-b8c2-5d52d177fe26
- Liven bitkisel kenarlar: https://mobbin.com/screens/58d2cdc7-7978-4c42-891f-f671e7f7615c
- Duolingo durak ritmi: https://mobbin.com/screens/673d73bb-bb22-4481-8f14-7cf966c9e7bd

Kullanıcı Ahead yönünü onayladı. Tam genişlikteki manzara uyarlaması uygulandı:
`journey-world-forest` ve `journey-world-water`, 1024×1536 PNG. Yerleşik image_gen
ile üretildi; tam prompt'lar `world-prompts.json` içindedir. PathLandscapeScene
resimleri ayrı bir arka plan düzleminde örtüştürür; rota ve düğümler native kalır.
Bu resimler kişisel veri kullanmaz; coğrafya dekoratiftir.

## Doğrulama

MyApp simulator derlemesi geçti. C1 ve C2 gerçek simulator ekran görüntülerinde
incelendi; yeni PNG'ler arka planla birleşiyor. Yolum örnek path ile görüntülendi.
Bu görsel çalışma için yeni test hedefi eklenmedi. Ses üretimindeki önceki
ElevenLabs 402 engeli bu değişiklikle ilişkili değildir ve çözülmüş sayılmaz.

### Kesintisiz manzara revizyonu

Aktif Yolum zemini `journey-world-continuous.imageset/artwork.png` (724×2172).
Built-in image_gen ile üretildi; prompt `continuous-world-prompt.json`.
Önceki iki dünya resmi arşivde durur ancak Yolum bunları artık kullanmaz.
