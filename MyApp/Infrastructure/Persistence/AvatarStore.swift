import Foundation
import Observation
import UIKit

/// Profil fotoğrafının cihazdaki kopyası.
///
/// Sunucudaki dosya özel kovada ve imzalı adresle okunuyor (1 saatlik); ekranda
/// gösterilen bu yerel önbellek. Her açılışta indirmek hem yavaş hem gereksiz —
/// dosya yalnızca önbellek boşken indirilir.
///
/// Dosya `ProfileRecord` gibi `completeUnlessOpen` korumasıyla yazılır: kişinin
/// yüzü, telefon kilitliyken okunmamalı.
@Observable
@MainActor
final class AvatarStore {
    private(set) var image: UIImage?
    @ObservationIgnored private let fileURL: URL?

    /// Yüklenen kare kenarı (px). Yüz tanınsın diye yeterli, sunucuya gidecek
    /// veri küçük kalsın diye sınırlı.
    nonisolated static let edge: CGFloat = 512
    nonisolated static let compressionQuality: CGFloat = 0.8

    init(fileURL: URL?) {
        self.fileURL = fileURL
        image = fileURL.flatMap { try? Data(contentsOf: $0) }.flatMap(UIImage.init(data:))
    }

    static func live() -> AvatarStore {
        let directory = URL.applicationSupportDirectory
            .appending(path: "Profile", directoryHint: .isDirectory)
        return AvatarStore(fileURL: directory.appending(path: "avatar.jpg"))
    }

    /// Diske hiç yazmayan kopya — önizleme ve DEBUG senaryoları.
    static func ephemeral(_ image: UIImage? = nil) -> AvatarStore {
        let store = AvatarStore(fileURL: nil)
        store.image = image
        return store
    }

    var hasImage: Bool { image != nil }

    // MARK: - Hazırlama

    /// Seçilen fotoğrafı ortadan kareye kırpar, 512 px'e indirir ve JPEG %80'e
    /// yeniden kodlar. Yeniden kodlama EXIF'i (konum dahil) atar: sunucuya giden
    /// dosyada yalnızca piksel var.
    nonisolated static func prepare(_ data: Data) -> Data? {
        guard let source = UIImage(data: data),
              source.size.width > 0, source.size.height > 0
        else { return nil }

        let side = min(source.size.width, source.size.height)
        let target = min(edge, side)
        let scale = target / side
        let drawSize = CGSize(width: source.size.width * scale, height: source.size.height * scale)
        let origin = CGPoint(x: (target - drawSize.width) / 2, y: (target - drawSize.height) / 2)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: target, height: target), format: format)
        return renderer.jpegData(withCompressionQuality: compressionQuality) { _ in
            source.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }

    // MARK: - Önbellek

    /// Sunucuya yazılmış fotoğrafı önbelleğe koyar.
    func cache(_ jpeg: Data) {
        guard let decoded = UIImage(data: jpeg) else { return }
        image = decoded
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try jpeg.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            // Yazılamayan önbellek bellekte kalır; bir sonraki açılışta yeniden iner.
        }
    }

    func clear() {
        image = nil
        guard let fileURL else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Sunucudaki durumla uzlaştırır: fotoğraf yoksa önbellek de boşalır (başka
    /// bir cihazda kaldırılmış olabilir); varsa ve önbellek boşsa indirilir.
    /// İndirilemezse sessizce baş harfe düşülür — fotoğraf yüzünden hata gösterilmez.
    func reconcile(withServerURL url: URL?) async {
        guard let url else {
            clear()
            return
        }
        guard image == nil else { return }
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return }
        cache(data)
    }
}
