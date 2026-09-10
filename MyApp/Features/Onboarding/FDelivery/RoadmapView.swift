import SwiftUI

/// F2 — Yolun hazır (PRD-Ek Onboarding §7.2 ve §7.3).
///
/// ## F2 ve F3 tek ekran
///
/// PRD bunları ayırıyordu: F2 özet kart, F3 kaydırınca açılan gerçek harita.
/// **Birleştirildi** (ürün sahibi kararı, 2026-09-09): iki ekran da aynı şeyi
/// gösteriyordu ve "kaydırınca haritaya geç" adımı, kullanıcının zaten gördüğü
/// bir şeyi tekrar açması demekti. Harita doğrudan burada; ölçüm noktaları da
/// üstünde işaretli.
///
/// ## Akışın zirvesi
///
/// Kullanıcı beş dakikadır soru cevaplıyor; karşılığını ilk kez burada görüyor.
/// Üç şey aynı anda okunuyor: (a) somut bir plan var, (b) 7. günde bir karşılık
/// noktası var, (c) fazların sırası rastgele değil.
///
/// ## Paywall yok — ve bu bir risk
///
/// İncelenen uygulamaların %22'si burada ödeme istiyor. Biz istemiyoruz: ürünün
/// tüm iddiası "işe yaradığını gördükten sonra öde" ve onboarding'de para
/// istemek bu iddiayı ilk beş dakikada çürütür (PRD-Ek Onboarding §7.3). Kabul
/// edilen bedel ilk altı günün gelirsiz olması.
struct RoadmapView: View {
    let flow: OnboardingFlowViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Kendiliğinden inip çıkma görevi. Kullanıcı ekrana dokunduğu anda iptal
    /// ediliyor: yürüyen bir kaydırmayı parmakla yakalamaya çalışmak, arayüzün
    /// kullanıcıyla güreşmesi demek.
    @State private var tour: Task<Void, Never>?

    private var rows: [PathPlan.Row] { PathPlan.rows(for: flow.pathLength) }
    private var generatedSteps: [GeneratedPathStep] {
        flow.generatedPath?.steps.sorted { $0.day < $1.day } ?? []
    }
    private var generatedPhases: [PathPhase?] {
        generatedSteps.map { PathPlan.phase(on: $0.day, length: flow.pathLength) }
    }
    private var generatedPositions: [JourneyRoutePosition] {
        JourneyRouteLayout.positions(
            for: generatedPhases,
            usesAccessibleLayout: dynamicTypeSize.isAccessibilitySize
        )
    }
    private var fallbackPhases: [PathPhase?] {
        rows.map { PathPlan.phase(for: $0, length: flow.pathLength) }
    }
    private var fallbackPositions: [JourneyRoutePosition] {
        JourneyRouteLayout.positions(
            for: fallbackPhases,
            usesAccessibleLayout: dynamicTypeSize.isAccessibilitySize
        )
    }

    /// Kaydırma konumu. `ScrollViewReader` + `scrollTo(id:)` yerine bu:
    /// bir kimliğe kaydırmak öğeyi görünür alanın kenarına yaslıyor ve dönüşte
    /// listenin üst boşluğu kadar aşağıda kalıyordu. Kenara kaydırmak (`.top` /
    /// `.bottom`) tam olarak içeriğin ucuna gidiyor.
    @State private var scrollPosition = ScrollPosition()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    DisplayText(
                        Copy.Onboarding.roadmapHeadline(name: flow.draft.displayName),
                        size: 30
                    )
                    .listReveal(0)

