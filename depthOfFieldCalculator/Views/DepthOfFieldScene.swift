//
//  DepthOfFieldScene.swift
//  depthOfFieldCalculator
//
//  An illustration of the shooting situation: the camera on the left, the subject
//  standing at the focus distance, the acceptably sharp zone highlighted on the
//  ground, the hyperfocal distance marked, and mountains on the horizon when the
//  zone reaches infinity.
//

import SwiftUI

struct DepthOfFieldScene: View {
    let result: DepthOfField
    /// Focus distance in millimetres.
    let focus: Double
    /// Formats a distance in millimetres for display; `nil` means infinity.
    let format: (Double?) -> String

    private let height: CGFloat = 150
    private let inset: CGFloat = 34
    private let zoneHeight: CGFloat = 12

    /// The distance represented by the right edge of the scene, in millimetres.
    private var scaleEnd: Double {
        if let far = result.far {
            // Keep the far limit inside the scene, and show the hyperfocal mark if it is not too far away.
            let candidate = max(far * 1.2, focus * 1.4)
            return result.hyperfocal <= candidate * 1.6 ? max(candidate, result.hyperfocal * 1.12) : candidate
        }
        return max(focus * 2.2, result.hyperfocal * 1.3)
    }

    private var hyperfocalIsVisible: Bool { result.hyperfocal <= scaleEnd }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let groundY = height - 34
            let usable = width - inset * 2
            let x = { (mm: Double) -> CGFloat in inset + CGFloat(min(max(mm / scaleEnd, 0), 1)) * usable }
            let nearX = x(result.near)
            let farX = result.far.map(x) ?? width - inset
            let subjectX = x(focus)

            ZStack(alignment: .topLeading) {
                // Sky and ground.
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.10), Color.accentColor.opacity(0.02), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: groundY)
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: width, height: 2)
                    .position(x: width / 2, y: groundY)

                // Horizon when the sharp zone extends to infinity.
                if result.isInfinite {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.tertiary)
                        .position(x: width - inset - 6, y: groundY - 15)
                }

                // Acceptably sharp zone on the ground.
                sharpZone
                    .frame(width: max(farX - nearX, zoneHeight), height: zoneHeight)
                    .position(x: (nearX + farX) / 2, y: groundY)
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 6, y: 2)

                // Hyperfocal mark.
                if hyperfocalIsVisible {
                    let hx = x(result.hyperfocal)
                    Path { path in
                        path.move(to: CGPoint(x: hx, y: groundY - 54))
                        path.addLine(to: CGPoint(x: hx, y: groundY + 10))
                    }
                    .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    Text("H")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .position(x: hx, y: groundY - 64)
                }

                // Camera.
                VStack(spacing: 2) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.primary)
                    Image(systemName: "tripod")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .position(x: inset, y: groundY - 30)

                // Subject.
                Image(systemName: "figure.stand")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.accentColor)
                    .position(x: subjectX, y: groundY - 24)

                // Captions below the ground line. The near value always wins; the others
                // are hidden when they would collide with it.
                let nearText = format(result.near)
                let farText = format(result.far)
                let nearLabelX = min(max(nearX, estimatedWidth(nearText) / 2 + 6), width - estimatedWidth(nearText) / 2 - 6)
                let farLabelX = result.far == nil ? width - inset : min(farX, width - estimatedWidth(farText) / 2 - 6)
                let captionY = groundY + 20

                if labelsFit(inset, "Camera", nearLabelX, nearText) {
                    caption("Camera").position(x: inset, y: captionY)
                }
                caption(nearText).position(x: nearLabelX, y: captionY)
                if labelsFit(nearLabelX, nearText, farLabelX, farText) {
                    caption(farText).position(x: farLabelX, y: captionY)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.snappy, value: result)
        .animation(.snappy, value: focus)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Depth of field illustration")
        .accessibilityValue("Sharp from \(format(result.near)) to \(format(result.far))")
    }

    @ViewBuilder
    private var sharpZone: some View {
        if result.isInfinite {
            Rectangle()
                .fill(LinearGradient(
                    colors: [.accentColor, .accentColor, .accentColor.opacity(0.15)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: zoneHeight / 2, bottomLeadingRadius: zoneHeight / 2
                ))
        } else {
            Capsule().fill(Color.accentColor)
        }
    }

    /// Rough width of a caption, used to decide whether two captions would overlap.
    private func estimatedWidth(_ text: String) -> CGFloat {
        CGFloat(text.count) * 7 + 6
    }

    private func labelsFit(_ x1: CGFloat, _ text1: String, _ x2: CGFloat, _ text2: String) -> Bool {
        abs(x1 - x2) >= (estimatedWidth(text1) + estimatedWidth(text2)) / 2 + 8
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .fixedSize()
    }
}

#Preview("Finite") {
    let result = DepthOfField(circleOfConfusion: 0.032, fNumber: 3.5, focalLength: 28, focusDistance: 2000)!
    DepthOfFieldScene(result: result, focus: 2000) { $0.map { String(format: "%.2f m", $0 / 1000) } ?? "∞" }
        .padding()
}

#Preview("Infinite") {
    let result = DepthOfField(circleOfConfusion: 0.032, fNumber: 3.5, focalLength: 28, focusDistance: 8000)!
    DepthOfFieldScene(result: result, focus: 8000) { $0.map { String(format: "%.2f m", $0 / 1000) } ?? "∞" }
        .padding()
}
