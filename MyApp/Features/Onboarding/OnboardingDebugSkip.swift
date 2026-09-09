#if DEBUG
import SwiftUI

/// Geliştirme sırasında akışı ileri sarma — **yalnızca DEBUG**.
///
/// Release derlemesinde bu dosyanın tamamı derlenmez: `#if DEBUG` en dışta.
/// Onboarding otuz üç ekran ve F/G bölümlerini her denemede baştan geçmek
/// geliştirmeyi durduruyordu; buradaki taslak gerçek bir kullanıcının verebileceği
/// cevaplarla dolduruluyor, uydurma değer yok — path üretimi gerçek payload'la
/// çalışsın diye.
///
/// Ölçüm cevapları `MeasurementLibrary`den türetiliyor, elle yazılmıyor: madde
/// listesi değiştiğinde bu dosya sessizce eksik cevap üretmesin.
extension OnboardingDraft {
    static func debugSample(category: ProblemCategory = .sleep) -> OnboardingDraft {
        var draft = OnboardingDraft()
        draft.name = "Taner"
        draft.gender = .man
        draft.ageRange = .twentyFiveToThirtyFour
        draft.categories = [category]
        draft.problemText = "Geceleri yatağa girince kafam durmuyor, uyumam saatler sürüyor."
        draft.duration = .months
        draft.timing = .bedtime
        draft.avoidanceText = "Akşamları arkadaşlarla buluşmayı erteliyorum."
        draft.previousAttempts = [.otherApps, .youtube]
        draft.currentMood = .heavy
        draft.tonePreference = .calmAndShort
        draft.reminderHour = ProblemTiming.bedtime.suggestedReminderHour
        draft.sessionLength = .standard

        for item in MeasurementLibrary.items(for: .baseline, category: category) {
            draft.measurementResponses[item.id] = Self.debugAnswer(for: item)
        }
        return draft
    }

    /// Ölçeğin ortası: uç değerler baseline'ı bir yöne yaslıyor ve 7. gündeki
    /// karşılaştırmayı denerken yanıltıcı oluyordu.
    private static func debugAnswer(for item: MeasurementItem) -> Double {
        switch item.style {
        case .intensity:
            return 6
        case .choice(let options):
            guard !options.isEmpty else { return 0 }
            return options[options.count / 2].value
        }
    }
}

extension OnboardingFlowViewModel {
    /// Taslağı örnek cevaplarla doldurup verilen adıma atlar.
    ///
    /// Palet de senkronlanır — atladıktan sonra arka planın kategoriyle
    /// eşleşmemesi, ekranın gerçekte nasıl göründüğünü yanlış gösteriyordu.
    func debugJump(to target: OnboardingStep, category: ProblemCategory = .sleep) {
        debugApply(draft: .debugSample(category: category))
        debugSetStep(target)
    }
}

extension OnboardingFlowViewModel {
    /// `-patika-debug-step f1` gibi bir başlatma argümanıyla akışı doğrudan bir
    /// adımdan açar.
    ///
    /// Düğmeye ek olarak var çünkü ikisi farklı işe yarıyor: düğme akışın
    /// ortasındayken ileri sarmak için, argüman **her çalıştırmada aynı ekranda
    /// açılmak** için. Xcode şemasına bir kez yazılınca F ve G bölümlerinde
    /// çalışırken her seferinde otuz ekran geçilmiyor. Simülatörde:
    /// `xcrun simctl launch booted <bundle-id> -patika-debug-step f1`
    func applyDebugLaunchStepIfNeeded() {
        guard step == .a1Welcome else { return }
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-patika-debug-step"),
              arguments.index(after: flagIndex) < arguments.endIndex,
              let target = OnboardingStep(debugName: arguments[arguments.index(after: flagIndex)])
        else { return }
        debugJump(to: target)
    }
}

extension OnboardingStep {
    init?(debugName: String) {
        switch debugName.lowercased() {
        case "a2": self = .a2Categories
        case "b1": self = .b1ProblemText
        case "c1": self = .c1Mirroring
        case "d0": self = .d0MeasurementIntro
        case "d1": self = .dMeasurement(1)
        case "e1": self = .e1Reminder
        case "f1": self = .f1Generation
        case "f2": self = .f2Roadmap
        case "g1": self = .g1FirstSession
        case "g2": self = .g2SessionComplete
        case "h1": self = .h1Account
        default: return nil
        }
    }
}

/// DEBUG derlemede kabuğun sağ üstünde duran ileri sarma düğmesi.
///
/// Görünür bir düğme, gizli bir jest yerine bilinçli seçim: gizli jest üç ay
/// sonra kimsenin hatırlamadığı bir bilgi oluyor ve yanlışlıkla tetikleniyor.
struct OnboardingDebugSkipButton: View {
    let flow: OnboardingFlowViewModel

    var body: some View {
        Menu {
            Button("F1 · Üretim") { flow.debugJump(to: .f1Generation) }
            Button("G1 · İlk oturum") { flow.debugJump(to: .g1FirstSession) }
            Button("G2 · Oturum sonu") { flow.debugJump(to: .g2SessionComplete) }
            Button("H1 · Hesap") { flow.debugJump(to: .h1Account) }
            Divider()
            Button("D1 · Ölçüm") { flow.debugJump(to: .dMeasurement(1)) }
            Button("E1 · Tercihler") { flow.debugJump(to: .e1Reminder) }
        } label: {
            Image(systemName: "forward.end.alt")
                .font(.footnote.weight(Theme.Weight.action))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.55))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Geliştirici: akışı ileri sar")
    }
}
#endif
