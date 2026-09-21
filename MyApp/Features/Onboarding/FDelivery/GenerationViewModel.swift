import Foundation
import Observation

/// F1 — üretim ekranının durumu (PRD-Ek Onboarding §7.1).
///
/// ## Bekleyiş performans değil
///
/// Cal AI'ın "planınız hesaplanıyor" ekranı büyük ihtimalle performatif. Bizde
/// path üretimi **gerçekten** 10–20 saniye sürüyor: sınıflandırma, şablon
/// seçimi, blok sıralaması, ses üretimi. Adımları göstermek bekleyişi değere
/// çeviriyor — kullanıcı ne beklediğini biliyor.
///
/// ## Şu an sahte, ama sahteliği gizlenmiyor
///
/// Ağ katmanı yazılmadığı için aşamalar zamanlayıcıyla ilerliyor. Gerçek üretim
/// geldiğinde `advance()` çağrısı sunucudan gelen ilerleme olaylarına bağlanır ve
/// ekran değişmez. Süreler o yüzden **gerçekçi** seçildi (toplam ~11 sn):
/// zamanlayıcı 2 saniyede bitseydi, gerçek üretim eklendiğinde ekran bambaşka
/// hissettirirdi.
///
/// Espri yok, ilerleme yüzdesi yok, "neredeyse bitti" yalanı yok — kullanıcı az
/// önce derdini anlattı, bu an ciddi (Ton eki §3.3).
@Observable
@MainActor
final class GenerationViewModel {
    /// Tamamlanan aşama sayısı. `stages.count`a ulaşınca ekran teslime geçer.
    private(set) var completedStages = 0
    private(set) var hasFailed = false
    /// Hatanın teknik açıklaması. Kullanıcıya **gösterilmez** (`Copy.Error`
    /// yeterli); DEBUG derlemede ekranda ve konsolda görünür, çünkü "bir şeyler
    /// ters gitti" hata ayıklanabilir bir bilgi değil.
    private(set) var failureDetail: String?

    let stages: [LocalizedStringResource] = Copy.Loading.steps

    private let flow: OnboardingFlowViewModel
    private let idempotencyKey = UUID()
    private var task: Task<Void, Never>?

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
    }

    func state(of index: Int) -> TrailNode {
        if index < completedStages { return .done }
        if index == completedStages { return .active }
        return .pending
    }

    func isActive(_ index: Int) -> Bool { index == completedStages }

    func start() {
        guard task == nil else { return }
        hasFailed = false
        failureDetail = nil
        task = Task { @MainActor in
            completedStages = 1
            do {
                let result = try await flow.generatePath(idempotencyKey: idempotencyKey)
                guard !Task.isCancelled else { return }
                switch result {
                case .crisis:
                    flow.flagCrisis()
                case .ready:
                    // Ses üretimi burada başlar ve beklenmez (JIT, PRD-Ek Path
                    // Üretimi §6): kullanıcı haritayı okurken ses üretiliyor.
                    flow.prepareFirstStepAudio()
                    completedStages = stages.count
                    try? await Task.sleep(for: .seconds(0.45))
                    guard !Task.isCancelled else { return }
                    flow.finishGeneration()
                }
            } catch {
                guard !Task.isCancelled else { return }
                // İz son ulaştığı yerde kalır. Sıfıra dönmek, yapılmış işin
                // kaybolduğunu söylerdi — oysa "yazdıkların kaybolmadı" diyoruz.
                hasFailed = true
                failureDetail = (error as? LocalizedError)?.errorDescription
                    ?? String(describing: error)
                task = nil
                #if DEBUG
                print("[patika] path generation failed: \(failureDetail ?? "?")")
                #endif
            }
        }
    }

    func retry() {
        start()
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
