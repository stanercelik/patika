import SwiftUI
import UIKit

struct EditableProfilePhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Kaydetmeden önce son profil görünümünü gösterir. Fotoğraf dairesi sürüklenir,
/// kıstırma veya alttaki denetimle yakınlaştırılır.
struct ProfilePhotoEditor: View {
    let photo: EditableProfilePhoto
    let onSave: (Data) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var zoom = 1.0
    @State private var offset: CGSize = .zero
    @State private var cropSide: CGFloat = 1
    @GestureState private var gestureZoom = 1.0
    @GestureState private var gestureOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                WoodlandStyle.background.ignoresSafeArea()

                GeometryReader { proxy in
                    let side = min(proxy.size.width - 32, proxy.size.height - 104)
                    VStack(spacing: 24) {
                        cropPreview(side: side)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        HStack(spacing: 14) {
                            Image(systemName: "minus.magnifyingglass")
                                .accessibilityHidden(true)
                            Slider(value: $zoom, in: 1...4)
                                .tint(WoodlandStyle.sage)
                                .onChange(of: zoom) { _, value in
                                    offset = clamped(offset, zoom: value, side: side)
                                }
                            Image(systemName: "plus.magnifyingglass")
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(Theme.textSecondary.color)
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                        .accessibilityElement(children: .contain)
                    }
                    .padding(.vertical, 16)
                    .onAppear { cropSide = side }
                    .onChange(of: side) { _, value in cropSide = value }
                }
            }
            .navigationTitle(Text(Copy.Me.photoTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Copy.Button.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Copy.Button.save) {
                        guard let data = renderedJPEG() else { return }
                        onSave(data)
                        dismiss()
                    }
                }
            }
        }
    }

    private func cropPreview(side: CGFloat) -> some View {
        let effectiveZoom = min(max(zoom * gestureZoom, 1), 4)
        let proposed = CGSize(
            width: offset.width + gestureOffset.width,
            height: offset.height + gestureOffset.height
        )
        let effectiveOffset = clamped(proposed, zoom: effectiveZoom, side: side)
        let size = baseDisplaySize(side: side)

        return Image(uiImage: photo.image)
            .resizable()
            .frame(width: size.width * effectiveZoom, height: size.height * effectiveZoom)
            .offset(effectiveOffset)
            .frame(width: side, height: side)
            .background(Color.black)
            .clipShape(.circle)
            .overlay {
                Circle()
                    .strokeBorder(Theme.textPrimary.color.opacity(0.7), lineWidth: 2)
                    .allowsHitTesting(false)
            }
            .contentShape(.circle)
            .gesture(
                DragGesture()
                    .updating($gestureOffset) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        let proposed = CGSize(
                            width: offset.width + value.translation.width,
                            height: offset.height + value.translation.height
                        )
                        offset = clamped(proposed, zoom: zoom, side: side)
                    }
            )
            .simultaneousGesture(
                MagnifyGesture()
                    .updating($gestureZoom) { value, state, _ in state = value.magnification }
                    .onEnded { value in
                        zoom = min(max(zoom * value.magnification, 1), 4)
                        offset = clamped(offset, zoom: zoom, side: side)
                    }
            )
            .accessibilityLabel(Text(Copy.Me.photoAccessibility))
    }

    private func baseDisplaySize(side: CGFloat) -> CGSize {
        let size = photo.image.size
        guard size.width > 0, size.height > 0 else { return CGSize(width: side, height: side) }
        let scale = max(side / size.width, side / size.height)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    private func clamped(_ proposed: CGSize, zoom: Double, side: CGFloat) -> CGSize {
        let size = baseDisplaySize(side: side)
        let limitX = max(0, (size.width * zoom - side) / 2)
        let limitY = max(0, (size.height * zoom - side) / 2)
        return CGSize(
            width: min(max(proposed.width, -limitX), limitX),
            height: min(max(proposed.height, -limitY), limitY)
        )
    }

    private func renderedJPEG() -> Data? {
        let edge = AvatarStore.edge
        let source = photo.image.size
        guard source.width > 0, source.height > 0 else { return nil }
        let baseScale = max(edge / source.width, edge / source.height)
        let drawSize = CGSize(
            width: source.width * baseScale * zoom,
            height: source.height * baseScale * zoom
        )
        let normalizedOffset = clamped(offset, zoom: zoom, side: cropSide)
        let outputOffset = CGSize(
            width: normalizedOffset.width * edge / cropSide,
            height: normalizedOffset.height * edge / cropSide
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: edge, height: edge), format: format)
        return renderer.jpegData(withCompressionQuality: AvatarStore.compressionQuality) { context in
            UIColor.black.setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: CGSize(width: edge, height: edge)))
            photo.image.draw(in: CGRect(
                x: (edge - drawSize.width) / 2 + outputOffset.width,
                y: (edge - drawSize.height) / 2 + outputOffset.height,
                width: drawSize.width,
                height: drawSize.height
            ))
        }
    }
}

struct ProfilePhotoViewer: View {
    let image: UIImage
    let onChoose: () -> Void
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var confirmsRemoval = false

    var body: some View {
        NavigationStack {
            ZStack {
                WoodlandStyle.background.ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer(minLength: 20)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 360, maxHeight: 360)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(.circle)
                        .overlay { Circle().strokeBorder(WoodlandStyle.sage.opacity(0.55), lineWidth: 2) }
                        .padding(.horizontal, Theme.Spacing.screenMargin)
                    Spacer(minLength: 20)
                    PrimaryButton(title: Copy.Me.photoChoose, isEnabled: true) {
                        dismiss()
                        onChoose()
                    }
                    Button {
                        confirmsRemoval = true
                    } label: {
                        Text(Copy.Me.photoRemove)
                            .font(.body.weight(Theme.Weight.action))
                            .foregroundStyle(Theme.textSecondary.color)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.calm)
                }
                .padding(.horizontal, Theme.Spacing.screenMargin)
                .padding(.bottom, 24)
            }
            .navigationTitle(Text(Copy.Me.photoTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) { dismiss() }
                }
            }
            .alert(Text(Copy.Me.photoRemove), isPresented: $confirmsRemoval) {
                Button(Copy.Me.photoRemove, role: .destructive) {
                    dismiss()
                    onRemove()
                }
                Button(Copy.Button.cancel, role: .cancel) {}
            }
        }
    }
}