                    // Görsel başlıkla kartın arasında, ikisinden de belirgin bir
                    // boşlukla ayrılmış: haritanın kendisi bir liste ve listeye
                    // yapışık bir görsel onu satır gibi gösterirdi.
                    OnboardingIllustration(name: "illustration-f2-path-ready", height: 208)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.bottom, 22)
                        .listReveal(2)

                    pathCard
                        .listReveal(4)
                        // Üst boşluk görselden bağımsız: varlık eklenmediğinde
                        // `OnboardingIllustration` hiç yer kaplamıyor ve kart
                        // başlığa yapışıyordu.
                        .padding(.top, 18)
                        .padding(.bottom, 26)

                    if generatedSteps.isEmpty {
                        fallbackMap
                    } else {
                        generatedMap
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            // Dokunmak turu bitirir. `simultaneousGesture` çünkü kaydırmanın
            // kendisi de çalışmaya devam etmeli — jest yakalanmıyor, dinleniyor.
            .simultaneousGesture(
                DragGesture(minimumDistance: 0).onChanged { _ in endTour() }
            )
            .scrollPosition($scrollPosition)
            .task { await runTour() }
            .onDisappear { endTour() }

            HoldToStartButton(
                title: Copy.Button.start,
                hint: Copy.Onboarding.holdToStartHint
            ) {
                flow.startFirstSession()
            }
            .padding(.horizontal, Theme.Spacing.screenMargin)
            .padding(.bottom, 10)
        }
    }

    private var generatedMap: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(generatedSteps.enumerated()), id: \.element.day) { index, step in
                let isFirst = index == 0
                let isMeasurement = flow.pathLength.measurementDays.contains(step.day) && step.day > 1
                let phase = generatedPhases[index]
                JourneyMapRow(
                    index: index,
                    totalCount: generatedSteps.count,
                    position: generatedPositions[index],
                    phase: phase,
                    startsPhase: PathPlan.startsPhase(on: step.day, length: flow.pathLength),
                    node: isFirst ? .active : (isMeasurement ? .milestone : .pending),
                    showsLock: !isFirst,
                    isProminent: false
                ) {
                    generatedStepContent(step, isMeasurement: isMeasurement)
                }
                .id("generated-\(step.day)")
            }
        }
    }

    private var fallbackMap: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                let phase = fallbackPhases[index]
                JourneyMapRow(
                    index: index,
                    totalCount: rows.count,
                    position: fallbackPositions[index],
                    phase: phase,
                    startsPhase: row.startsPhase,
                    node: node(for: row),
                    showsLock: false,
                    isProminent: false
                ) {
                    rowContent(row)
                }
                .id(row.id)
            }
        }
    }

    private func generatedStepContent(
        _ step: GeneratedPathStep,
        isMeasurement: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(Copy.Path.stepLabel(day: step.day))
                    .font(.caption.weight(Theme.Weight.emphasis))
                if step.day > 1 {
                    Image(systemName: "lock")
                        .font(.caption2.weight(Theme.Weight.emphasis))
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(Theme.textPrimary.color.opacity(0.50))

            Text(verbatim: step.title)
                .font(.body.weight(Theme.Weight.action))
                .foregroundStyle(Theme.textPrimary.color.opacity(step.day == 1 ? 1 : 0.72))
                .fixedSize(horizontal: false, vertical: true)

            if let techniques = BlockLibrary.techniqueSummary(for: step.blockIds) {
                Text(verbatim: techniques)
                    .font(.caption.weight(Theme.Weight.body))
                    .foregroundStyle(
                        Theme.textPrimary.color.opacity(step.day == 1 ? 0.68 : 0.48)
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isMeasurement {
                Text(Copy.Path.measurementNote)
                    .font(.caption2.weight(Theme.Weight.emphasis))
                    .foregroundStyle(Theme.textPrimary.color.opacity(0.62))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityHint(step.day > 1 ? Text(Copy.Path.lockedAccessibility) : Text(""))
    }

    // MARK: - Haritayı bir kez gezdir
    //
    // Ürün sahibi kararı, 2026-09-09. Harita ekrana sığmıyor; alt satırların
    // varlığını yalnızca kendiliğinden kaydıran kullanıcı görüyordu ve "21 günün
    // tamamı burada" mesajı akışın zirvesinde kayboluyordu. Ekran bir kez aşağı
    // inip geri çıkıyor — kaydırma çubuğu ya da "aşağı kaydır" oku yerine izin
    // kendisi gösteriliyor.
    //
    // Tur **bilgilendirir, yönlendirmez**: CTA baştan beri basılabilir ve
    // dokunmak turu bitirir.

    private func runTour() async {
        // Reduce Motion'da hiç çalışmaz. Kendiliğinden hareket eden bir ekran,
        // bu ayarı açan kullanıcının tam olarak kapattığı şey (Ton eki §7).
        guard !reduceMotion else { return }

        tour = Task { @MainActor in
            // Satırlar `listReveal` ile hâlâ beliriyorken kaydırmaya başlamak,
            // iki hareketi üst üste bindiriyordu.
            try? await Task.sleep(for: .seconds(Theme.Motion.roadmapTourLeadIn))
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: Theme.Motion.roadmapTourDown)) {
                scrollPosition.scrollTo(edge: .bottom)
            }
            try? await Task.sleep(
                for: .seconds(Theme.Motion.roadmapTourDown + Theme.Motion.roadmapTourHold)
            )
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: Theme.Motion.roadmapTourUp)) {
                scrollPosition.scrollTo(edge: .top)
            }
        }
        await tour?.value
    }

    private func endTour() {
        tour?.cancel()
        tour = nil
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
                .fill(Color.white.opacity(0.07))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.textPrimary.color.opacity(0.16), lineWidth: Theme.Line.border)
        }
    }

    // MARK: - Harita satırları

    private func node(for row: PathPlan.Row) -> TrailNode {
        switch row {
        case .phase: .pending
        case .measurement: .milestone
        }
    }

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
