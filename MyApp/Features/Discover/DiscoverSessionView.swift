import SwiftUI

struct DiscoverSessionView: View {
    @State private var model: DiscoverSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    init(path: DiscoverPath, step: DiscoverStep, library: DiscoverLibrary) {
        _model = State(initialValue: DiscoverSessionViewModel(path: path, step: step, library: library))
    }
    var body: some View {
        ZStack {
            DiscoverStyle.background.ignoresSafeArea()
            VStack(spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.path.title.value).font(.caption.weight(Theme.Weight.emphasis)).foregroundStyle(Theme.textSecondary.color)
                        Text(model.step.title.value).font(.title3.weight(Theme.Weight.title)).foregroundStyle(Theme.textPrimary.color)
                    }
                    Spacer()
                    Button { model.stop(); dismiss() } label: {
                        Image(systemName: "xmark").font(.body.weight(Theme.Weight.action)).frame(width: 44, height: 44)
                    }.foregroundStyle(Theme.textPrimary.color).accessibilityLabel(DiscoverCopy.close)
                }
                if model.finished {
                    Spacer()
                    Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(DiscoverStyle.apricot).accessibilityHidden(true)
                    Text(DiscoverCopy.completed).font(.largeTitle.weight(Theme.Weight.display)).foregroundStyle(Theme.textPrimary.color)
                    Text(DiscoverCopy.completedBody).font(.body.weight(Theme.Weight.body)).foregroundStyle(Theme.textSecondary.color)
                    Spacer()
                    DiscoverAction(title: DiscoverCopy.close) { dismiss() }
                } else if model.failed {
                    Spacer()
                    Text(DiscoverCopy.audioUnavailable).foregroundStyle(Theme.textPrimary.color)
                    DiscoverAction(title: DiscoverCopy.retry) { Task { await model.start() } }
                    Spacer()
                } else if model.isPreparing {
                    Spacer()
                    ProgressView().tint(Theme.textPrimary.color).accessibilityLabel(DiscoverCopy.loading)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            if !dynamicTypeSize.isAccessibilitySize {
                                DiscoverArtwork(name: model.path.artwork, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                            }
                            Text(model.sceneText).font(.title3.weight(Theme.Weight.body))
                                .foregroundStyle(Theme.textPrimary.color).multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 16)
                        }
                    }.scrollIndicators(.hidden).defaultScrollAnchor(.center, for: .alignment)
                    SessionProgressTrail(progress: model.progress)
                    Button { model.togglePause() } label: {
                        Image(systemName: model.audio.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2.weight(Theme.Weight.action)).frame(width: 68, height: 68)
                            .foregroundStyle(.black).background(Theme.textPrimary.color, in: Circle())
                    }.buttonStyle(.calm)
                        .accessibilityLabel(model.audio.isPlaying ? DiscoverCopy.pause : DiscoverCopy.resume)
                }
            }
            .padding(24)
        }
        .task { await model.start() }
        .onDisappear { model.stop() }
    }
}
