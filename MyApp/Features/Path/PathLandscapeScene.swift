import SwiftUI

/// Long painted meadow repeats through matching light clearings. Only the new
/// tile fades in over the opaque previous tile: opacity never exposes dark gaps.
struct PathLandscapeScene: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            if !reduceTransparency && !dynamicTypeSize.isAccessibilitySize {
                let height = geometry.size.width * 3
                let overlap = height * 0.12
                let stride = height - overlap
                let count = Int(ceil(geometry.size.height / stride)) + 1
                ZStack(alignment: .top) {
                    ForEach(0..<count, id: \.self) { index in
                        Image(decorative: "journey-world-continuous")
                            .resizable()
                            .frame(width: geometry.size.width, height: height)
                            .mask {
                                if index == 0 {
                                    Rectangle()
                                } else {
                                    LinearGradient(stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .black, location: 0.12),
                                        .init(color: .black, location: 1)
                                    ], startPoint: .top, endPoint: .bottom)
                                }
                            }
                            .offset(y: CGFloat(index) * stride)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                .visualEffect { content, proxy in
                    let y = proxy.frame(in: .scrollView(axis: .vertical)).minY
                    return content.offset(y: reduceMotion ? 0 : min(24, max(0, -y * 0.025)))
                }
                .clipped()
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
