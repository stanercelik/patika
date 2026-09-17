import Foundation
import Observation

/// "Yolum" sekmesi — onboarding sonrası patikanın hâli.
///
/// ## Ekrandaki her satır kullanıcının kendi path'inden geliyor
///
/// Başlıklar, teknikler ve sıra **üretilen path'in kendisi** (`ActivePath`):
/// A2'de seçtiği kategori, B1'de yazdığı cümle ve D bölümündeki cevapları
/// sunucuda bir plana dönüştü, bu ekran o planı okuyor. Hiçbir satır istemcide
/// uydurulmuyor; üretim gelmediyse ekran boş kalır, sahte bir yol çizmez.
///
/// ## Streak yok, kaçırılan gün için tek kelime yok
///
/// Kaçırılan gün hiçbir şeyi geri almıyor (Değiştirilemez kurallar). Dönüşte
/// söylenen tek şey sıradaki adımın hazır olduğu.
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
    /// Son yenilemede sunucuda ilk kez tamamlanmış görülen adım. Görünüm bunu
    /// yalnızca düğüm dönüşümü ve tek, yumuşak haptik için kullanır.
    private(set) var recentlyCompletedStepID: UUID?
    /// Açık duran adım. Varsayılan olarak sıradaki adım: ekran açıldığında
    /// kullanıcının yapacağı şey zaten açık duruyor, bir dokunuş kazanılıyor.
    private(set) var expandedStepID: UUID?
    #if DEBUG
    private(set) var isDesignPreview = false

    func showDesignPreview() {
        isDesignPreview = true
        state = .ready(PathPreviewFixture.path)
        expandedStepID = PathPreviewFixture.path.nextStep?.id
    }
    #endif

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

    var steps: [PathStepRecord] { path?.steps.sorted { $0.day < $1.day } ?? [] }

    func load() async {
        #if DEBUG
        if isDesignPreview { return }
        if PathPreviewFixture.showsEmpty { state = .empty; return }
        if PathPreviewFixture.isEnabled {
            if path == nil {
                state = .ready(PathPreviewFixture.path)
                expandedStepID = PathPreviewFixture.startsCollapsed ? nil : PathPreviewFixture.path.nextStep?.id
            }
            return
        }
        #endif
        let previousPath = path
        if previousPath == nil { state = .loading }
        recentlyCompletedStepID = nil
        do {
            let token = try await services.auth.validAccessToken()
            guard let path = try await services.backend.activePath(accessToken: token),
                  !path.steps.isEmpty
            else {
                state = .empty
                return
            }
            if let previousPath, previousPath.id == path.id {
                let completedBefore = Set(
                    previousPath.steps.compactMap { step in
                        step.completedAt == nil ? nil : step.id
                    }
                )
                recentlyCompletedStepID = path.steps
                    .filter { $0.completedAt != nil && !completedBefore.contains($0.id) }
                    .sorted { $0.day < $1.day }
                    .last?.id
            }

            state = .ready(path)
            expandedStepID = path.nextStep?.id
            #if DEBUG
            if let day = DebugDirectEntry.expandedDay {
                expandedStepID = path.steps.first { $0.day == day }?.id ?? expandedStepID
            }
            #endif
        } catch {
            services.observability.capture(.pathGeneration)
            state = .failed
        }
    }

    // MARK: - Seçim

    func isExpanded(_ step: PathStepRecord) -> Bool { expandedStepID == step.id }

    /// The current stop remains identified even when its details are closed.
    func isCurrent(_ step: PathStepRecord) -> Bool { step.id == nextStep?.id }

    func toggle(_ step: PathStepRecord) {
        guard !isLocked(step) else { return }
        expandedStepID = expandedStepID == step.id ? nil : step.id
    }

    // MARK: - Satırın hâli

    /// Sıradaki adımdan sonrası **henüz açılmadı**.
    ///
    /// Bu bir ödül mekaniği değil, sıranın kendisi: adımlar birbirinin üstüne
    /// biniyor ve 9. adım 3. adım dinlenmeden anlamını kaybediyor. Başlığı yine
    /// de okunuyor — ne aldığını görmek ürünün vaadi; kapalı olan yalnızca
    /// bugün dinlenebilmesi.
    func isLocked(_ step: PathStepRecord) -> Bool {
        JourneyStepAccess.isLocked(
            day: step.day,
            isCompleted: step.completedAt != nil,
            nextDay: nextStep?.day
        )
    }

    func isCompleted(_ step: PathStepRecord) -> Bool { step.completedAt != nil }

    func isMeasurementDay(_ step: PathStepRecord) -> Bool {
        measurementDays.contains(step.day)
    }

    /// Bir adımın iz üzerindeki hâli. Ölçüm günleri halkalı düğüm —
    /// **yıldız/emoji değil** (tek mürekkep kuralı).
    func node(for step: PathStepRecord) -> TrailNode {
        if step.completedAt != nil { return .done }
        if step.id == nextStep?.id { return .active }
        if isMeasurementDay(step) { return .milestone }
        return .pending
    }

    /// Adımın hangi faza düştüğü (PRD §9.3'ün 21 günlük arkı). Gün sayısından
    /// deterministik olarak türüyor — model takdiri değil.
    func phase(for step: PathStepRecord) -> PathPhase? {
        guard let length = PathLength(rawValue: steps.count) else { return nil }
        return PathPlan.phase(on: step.day, length: length)
    }

    func startsPhase(_ step: PathStepRecord) -> Bool {
        guard let length = PathLength(rawValue: steps.count) else { return false }
        return PathPlan.startsPhase(on: step.day, length: length)
    }

    /// Adımın taşıdığı teknikler. Sunucunun seçtiği `block_ids` istemcideki
    /// kütüphaneden çözülüyor: kimlikler iki tarafta birebir aynı.
    func techniques(for step: PathStepRecord) -> String? {
        BlockLibrary.techniqueSummary(for: step.blockIds)
    }

    /// Ölçüm günleri path uzunluğundan geliyor; adım sayısı uzunluğun kendisi.
    ///
    /// **1. gün işaretlenmiyor**: baseline ölçümü onboarding'de dolduruldu,
    /// ileriye dönük bir nokta değil. F2 haritası da aynı sebeple atlıyor.
    private var measurementDays: [Int] {
        guard let length = PathLength(rawValue: steps.count) else { return [] }
        return length.measurementDays.filter { $0 > 1 }
    }
}
