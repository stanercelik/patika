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
                if isEditing {
                    DatePicker(
                        String(localized: Copy.Onboarding.reminderPickerLabel),
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
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
