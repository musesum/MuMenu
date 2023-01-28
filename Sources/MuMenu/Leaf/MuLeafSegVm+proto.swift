//  Created by warren on 9/10/22.

import SwiftUI
import MuPar

extension MuLeafSegVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        if let menuSync {
            range = menuSync.getMenuRange(named: nodeType.name)
            if let val = menuSync.getMenuAny(named: nodeType.name) as? Double {
                thumbNext[0] = scale(val, from: range, to: 0...1)
            } else {
                print("⁉️ refreshValue is not Double")
                thumbNext[0] = 0
            }
            visit.nowHere(self.hash)
            if visit.from.user {
                animateThumb()
                updateLeafPeers(visit)
            }
        }
    }
    
    public func updateLeaf(_ any: Any, _ visit: Visitor) {
        if !visit.from.animate,
            visit.newVisit(hash) {
            editing = true
            switch any {
                case let v as Double:   thumbNext[0] = v
                case let v as [Double]: thumbNext[0] = v[0]
                default: break
            }
            editing = false
            thumbNow = thumbNext
            syncNext(visit)
            updateLeafPeers(visit)
        }
    }

    public func leafTitle() -> String {
        treeTitle()
    }
    public func treeTitle() -> String {
        range.upperBound > 1
        ? String(format: "%.f", scale(thumbNext[0], from: 0...1, to: range))
        : String(format: "%.1f", thumbNext[0])
    }
    public func thumbOffset() -> CGSize {
        panelVm.isVertical
        ? CGSize(width: 1, height: (1-thumbNext[0]) * panelVm.runway)
        : CGSize(width: thumbNext[0] * panelVm.runway, height: 1)
    }
    public func syncNow(_ visit: Visitor) {
       syncNext(visit)
    }
    public func syncNext(_ visit: Visitor) {

        menuSync?.setMenuAny(named: nodeType.name, expanded, visit)
        thumbNow = thumbNext
        refreshView()
    }
}
