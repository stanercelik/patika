import Foundation
import Observation

/// Tek seçimlik bir onboarding sorusunun cevap kümesi.
///
/// `Sendable` istemiyoruz: uygunluk tipleri kendileri `Sendable` ama modül
/// varsayılan olarak `MainActor` yalıtımında derleniyor ve `Identifiable`
/// uygunlukları da öyle işaretleniyor — `Sendable` kısıtı bunları eleyecekti.
/// Buna ihtiyaç da yok, kullanıldığı yer zaten `@MainActor`.
protocol OnboardingChoice: Identifiable, Hashable, CaseIterable
where AllCases == [Self] {
    var label: LocalizedStringResource { get }
}

extension Gender: OnboardingChoice {}
extension AgeRange: OnboardingChoice {}
extension SessionLength: OnboardingChoice {}
extension TonePreference: OnboardingChoice {}
extension ProblemDuration: OnboardingChoice {}
extension ProblemTiming: OnboardingChoice {}
extension MoodLevel: OnboardingChoice {}

/// B2, B3 ve B6 gibi "birini seç" ekranlarının ortak ViewModel'i.
///
/// ## Dokunmak cevap değil, seçim
///
/// Bu ekranlar önce dokunuşla anında ilerliyordu. Kalıcı kabuk (sabit geri tuşu +
/// iz) geldikten sonra bu tercih üç yerden bozuldu ve geri alındı (ürün sahibi
/// kararı, 2026-09-08):
///
/// 1. **Kabuk tutarlılığı.** B1/B4/B5'te alt bölgede buton var, B2/B3/B6'da yoktu;
///    alt bölge ekran ekran belirip kayboluyordu. Az önce üst çubuk için verdiğimiz
///    "kabuk yerinde kalır" kararının altını oyuyordu.
/// 2. **Hatalı dokunuş.** 240 ms'de commit olan seçim, kullanıcı tepki veremeden
///    işleniyor ve ancak geri tuşuyla düzeltilebiliyordu. Kaygı ürününde arayüzün
///    kullanıcıdan hızlı davranması kötü his.
/// 3. **B6'nın kendisi.** Ruh hâli seçimi artık arka planı değiştiriyor; otomatik
///    ilerleme o cevabı kullanıcıya göstermeden ekranı kapatıyordu.
///
/// Bedeli akış boyunca 3 fazladan dokunuş — takas bilinçli.
///
/// ## Kaçış kapısı seçeneğin içinde
///
/// B2–B4 atlanabilir olmalı (PRD-Ek Onboarding §10) ama bu ekranlarda ayrı bir
/// "geç" bağlantısı yok: "Emin değilim" ve "Belli bir zamanı yok" zaten dürüst
/// birer cevap. Atlamakla bilmemek aynı şey değil ve ikincisi daha iyi veri.
@Observable
@MainActor
final class SingleChoiceStepViewModel<Option: OnboardingChoice> {
    private(set) var selection: Option?

    let options: [Option] = Option.allCases

    private let commit: (Option) -> Void
    /// Seçim değiştiği anda çağrılır — B6 arka planı buradan canlı sürüyor.
    private let onChange: ((Option) -> Void)?

    init(
        selection: Option?,
        onChange: ((Option) -> Void)? = nil,
        commit: @escaping (Option) -> Void
    ) {
        self.selection = selection
        self.onChange = onChange
        self.commit = commit
    }

    var canContinue: Bool { selection != nil }

    func isSelected(_ option: Option) -> Bool { selection == option }

    func select(_ option: Option) {
        guard selection != option else { return }
        selection = option
        onChange?(option)
    }

    func submit() {
        guard let selection else { return }
        commit(selection)
    }
}
