//  created by musesum on 12/12/22.

import Foundation
import MuFlo

extension NodeVm { // + Touch

    /// reset leaf to default value
    func maybeTapLeaf() {
        if spotlight || nodeType.isLeaf {
            //MuLog.Print("●"+menuTree.title, terminator: " ")
            tapLeaf()
        } else {
            //MuLog.Print("⦰" + menuTree.title, terminator: " ")
        }
    }
    /// update only chain of spotlight nodes
    private func tapSpotlights() {
        maybeTapLeaf()
        nextBranchVm?.nodeSpotVm?.tapSpotlights()
    }
    /// handle repeated touchBegin counts on self
    func tapNode(_ touchState: TouchState) {
        //MuLog.Print("🔰".superScript(touchState.touchBeginCount), terminator: " ")
        tapSpotlights()
    }
}
