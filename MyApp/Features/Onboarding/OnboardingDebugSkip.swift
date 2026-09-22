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
        draft.problemText = "My mind won't stop when I get into bed at night, and falling asleep takes hours."
        draft.duration = .months
        draft.timing = .bedtime
        draft.avoidanceText = "I keep putting off meeting friends in the evening."
        draft.previousAttempts = [.otherApps, .youtube]
        draft.currentMood = .heavy
        draft.tonePreference = .calmAndShort
        draft.voicePreference = .feminine
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
        case "identity", "name": self = .identityName
        case "gender": self = .identityGender
        case "age": self = .identityAge
        case "commit": self = .commitment
        case "price": self = .price
        case "h2": self = .h2Priming
        case "a2": self = .a2Categories
        case "b1": self = .b1ProblemText
        case "b2": self = .b2Duration
        case "b3": self = .b3Timing
        case "b4": self = .b4Avoidance
        case "b5": self = .b5PreviousAttempts
        case "b6": self = .b6CurrentMood
        case "c1": self = .c1Mirroring
        case "c2": self = .c2NotAlone
        case "c3": self = .c3PathNotLibrary
        case "c4": self = .c4HonestExpectation
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

/// Onboarding'i atlayıp doğrudan uygulama kabuğunu açmak — **yalnızca DEBUG**.
///
/// "Yolum" sekmesi gerçek bir path olmadan hiçbir şey göstermiyor ve o path
/// ancak onboarding'in sonunda üretiliyor. Ekran üzerinde çalışırken her
/// denemede otuz üç ekran geçmek yerine burası aynı işi yapıyor: anonim
/// kullanıcının path'i yoksa **gerçek** üretim çağrısını örnek taslakla atıyor,
/// varsa olanı kullanıyor. Sahte veri üretilmiyor — ekranın gösterdiği her
/// satır yine sunucudan geliyor.
///
/// `xcrun simctl launch booted <bundle-id> -patika-debug-step yolum`
enum DebugDirectEntry {
    static var opensRoot: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-patika-debug-step"),
              arguments.index(after: index) < arguments.endIndex
        else { return false }
        return ["yolum", "root", "path"].contains(arguments[arguments.index(after: index)].lowercased())
    }

    /// `-patika-debug-expand 5` ile "Yolum" ekranı o adım açık başlar.
    /// Açık satırın yanındakileri nasıl geri çektiğini simülatörde görmek
    /// dokunmadan mümkün olmuyordu.
    static var expandedDay: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-patika-debug-expand"),
              arguments.index(after: index) < arguments.endIndex
        else { return nil }
        return Int(arguments[arguments.index(after: index)])
    }

    static func prepareIfNeeded(services: AppServices) async {
        guard opensRoot else { return }
        let draft = OnboardingDraft.debugSample()
        if PathPreviewFixture.isEnabled || PathPreviewFixture.showsEmpty { return }
        do {
            let token = try await services.auth.validAccessToken()
            if let existing = try await services.backend.activePath(accessToken: token),
               !existing.steps.isEmpty {
                return
            }
            _ = try await services.backend.generatePathWithReconciliation(
                from: draft,
                measurementVariant: .a,
                accessToken: token,
                idempotencyKey: UUID()
            )
        } catch {
            services.observability.capture(.pathGeneration)
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
            Button("F1 · Generation") { flow.debugJump(to: .f1Generation) }
            Button("G1 · First session") { flow.debugJump(to: .g1FirstSession) }
            Button("G2 · Session end") { flow.debugJump(to: .g2SessionComplete) }
            Button("H1 · Account") { flow.debugJump(to: .h1Account) }
            Divider()
            Button("D1 · Measurement") { flow.debugJump(to: .dMeasurement(1)) }
            Button("E1 · Preferences") { flow.debugJump(to: .e1Reminder) }
        } label: {
            Image(systemName: "forward.end.alt")
                .font(.footnote.weight(Theme.Weight.action))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.55))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Developer: fast-forward the flow")
    }
}
#endif
