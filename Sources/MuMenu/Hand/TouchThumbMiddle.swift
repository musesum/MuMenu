// created by musesum on 1/22/24
#if os(visionOS)
import ARKit
import MuHand

open class TouchThumbMiddle {

    var leftHand: HandFlo
    var rightHand: HandFlo
    var timeLeft = TimeInterval.zero
    var timeRight = TimeInterval.zero
    var touchLeft: TouchHand
    var touchRight: TouchHand
    var touchPhase: TouchHandDelegate

    public init(_ touchPhase: TouchHandDelegate,
                _ handsFlo: HandsFlo) {

        self.touchPhase = touchPhase
        self.touchLeft = TouchHand(touchPhase, .left)
        self.touchRight = TouchHand(touchPhase, .right)

        self.leftHand = handsFlo.leftHand
        self.rightHand = handsFlo.rightHand
        leftHand.setJoints([.thumbTip, .middleTip], on: true)
        rightHand.setJoints([.thumbTip, .middleTip], on: true)
    }

    public func updateTouch() {

        if touchLeft.time < leftHand.time {
            touchLeft.time = leftHand.time
            if let thumbTip = leftHand.joints[.thumbTip]?.xyz,
               let middleTip = leftHand.joints[.middleTip]?.xyz {
                let tipsDistance = distance(thumbTip, middleTip)
                if tipsDistance < 0.04 {
                    touchLeft.touching(true, middleTip)
                } else {
                    touchLeft.touching(false, middleTip)
                }
            }

        }
        if touchRight.time < rightHand.time {
            touchRight.time = rightHand.time
            if let thumbTip = rightHand.joints[.thumbTip]?.xyz,
               let middleTip = rightHand.joints[.middleTip]?.xyz {
                let tipsDistance = distance(thumbTip, middleTip)
                if tipsDistance < 0.04 {
                    touchRight.touching(true, middleTip)
                    //print("🤏", terminator: " ")
                } else {
                    touchRight.touching(false, middleTip)
                }
            }

        }

    }

}

#endif
