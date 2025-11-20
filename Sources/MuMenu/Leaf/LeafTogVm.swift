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

        if visit.type.has([.model,.bind,.midi]) {
            menuTree.flo.setNameNums([("x", thumb.value.x)], .sneak, visit)

        } else if visit.type.has([.user,.remote]) {
            menuTree.flo.setNameNums([("x", thumb.value.x)], .fire, visit)
            updateLeafPeers(visit)
        }
        thumb.tween = thumb.value
        refreshView()
    }
}

/// tap control
public class LeafTapVm: LeafVm {

    /// user touches tap
    override public func touchLeaf(_ touchState: TouchState, _ visit: Visitor) {
        if let bounds = runways.bounds(),
           let thumb = runways.thumb(),
           bounds.contains(touchState.pointNow) {
            switch touchState.phase {
            case .began: thumb.value.x = 1
            case .ended: thumb.value.x = 0
            default: return
            }
            syncVal(Visitor(0,.user))
        }
    }

    override public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb() else { return  }

        if visit.type.has([.model,.bind,.midi]) {
            menuTree.flo.setNameNums([("x", thumb.value.x)], .sneak, visit)

        } else if visit.type.has([.user,.remote]) {
            menuTree.flo.setNameNums([("x", thumb.value.x)], .fire, visit)
            updateLeafPeers(visit)
        }
        thumb.tween = thumb.value
        refreshView()
    }
}

