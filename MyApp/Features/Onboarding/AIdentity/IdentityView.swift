import SwiftUI

/// Kimlik — ad, cinsiyet ve yaş tek kartta (docs/onboarding-redesign.md, Bölüm 1).
///
/// Cinsiyet ve yaş ürünün **hiçbir davranışını değiştirmiyor** (`Gender`, `AgeRange`
/// doküman yorumları): iki tam ekranı bir istatistiğe harcamak akışın en zayıf oranıydı.
/// Üç soru bir kartta, ad önce; cinsiyet adın çözülmesinden, yaş cinsiyetten sonra belirir.
///
/// ## Ürün kuralları aynen duruyor
///
/// - **İsim isteğe bağlı ve isimsiz yol eksik değil.** "İsim vermek istemiyorum" hiçbir
///   yeri kapatmaz; ad da serbest metin olduğu için `CrisisClassifier`dan geçer
///   (`commitIdentity`).
/// - **Cinsiyet ve yaş cevapsız kalabilir** ve `undisclosed` yazılır: ikisinin de
///   ekranında bunu söyleyen bir not var (`identityStatsNote`), karşılığı olmayan bir
///   soruyu varmış gibi sunmuyoruz. Bu, ölçümdeki "varsayılan cevap yok" kuralının
///   ihlali değil: orada cevap veri, burada istatistik ve açıkça "söylemek istemiyorum".
/// - Ad, kullanıcının kendi sözü olduğu için serif yazılır (`Theme.Voice.user`).
/// - Bağlayıcı 18+ kontrolü H1'de kalıyor; buradaki aralık kapı değil (PRD §11.4).
struct IdentityView: View {
    let flow: OnboardingFlowViewModel

    @State private var name: String
    @State private var isNameResolved: Bool
    @State private var gender: Gender?
    @State private var age: AgeRange?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(flow: OnboardingFlowViewModel) {
        self.flow = flow
        self._name = State(initialValue: flow.draft.name ?? "")
        self._isNameResolved = State(initialValue: flow.draft.name != nil)
        self._gender = State(initialValue: flow.draft.gender)
        self._age = State(initialValue: flow.draft.ageRange)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var showsGender: Bool { isNameResolved || !trimmedName.isEmpty }
    private var showsAge: Bool { showsGender && gender != nil }
    private var orderedAges: [AgeRange] { AgeRange.allCases.filter { $0 != .undisclosed } }

    var body: some View {
        OnboardingQuestionLayout(
            headline: Copy.Onboarding.nameHeadline,
            hint: Copy.Onboarding.nameHint
        ) {
            VStack(alignment: .leading, spacing: 22) {
                OnboardingArtworkView(artwork: .identity, height: 96)

                OnboardingTextInput(
                    text: $name,
                    placeholder: Copy.Onboarding.namePlaceholder,
                    lineRange: 1...1,
                    capitalization: .words,
                    font: Theme.Voice.user(.title3)
                )

                if showsGender { genderSection.transition(reveal) }
                if showsAge { ageSection.transition(reveal) }
                if showsGender {
                    Text(Copy.Onboarding.identityStatsNote)
                        .font(.footnote.weight(Theme.Weight.body))
                        .inkStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(reveal)
                }
            }
            .animation(reduceMotion ? nil : Theme.Motion.crossFade, value: showsGender)
            .animation(reduceMotion ? nil : Theme.Motion.crossFade, value: showsAge)
        } footer: {
            OnboardingQuestionFooter(
                primaryTitle: Copy.Button.next,
                primaryDisabledTitle: Copy.Onboarding.nameFirstCTA,
                isPrimaryEnabled: showsGender,
                primaryAction: {
                    flow.commitIdentity(name: name, gender: gender ?? .undisclosed, ageRange: age ?? .undisclosed)
                },
                skipTitle: showsGender ? nil : Copy.Onboarding.nameSkip,
                skipAction: showsGender ? nil : { isNameResolved = true }
            )
        }
    }

    private var reveal: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top))
    }

    // MARK: - Cinsiyet

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(.onboardingGenderHeadline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 116), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(Gender.allCases) { option in
                    IdentityChip(label: option.label, isSelected: gender == option) {
                        gender = option
                    }
                }
            }
        }
    }

    // MARK: - Yaş

    private var ageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(.onboardingAgeHeadline)
            DualStatementSlider(
                options: orderedAges,
                selection: age.flatMap { orderedAges.contains($0) ? $0 : nil },
                onSelect: { age = $0 },
                lowStatement: AgeRange.eighteenToTwentyFour.label,
                highStatement: AgeRange.fiftyFivePlus.label,
                accessibilityLabel: .onboardingAgeHeadline,
                fillsTrack: false
            )
            ChoiceRow(label: AgeRange.undisclosed.label, isSelected: age == .undisclosed) {
                age = .undisclosed
            }
        }
    }

    private func sectionLabel(_ text: LocalizedStringResource) -> some View {
        Text(text)
            .font(.headline.weight(Theme.Weight.title))
            .inkStyle(.primary)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Kâğıt kart içinde küçük seçenek hapı. Seçili durum yine üç sinyalle: dolgu,
/// kalın kenarlık ve metin ağırlığı.
private struct IdentityChip: View {
    let label: LocalizedStringResource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Theme.softHaptic()
            action()
        } label: {
            Text(label)
                .font(.subheadline.weight(isSelected ? Theme.Weight.action : Theme.Weight.emphasis))
                .foregroundStyle(WoodlandStyle.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 12)
                .background { PaperInsetSurface(isEmphasized: isSelected) }
        }
        .buttonStyle(.calm)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    OnboardingPreviewHost(step: .identity) { flow in
        IdentityView(flow: flow)
    }
}
