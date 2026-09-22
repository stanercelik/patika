import SwiftUI

/// Colors sampled from the approved gouache illustrations.
enum WoodlandStyle {
    static let background = RGB(hex: 0x101918).color
    static let surface = RGB(hex: 0x1B2928).color
    static let paper = RGB(hex: 0xEDE7D9).color
    static let ink = RGB(hex: 0x203C36).color
    static let secondaryInk = RGB(hex: 0x4A6058).color
    static let apricot = RGB(hex: 0xE9BA8F).color
    static let sage = RGB(hex: 0x9BAE9B).color
    static let scenePlate = RGB(hex: 0x15211F)
    static let scenePlateSecondary = RGB(hex: 0xB9C4BF)
    static let scenePlateBorder = RGB(hex: 0x60716B)
    static let timeMorningTint = RGB(hex: 0xD9A978)
    static let timeDayTint = RGB(hex: 0xA8BCA1)
    static let timeEveningTint = RGB(hex: 0xB97858)
    static let timeNightTint = RGB(hex: 0x314B63)
    static let timeNeutralTint = RGB(hex: 0x667773)

}

struct WoodlandGlassSurface: ViewModifier {
    var cornerRadius: CGFloat = 24
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        if reduceTransparency || contrast == .increased {
            content.background(WoodlandStyle.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            content
                .glassEffect(.regular.tint(WoodlandStyle.ink.opacity(0.65)), in: .rect(cornerRadius: cornerRadius))
                .environment(\.colorScheme, .dark)
        }
    }
}
