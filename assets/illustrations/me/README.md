# "Ben" sekmesi görselleri

İki isteğe bağlı görsel. Varlık eklenmediyse bileşenler yer kaplamaz; sayfa
görselsiz de eksiksiz çalışır.

Prompt'lar ve kontrol listesi: [`docs/profile-design.md`](../../../docs/profile-design.md) §19.

| Yuva (`MyApp/Assets.xcassets/Me/`) | Nerede | Kaynak dosya |
|---|---|---|
| `me-header-notebook` | Başlığın sağında, %20 opaklık | `me-header-notebook-source.png` |
| `me-paths-empty` | "Yürüdüğün yollar" boş durumu | `me-paths-empty-source.png` |

Mühürler (`RouteSeal`), başlangıç izi (`BaselineTrack`) ve değişim grafiği kodla
çiziliyor — onlar için görsel üretilmez.

Teknik: şeffaf PNG, yalnızca kırık beyaz (#F2EFE9) ve soğuk gri, uzun kenar 512 px,
yuvanın 2x kutusuna.
