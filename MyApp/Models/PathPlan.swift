import Foundation

/// F2'de gösterilen yol haritasının iskeleti — PRD §9.3 (21 günlük ark) ve
/// PRD-Ek Onboarding §7.2.
///
/// ## Neden burada hesaplanıyor
///
/// Harita ekranı "gün 1–3 rahatlama, gün 7 ölçüm" gibi kararları `if`'lerle
/// kurmaz; sıralamayı ve ölçüm noktalarının nereye düştüğünü bu tip söyler.
/// Path üretimi geldiğinde sunucudan gelen gerçek adımlar aynı satır tipine
/// dönüştürülür ve ekran değişmez.
///
/// ## Zor içerik arka yarıda — bilinçli
///
/// Faz sınırları 21 günlük arka göre oranlanır: rahatlama ilk %14'te, kaçınmayla
/// yüzleşme %67'den sonra. Sıra pedagojik olarak doğru olduğu kadar ticari bir
/// karardır da: "bu kadarı yeter" hissini geciktiriyor (PRD §9.3).
enum PathPlan {

    /// Haritadaki bir satır.
    enum Row: Identifiable, Equatable {
        /// Bir faz ve kapsadığı gün aralığı.
        case phase(PathPhase, ClosedRange<Int>)
        /// Ölçüm günü. `isFirst` olan satır "İlk ölçüm" diye adlandırılır —
        /// 7. gün akışın vaat ettiği ilk somut karşılık, öne çıkması gerekiyor.
        case measurement(day: Int, isFirst: Bool)

        var id: String {
            switch self {
            case .phase(let phase, let range): "phase-\(phase.rawValue)-\(range.lowerBound)"
            case .measurement(let day, _): "measurement-\(day)"
            }
        }

        /// Kompakt fallback haritasında faz satırı doğrudan bir eşiktir;
        /// ölçüm satırı aynı fazın içinde kalır.
        var startsPhase: Bool {
            if case .phase = self { return true }
            return false
        }
    }

    /// Faz sınırları — toplam günün oranı olarak. 21 günde tam olarak PRD §9.3'ün
    /// tablosunu verir (1–3 / 4–7 / 8–14 / 15–20 / 21).
    private static let phaseBoundaries: [(PathPhase, Double)] = [
        (.relief, 0.143),
        (.awareness, 0.333),
        (.skill, 0.667),
        (.behavior, 0.952),
    ]

    static func rows(for length: PathLength) -> [Row] {
        let total = length.days
        var rows: [Row] = []

        // Fazlar. Son gün her zaman kapanışa ayrılır; kalan günler oranlara göre
        // bölünür ve her fazın en az bir günü olur — kısa path'lerde (7 gün)
        // oranlar aynı güne düşebiliyor.
        var start = 1
        for (phase, fraction) in phaseBoundaries {
            let end = max(start, min(Int((Double(total) * fraction).rounded()), total - 1))
            rows.append(.phase(phase, start...end))
            start = end + 1
            if start >= total { break }
        }
        rows.append(.phase(.closing, total...total))

        // Ölçüm noktaları. Gün 1 (baseline) haritada görünmez: kullanıcı onu az
        // önce onboarding'de doldurdu, ileriye dönük bir kilometre taşı değil.
        // Son gün de ayrı satır almaz — kapanış satırı zaten "son ölçüm" diyor,
        // aynı günü iki kez yazmak haritayı uzatıp anlamı bölerdi.
        let measurementDays = length.measurementDays.filter { $0 > 1 && $0 < total }

        for (index, day) in measurementDays.enumerated() {
            guard let position = rows.lastIndex(where: { row in
                if case .phase(_, let range) = row { return range.contains(day) }
                return false
            }) else { continue }
            rows.insert(.measurement(day: day, isFirst: index == 0), at: position + 1)
        }

        return rows
    }

    /// Tek bir günün ait olduğu faz. Harita ekranları faz sınırlarını kendi
    /// içinde yeniden hesaplamaz; fallback ve gerçek path aynı kaynağı okur.
    static func phase(on day: Int, length: PathLength) -> PathPhase? {
        for case .phase(let phase, let range) in rows(for: length)
        where range.contains(day) {
            return phase
        }
        return nil
    }

    /// Faz etiketinin yalnızca gerçek başlangıç gününde görünmesini sağlar.
    static func startsPhase(on day: Int, length: PathLength) -> Bool {
        rows(for: length).contains { row in
            guard case .phase(_, let range) = row else { return false }
            return range.lowerBound == day
        }
    }

    /// F2'nin kompakt fallback satırını gerçek faz ritmine bağlar.
    static func phase(for row: Row, length: PathLength) -> PathPhase? {
        switch row {
        case .phase(let phase, _):
            phase
        case .measurement(let day, _):
            phase(on: day, length: length)
        }
    }
}
