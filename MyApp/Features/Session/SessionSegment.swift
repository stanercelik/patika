import Foundation

/// Oturumdaki tek bir sahne.
///
/// Metin `String`, `LocalizedStringResource` değil: içeriğin bir kısmı sunucudan
/// (kişiselleştirilmiş yuvalar) ve bir kısmı kullanıcının kendi cümlesinden
/// geliyor. Sabit metinler `Copy`den okunup burada çözülüyor.
struct SessionSegment: Identifiable, Equatable {
    enum Kind: Equatable {
        /// Kişiselleştirilmiş açılış — seslendirilen kısım.
        case opening
        /// Kullanıcının kendi cümlesi. Aha momenti (PRD-Ek Onboarding §8).
        case ownWords
        /// Blok kütüphanesinden gelen sabit teknik.
        case technique
        /// Sunucudan gelen geçiş cümlesi.
        case bridge
        case closing
    }

    let id: String
    let text: String
    let kind: Kind
    var duration: TimeInterval
}
