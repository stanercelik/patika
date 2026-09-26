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

/// Ülkeye göre hatlar. Listede olmayan ülke genel acil numaraya (112) ve
/// "Other helplines in your country" dizinine düşer.
///
/// 26 Eylül 2026: uygulama tüm ülkelerde satışa açıldığı için 20 ülke eklendi;
/// numaralar ülkenin resmî sayfası ya da findahelpline.com ülke sayfasıyla
/// karşılaştırıldı (CA 988.ca, AU lifeline.org.au, FR 3114.fr, ES sanidad.gob.es,
/// IN telemanas.mohfw.gov.in).
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
        case "CA":
            [line("ca-988", Copy.Support.ca988Name, Copy.Support.us988Detail, "988"), emergency("911")]
        case "AU":
            [line("au-lifeline", Copy.Support.auLifelineName, Copy.Support.crisisLineDetail, "13 11 14", "131114"), emergency("000")]
        case "NZ":
            [line("nz-1737", Copy.Support.nz1737Name, Copy.Support.us988Detail, "1737"), emergency("111")]
        case "IE":
            [line("ie-samaritans", Copy.Support.gbSamaritansName, Copy.Support.gbSamaritansDetail, "116 123", "116123"), emergency("112")]
        case "FR":
            [line("fr-3114", Copy.Support.fr3114Name, Copy.Support.crisisLineDetail, "3114"), emergency("112")]
        case "ES":
            [line("es-024", Copy.Support.es024Name, Copy.Support.crisisLineDetail, "024"), emergency("112")]
        case "IT":
            [line("it-telefono-amico", Copy.Support.itTelefonoAmicoName, Copy.Support.gbSamaritansDetail, "02 2327 2327", "0223272327"), emergency("112")]
        case "NL":
            [line("nl-113", Copy.Support.nl113Name, Copy.Support.crisisLineDetail, "113"), emergency("112")]
        case "AT":
            [line("at-telefonseelsorge", Copy.Support.deTelefonSeelsorgeName, Copy.Support.deTelefonSeelsorgeDetail, "142"), emergency("112")]
        case "CH":
            [line("ch-143", Copy.Support.chDargeboteneHandName, Copy.Support.gbSamaritansDetail, "143"), emergency("144")]
        case "SE":
            [line("se-mind", Copy.Support.seMindName, Copy.Support.crisisLineDetail, "90101"), emergency("112")]
        case "NO":
            [line("no-kirkens-sos", Copy.Support.noKirkensSosName, Copy.Support.crisisLineDetail, "22 40 00 40", "22400040"), emergency("113")]
        case "DK":
            [line("dk-livslinien", Copy.Support.dkLivslinienName, Copy.Support.crisisLineDetail, "70 201 201", "70201201"), emergency("112")]
        case "FI":
            [line("fi-mieli", Copy.Support.fiMieliName, Copy.Support.crisisLineDetail, "09 2525 0111", "0925250111"), emergency("112")]
        case "BR":
            [line("br-cvv", Copy.Support.brCvvName, Copy.Support.gbSamaritansDetail, "188"), emergency("192")]
        case "MX":
            [line("mx-linea-vida", Copy.Support.mxLineaVidaName, Copy.Support.crisisLineDetail, "800 911 2000", "8009112000"), emergency("911")]
        case "JP":
            [line("jp-yorisoi", Copy.Support.jpYorisoiName, Copy.Support.gbSamaritansDetail, "0120-279-338", "0120279338"), emergency("119")]
        case "SG":
            [line("sg-sos", Copy.Support.sgSosName, Copy.Support.crisisLineDetail, "1767"), emergency("995")]
        case "ZA":
            [line("za-sadag", Copy.Support.zaSadagName, Copy.Support.crisisLineDetail, "0800 567 567", "0800567567"), emergency("112")]
        case "IN":
            [line("in-tele-manas", Copy.Support.inTeleManasName, Copy.Support.mentalHealthLineDetail, "14416"), emergency("112")]
        default:
            [emergency("112")]
        }
    }

    private static func line(
        _ id: String,
        _ name: LocalizedStringResource,
        _ detail: LocalizedStringResource,
        _ displayNumber: String,
        _ dialNumber: String? = nil
    ) -> SupportLine {
        SupportLine(id: id, name: name, detail: detail, displayNumber: displayNumber, dialNumber: dialNumber ?? displayNumber)
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
