import SwiftUI
import UIKit

/// Görsel varlığın pakette olup olmadığı.
///
/// Ekranlar görseller eklenmeden de kırılmaz (docs/profile-v2-plan.md Doğrulama 6):
/// varlık yoksa ya yer kaplamaz ya da adaçayı düz yüzey çizilir. `Image(decorative:)`
/// eksik bir adı sessizce boş çiziyor ve çerçevesinin boşluğunu bırakıyor; bu yüzden
/// varlığa bağlı her yerleşim önce buraya sorar.
///
/// DEBUG: `-patika-debug-no-art` bütün görselleri yokmuş gibi gösterir.
enum PatikaArt {
    static func exists(_ name: String) -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-patika-debug-no-art") { return false }
        #endif
        return UIImage(named: name) != nil
    }
}

/// Krem kâğıt dokusu; yoksa düz kâğıt rengi. Defter kartının altındaki sayfa ve
/// defter sayfasının kendisi aynı yüzeyi kullanır.
struct PatikaPaperTexture: View {
    var body: some View {
        if PatikaArt.exists("me-journal-paper") {
            Image(decorative: "me-journal-paper")
                .resizable()
                .scaledToFill()
                .overlay(WoodlandStyle.paper.opacity(0.35))
                .clipped()
        } else {
            WoodlandStyle.paper
        }
    }
}
