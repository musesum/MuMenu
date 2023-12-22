//  created by musesum on 12/12/22.

import Foundation
import MuFlo

extension NodeVm { // + Touch

    /// reset leaf to default value
    func maybeTapLeaf() {
        if nodeType.isLeaf,
           let leafVm = self as? LeafVm {
            
            let visit = Visitor(.user)
            node.modelFlo.bindDefaults(visit)
            node.modelFlo.activate(visit)
            leafVm.leafProto?.refreshValue(Visitor(.user))
        }
    }
    /// update all descendants
    func tapAllDescendants() {
        maybeTapLeaf()
        for nodeVm in nextBranchVm?.nodeVms ?? [] {
            nodeVm.tapAllDescendants()
        }
    }
    /// update only chain of spotlight nodes
    func tapSpotlights() {
        maybeTapLeaf()
        nextBranchVm?.nodeSpotVm?.tapSpotlights()
    }
    /// handle repeated touchBegin counts on self
    func touchBegin(_ touchState: TouchState) {

        let timeDelta = touchState.timeBegin - myTouchBeginTime
        if timeDelta < touchState.tapThreshold {
            myTouchBeginCount += 1
        } else {
            myTouchBeginCount = 0
        }
        myTouchBeginTime = touchState.timeBegin
        switch myTouchBeginCount {
            case 0:   break
            case 1:   tapSpotlights() 
            case 2,3: tapAllDescendants()
            default: return
        }
        //print("(\(touchState.touchBeginCount),\(myTouchBeginCount))", terminator: "  ")
    }

    /// handle repeated touchBegin counts on self
    func touchEnded(_ touchState: TouchState) {

        let timeDelta = touchState.timeEnded - myTouchEndedTime
        if timeDelta < touchState.tapThreshold {
            myTouchEndedCount += 1
        } else {
            myTouchEndedCount = 0
        }
        myTouchEndedTime = touchState.timeBegin
        switch myTouchEndedCount {
            case 0:   break
            case 1:   tapSpotlights()
            //case 2,3: tapAllDescendants()
            default: return
        }
        //print("(\(touchState.touchBeginCount),\(myTouchBeginCount))", terminator: "  ")
    }
}
