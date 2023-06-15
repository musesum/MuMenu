//  Created by warren on 9/10/22.

import SwiftUI
import MuFlo
import MuPar

extension MuLeafSegVm: MuLeafProtocol {


    public func refreshValue(_ visit: Visitor) {
        if let scalar = node.modelFlo.scalars().first
        {
            range = scalar.range()
            let val = scalar.val //??? now?
            thumbVal[0] = scale(val, from: range, to: 0...1)
        } else {
            print("⁉️ refreshValue: scalar not found")
            thumbVal[0] = 0
        }
        refreshPeersDifferent(visit)
    }
    public func refreshPeers(_ visit: Visitor) {
        visit.nowHere(self.hash)
        if visit.from.user {
            syncNext(Visitor(self.hash))
            updateLeafPeers(visit)
        }
    }
    //... different
    public func refreshPeersDifferent(_ visit: Visitor) {
        if !visit.from.tween {
            visit.nowHere(self.hash)
            syncNext(Visitor(self.hash))
            updateLeafPeers(visit)
        }
    }
    
    public func updateLeaf(_ any: Any, _ visit: Visitor) {
        visit.nowHere(hash)
        editing = true
        switch any {
            case let v as Double:   thumbVal[0] = v
            case let v as [Double]: thumbVal[0] = v[0]
            default: break
        }
        editing = false
        syncNext(visit)
        updateLeafPeers(visit)
    }

    public func leafTitle() -> String {
        range.upperBound > 1
        ? String(format: "%.f", scale(thumbVal[0], from: 0...1, to: range))
        : String(format: "%.1f", thumbVal[0])
    }
    public func treeTitle() -> String {
        node.title
    }
    public func thumbOffset() -> CGSize {
        panelVm.isVertical
        ? CGSize(width: 1, height: (1-thumbVal[0]) * panelVm.runway)
        : CGSize(width: thumbVal[0] * panelVm.runway, height: 1)
    }
    public func syncNext(_ visit: Visitor) {
        if visit.newVisit(hash) {
            let expanded = scale(Double(nearestTick), from: 0...1, to: range)
            node.modelFlo.setAny(expanded, .activate, visit)
            refreshView()
        }
    }
}
