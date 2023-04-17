//  Created by warren on 12/12/22.

import Foundation
import MuPar // Visitor

extension MuNodeVm { // + Touch

    /// reset leaf to default value
    func maybeTapLeaf() {
        if nodeType.isLeaf,
           let leafVm = self as? MuLeafVm,
           let menuSync = leafVm.menuSync {
            
            let visit = Visitor(.user)
            menuSync.setMenuDefault(visit)
            leafVm.leafProto?.refreshValue(visit)
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
    func touchBegin(_ touchState: MuTouchState) {

        let timeDelta = touchState.timeBegin - myTouchBeginTime
        if timeDelta < touchState.tapThreshold {
            myTouchBeginCount += 1
        } else {
            myTouchBeginCount = 0
        }
        myTouchBeginTime = touchState.timeBegin
        switch myTouchBeginCount {
            case 0:   break
            //case 1:   tapSpotlights()
            case 2,3: tapAllDescendants()
            default: return
        }
        //print("(\(touchState.touchBeginCount),\(myTouchBeginCount))", terminator: "  ")
    }

    /// handle repeated touchBegin counts on self
    func touchEnded(_ touchState: MuTouchState) {

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
