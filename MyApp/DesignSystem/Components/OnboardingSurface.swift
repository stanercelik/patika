import SwiftUI

/// Bir onboarding adımının malzemesi (docs/onboarding-redesign.md, Bölüm 2.2).
///
/// Uygulamanın üç katmanı (zemin, kâğıt, cam) onboarding'de şöyle dağılır:
/// - `.ground`: kontrol doğrudan nefes alan mesh'in üstünde, açık mürekkep. A2 ve B6
///   bilerek burada: A2'nin paleti ve B6'nın ruh hâli **arka planı değiştiriyor**;
///   önlerine kart koymak neden ile sonucu birbirinden koparırdı.
/// - `.paper`: okuma ve cevap yüzeyi krem kâğıt, koyu mürekkep. Kontrast palete
///   bağlı değil, sabit (~9,5:1).
/// - `.scene`: guaj manzara zemin olur. Ortak yerleşimleri kullanmayan özel
///   ekranlar (A1, F1, F2, G2) için.
enum OnboardingSurfaceStyle: Equatable, Sendable {
    case ground
    case paper
    case scene
}

extension EnvironmentValues {
    /// Adımın malzemesi. Kabuk `OnboardingStep.surfaceStyle`dan doldurur; ortak
    /// yerleşimler okur. **Varsayılan `.ground`**: `PathSessionView` (oturumun
    /// ortasındaki ekran) bu değeri hiç kurmaz ve bugünkü görünümünü, ayrı bir
    /// dal ya da bayrak olmadan korur.
    @Entry var onboardingSurface: OnboardingSurfaceStyle = .ground

    /// Yaprak bileşenlerin mürekkebi. Yalnızca **kartın içine** verilir: kartın
    /// altındaki buton mesh'in üstünde durur ve açık kalmalıdır, bu yüzden malzeme
    /// ile mürekkep iki ayrı değer.
    @Entry var patikaInk: PatikaInk = .light
}

/// Adım `.paper` ise içeriği krem karta sarar ve içindeki yapraklara koyu mürekkep
/// verir; diğer malzemelerde içeriğe dokunmaz.
struct OnboardingSurfaceCard: ViewModifier {
    let style: OnboardingSurfaceStyle

    func body(content: Content) -> some View {
        if style == .paper {
            content
                .padding(PatikaSurfaceMetrics.padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .paperSurface()
                .environment(\.patikaInk, .ink)
        } else {
            content
        }
    }
}

/// Açılış stili malzemeyi izler (docs/onboarding-redesign.md, Bölüm 3).
///
/// Kâğıt ekranlar `woodlandReveal` kullanır: 1,5 sn'lik cümle cümle belirme
/// (`sequentialReveal`) uygulamanın yavaş olduğu hissini veriyordu (ürün sahibi
/// kararı, 2026-09-21). Zemin malzemesi eski davranışı korur çünkü onu
/// `PathSessionView` (oturumun ortası) kullanıyor.
private struct SurfaceReveal: ViewModifier {
    let index: Int
    @Environment(\.onboardingSurface) private var surface

    func body(content: Content) -> some View {
        if surface == .paper {
            content.woodlandReveal(index)
        } else {
            content.sequentialReveal(index)
        }
    }
}

/// Mürekkep **yaprakta** okunur, çağıran görünümde değil.
///
/// Bir ekran `@Environment(\.patikaInk)` okuyup metnine uygularsa, o ekran kartın
/// *dışında* durduğu için `.light` görür; oluşturduğu metin ise kartın içine yerleşir ve
/// kâğıtta açık renkle görünmez kalır. Ortam değeri, görünümün kendi hiyerarşisinden
/// geldiği için değiştirici (modifier) doğru yerde okur.
enum InkRole { case primary, secondary }

private struct InkStyle: ViewModifier {
    let role: InkRole
    @Environment(\.patikaInk) private var ink

    func body(content: Content) -> some View {
        content.foregroundStyle(role == .primary ? ink.primary : ink.secondary)
    }
}

extension View {
    func inkStyle(_ role: InkRole = .primary) -> some View {
        modifier(InkStyle(role: role))
    }

    func statementReveal(_ index: Int) -> some View {
        modifier(SurfaceReveal(index: index))
    }

    func onboardingSurfaceCard(_ style: OnboardingSurfaceStyle) -> some View {
        modifier(OnboardingSurfaceCard(style: style))
    }
}
