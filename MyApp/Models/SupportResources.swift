import Foundation

/// "Destek al" ekranındaki bir hat.
///
/// PRD §11: kriz anında harita değil **numara** gösterilir ve tek dokunuşla
/// arama başlar. Yönlendirme komisyonu, terapist reklamı yok.
struct SupportLine: Identifiable, Sendable {
    let id: String
    let name: LocalizedStringResource
    let detail: LocalizedStringResource
    let displayNumber: String
    let dialNumber: String

    var callURL: URL? { URL(string: "tel:\(dialNumber)") }
}

/// Ülkeye göre hatlar (TR / DE / US / GB, diğerleri için genel acil numara).
///
/// > **Yayından önce doğrulanmalı.** Numaralar her ülkenin resmî kaynağından
/// > yeniden kontrol edilmeli; yanlış bir numara bu ekranın var olma sebebini
/// > çürütür. Hatlar remote config'e taşındığında buradaki liste yalnızca
/// > çevrimdışı yedek olarak kalmalı.
enum SupportResources {
    static let directoryURL = URL(string: "https://findahelpline.com")!

    static func lines(regionCode: String?) -> [SupportLine] {
        switch regionCode?.uppercased() {
        case "TR":
            [
                emergency("112"),
                SupportLine(
                    id: "tr-183",
                    name: Copy.Support.trSocialSupportName,
                    detail: Copy.Support.trSocialSupportDetail,
                    displayNumber: "183",
                    dialNumber: "183"
                ),
            ]
        case "DE":
            [
                SupportLine(
                    id: "de-telefonseelsorge",
                    name: Copy.Support.deTelefonSeelsorgeName,
                    detail: Copy.Support.deTelefonSeelsorgeDetail,
                    displayNumber: "0800 111 0 111",
                    dialNumber: "08001110111"
                ),
                emergency("112"),
            ]
        case "US":
            [
                SupportLine(
                    id: "us-988",
                    name: Copy.Support.us988Name,
                    detail: Copy.Support.us988Detail,
                    displayNumber: "988",
                    dialNumber: "988"
                ),
                emergency("911"),
            ]
        case "GB":
            [
                SupportLine(
                    id: "gb-samaritans",
                    name: Copy.Support.gbSamaritansName,
                    detail: Copy.Support.gbSamaritansDetail,
                    displayNumber: "116 123",
                    dialNumber: "116123"
                ),
                emergency("999"),
            ]
        default:
            [emergency("112")]
        }
    }

    private static func emergency(_ number: String) -> SupportLine {
        SupportLine(
            id: "emergency-\(number)",
            name: Copy.Support.emergencyName,
            detail: Copy.Support.emergencyDetail,
            displayNumber: number,
            dialNumber: number
        )
    }
}
