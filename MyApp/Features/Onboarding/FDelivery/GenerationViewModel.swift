import Foundation
import Observation

/// F1 — üretim ekranının durumu (PRD-Ek Onboarding §7.1).
///
/// ## Bekleyiş performans değil
///
/// Cal AI'ın "planınız hesaplanıyor" ekranı büyük ihtimalle performatif. Bizde
/// path üretimi **gerçekten** birkaç saniye sürüyor (canlı ölçüm: TR path 3 sn'de
/// 21 adım). Adımları göstermek bekleyişi değere çeviriyor — kullanıcı ne
/// beklediğini biliyor.
///
/// ## Gerçek ağ çağrısı, ölçülü ara aşamalar (2026-09-22 düzeltmesi)
///
/// `completedStages` **1**den başlar (kullanıcının yazdıkları zaten okundu) ve
/// gerçek `flow.generatePath` çağrısı uçarken 2. ve 3. aşama ölçülü bir tempoyla
/// ilerler (`pacedAdvance`) — bu bir zamanlayıcı simülasyonu değil, gerçek ağ
/// isteği devam ederken ekranın "bir şey oluyor" demesi. **4. aşama yalnızca
/// gerçek sonuç gelince işaretlenir**; önceki sürümdeki "tek atlayış" (1'den
/// doğrudan 4'e) burada düzeltildi — 2. ve 3. satır artık gerçekten aktif oluyor.
/// Ağ hızlı dönerse (`< 2,2 sn`) ara aşamalar yine de en az bir kare görünür kalır
/// (`minStepDisplay`) — aksi hâlde eş zamanlı iki atama tek karede birleşip aynı
/// "atlama" hissini geri getirirdi.
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

    /// Ara aşamaların (2. ve 3.) her birinin ekranda kalması gereken en az süre.
    /// Ağ hızlı dönse bile bu kadar görünür kalır — yoksa arka arkaya iki atama
    /// aynı karede birleşip eski "1'den 4'e atlama" hissini geri getirirdi.
    private let minStepDisplay: Duration = .milliseconds(650)

    func start() {
        guard task == nil else { return }
        hasFailed = false
        failureDetail = nil
        completedStages = 1
        task = Task { @MainActor in
            // Gerçek ağ isteği uçarken 2. ve 3. aşama ölçülü bir tempoyla ilerler.
            // Bu bir sahte zamanlayıcı değil: istek gerçekten sürüyor, yalnızca
            // ekran bu süre boyunca sessiz kalmıyor.
            let pacing = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1.2))
                guard let self, !Task.isCancelled, completedStages < 2 else { return }
                completedStages = 2
                try? await Task.sleep(for: .seconds(1.6))
                guard !Task.isCancelled, completedStages < 3 else { return }
                completedStages = 3
            }
            do {
                let result = try await flow.generatePath(idempotencyKey: idempotencyKey)
                pacing.cancel()
                guard !Task.isCancelled else { return }
                switch result {
                case .crisis:
                    flow.flagCrisis()
                case .ready:
                    // Ses üretimi burada başlar ve beklenmez (JIT, PRD-Ek Path
                    // Üretimi §6): kullanıcı haritayı okurken ses üretiliyor.
                    flow.prepareFirstStepAudio()
                    // 4. aşama yalnızca gerçek sonuç geldiğinde işaretlenir; ama
                    // ağ ara aşamalardan daha hızlı dönmüşse önce onlardan geçilir —
                    // "yolu sıraya diziyorum" hiç görünmeden bitmiş göstermek yalan.
                    if completedStages < 2 {
                        completedStages = 2
                        try? await Task.sleep(for: minStepDisplay)
                    }
                    if completedStages < 3 {
                        completedStages = 3
                        try? await Task.sleep(for: minStepDisplay)
                    }
                    completedStages = stages.count
                    try? await Task.sleep(for: .seconds(0.45))
                    guard !Task.isCancelled else { return }
                    flow.finishGeneration()
                }
            } catch {
                pacing.cancel()
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
