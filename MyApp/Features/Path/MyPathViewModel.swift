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
    /// Açık duran adım. Varsayılan olarak sıradaki adım: ekran açıldığında
    /// kullanıcının yapacağı şey zaten açık duruyor, bir dokunuş kazanılıyor.
    private(set) var expandedStepID: UUID?

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

    /// Bir satıra dokunmak onu açar, açık olanı kapatır.
    ///
    /// Sıradaki adım istisna: dokunmak onu kapatmıyor. Ekranın birincil eylemi
    /// o kart ve kullanıcının kendi dokunuşuyla kaybolması, aradığı şeyi
    /// aramaya geri döndürüyordu.
    func toggle(_ step: PathStepRecord) {
        if expandedStepID == step.id {
            guard step.id != nextStep?.id else { return }
            expandedStepID = nil
        } else {
            expandedStepID = step.id
        }
    }

    // MARK: - Satırın hâli

    /// Sıradaki adımdan sonrası **henüz açılmadı**.
    ///
    /// Bu bir ödül mekaniği değil, sıranın kendisi: adımlar birbirinin üstüne
    /// biniyor ve 9. adım 3. adım dinlenmeden anlamını kaybediyor. Başlığı yine
    /// de okunuyor — ne aldığını görmek ürünün vaadi; kapalı olan yalnızca
    /// bugün dinlenebilmesi.
    func isLocked(_ step: PathStepRecord) -> Bool {
        guard step.completedAt == nil else { return false }
        guard let next = nextStep else { return true }
        return step.day > next.day
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
        for case .phase(let phase, let range) in PathPlan.rows(for: length)
        where range.contains(step.day) {
            return phase
        }
        return nil
    }

    /// Adımın taşıdığı teknikler. Sunucunun seçtiği `block_ids` istemcideki
    /// kütüphaneden çözülüyor: kimlikler iki tarafta birebir aynı.
    func techniques(for step: PathStepRecord) -> String? {
        let titles = step.blockIds
            .compactMap(BlockLibrary.block(id:))
            .map { String(localized: $0.title) }
        return titles.isEmpty ? nil : titles.joined(separator: " · ")
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
