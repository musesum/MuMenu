import SwiftUI
import MuFlo
import MuPeers
import MuVision
import MuHands


enum TouchFrom: String {
    case none   = "⬜︎"
    case edge   = "║║"
    case menu   = "📋"
    case canvas = "🎑"
}

/// Sometimes UITouches recycle hashes. This becomes a problem with remote replay
/// as there is a lagtime, resulting in some touch begin…end cycles getting
/// stuffed into the same touchBuffers[item.hash]. The result is that some
/// recycled gestures may be ignored or get stuck.
/// 
/// Instead, HashBump looks at recycled Hashes and bumps up the hash value by +1.
/// After a timeout of 60 seconds, the history will get clear out, which should be
/// enough time for any remote timelag.
class HashBump {

    let id = Visitor.nextId()
    let maxLag = TimeInterval(60) // after two seconds clear out history
    var lastTime = TimeInterval(0)
    var history = [Int: Int]()

    func hash(_ phase: Int,_ hash: Int) -> Int {

        let now = Date().timeIntervalSince1970
        if now - lastTime > maxLag {
            history.removeAll()
        }
        lastTime = now

        if phase == UITouch.Phase.began.rawValue {
            history[hash] = (history[hash] ?? -1) + 1
        }
        return hash + (history[hash] ?? 0)
    }
}
open class TouchView: UIView, UIGestureRecognizerDelegate {

    var safeBounds: CGRect { frame.pad(-4) }
    var touchBlock = [Hash: Bool]()
    var touchPhase = [Hash: Int]()
    var touchCanvas: TouchCanvas?
    let hashBump = HashBump()

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
            let hash = hashBump.hash(phase,touch.hash) // allows multi-finger
            let touchData = TouchData(
                force    : Float(touch.force),
                radius   : Float(touch.majorRadius),
                nextXY   : touch.preciseLocation(in: nil),
                phase    : phase,
                azimuth  : touch.azimuthAngle(in: nil),
                altitude : touch.altitudeAngle,
                hash     : hash,
                type     : VisitType.user.rawValue
            )

            var from = TouchFrom.none

            switch phase {
            case 0: // begin
                if TouchMenuLocal.beginTouch(location, phase, hash) {  from = .menu }
                else if willBeginFromEdge() {
                    touchCanvas?.beginTouch(touchData); from = .edge
                } else {
                    touchCanvas?.beginTouch(touchData); from = .canvas
                }
            default: // moved, stationary, ended
                if beganFromEdge() { from = .edge }
                else if TouchMenuLocal.updateTouch(location,phase,hash) {
                    from = .menu
                } else {
                    touchCanvas?.updateTouch(touchData); from = .canvas
                }
            }
            // log()

            // block touch when finger starts from edge of iPhone
            func willBeginFromEdge() -> Bool {
                if !Idiom.iOS { return false }
                let fromEdge = safeBounds.contains(location) ? false : true
                touchBlock[hash] = fromEdge
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

            func log() {
                switch phase {
                case 0,2,3: DebugLog { P("👆 \(from.rawValue) hash: \(hash) phase: \(touch.phase.rawValue)") }
                default: TimeLog("👆 \(hash)", interval:0.5) { P("👆 \(from.rawValue) hash: \(hash) phase: \(touch.phase.rawValue)")}
                }
            }
        }
    }
    open override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) { addTouches(touches) }
    open override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) { addTouches(touches) }
    open override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) { addTouches(touches) }
    open override func touchesCancelled(_ touches: Set<UITouch>, with _: UIEvent?) { addTouches(touches) }
}
