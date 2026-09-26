import SwiftUI

/// Guaj sahne üstündeki soru ve seçenekleri arka planın açık bölgelerinden ayırır.
/// Bu yüzey cam değildir; sahnenin kimliğini koruyan, yerel ve sabit koyu bir levhadır.
struct SceneContentPlate<Content: View>: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: Theme.OnboardingLayout.plateCornerRadius)
                    .fill(WoodlandStyle.scenePlate.color.opacity(contrast == .increased ? 1 : 0.94))
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.OnboardingLayout.plateCornerRadius)
                    .strokeBorder(WoodlandStyle.scenePlateBorder.color, lineWidth: Theme.Line.border)
            }
            .environment(\.patikaInk, .light)
    }
}
