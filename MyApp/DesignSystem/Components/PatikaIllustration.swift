import SwiftUI

/// The shared gouache family. Artwork expresses a moment, never a user's score.
enum PatikaArtwork: String {
    case reflection = "illustration-reflection"
    case belonging = "illustration-belonging"
    case shelter = "illustration-shelter"
    case trail = "illustration-trail"
    case rest = "illustration-rest"
    case journal = "illustration-journal"
}

/// Alpha is part of the artwork, so the existing palette remains visible.
/// No independent animation: the screen owns its reveal and motion policy.
struct PatikaIllustration: View {
    let artwork: PatikaArtwork

    var body: some View {
        Image(decorative: artwork.rawValue)
            .resizable()
            .scaledToFit()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
