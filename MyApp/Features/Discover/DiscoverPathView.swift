import SwiftUI

struct DiscoverPathView: View {
    let path: DiscoverPath
    let isPreview: Bool
    var onJoined: () -> Void = {}
    @Environment(DiscoverLibrary.self) private var library
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedVoice: SessionVoice = .feminine
    @State private var confirmsJoin = false
    @State private var session: DiscoverStep?

    var body: some View {
        ZStack {
            DiscoverStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    DiscoverArtwork(name: path.artwork, height: dynamicTypeSize.isAccessibilitySize ? 140 : 230)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    VStack(alignment: .leading, spacing: 12) {
                        if isPreview { badge(DiscoverCopy.preview, symbol: "eye") }
                        Text(path.title.value).font(.largeTitle.weight(Theme.Weight.display))
                            .foregroundStyle(Theme.textPrimary.color).fixedSize(horizontal: false, vertical: true)
                        Text(path.summary.value).font(.body.weight(Theme.Weight.body)).foregroundStyle(Theme.textSecondary.color)
                        Text(DiscoverCopy.duration).font(.footnote.weight(Theme.Weight.emphasis)).foregroundStyle(DiscoverStyle.apricot)
                        Text(isPreview ? DiscoverCopy.previewNote : DiscoverCopy.offline)
                            .font(.footnote.weight(Theme.Weight.body)).foregroundStyle(Theme.textSecondary.color)
                    }
                    voicePicker
                    if !isPreview, library.nextStep(path) == nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(DiscoverCopy.allDone).font(.title2.weight(Theme.Weight.title))
                            Text(DiscoverCopy.allDoneBody).font(.body.weight(Theme.Weight.body))
                        }.foregroundStyle(Theme.textPrimary.color)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(DiscoverCopy.steps).font(.title2.weight(Theme.Weight.title))
                            .foregroundStyle(Theme.textPrimary.color).padding(.bottom, 20)
                        ForEach(Array(path.steps.enumerated()), id: \.element.id) { index, step in
                            stepRow(step, number: index + 1)
                        }
                    }
                    if isPreview && dynamicTypeSize.isAccessibilitySize { joinControls }
                    if library.saveFailed {
                        Text(DiscoverCopy.saveError).foregroundStyle(Theme.textPrimary.color)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, isPreview ? 16 : 72)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .all)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isPreview && !dynamicTypeSize.isAccessibilitySize {
                joinControls.padding(20).background(DiscoverStyle.background)
            }
        }
        .confirmationDialog(DiscoverCopy.joinTitle, isPresented: $confirmsJoin, titleVisibility: .visible) {
            Button(DiscoverCopy.join) { library.enroll(path, voice: selectedVoice); onJoined() }
            Button(DiscoverCopy.cancel, role: .cancel) {}
        } message: { Text(DiscoverCopy.joinBody) }
        .fullScreenCover(item: $session) { step in
            DiscoverSessionView(path: path, step: step, library: library)
        }
        .onAppear { selectedVoice = library.voice(for: path) }
        .onChange(of: selectedVoice) { _, voice in
            if !isPreview { library.selectVoice(voice, for: path) }
        }
    }

    private var joinControls: some View {
        VStack(spacing: 10) {
            DiscoverAction(title: library.isEnrolled(path) ? DiscoverCopy.continuePath : DiscoverCopy.join, enabled: library.audioIsReady(path)) {
                confirmsJoin = true
            }
            if !library.audioIsReady(path) {
                Text(DiscoverCopy.audioPreparing)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary.color)
            }
        }
    }

    private var voicePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(DiscoverCopy.voice).font(.headline.weight(Theme.Weight.title)).foregroundStyle(Theme.textPrimary.color)
            Picker(DiscoverCopy.voice, selection: $selectedVoice) {
                Text(DiscoverCopy.feminine).tag(SessionVoice.feminine)
                Text(DiscoverCopy.masculine).tag(SessionVoice.masculine)
            }
            .pickerStyle(.menu)
            .tint(Theme.textPrimary.color)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .padding(.horizontal, 16)
            .background(DiscoverStyle.surface, in: RoundedRectangle(cornerRadius: 16))
            Text(DiscoverCopy.voiceNote).font(.footnote.weight(Theme.Weight.body)).foregroundStyle(Theme.textSecondary.color)
        }
    }

    private func stepRow(_ step: DiscoverStep, number: Int) -> some View {
        let done = library.isComplete(step, in: path)
        let available = !isPreview && library.isAvailable(step, in: path)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle().fill(DiscoverStyle.surface)
                    if done && !isPreview {
                        Image(systemName: "checkmark").font(.body.weight(Theme.Weight.action))
                    } else { Text(number.formatted()).font(.body.weight(Theme.Weight.action)) }
                }.frame(width: 44, height: 44).foregroundStyle(Theme.textPrimary.color).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text(step.title.value).font(.headline.weight(Theme.Weight.title)).foregroundStyle(Theme.textPrimary.color)
                        .fixedSize(horizontal: false, vertical: true)
                    if !isPreview {
                        Text(done ? DiscoverCopy.done : available ? DiscoverCopy.now : DiscoverCopy.nextLocked)
                            .font(.caption.weight(Theme.Weight.emphasis)).foregroundStyle(Theme.textSecondary.color)
                    }
                }
                Spacer(minLength: 0)
                if !isPreview && !available {
                    Image(systemName: "lock").font(.caption).foregroundStyle(Theme.textSecondary.color).accessibilityHidden(true)
                }
            }
            if available {
                DiscoverAction(title: done ? DiscoverCopy.replay : DiscoverCopy.start, enabled: library.audioIsReady(path)) { session = step }
            }
            Rectangle().fill(.white.opacity(0.08)).frame(height: Theme.Line.journeyConnector).padding(.top, 6)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .contain)
    }
    private func badge(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol).font(.caption.weight(Theme.Weight.action))
            .foregroundStyle(DiscoverStyle.apricot).padding(.horizontal, 12).padding(.vertical, 8)
            .background(DiscoverStyle.surface, in: Capsule())
    }
}

struct DiscoverAction: View {
    let title: String
    var enabled = true
    let action: () -> Void
    var body: some View {
        Button {
            Theme.softHaptic(intensity: 0.4)
            action()
        } label: {
            Text(title).font(.body.weight(Theme.Weight.action)).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(enabled ? Color.black : Theme.textSecondary.color)
                .padding(.horizontal, 20).padding(.vertical, 18)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(enabled ? Theme.textPrimary.color : DiscoverStyle.surface, in: Capsule())
        }.buttonStyle(.calm).disabled(!enabled)
    }
}
