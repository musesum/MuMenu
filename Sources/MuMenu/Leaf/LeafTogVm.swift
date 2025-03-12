//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// toggle control
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

        switch visit.type {
        case .tween: break
        //.... case .bind: thumb.value.x = menuTree.model˚.double
        default:
            menuTree.model˚.setAnyExprs(("x", thumb.value.x), .fire, visit)
            updateLeafPeers(visit)
        }
        refreshView()
    }
}

