import SwiftUI

struct SignatureCanvas: View {
    @Binding var signature: NormalizedSignature
    @State private var currentStroke: [NormalizedSignaturePoint] = []

    var body: some View {
        VStack(spacing: 10) {
            Canvas { context, size in
                for stroke in signature.strokes + (currentStroke.isEmpty ? [] : [currentStroke]) {
                    guard let first = stroke.first else { continue }
                    if stroke.count == 1 {
                        let center = CGPoint(x: first.x * size.width, y: first.y * size.height)
                        context.fill(
                            Path(ellipseIn: CGRect(x: center.x - 2, y: center.y - 2, width: 4, height: 4)),
                            with: .color(WoodlandStyle.ink)
                        )
                        continue
                    }
                    var path = Path()
                    path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
                    for point in stroke.dropFirst() {
                        path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
                    }
                    context.stroke(path, with: .color(WoodlandStyle.ink), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(height: 164)
            .background(WoodlandStyle.paper.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(WoodlandStyle.secondaryInk.opacity(0.45), lineWidth: Theme.Line.border) }
            .contentShape(Rectangle())
            .overlay {
                GeometryReader { proxy in
                    Color.clear.contentShape(Rectangle()).gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                currentStroke.append(.init(x: value.location.x / proxy.size.width, y: value.location.y / proxy.size.height))
                            }
                            .onEnded { _ in
                                if !currentStroke.isEmpty { signature.strokes.append(currentStroke) }
                                currentStroke = []
                            }
                    )
                }
            }
            .accessibilityLabel(Text(Copy.Onboarding.signatureDrawHint))

            HStack {
                Button(Copy.Onboarding.signatureClear) { signature.strokes = [] }
                Spacer()
                Button(Copy.Onboarding.signatureSimpleMark) {
                    signature.strokes = [[.init(x: 0.18, y: 0.62), .init(x: 0.42, y: 0.78), .init(x: 0.82, y: 0.28)]]
                }
            }
            .font(Theme.TypeFace.rowAction)
            .foregroundStyle(WoodlandStyle.ink)
            .frame(minHeight: 44)
        }
    }
}
