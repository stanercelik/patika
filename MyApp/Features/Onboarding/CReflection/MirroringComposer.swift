import Foundation

/// C1'in metnini taslaktan üretir (PRD-Ek Onboarding §4.1).
///
/// ## Bu, LLM'in yerini tutan geçici bir besteci
///
/// PRD bu metni "şablonu kısıtlı LLM çıktısı" olarak tarif ediyor: 3 cümle,
/// kullanıcının kelimeleriyle, yorum yok, teşhis yok. Sunucu tarafı henüz yok, o
/// yüzden şimdilik cevaplardan **deterministik** olarak kuruluyor. Path üretimi
/// eklendiğinde bu tip aynı sözleşmeyi koruyarak LLM çıktısına devredilebilir —
/// çağıran taraf yalnızca paragraf dizisi görüyor.
///
/// ## Uydurmama kuralı
///
/// Besteci **yalnızca verilmiş cevaplardan** cümle kurar. Süreyi bilmiyorsa süre
/// cümlesi düşer, kaçınma yazılmadıysa o paragraf hiç görünmez. Boşluğu "muhtemelen"
/// ile doldurmak bu ekranın tek işini — güven üretmeyi — tersine çevirirdi.
///
/// ## B1 metni neden burada kullanılmıyor
///
/// Kullanıcının serbest metni birinci tekil şahısla yazılıyor ("uyuyamıyorum"),
/// ekranın sesi ise ikinci tekil. Bunu çevirmek çekim gerektirir, yani LLM işi.
/// Yapılabilecek dürüst şey alıntılamak: B4 cevabı kısa ve tek parça olduğu için
/// tırnak içinde aynen geri veriliyor, B1 metni ise F2'ye bırakılıyor.
enum MirroringComposer {

    /// Görsel, kullanıcının durumu ve süre cevabı birlikte aynalandıktan sonra
    /// gelir. Süre yanıtı yoksa uydurulmaz; ilk durum cümlesinden sonra yerleşir.
    static func illustrationInsertionIndex(for draft: OnboardingDraft) -> Int {
        durationSentence(for: draft) == nil ? 1 : 2
    }

    /// Ekranda alt alta basılacak paragraflar. En az bir tane döner:
    /// A2 atlanamadığı için kategori her zaman var.
    static func paragraphs(for draft: OnboardingDraft) -> [AttributedString] {
        var result: [AttributedString] = []

        result.append(situationSentence(for: draft))

        if let duration = durationSentence(for: draft) {
            result.append(duration)
        }

        if let avoidance = quotedAvoidance(draft.avoidanceText) {
            var paragraph = AttributedString(localized: Copy.Onboarding.mirroringAvoidanceLead)
            paragraph += AttributedString(" ")
            paragraph += emphasized("“\(avoidance)”")
            result.append(paragraph)
        }

        result.append(AttributedString(localized: Copy.Onboarding.mirroringClosing))
        return result
    }

    /// "When you get into bed, your mind won't stop."
    private static func situationSentence(for draft: OnboardingDraft) -> AttributedString {
        let predicate = String(localized: draft.primaryCategory.mirrorPhrase)

        var sentence: String
        if let timing = draft.timing {
            sentence = String(localized: .onboardingMirroringSituation(String(localized: timing.mirrorPhrase), predicate))
        } else {
            sentence = predicate
        }
        return AttributedString(capitalizingFirstLetter(sentence) + ".")
    }

    /// "This has been going on **for months**." Ayrı cümle — ekranda bir öncekinden sonra belirir.
    private static func durationSentence(for draft: OnboardingDraft) -> AttributedString? {
        guard let duration = draft.duration?.mirrorPhrase else { return nil }
        var paragraph = AttributedString(localized: Copy.Onboarding.mirroringDurationLead)
        paragraph += AttributedString(" ")
        paragraph += emphasized(String(localized: duration))
        // Kuyruk kendi noktalamasını taşır ("."), araya boşluk girmez.
        paragraph += AttributedString(localized: Copy.Onboarding.mirroringDurationTail)
        return paragraph
    }

    /// Kullanıcının B4 cevabı tırnak içinde aynen kullanılır; yalnızca kenar
    /// boşlukları ve cümle sonundaki nokta alınır, çünkü tırnak zaten kapatıyor.
    /// Kelimelerin kendisine dokunulmaz — dokunulursa "kendi cümlen" iddiası düşer.
    private static func quotedAvoidance(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        let withoutTrailingStop = trimmed.hasSuffix(".")
            ? String(trimmed.dropLast())
            : trimmed
        return withoutTrailingStop.isEmpty ? nil : withoutTrailingStop
    }

    /// Türkçe büyütme: `"i"` harfi `"İ"` olmalı, `"I"` değil. Varsayılan
    /// `uppercased()` bunu İngilizce kurallarıyla yapıyor.
    private static func capitalizingFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        let locale = Locale(identifier: "tr_TR")
        return String(first).uppercased(with: locale) + text.dropFirst()
    }

    private static func emphasized(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.inlinePresentationIntent = .stronglyEmphasized
        return attributed
    }
}
