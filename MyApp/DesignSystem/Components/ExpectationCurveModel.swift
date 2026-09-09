import Foundation

/// C4 sürec grafiğinin veri sözleşmesi.
///
/// Değerler ölçüm sonucu değildir; iki ürün yaklaşımının zaman içindeki şeklini
/// tarif eden normalize görsel koordinatlardır. Bu nedenle dikey eksende sayı
/// gösterilmez ve kullanıcıya sonuç vaadi olarak sunulmaz.
enum ExpectationCurveModel {
    struct Point: Equatable, Sendable {
        let day: Int
        let level: Double
    }

    static let turningDay = 8
    static let totalDays = 21

    /// Kısa süreli hareket üretip kalıcı bir yol kurmayan uygulamalar.
    static let otherApps: [Point] = [
        .init(day: 0, level: 0.52),
        .init(day: 2, level: 0.60),
        .init(day: 4, level: 0.49),
        .init(day: 6, level: 0.56),
        .init(day: 8, level: 0.44),
        .init(day: 10, level: 0.50),
        .init(day: 12, level: 0.38),
        .init(day: 14, level: 0.42),
        .init(day: 16, level: 0.34),
        .init(day: 18, level: 0.37),
        .init(day: 21, level: 0.28),
    ]

    /// Patika: ilk günlerde küçük adımlar, 7–8. günden sonra birikimi görünür
    /// kılan ve giderek hızlanan bir yol.
    static let patika: [Point] = [
        .init(day: 0, level: 0.18),
        .init(day: 2, level: 0.19),
        .init(day: 4, level: 0.21),
        .init(day: 6, level: 0.23),
        .init(day: 8, level: 0.27),
        .init(day: 10, level: 0.31),
        .init(day: 12, level: 0.38),
        .init(day: 14, level: 0.49),
        .init(day: 16, level: 0.64),
        .init(day: 18, level: 0.80),
        .init(day: 21, level: 0.96),
    ]
}
