import SwiftUI

/// Destek al (profile-design §6.7, PRD §11).
///
/// 🔴 Nötr kademe: hareket yok (`BreathAmplitude.crisis`), süsleme yok, satış
/// yok. Harita değil **numara**; tek dokunuşla arama başlar. Hiçbir zaman ödeme
/// duvarının ya da uygulama kilidinin arkasında değil.
struct SupportView: View {
    @Environment(\.dismiss) private var dismiss

    private let lines = SupportResources.lines(regionCode: Locale.current.region?.identifier)

    var body: some View {
        ZStack {
            // Kriz kaynakları: düz zemin, hareket yok, dekoratif hiçbir şey.
            WoodlandStyle.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Button { dismiss() } label: {
                        Text(Copy.Support.close)
                            .font(.body.weight(Theme.Weight.action))
                            .foregroundStyle(Theme.textSecondary.color)
                            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.calm)

                    VStack(alignment: .leading, spacing: 12) {
                        DisplayText(Copy.Support.title, size: 34)
                            .accessibilityAddTraits(.isHeader)
                        BodyText(Copy.Support.body)
                    }

                    VStack(spacing: 12) {
                        ForEach(lines) { line in
                            SupportLineRow(line: line)
                        }
                    }

                    Link(destination: SupportResources.directoryURL) {
                        HStack(spacing: 6) {
                            Text(Copy.Support.directory)
                            Image(systemName: "arrow.up.right")
                                .accessibilityHidden(true)
                        }
                        .font(.subheadline.weight(Theme.Weight.action))
                        .foregroundStyle(Theme.textPrimary.color)
                        .frame(minHeight: 44)
                    }

                    Text(Copy.Support.notEmergencyService)
                        .font(.footnote.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct SupportLineRow: View {
    let line: SupportLine

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if let url = line.callURL {
            Link(destination: url) {
                ProfileCard {
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
                        : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
                    layout {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(line.name)
                                .font(.body.weight(Theme.Weight.emphasis))
                                .foregroundStyle(Theme.textPrimary.color)
                            Text(line.detail)
                                .font(.footnote.weight(Theme.Weight.body))
                                .foregroundStyle(Theme.textSecondary.color)
                        }
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                        if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }

                        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
                            Text(verbatim: line.displayNumber)
                                .font(.title2.weight(Theme.Weight.title))
                                .monospacedDigit()
                                .foregroundStyle(Theme.textPrimary.color)
                            Label {
                                Text(Copy.Support.call)
                            } icon: {
                                Image(systemName: "phone")
                            }
                            .font(.footnote.weight(Theme.Weight.action))
                            .foregroundStyle(Theme.textSecondary.color)
                        }
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: Copy.Support.callAccessibility(
                name: String(localized: line.name),
                number: line.displayNumber
            )))
            .accessibilityAddTraits(.isLink)
        }
    }
}
