import Foundation

/// Keşfet'in bölüm başlıkları. Patika kategorisinden türer; katalogda ayrı bir
/// alan yok, böylece bir patikanın hem kategorisi hem bölümü çelişemez.
///
/// Sıra ekrandaki sıradır. Patikası olmayan bölüm çizilmez.
enum DiscoverSection: String, CaseIterable, Identifiable, Sendable {
    /// Şiddetli anlarda yükü hafifleten patikalar.
    case relief
    /// Gün sonu ve tükenmişlik.
    case rest
    /// Dikkat ve insanların arasında bulunmak.
    case attention
    /// Kendine karşı tutum: sertlik, kayıp, adı konmamış.
    case toSelf

    var id: String { rawValue }

    init(category: ProblemCategory) {
        switch category {
        case .anxiety, .anger, .exam: self = .relief
        case .sleep, .burnout: self = .rest
        case .focus, .social: self = .attention
        case .selfcrit, .grief, .unnamed: self = .toSelf
        }
    }

    var title: String {
        switch self {
        case .relief: DiscoverCopy.sectionRelief
        case .rest: DiscoverCopy.sectionRest
        case .attention: DiscoverCopy.sectionAttention
        case .toSelf: DiscoverCopy.sectionToSelf
        }
    }
}

extension DiscoverPath {
    var section: DiscoverSection { DiscoverSection(category: category) }
}

/// Bir bölüm ve içindeki patikalar — ekrandaki bir şerit.
struct DiscoverShelf: Identifiable, Equatable, Sendable {
    let section: DiscoverSection
    let paths: [DiscoverPath]
    var id: String { section.id }
}
