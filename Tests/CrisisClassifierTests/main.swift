import Foundation

// Cihazdaki kriz ön filtresinin vaka tablosu. Test hedefi yok, elle derlenir:
//   swiftc -o /tmp/crisistest MyApp/Features/Onboarding/BProblemDiscovery/CrisisClassifier.swift \
//     Tests/CrisisClassifierTests/main.swift && /tmp/crisistest
//
// Eşik bilerek gevşek: yanlış pozitifin bedeli yardım ekranı, yanlış negatifin bedeli
// kriz sinyali vermiş birine program satmak.

var failures: [String] = []
func expect(_ text: String, signal: Bool, file: StaticString = #file, line: UInt = #line) {
    let got = CrisisClassifier.evaluate(text).hasSignal
    if got != signal { failures.append("\(signal ? "MISSED" : "FALSE POSITIVE"): \(text)") }
}

// Yakalanmalı: doğrudan ve dolaylı İngilizce ifadeler, biçim varyasyonları.
for text in [
    "I want to kill myself",
    "i've been thinking about suicide",
    "Sometimes I feel suicidal.",
    "I just want to end my life",
    "I don't want to live anymore",
    "I dont want to live",
    "I don’t want to live like this",               // akıllı kesme işareti
    "I do not want to live",
    "everyone would be better off without me",
    "I wish I were dead",
    "I wish I was dead.",
    "I want to die",
    "I keep hurting myself lately, i hurt myself again",
    "I self-harm when it gets bad",
    "i self harm",
    "SELF-HARM",
    "I've started cutting myself",
    "there is no point in living",
    "I think I'll just end it all",
    "I might take an overdose",
    "planning to jump off a bridge",
    "I don't want to wake up tomorrow",
    "life is not worth living",
    "I    want   to   die",                           // çoklu boşluk
    "kendimi öldürmek istiyorum",                    // Türkçe hâlâ yakalanır
    "intihar etmeyi düşünüyorum",
] { expect(text, signal: true) }

// Yakalanmamalı: yaygın abartılar ve iyi huylu cümleler (ifade tek başına ciddi olmalı).
for text in [
    "I can't sleep and my mind keeps racing",
    "This deadline is killing me",
    "I'm dying to see the results",
    "My boss makes me want to scream",
    "I hurt my knee running",
    "I feel exhausted and overwhelmed",
    "I avoid phone calls",
    "The exam is going to kill my weekend",
    "",
    "   ",
] { expect(text, signal: false) }

if failures.isEmpty { print("CrisisClassifierTests passed") } else {
    failures.forEach { print($0) }
    fatalError("\(failures.count) crisis cases failed")
}
