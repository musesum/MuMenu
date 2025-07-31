import SwiftUI
import MuFlo
import MuPeers
import MuVision
import MuHands

open class TouchView: UIView, UIGestureRecognizerDelegate {

    var safeBounds: CGRect { frame.pad(-4) }
    var blockTouch = [Int: Bool]()
    var touchCanvas: TouchCanvas?

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public init(_ pipeline: Pipeline,
                _ touchCanvas: TouchCanvas) {
        let size = pipeline.pipeSize
        NoDebugLog { P("🧭 TouchView::init size \(size.digits())") }
        super.init(frame: .zero)
        self.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.touchCanvas = touchCanvas
        self.backgroundColor = .clear
        self.isOpaque = false
        self.layer.addSublayer(pipeline.layer)
        isMultipleTouchEnabled = true
    }

    open func addTouches(_ touches: Set<UITouch>) {

        for touch in touches {

            let location = touch.preciseLocation(in: nil)
            let phase = min(3,touch.phase.rawValue)
            let hash = touch.hash // allows multi-finger
            let touchData = TouchData(
                force    : Float(touch.force),
                radius   : Float(touch.majorRadius),
                nextXY   : touch.preciseLocation(in: nil),
                phase    : phase,
                azimuth  : touch.azimuthAngle(in: nil),
                altitude : touch.altitudeAngle,
                key      : touch.hash
            )
            switch phase {
            case 0: // begin
                if TouchMenuLocal.beginTouch(location, phase, hash) { return }
                if willBeginFromEdge() { return }
                touchCanvas?.beginTouch(touchData)
            default: // moved, stationaru, ennded
                if beganFromEdge() { return }
                if TouchMenuLocal.updateTouch(location,phase,hash) { return }
                touchCanvas?.updateTouch(touchData)
            }
            // block touch when finger starts from edge of iPhone
            func willBeginFromEdge() -> Bool {
                if !Idiom.iOS { return false }
                let fromEdge = safeBounds.contains(location) ? false : true
                blockTouch[hash] = fromEdge
                return fromEdge
            }
            func beganFromEdge() -> Bool {
                if !Idiom.iOS { return false }
                if let fromEdge = blockTouch[hash] {
                    if touch.phase.done {
                        blockTouch.removeValue(forKey: hash)
                    }
                    return fromEdge
                }
                return false
            }
        }
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) { addTouches(touches) }
    open override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) { addTouches(touches) }
    open override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) { addTouches(touches) }
    open override func touchesCancelled(_ touches: Set<UITouch>, with _: UIEvent?) {
        DebugLog { P("👆❌touches cancelled phase: \(touches.first?.phase.rawValue ?? -1)") }
        addTouches(touches)
    }
}
