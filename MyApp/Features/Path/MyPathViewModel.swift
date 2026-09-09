import Foundation
import Observation

/// "Yolum" sekmesi — onboarding sonrası patikanın hâli.
///
/// Ekranda **streak yok, kaçırılan gün için tek kelime yok**: kaçırılan gün
/// hiçbir şeyi geri almıyor (Değiştirilemez kurallar). Dönüşte söylenen tek şey
/// sıradaki adımın hazır olduğu.
@Observable
@MainActor
final class MyPathViewModel {
    enum State: Equatable {
        case loading
        case empty
        case ready(ActivePath)
        case failed
    }

    private(set) var state: State = .loading

    private let services: AppServices

    init(services: AppServices) {
        self.services = services
    }

    var path: ActivePath? {
        if case .ready(let path) = state { return path }
        return nil
    }

    /// Sıradaki adım: tamamlanmamış ilk gün. Hepsi tamamlandıysa nil ve ekran
    /// yolun bittiğini söyler.
    var nextStep: PathStepRecord? { path?.nextStep }

    func load() async {
        state = .loading
        do {
            let token = try await services.auth.validAccessToken()
            guard let path = try await services.backend.activePath(accessToken: token),
                  !path.steps.isEmpty
            else {
                state = .empty
                return
            }
            state = .ready(path)
        } catch {
            services.observability.capture(.pathGeneration)
            state = .failed
        }
    }

    /// Ölçüm günleri path uzunluğundan geliyor; adım sayısı uzunluğun kendisi.
    private var measurementDays: [Int] {
        guard let steps = path?.steps.count,
              let length = PathLength(rawValue: steps)
        else { return [] }
        return length.measurementDays
    }

    /// Bir adımın iz üzerindeki hâli. Ölçüm günleri halkalı düğüm —
    /// **yıldız/emoji değil** (tek mürekkep kuralı).
    func node(for step: PathStepRecord) -> TrailNode {
        if step.completedAt != nil { return .done }
        if step.id == nextStep?.id { return .active }
        if measurementDays.contains(step.day) { return .milestone }
        return .pending
    }
}
