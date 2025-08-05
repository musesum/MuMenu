import SwiftUI
import MuFlo
import MuPeers
import MuVision
import MuHands




open class TouchView: UIView, UIGestureRecognizerDelegate {

    var safeBounds: CGRect { frame.pad(-4) }
    var touchBlock = [Hash: Bool]()
    var touchPhase = [Hash: Int]()
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
            var phase3 = min(3,touch.phase.rawValue)
            let hash = touch.hash // allows multi-finger

            if phase3 == 0, touchPhase[hash] != nil {
                phase3 = 3 // switch to endeded
            }
            let touchData = TouchData(
                force    : Float(touch.force),
                radius   : Float(touch.majorRadius),
                nextXY   : touch.preciseLocation(in: nil),
                phase    : phase3,
                azimuth  : touch.azimuthAngle(in: nil),
                altitude : touch.altitudeAngle,
                hash     : hash
            )
            switch phase3 {
            case 0: // begin

                if TouchMenuLocal.beginTouch(location, phase3, hash) { return }
                if willBeginFromEdge() { return }
                touchCanvas?.beginTouch(touchData)
                touchPhase[hash] = phase3

            default: // moved, stationaru, ended
                if beganFromEdge() { return }
                if TouchMenuLocal.updateTouch(location,phase3,hash) { return }
                touchCanvas?.updateTouch(touchData)
                if phase3 == 3 {
                    touchPhase.removeValue(forKey: hash)
                }
            }
        
            if !beganFromEdge(), phase3 != 1 {
                DebugLog { P("👆 hash: \(hash) phase: \(touch.phase.rawValue)") }
            }

            // block touch when finger starts from edge of iPhone
            func willBeginFromEdge() -> Bool {
                if !Idiom.iOS { return false }
                let fromEdge = safeBounds.contains(location) ? false : true
                touchBlock[hash] = fromEdge
                if fromEdge {
                    DebugLog { P("👆 hash: \(hash) fromEdge ***") }
                }
                return fromEdge
            }
            func beganFromEdge() -> Bool {
                if !Idiom.iOS { return false }
                if let fromEdge = touchBlock[hash] {
                    if touch.phase.done {
                        touchBlock.removeValue(forKey: hash)
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
    open override func touchesCancelled(_ touches: Set<UITouch>, with _: UIEvent?) { addTouches(touches) }
}
