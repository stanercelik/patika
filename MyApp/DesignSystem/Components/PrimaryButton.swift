import SwiftUI

/// Birincil CTA — dolu hap. Pasifken metin değişir ve **ne eksik olduğunu söyler**;
/// kullanıcı neden ilerleyemediğini tahmin etmek zorunda kalmaz.
struct PrimaryButton: View {
    let title: LocalizedStringResource
    /// Pasif haldeyken gösterilecek metin. Nil ise `title` soluk gösterilir.
    var disabledTitle: LocalizedStringResource?
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            Theme.softHaptic()
            action()
        } label: {
            Text(isEnabled ? title : (disabledTitle ?? title))
                .font(.body.weight(Theme.Weight.action))
                .foregroundStyle(isEnabled ? Color.black : Theme.textSecondary.color)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .frame(minHeight: 44)
                .background {
                    Capsule()
                        .fill(isEnabled ? Theme.textPrimary.color : Color.white.opacity(0.10))
                }
        }
        .buttonStyle(.calm)
        .disabled(!isEnabled)
        .animation(Theme.Motion.crossFade, value: isEnabled)
    }
}

/// İkincil aksiyon — düz metin, altı çizili. Reddetmeyi suçsuzlaştıran ton (Ton eki §3.4).
struct SecondaryTextButton: View {
    let title: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(Theme.Weight.emphasis))
                .foregroundStyle(Theme.textSecondary.color)
                .underline()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44)
        }
        .buttonStyle(.calm)
    }
}
