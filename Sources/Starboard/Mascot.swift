import SwiftUI

struct Mascot: View {
    private static let bodyColor = Color(red: 0x0e / 255, green: 0x7a / 255, blue: 0x48 / 255)
    private static let eyeWhite = Color(red: 0xf8 / 255, green: 0xf3 / 255, blue: 0xe8 / 255)
    private static let pupil = Color(red: 0x18 / 255, green: 0x14 / 255, blue: 0x0f / 255)

    private static let gridWidth: CGFloat = 16
    private static let gridHeight: CGFloat = 13
    static let aspectRatio: CGFloat = gridHeight / gridWidth

    private static let tickInterval: TimeInterval = 0.05

    @State private var animator = MascotAnimator()

    var body: some View {
        TimelineView(.periodic(from: .now, by: Self.tickInterval)) { context in
            Canvas { ctx, size in
                draw(state: animator.advance(to: context.date), in: &ctx, size: size)
            }
        }
        .aspectRatio(Self.gridWidth / Self.gridHeight, contentMode: .fit)
    }

    private func draw(state: MascotFrameState, in context: inout GraphicsContext, size: CGSize) {
        let unit = size.width / Self.gridWidth

        func fill(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
            let rect = CGRect(x: x * unit, y: y * unit, width: w * unit, height: h * unit)
            context.fill(Path(rect), with: .color(color))
        }

        fill(8, 0, 1, 2, Self.bodyColor)
        fill(5, 2, 6, 1, Self.bodyColor)
        fill(3, 3, 10, 1, Self.bodyColor)
        fill(2, 4, 12, 5, Self.bodyColor)
        fill(3, 9, 10, 1, Self.bodyColor)

        if state.blinking {
            fill(5, 6, 2, 1, Self.pupil)
            fill(9, 6, 2, 1, Self.pupil)
        } else {
            fill(5, 5, 2, 2, Self.eyeWhite)
            fill(9, 5, 2, 2, Self.eyeWhite)
            let offset = state.look.offset
            fill(5 + offset.0, 5 + offset.1, 1, 1, Self.pupil)
            fill(9 + offset.0, 5 + offset.1, 1, 1, Self.pupil)
        }

        let leftLeg: CGFloat = state.legFrameA ? 2 : 1
        let rightLeg: CGFloat = state.legFrameA ? 1 : 2
        fill(5, 10, 2, leftLeg, Self.bodyColor)
        fill(9, 10, 2, rightLeg, Self.bodyColor)
    }
}

private enum MascotLook: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight

    var offset: (CGFloat, CGFloat) {
        switch self {
        case .topLeft: return (0, 0)
        case .topRight: return (1, 0)
        case .bottomLeft: return (0, 1)
        case .bottomRight: return (1, 1)
        }
    }
}

private struct MascotFrameState {
    let legFrameA: Bool
    let blinking: Bool
    let look: MascotLook
}

private final class MascotAnimator {
    private static let legInterval: TimeInterval = 0.34
    private static let blinkHoldMin: TimeInterval = 4.2
    private static let blinkHoldRandom: TimeInterval = 2.0
    private static let blinkDuration: TimeInterval = 0.15
    private static let lookHoldMin: TimeInterval = 1.5
    private static let lookHoldRandom: TimeInterval = 3.5

    private var legFrameA = true
    private var blinking = false
    private var look: MascotLook = .bottomRight
    private var lastLegToggle: Date
    private var blinkUntil: Date?
    private var nextBlinkAt: Date
    private var nextLookAt: Date

    init(now: Date = Date()) {
        lastLegToggle = now
        nextBlinkAt =
            now.addingTimeInterval(Self.blinkHoldMin + Double.random(in: 0...Self.blinkHoldRandom))
        nextLookAt =
            now.addingTimeInterval(Self.lookHoldMin + Double.random(in: 0...Self.lookHoldRandom))
    }

    func advance(to now: Date) -> MascotFrameState {
        if now.timeIntervalSince(lastLegToggle) >= Self.legInterval {
            legFrameA.toggle()
            lastLegToggle = now
        }

        if let until = blinkUntil {
            if now >= until {
                blinking = false
                blinkUntil = nil
                nextBlinkAt =
                    now.addingTimeInterval(
                        Self.blinkHoldMin + Double.random(in: 0...Self.blinkHoldRandom))
            }
        } else if now >= nextBlinkAt {
            blinking = true
            blinkUntil = now.addingTimeInterval(Self.blinkDuration)
        }

        if now >= nextLookAt {
            let options = MascotLook.allCases.filter { $0 != look }
            look = options.randomElement() ?? look
            nextLookAt =
                now.addingTimeInterval(Self.lookHoldMin + Double.random(in: 0...Self.lookHoldRandom))
        }

        return MascotFrameState(legFrameA: legFrameA, blinking: blinking, look: look)
    }
}
