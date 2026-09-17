import SwiftUI

struct DiscoverView: View {
    @Environment(DiscoverLibrary.self) private var library
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var preview: DiscoverPath?
    @State private var confirmsPersonal = false
    let onOpenPath: () -> Void

    var body: some View {
        ZStack {
            DiscoverStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(DiscoverCopy.title).font(.caption.weight(Theme.Weight.emphasis)).tracking(2)
                            .foregroundStyle(Theme.textSecondary.color)
                        Text(DiscoverCopy.headline).font(.largeTitle.weight(Theme.Weight.display))
                            .foregroundStyle(Theme.textPrimary.color)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(DiscoverCopy.intro).font(.subheadline.weight(Theme.Weight.body))
                            .foregroundStyle(Theme.textSecondary.color)
                    }
                    personalCard
                    VStack(alignment: .leading, spacing: 8) {
                        Text(DiscoverCopy.collection).font(.title2.weight(Theme.Weight.title))
                            .foregroundStyle(Theme.textPrimary.color)
                        Text(DiscoverCopy.collectionNote).font(.footnote.weight(Theme.Weight.body))
                            .foregroundStyle(Theme.textSecondary.color)
                    }
                    if library.loadFailed {
                        Text(DiscoverCopy.catalogError).foregroundStyle(Theme.textPrimary.color)
                    }
                    ForEach(library.paths) { path in
                        Button { preview = path } label: { DiscoverPathCard(path: path) }
                            .buttonStyle(.calm)
                            .accessibilityHint(DiscoverCopy.previewNote)
                    }
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .all)
        }
        .sheet(item: $preview) { path in
            NavigationStack {
                DiscoverPathView(path: path, isPreview: true) {
                    preview = nil
                    onOpenPath()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(DiscoverCopy.cancel, systemImage: "xmark") { preview = nil }
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(DiscoverCopy.personalConfirm, isPresented: $confirmsPersonal, titleVisibility: .visible) {
            Button(DiscoverCopy.personalAction) { library.openPersonalPath(); onOpenPath() }
            Button(DiscoverCopy.cancel, role: .cancel) {}
        } message: { Text(DiscoverCopy.personalConfirmBody) }
        #if DEBUG
        .task {
            let args = ProcessInfo.processInfo.arguments
            if let index = args.firstIndex(of: "-patika-debug-discover-preview"), args.indices.contains(index + 1) {
                preview = library.paths.first { $0.id == args[index + 1] }
            }
        }
        #endif
    }

    private var personalCard: some View {
        Button {
            if library.activePath == nil { onOpenPath() }
            else { confirmsPersonal = true }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                DiscoverArtwork(name: "discover-personal", height: 168)
                VStack(alignment: .leading, spacing: 12) {
                    Text(DiscoverCopy.personalEyebrow).font(.caption2.weight(Theme.Weight.action)).tracking(1.5)
                        .foregroundStyle(DiscoverStyle.apricot)
                    Text(DiscoverCopy.personalTitle).font(.title2.weight(Theme.Weight.title))
                        .foregroundStyle(Theme.textPrimary.color)
                    Text(DiscoverCopy.personalBody).font(.subheadline.weight(Theme.Weight.body))
                        .foregroundStyle(Theme.textSecondary.color)
                    HStack {
                        Text(DiscoverCopy.personalAction)
                        Spacer()
                        Image(systemName: "arrow.up.right").accessibilityHidden(true)
                    }
                    .font(.subheadline.weight(Theme.Weight.action))
                    .foregroundStyle(Theme.textPrimary.color)
                    .padding(.top, 8)
                }
                .padding(22)
            }
            .background(DiscoverStyle.surface)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 28).strokeBorder(.white.opacity(0.09), lineWidth: Theme.Line.journeyConnector) }
            .contentShape(RoundedRectangle(cornerRadius: 28))
        }
        .buttonStyle(.calm)
    }
}

struct DiscoverPathCard: View {
    let path: DiscoverPath
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DiscoverArtwork(name: path.artwork, height: 194)
                .overlay(alignment: .topLeading) {
                    Text(DiscoverCopy.preview)
                        .font(.caption.weight(Theme.Weight.action))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .foregroundStyle(Theme.textPrimary.color)
                        .background(DiscoverStyle.background, in: Capsule())
                        .padding(16)
                }
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 16) {
                    Text(path.title.value).font(.title2.weight(Theme.Weight.title))
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right").font(.body.weight(Theme.Weight.action)).accessibilityHidden(true)
                }
                .foregroundStyle(Theme.textPrimary.color)
                Text(path.summary.value).font(.subheadline.weight(Theme.Weight.body)).foregroundStyle(Theme.textSecondary.color)
                Text(DiscoverCopy.duration).font(.caption.weight(Theme.Weight.emphasis)).foregroundStyle(Theme.textSecondary.color).padding(.top, 6)
            }.padding(22)
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(DiscoverStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 28))
    }
}

enum DiscoverStyle {
    static let background = RGB(hex: 0x101918).color
    static let surface = RGB(hex: 0x1B2928).color
    static let apricot = RGB(hex: 0xE9BA8F).color
}

struct DiscoverArtwork: View {
    let name: String
    var height: CGFloat
    var body: some View {
        Color.clear.frame(height: height)
            .overlay { Image(decorative: name).resizable().scaledToFill() }
            .clipped()
            .accessibilityHidden(true)
    }
}
