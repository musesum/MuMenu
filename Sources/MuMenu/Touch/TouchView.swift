
import SwiftUI
import MuFlo
import MultipeerConnectivity


open class TouchView: UIView, UIGestureRecognizerDelegate {

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    var peersDelegate: PeersControllerDelegate!

    public init(_ drawPoint: TouchDrawPoint? = nil,
                _ drawRadius: TouchDrawRadius? = nil,
                _ peersDelegate: PeersControllerDelegate? = nil) {

        super.init(frame:.zero)

        self.peersDelegate = peersDelegate 

        let bounds = UIScreen.main.bounds
        let w = bounds.size.width
        let h = bounds.size.height
        frame = CGRect(x: 0, y: 0, width: w, height: h)
        isMultipleTouchEnabled = true
        PeersController.shared.peersDelegates.append(self.peersDelegate)
        if let drawPoint, let drawRadius {
            TouchCanvas.setDraw(drawPoint, drawRadius)
        }
    }
    deinit {
        PeersController.shared.remove(peersDelegate: peersDelegate)
    }


    /// When starting new touch, assign finger to either Menu or Canvas.
    open func beginTouches(_ touches: Set<UITouch>) {

        for touch in touches {
            _ = TouchMenuLocal.beginTouch(touch)
        }
    }

    /// Continue dispatching finger to canvas or menu
    open func updateTouches(_ touches: Set<UITouch>) {

        for touch in touches {
            if TouchMenuLocal.updateTouch(touch) { }
            else { print("*** unknown touch \(touch.hash)") }
        }
    }
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { beginTouches(touches) }
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouches(touches) }
}
