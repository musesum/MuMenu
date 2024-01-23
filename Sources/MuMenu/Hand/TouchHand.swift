// created by musesum on 1/22/24
#if os(visionOS)
import UIKit
import ARKit
import simd // distance

public class TouchHand {

    var hand  : HandAnchor.Chirality
    var phase = UITouch.Phase.ended
    var pos   = SIMD3<Float>.zero
    var time = TimeInterval.zero
    var hash: Int { hand.hashValue }

    public init( _ hand: HandAnchor.Chirality) {
        self.hand  = hand
    }
    public func touching(_ touching: Bool, _ pos: SIMD3<Float>) {
        switch (phase, touching) {

        case (.ended, true):

            self.phase = .began
            self.pos = pos
            TouchCanvas.shared.beginTouchHand(self)

        case (.began, true),
               (.moved, true):

            self.phase = .moved
            self.pos = pos
            TouchCanvas.shared.updateTouchHand(self)

        case (.moved, false),
            (.began, false): // tap?
            
            self.phase = .ended
            self.pos = pos
            TouchCanvas.shared.updateTouchHand(self)

        default: return //

        }
    }
}

#endif
