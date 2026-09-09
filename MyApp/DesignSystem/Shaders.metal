#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// Grain + metin güvenli bölge scrim'i — PRD-Ek Görsel Sistem §5, §6.3.
//
// İkisi tek geçişte yapılır (karar #3): ayrı overlay katmanı ekstra kompozisyon
// maliyeti çıkarır. `.background(.regularMaterial)` bilinçli olarak kullanılmaz —
// material blur gradyanın rengini yıkayıp görsel kimliği siler; buradaki scrim
// rengi korur, sadece parlaklığı düşürür.
//
// colorEffect imzası: [[stitchable]] half4 name(float2 position, half4 color, args...)
[[ stitchable ]] half4 grainAndScrim(float2 pos,
                                     half4 color,
                                     float2 size,
                                     float time,
                                     float grain,
                                     float safeY,
                                     float safeStrength)
{
    // Metin bloğunun bulunduğu dikey banda doğru yumuşak karartma.
    // smoothstep kullanılır — keskin bant görünmemeli.
    float y = pos.y / max(size.y, 1.0);
    float safe = smoothstep(0.38, 0.0, abs(y - safeY));
    half3 c = color.rgb * half(1.0 - safe * safeStrength);

    // Analog risograph dokusu.
    //
    // Grain **kaydırılır, yeniden atılmaz** (ürün sahibi kararı, 2026-09-08).
    // Önceki hâlde örüntü her karede 100 piksele kadar rastgele yer değiştiriyor
    // ve doku kaynıyordu; hareketli ama yorucu, üstelik yönü olmadığı için akış
    // da hissettirmiyordu. Şimdi alan saniyede birkaç piksel süzülüyor: bakınca
    // fark ediliyor, bakmayınca rahatsız etmiyor.
    //
    // Kayma hızı buradan artırılacaksa dikkat: 30 fps'te kare başına ~1 pikseli
    // geçince doku yeniden kaynamaya başlıyor.
    float2 grainOffset = float2(time * 6.0, time * -4.0);
    float n = fract(sin(dot(pos + grainOffset,
                            float2(127.1, 311.7))) * 43758.5453);
    c += half((n - 0.5) * grain);

    return half4(c, color.a);
}
