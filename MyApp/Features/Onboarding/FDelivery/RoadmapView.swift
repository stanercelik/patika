import SwiftUI

/// F2 — Yolun hazır (PRD-Ek Onboarding §7.2 ve §7.3).
///
/// ## Ekrana sığan teslim
///
/// 2026-09-22 kararıyla uzun rota ve otomatik kaydırma kalktı. Kullanıcı burada
/// path başlığını, uzunluğunu ve ilk dört somut durağı tek bakışta görür;
/// tam rota onboarding sonrası Yolum ekranına aittir. AX boyutlarında aynı içerik
/// kaydırılabilir belgeye döner, metin kırpılmaz.
///
/// ## Akışın zirvesi
///
/// Kullanıcı beş dakikadır soru cevaplıyor; karşılığını ilk kez burada görüyor.
/// Üç şey aynı anda okunuyor: (a) somut bir plan var, (b) ilk karşılaştırma
/// noktası görünür, (c) fazların sırası rastgele değil.
///
/// ## Paywall yok — ve bu bir risk
///
/// İncelenen uygulamaların %22'si burada ödeme istiyor. Biz istemiyoruz: ürünün
/// tüm iddiası "işe yaradığını gördükten sonra öde" ve onboarding'de para
/// istemek bu iddiayı ilk beş dakikada çürütür (PRD-Ek Onboarding §7.3). Kabul
/// edilen bedel ilk altı günün gelirsiz olması.
struct RoadmapView: View {
    let flow: OnboardingFlowViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var rows: [PathPlan.Row] { PathPlan.rows(for: flow.pathLength) }
    private var generatedSteps: [GeneratedPathStep] {
        flow.generatedPath?.steps.sorted { $0.day < $1.day } ?? []
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    roadmapContent
                    continueButton
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.vertical, 10)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .scrollEdgeEffectStyle(.soft, for: .bottom)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                roadmapContent
                Spacer(minLength: 0)
                continueButton
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
    }

    private var roadmapContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            DisplayText(Copy.Onboarding.roadmapHeadline(name: flow.draft.displayName), size: 30)

            OnboardingIllustration(
                name: OnboardingArtwork.pathReady.isAvailable ? OnboardingArtwork.pathReady.rawValue : PatikaArtwork.trail.rawValue,
                height: 124,
                accessibilityHeight: 88
            )
            .frame(maxWidth: .infinity)

            pathCard

            SceneContentPlate {
                VStack(alignment: .leading, spacing: 12) {
                    if generatedSteps.isEmpty {
                        ForEach(Array(rows.prefix(4).enumerated()), id: \.element.id) { index, row in
                            HStack(spacing: 10) {
                                Image(systemName: index == 0 ? "circle.inset.filled" : "circle")
                                    .accessibilityHidden(true)
                                rowContent(row)
                            }
                            .foregroundStyle(index == 0 ? Theme.textPrimary.color : WoodlandStyle.scenePlateSecondary.color)
                        }
                    } else {
                        ForEach(Array(generatedSteps.prefix(4)), id: \.day) { step in
                            HStack(spacing: 10) {
                                Image(systemName: step.day == 1 ? "circle.inset.filled" : "circle")
                                    .accessibilityHidden(true)
                                Text(verbatim: step.title)
                                    .font(Theme.TypeFace.cardTitle)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundStyle(step.day == 1 ? Theme.textPrimary.color : WoodlandStyle.scenePlateSecondary.color)
                        }
                    }
                }
            }

        }
    }

    private var continueButton: some View {
        PrimaryButton(title: Copy.Onboarding.roadmapContinue, isEnabled: true) {
            flow.finishRoadmap()
        }
    }

    // MARK: - Path kartı

    private var pathCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(flow.pathTitle)
                .font(.title3.weight(Theme.Weight.title))
                .foregroundStyle(Theme.textPrimary.color)
                .fixedSize(horizontal: false, vertical: true)

            Text(Copy.Onboarding.roadmapMeta(
                steps: flow.pathLength.days,
                minutes: flow.draft.sessionLength.minutes
            ))
            .font(.subheadline.weight(Theme.Weight.emphasis))
            .foregroundStyle(Theme.textPrimary.color.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(WoodlandStyle.scenePlate.color.opacity(0.94))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(WoodlandStyle.scenePlateBorder.color, lineWidth: Theme.Line.border)
        }
    }

    // MARK: - Harita satırları

    @ViewBuilder
    private func rowContent(_ row: PathPlan.Row) -> some View {
        switch row {
        case .phase(let phase, let range):
            rowText(
                title: Copy.Onboarding.dayLabel(range),
                subtitle: phase.label,
                description: phase.roadmapDescription,
                isMilestone: false
            )

        case .measurement(let day, let isFirst):
            rowText(
                title: Copy.Onboarding.dayLabel(day...day),
                subtitle: isFirst
                    ? Copy.Onboarding.roadmapFirstMeasurement
                    : Copy.Onboarding.roadmapMeasurement,
                description: Copy.Onboarding.roadmapMeasurementDescription,
                isMilestone: true
            )
        }
    }

    /// Gün etiketi üstte ve küçük, faz adı altında ve iri: kullanıcı listeyi
    /// tarihlerle değil, ne yapacağıyla okuyor.
    private func rowText(
        title: LocalizedStringResource,
        subtitle: LocalizedStringResource,
        description: LocalizedStringResource,
        isMilestone: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(Theme.Weight.emphasis))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.50))

            Text(subtitle)
                .font(.body.weight(Theme.Weight.action))
                .foregroundStyle(Theme.textPrimary.color.opacity(isMilestone ? 1.0 : 0.92))

            Text(description)
                .font(.subheadline.weight(Theme.Weight.body))
                .foregroundStyle(Theme.textPrimary.color.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingPreviewHost(
        step: .f2Roadmap,
        draft: {
            var draft = OnboardingDraft()
            draft.name = "Taner"
            draft.categories = [.sleep]
            draft.currentMood = .heavy
            return draft
        }()
    ) { flow in
        RoadmapView(flow: flow)
    }
}
