import SwiftUI

/// E1 — "Ne zaman?" (PRD-Ek Onboarding §6).
///
/// ## Varsayılan yanlılığı burada serbest
///
/// Saat boş bir alan olarak sorulmuyor; B3'teki cevaba göre **önceden dolu**
/// geliyor ve ekranın işi bir öneriyi onaylatmak. Bu, PRD-Ek 5.6'nın bilinçli
/// uygulaması — ve sınırı da net: varsayılan yanlılığı **ödeme ve abonelik
/// kararlarında kullanılmaz**, orada aynı teknik manipülasyon olurdu.
///
/// Öneri gerekçesiz sunulmuyor: alt satır kullanıcının kendi cevabına atıf
/// yapıyor (`ProblemTiming.reminderReason`). Sorduğumuz her şeyin görünür bir
/// karşılığı olmalı, yoksa akış anket gibi hissettirir.
///
/// "Başka saat seç" tekerleği **yerinde** açar; ayrı bir ekran ya da yaprak
/// açmak, tek dokunuşluk bir düzeltmeyi bir yolculuğa çevirirdi.
struct ReminderTimeView: View {
    let flow: OnboardingFlowViewModel

    @State private var time: Date
    @State private var isEditing = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    /// Sürükleme yardımcı teknoloji için bir cevap yolu değil: erişilebilirlik
    /// boyutlarında ve VoiceOver açıkken kadran yerine tekerlek gelir.
    private var usesDial: Bool { !dynamicTypeSize.isAccessibilitySize && !voiceOverEnabled }

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self._time = State(
            initialValue: Self.date(
                hour: flow.suggestedReminderHour,
                minute: flow.suggestedReminderMinute
            )
        )
    }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.reminderHeadline(formattedTime),
            hint: flow.draft.timing?.reminderReason
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if usesDial {
                    // Öneri halkada içi boş bir işaretle görünür; onaylamak tek dokunuş,
                    // sürüklemek isteğe bağlı.
                    RadialClockDial(
                        hour: components.hour ?? 22,
                        minute: components.minute ?? 30,
                        suggestionHour: flow.suggestedReminderHour,
                        onChange: { time = Self.date(hour: $0, minute: $1) }
                    )
                } else if isEditing {
                    DatePicker(
                        String(localized: Copy.Onboarding.reminderPickerLabel),
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    // Kâğıtta koyu metin: uygulama koyu şemaya sabit, tekerlek açık şemayla çizilir.
                    .environment(\.colorScheme, .light)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
                } else {
                    // Ortalanmış: cevap alanındaki tek nesne bu ve sola
                    // yaslandığında geniş boşluğun içinde kaybolmuş görünüyordu.
                    SecondaryTextButton(title: Copy.Onboarding.reminderChange) {
                        withAnimation(Theme.Motion.crossFade) { isEditing = true }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Onboarding.reminderAccept,
                primaryAction: { commit() }
            )
        }
        .onChange(of: time, initial: true) { _, _ in
            flow.previewReminder(hour: components.hour ?? 22)
        }
    }

    private var components: DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: time)
    }

    private var formattedTime: String {
        time.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }

    private func commit() {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        flow.commitReminder(hour: parts.hour ?? 22, minute: parts.minute ?? 30)
    }

    private static func date(hour: Int, minute: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: .now
        ) ?? .now
    }
}

#Preview {
    OnboardingPreviewHost(
        step: .e1Reminder,
        draft: {
            var draft = OnboardingDraft()
            draft.categories = [.sleep]
            draft.timing = .bedtime
            draft.reminderHour = ProblemTiming.bedtime.suggestedReminderHour
            return draft
        }()
    ) { flow in
        ReminderTimeView(flow: flow)
    }
}
