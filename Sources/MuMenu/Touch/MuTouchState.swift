//  Created by warren on 1/15/22.

import SwiftUI

public class MuTouchState {

    public enum MuTouchPhase { case none, begin, moved, ended }
    let tapThreshold = TimeInterval(0.5) /// tap time threshold
    let speedThreshold = CGFloat(300) /// test to skip branches
    let moveThreshold = CGFloat(5)   /// move distance to reset touchEndCount

    var touchBeginCount = 0  /// count `touchBegin`s within tapThreshold
    var touchEndedCount = 0    /// count `touchEnd`s within tapThreshold
    var isFast = false  /// is moving fast to skip branches
    var pointNow = CGPoint.zero /// current position of touch
    var phase = UITouch.Phase.ended
    var touching: Bool { return timeBegin > timeEnded }

    var timeBegin  = TimeInterval(0) /// starting time for tap candidate
    var timeEnded  = TimeInterval(0) /// ending time for tap candidate
    var moved: CGPoint { pointNow - pointBegin }/// pointNow - pointBegin
                                   ///
    private var timePrev   = TimeInterval(0) /// previous time of touch
    private var timeBeginΔ = TimeInterval(0) /// time elapsed since beginning
    private var pointBegin  = CGPoint.zero /// where touch started
    private var pointPrev   = CGPoint.zero /// last reported touch while moving
    private var touchSpeed  = CGFloat.zero /// speed of movement

    func beginPoint(_ pointNow: CGPoint) {

        phase = .began

        let timeNow = Date().timeIntervalSince1970
        timeBegin = timeNow
        timePrev = timeNow

        self.pointNow = pointNow
        pointBegin = pointNow
        pointPrev = pointNow

        logTouch(0, "🟢")
        updateTouchBeginCount()
    }

    func movedPoint(_ point: CGPoint) {
        phase = .moved
        updateTimePoint(point)
        if point.distance(pointBegin) > moveThreshold {
            touchEndedCount = 0
        }
    }
    func ended() {

        phase = .ended
        updateTimePoint(pointNow)
        updateTouchEndCount()
        logTouch(timeBeginΔ, "🛑")
    }

    private func updateTimePoint(_ point: CGPoint) {

        let timeNow = Date().timeIntervalSince1970
        let timePrevΔ = timeNow - timePrev

        timeBeginΔ = timeNow - timeBegin
        timePrev = timeNow

        if phase == .ended {
            timeEnded = timeNow
        }
        pointNow = point
        pointPrev = point
        let distance = pointPrev.distance(point)

        touchSpeed = CGFloat(distance/timePrevΔ)
        isFast = touchSpeed > speedThreshold
    }

    func updateTouchBeginCount() {

        timeBeginΔ = timeBegin - timeEnded

        if timeBeginΔ < tapThreshold {
            touchBeginCount += 1
            //log("⇂⃝" + superScript(touchBeginCount), format: "%.2f", [timeBeginΔ], terminator: " ")
        } else {
            touchBeginCount = 0
            touchEndedCount = 0
            timeBeginΔ = 0
        }
    }
    func updateTouchEndCount() {

        let timeEndedΔ = timeEnded - timeBegin

        if timeEndedΔ < tapThreshold {
            touchEndedCount += 1
            //log("↾⃝" + superScript(touchEndedCount), format: "%.2f", [timeEndedΔ], terminator: " ")
        } else {
            touchEndedCount = 0
        }
    }

}
