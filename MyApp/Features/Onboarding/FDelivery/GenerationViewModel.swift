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

    let stages: [LocalizedStringResource] = Copy.Loading.steps

    /// Aşama başına bekleme. Eşit değil: son aşama (ses üretimi) gerçekte de en
    /// uzun süren adım.
    private let durations: [TimeInterval] = [2.2, 2.6, 2.8, 3.4]

    private let onFinished: () -> Void
    private var task: Task<Void, Never>?

    init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    func state(of index: Int) -> TrailNode {
        if index < completedStages { return .done }
        if index == completedStages { return .active }
        return .pending
    }

    func isActive(_ index: Int) -> Bool { index == completedStages }

    func start() {
        guard task == nil else { return }
        task = Task { @MainActor in
            for index in stages.indices {
                try? await Task.sleep(for: .seconds(durations[min(index, durations.count - 1)]))
                guard !Task.isCancelled else { return }
                completedStages = index + 1
            }
            // Son satır işaretlendikten sonra kısa bir duruş: ekran biter bitmez
            // kaymak, tamamlanmayı görmeye zaman bırakmıyor.
            try? await Task.sleep(for: .seconds(0.7))
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
