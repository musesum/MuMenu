//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// toggle control
@MainActor
public class LeafTogVm: LeafVm {

    /// user touches tog
    override public func touchLeaf(_ touchState: TouchState, _ visit: Visitor) {
        if let bounds = runways.bounds(),
           let thumb = runways.thumb(),
           bounds.contains(touchState.pointNow),
           touchState.phase == .ended {

            thumb.value.x = (thumb.value.x == 1.0 ? 0 : 1)
            syncVal(Visitor(0,.user))
        }
    }

    override public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb() else { return  }

        if visit.type.has([.model,.bind,.midi,.remote]) {

            menuTree.flo.setAnyExprs([("x", thumb.value.x)], .sneak, visit)

        } else if visit.type.has([.user,.midi]) {

            menuTree.flo.setAnyExprs(("x", thumb.value.x), .fire, visit)
            updateLeafPeers(visit)
        }
        // no tweens for Tog
        refreshView()
    }
}

