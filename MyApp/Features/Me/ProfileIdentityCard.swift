import SwiftUI
import UIKit

/// "Ben" sayfasının başındaki kimlik kartı — fotoğraf, ad, yol, "N. adım · faz",
/// mini iz ve bu haftanın yedi noktası (`docs/profile-design.md` §21.3).
///
/// - Ad yoksa ad satırı hiç yoktur; yol adı başlık rolünü alır. "Sen" ya da
///   "Misafir" yazılmaz (kimlik bloğu kuralı).
/// - Yol yoksa adım satırı ve iz çizilmez; hafta noktaları yol olmadan da durur.
/// - Haftada 0 gün varsa noktalar boş kalır ve yanında metin **yazılmaz**.
/// - Kriz modunda iz ve hafta yoktur (`progress` ve `rhythm` nil gelir): seri
///   o anda yanlış bir dil olurdu.
///
/// VoiceOver: metin, iz ve noktalar tek öğe; fotoğraf ve ayarlar ayrı eylemler.
struct ProfileIdentityCard: View {
    let name: String?
    let avatar: UIImage?
    let pathTitle: String?
    let detail: String?
    /// 0…1. nil ise iz çizilmez.
    let progress: Double?
    let rhythm: WeeklyRhythm?
    let summaryAccessibility: String
    var canEditPhoto = true
    let onPhoto: () -> Void
    let onSettings: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var avatarSize: CGFloat = 64

    var body: some View {
        ProfileCard {
            VStack(alignment: .leading, spacing: 16) {
                // Erişilebilir boyutlarda avatar ve metin alt alta: yan yana
                // olunca metin tek kelimelik sütuna sıkışıyordu.
                headerLayout {
                    avatarButton
                    identityText
                }
                if progress != nil || rhythm != nil {
                    progressRow
                }
            }
        }
        // Ayarlar düğmesi kartın içeriğinden bağımsız bir katmanda: metin onun
        // altına girmesin diye `identityText` sağdan boşluk bırakıyor.
        .overlay(alignment: .topTrailing) {
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(Theme.TypeFace.rowSymbol)
                    .foregroundStyle(Theme.textPrimary.color)
                    .frame(width: 44, height: 44)
                    .modifier(WoodlandGlassSurface(cornerRadius: 22))
                    .contentShape(.circle)
            }
            .buttonStyle(.calm)
            .padding(12)
            .accessibilityLabel(Text(Copy.Me.settingsButton))
        }
    }

    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 14))
    }

    /// Avatar metinle birlikte büyür ama sınırlı: AX5'te 64 pt'in ölçeklenmişi
    /// kartın yarısını kaplıyordu.
    private var resolvedAvatarSize: CGFloat { min(avatarSize, 96) }

    // MARK: Avatar

    private var avatarButton: some View {
        Button(action: onPhoto) {
            avatarFace
                .frame(width: resolvedAvatarSize, height: resolvedAvatarSize)
                .clipShape(.circle)
                .overlay {
                    Circle().strokeBorder(WoodlandStyle.sage.opacity(0.45), lineWidth: Theme.Line.journeyConnector)
                }
                .contentShape(.circle)
        }
        .buttonStyle(.calm)
        .disabled(!canEditPhoto)
        .accessibilityLabel(Text(Copy.Me.photoAccessibility))
    }

    /// Fotoğraf → adın baş harfi → `leaf`. Renk anlam taşımıyor: hepsi aynı krem
    /// disk.
    @ViewBuilder
    private var avatarFace: some View {
        if let avatar {
            Image(uiImage: avatar)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                WoodlandStyle.paper
                if let initial = Self.initial(of: name) {
                    Text(verbatim: initial)
                        .font(Theme.TypeFace.sectionTitle)
                        .foregroundStyle(WoodlandStyle.ink)
                } else {
                    Image(systemName: "leaf")
                        .font(Theme.TypeFace.rowSymbol)
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                }
            }
        }
    }

    static func initial(of name: String?) -> String? {
        guard let first = name?.trimmingCharacters(in: .whitespacesAndNewlines).first else { return nil }
        return String(first).uppercased(with: .current)
    }

    // MARK: Metin

    private var identityText: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let name {
                Text(verbatim: name)
                    .font(Theme.TypeFace.screenTitle)
                    .foregroundStyle(Theme.textPrimary.color)
            }
            if let pathTitle {
                Text(verbatim: pathTitle)
                    .font(name == nil ? Theme.TypeFace.screenTitle : Theme.TypeFace.rowTitle)
                    .foregroundStyle(name == nil ? Theme.textPrimary.color : Theme.textSecondary.color)
            }
            if let detail {
                Text(verbatim: detail)
                    .font(Theme.TypeFace.rowCaption)
                    .foregroundStyle(Theme.textSecondary.color)
            }
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        // Ayarlar düğmesi yalnızca yan yana düzende metnin sağında durur.
        .padding(.trailing, dynamicTypeSize.isAccessibilitySize ? 0 : 44)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: summaryAccessibility))
    }

    // MARK: İz ve hafta

    @ViewBuilder
    private var progressRow: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 16))
        layout {
            if let progress {
                SessionProgressTrail(progress: progress)
                    .frame(maxWidth: .infinity)
            }
            if let rhythm, !rhythm.days.isEmpty {
                WeeklyRhythmDots(rhythm: rhythm)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Bu haftanın yedi günü. Dolu nokta = o gün adım tamamlandı; halka = bugün.
/// Renk tek başına anlam taşımıyor: dolu/boş biçim farkı, bugün ayrı halka.
struct WeeklyRhythmDots: View {
    let rhythm: WeeklyRhythm

    private let size: CGFloat = 10

    var body: some View {
        HStack(spacing: 8) {
            ForEach(rhythm.days) { day in
                ZStack {
                    Circle()
                        .fill(day.isCompleted ? WoodlandStyle.sage : .clear)
                    Circle()
                        .strokeBorder(WoodlandStyle.sage.opacity(day.isCompleted ? 0 : 0.4), lineWidth: 1.5)
                    if day.isToday {
                        Circle()
                            .strokeBorder(Theme.textPrimary.color.opacity(0.9), lineWidth: 1.5)
                            .padding(-4)
                    }
                }
                .frame(width: size, height: size)
            }
        }
        .padding(.horizontal, 4)
        .fixedSize()
    }
}
