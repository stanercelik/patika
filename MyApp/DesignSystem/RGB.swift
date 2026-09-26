import Foundation
import SwiftUI

/// Sabit sRGB rengi.
///
/// PRD-Ek Görsel Sistem §6.5: uygulama koyu moda sabit olduğu için dinamik `Color`
/// yerine sabit RGB kullanılır — renk interpolasyonu dinamik renkler çözümlendikten
/// sonra çalıştığından, dinamik renkler gradyanda öngörülemeyen ara tonlar üretir.
struct RGB: Equatable, Hashable, Sendable {
    var r: Double
    var g: Double
    var b: Double

    init(r: Double, g: Double, b: Double) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(hex: UInt32) {
        self.r = Double((hex >> 16) & 0xFF) / 255
        self.g = Double((hex >> 8) & 0xFF) / 255
        self.b = Double(hex & 0xFF) / 255
    }

    var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// WCAG 2.1 bağıl luminans. Kontrast doğrulaması ve "daha koyu arka planı seç"
    /// kuralı (PRD-Ek Görsel Sistem §3.3) bunun üzerinden çalışır.
    var relativeLuminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// WCAG kontrast oranı (1.0 – 21.0).
    func contrastRatio(against other: RGB) -> Double {
        let a = relativeLuminance
        let b = other.relativeLuminance
        let lighter = max(a, b)
        let darker = min(a, b)
        return (lighter + 0.05) / (darker + 0.05)
    }

    func scaled(brightness: Double, blue: Double = 1.0) -> RGB {
        RGB(
            r: min(1, r * brightness),
            g: min(1, g * brightness),
            b: min(1, b * brightness * blue)
        )
    }
}
