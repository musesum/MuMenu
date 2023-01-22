//  Created by warren on 9/10/22.

import SwiftUI
import Par

extension MuLeafSegVm: MuLeafProtocol {

    public func refreshValue(_ visitor: Visitor) {
        if let menuSync {
            range = menuSync.getRange(named: nodeType.name)
            if let val = menuSync.getAny(named: nodeType.name) as? Double {
                thumbNext[0] = scale(val, from: range, to: 0...1)
            } else {
                print("⁉️ refreshValue is not Double")
                thumbNext[0] = 0
            }
            visitor.nowHere(self.hash)
            if visitor.from.user {
                animateThumb()
                updateLeafPeers(visitor)
            }
        }
    }
    
    public func updateLeaf(_ any: Any, _ visitor: Visitor) {
        if visitor.newVisit(hash) {
            editing = true
            switch any {
                case let v as Double:   thumbNext[0] = v
                case let v as [Double]: thumbNext[0] = v[0]
                default: break
            }
            editing = false
            thumbNow = thumbNext
            syncNext(visitor)
            updateLeafPeers(visitor)
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
    public func syncNow(_ visitor: Visitor) {
        print("syncNow animation not used for discreet values")
    }
    public func syncNext(_ visitor: Visitor) {

        menuSync?.setAny(named: nodeType.name, expanded, visitor)
        thumbNow = thumbNext
        refreshView()
    }
}
