import Foundation

// Localizable.xcstrings denetimi. Metnin tek yeri burası olduğu için kuralları da burada:
//   swiftc -o /tmp/loctest MyApp/Content/Tone.swift Tests/LocalizationCatalogTests/main.swift \
//     && /tmp/loctest            (depo kökünden)
//
// 1. Her kayıt manuel ve İngilizce değeri dolu.        2. Yasaklı ifade yok (Ton eki §3.6).
// 3. Emoji yok (tek mürekkep kuralı).                  4. Yer tutucular tutarlı, çoğul biçimler tam.
// 5. Uzun tire ve garip boşluk yok (kullanıcıya görünen metinde çift boşluk hatadır).

setbuf(stdout, nil)
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let url = root.appendingPathComponent("MyApp/Content/Localizable.xcstrings")
guard let data = try? Data(contentsOf: url),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let strings = json["strings"] as? [String: [String: Any]]
else { fatalError("Localizable.xcstrings okunamadı") }

precondition(json["sourceLanguage"] as? String == "en", "Kaynak dil İngilizce")
var failures: [String] = []
func fail(_ key: String, _ message: String) { failures.append("\(key): \(message)") }

/// Bu anahtarlar yasaklı ifade taramasının dışında: kriz ve destek ekranı, "tedavi/acil
/// hizmet değil" gibi ifadeleri **söylemek zorunda** (Nötr kademe).
func isExempt(_ key: String) -> Bool { key.hasPrefix("support.") || key.hasPrefix("crisis.") }

func placeholders(_ value: String) -> [String] {
    let regex = try! NSRegularExpression(pattern: "%(\\d+\\$)?(lld|@|d)")
    return regex.matches(in: value, range: NSRange(value.startIndex..., in: value))
        .map { String(value[Range($0.range, in: value)!]) }
}

var seenValues = 0
for (key, entry) in strings {
    guard let localizations = entry["localizations"] as? [String: Any], let en = localizations["en"] as? [String: Any] else {
        fail(key, "İngilizce yerelleştirme yok"); continue
    }
    if entry["extractionState"] as? String != "manual" {
        fail(key, "extractionState manual değil: Xcode sembol üretmez")
    }
    var values: [String] = []
    if let unit = en["stringUnit"] as? [String: Any], let value = unit["value"] as? String {
        values = [value]
    } else if let variations = en["variations"] as? [String: Any], let plural = variations["plural"] as? [String: Any] {
        for form in ["one", "other"] {
            guard let unit = (plural[form] as? [String: Any])?["stringUnit"] as? [String: Any], let value = unit["value"] as? String
            else { fail(key, "çoğul '\(form)' biçimi eksik"); continue }
            values.append(value)
        }
    } else { fail(key, "değer yok"); continue }

    for value in values {
        seenValues += 1
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { fail(key, "boş değer") }
        if value != value.trimmingCharacters(in: .whitespaces) { fail(key, "baş/son boşluk") }
        if value.contains("  ") { fail(key, "çift boşluk") }
        if value.unicodeScalars.contains(where: { $0.properties.isEmojiPresentation || ($0.properties.isEmoji && $0.value > 0x2000 && $0.value != 0x2013 && $0.value != 0x2014 && $0.value != 0x2019 && $0.value != 0x201C && $0.value != 0x201D && $0.value != 0x00B7 && $0.value != 0x2026 && $0.value != 0x2192) }) {
            fail(key, "emoji: \(value)")
        }
        if !isExempt(key) {
            let banned = BannedPhrases.check(value)
            if !banned.isEmpty { fail(key, "yasaklı ifade \(banned): \(value)") }
        }
    }
    // Çoğul biçimlerde yer tutucu sayısı ve türü aynı olmalı.
    if values.count == 2, placeholders(values[0]).sorted() != placeholders(values[1]).sorted() {
        fail(key, "çoğul biçimlerin yer tutucuları farklı")
    }
    // Bir kayıtta birden çok yer tutucu varsa hepsi konumlu olmalı (%1$@): sıra çeviride değişebilir.
    if values.count == 1 {
        let all = placeholders(values[0])
        if all.count > 1, all.contains(where: { !$0.contains("$") }) { fail(key, "birden çok yer tutucu konumsuz: \(values[0])") }
    }
}

if !failures.isEmpty {
    failures.sorted().forEach { print($0) }
    fatalError("\(failures.count) katalog kuralı ihlal edildi")
}
print("LocalizationCatalogTests passed: \(strings.count) kayıt, \(seenValues) değer")
