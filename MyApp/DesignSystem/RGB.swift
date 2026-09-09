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

    /// İki rengi doğrusal (gamma açılmış) uzayda karıştırır.
    ///
    /// sRGB değerlerini doğrudan karıştırmak koyu tonlarda gri bir ara renk üretir;
    /// gradyanda bu "çamur" olarak görünür. Karışım ışığın davrandığı uzayda yapılır.
    func mixed(with other: RGB, amount: Double) -> RGB {
        let t = amount.clamped(to: 0...1)
        let a = linearComponents, b = other.linearComponents
        return RGB(
            linear: (
                a.0 + (b.0 - a.0) * t,
                a.1 + (b.1 - a.1) * t,
                a.2 + (b.2 - a.2) * t
            )
        )
    }

    /// Rengi, **tonunu koruyarak** hedef bağıl luminansa taşır.
    ///
    /// Kontrast yalnızca luminansa bağlı olduğu için ton serbestçe değişebilirken
    /// okunabilirlik tam olarak kontrol altında kalır: mood tonlaması bu sayede
    /// renkleri sarıya ya da laciverte çekerken metin kontrastını hiç oynatmıyor.
    func withLuminance(_ target: Double) -> RGB {
        let current = relativeLuminance
        guard current > 0.0001, target > 0 else { return self }
        let k = target / current
        let c = linearComponents
        return RGB(linear: (min(1, c.0 * k), min(1, c.1 * k), min(1, c.2 * k)))
    }

    private var linearComponents: (Double, Double, Double) {
        func linear(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return (linear(r), linear(g), linear(b))
    }

    private init(linear: (Double, Double, Double)) {
        func encode(_ c: Double) -> Double {
            let v = max(0, min(1, c))
            return v <= 0.0031308 ? v * 12.92 : 1.055 * pow(v, 1 / 2.4) - 0.055
        }
        self.r = encode(linear.0)
        self.g = encode(linear.1)
        self.b = encode(linear.2)
    }
}
