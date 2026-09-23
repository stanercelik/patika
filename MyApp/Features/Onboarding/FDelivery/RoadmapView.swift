import SwiftUI

/// A single readable plan sheet, followed by a clear first-step action.
struct RoadmapView: View {
    let flow: OnboardingFlowViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var rows: [PathPlan.Row] { Array(PathPlan.rows(for: flow.pathLength).prefix(4)) }
    private var generatedSteps: [GeneratedPathStep] {
        Array((flow.generatedPath?.steps.sorted { $0.day < $1.day } ?? []).prefix(4))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "leaf.circle")
                            .font(.largeTitle.weight(Theme.Weight.body))
                            .accessibilityHidden(true)
                        Text(Copy.Onboarding.roadmapHeadline(name: flow.draft.displayName))
                            .font(Theme.TypeFace.sectionTitle)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(flow.pathTitle)
                            .font(.title2.weight(Theme.Weight.title))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(Copy.Onboarding.roadmapMeta(
                            steps: flow.pathLength.days,
                            minutes: flow.draft.sessionLength.minutes
                        ))
                        .font(.subheadline.weight(Theme.Weight.emphasis))
                        .foregroundStyle(WoodlandStyle.secondaryInk)
                    }

                    OnboardingIllustration(
                        name: OnboardingArtwork.pathReady.isAvailable
                            ? OnboardingArtwork.pathReady.rawValue : PatikaArtwork.trail.rawValue,
                        height: 126,
                        accessibilityHeight: 80
                    )
                    .frame(maxWidth: .infinity)

                    Rectangle()
                        .fill(WoodlandStyle.secondaryInk.opacity(0.25))
                        .frame(height: Theme.Line.border)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 16) {
                        if generatedSteps.isEmpty {
                            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                                planRow(index: index) { rowContent(row) }
                            }
                        } else {
                            ForEach(Array(generatedSteps.enumerated()), id: \.element.day) { index, step in
                                planRow(index: index) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(Copy.Onboarding.dayLabel(step.day...step.day))
                                            .font(.caption.weight(Theme.Weight.emphasis))
                                            .foregroundStyle(WoodlandStyle.secondaryInk)
                                        Text(verbatim: step.title)
                                            .font(.body.weight(Theme.Weight.emphasis))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }
                .foregroundStyle(WoodlandStyle.ink)
                .padding(22)
                .paperSurface()
                .environment(\.patikaInk, .ink)

                if dynamicTypeSize.isAccessibilitySize { continueButton }
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.vertical, 14)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            if !dynamicTypeSize.isAccessibilitySize {
                continueButton
                    .padding(.horizontal, Theme.Spacing.screenMargin)
                    .padding(.vertical, 12)
                    .background(WoodlandStyle.background)
            }
        }
    }

    private var continueButton: some View {
        PrimaryButton(title: Copy.Onboarding.roadmapContinue, isEnabled: true) {
            flow.finishRoadmap()
        }
    }

    private func planRow<Content: View>(index: Int, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: index == 0 ? "circle.inset.filled" : "circle")
                .font(.body.weight(Theme.Weight.body))
                .frame(width: 22, height: 24)
                .accessibilityHidden(true)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func rowContent(_ row: PathPlan.Row) -> some View {
        switch row {
        case .phase(let phase, let range):
            rowText(title: Copy.Onboarding.dayLabel(range), subtitle: phase.label)
        case .measurement(let day, let isFirst):
            rowText(
                title: Copy.Onboarding.dayLabel(day...day),
                subtitle: isFirst ? Copy.Onboarding.roadmapFirstMeasurement : Copy.Onboarding.roadmapMeasurement
            )
        }
    }

    private func rowText(title: LocalizedStringResource, subtitle: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(Theme.Weight.emphasis))
                .foregroundStyle(WoodlandStyle.secondaryInk)
            Text(subtitle)
                .font(.body.weight(Theme.Weight.emphasis))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
