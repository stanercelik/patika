import Foundation

/// Yazılıp kaydedilmemiş defter notunun cihazdaki taslağı.
///
/// Ağ hatasında kullanıcının yazdığı kaybolmasın diye. **UserDefaults değil**:
/// plist düz metin ve yedeklerle dolaşır; not kullanıcının en özel metni.
/// Taslak `ProfileRecord` ile aynı korumayı taşıyan bir dosyada (`completeUnlessOpen`)
/// durur ve kaydedilince, kriz sinyalinde ve kayıt silinince **silinir**.
enum NoteDraftStore {
    private static var fileURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "Profile", directoryHint: .isDirectory)
            .appending(path: "note-draft.txt")
    }

    static func load() -> String? {
        guard let data = try? Data(contentsOf: fileURL),
              let text = String(data: data, encoding: .utf8),
              !text.isEmpty
        else { return nil }
        return text
    }

    /// Boş metin taslağı siler.
    static func save(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            clear()
            return
        }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(text.utf8).write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            // Yazılamayan taslak bellekte kalır; kullanıcının elindeki kaybolmadı.
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
