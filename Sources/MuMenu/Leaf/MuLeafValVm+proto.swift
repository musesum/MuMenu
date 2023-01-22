//  Created by warren on 9/10/22.


import Foundation
import Par

extension MuLeafValVm: MuLeafProtocol {

    public func refreshValue(_ visitor: Visitor) {

        thumbNext[0] = normalizeNamed(nodeType.name)
        range = menuSync?.getRange(named: nodeType.name) ?? 0...1

        if visitor.from.user {
            visitor.nowHere(self.hash)
            animateThumb()
            updateLeafPeers(visitor)
        } else {
            thumbNow = thumbNext
        }
    }

    /// update from model - not touch
    public func updateLeaf(_ any: Any,_ visitor: Visitor) {
        if visitor.newVisit(hash) {
            editing = true
            switch any {
                case let v as Double:   thumbNext[0] = v
                case let v as [Double]: thumbNext[0] = v[0]
                default: break
            }
            editing = false
            animateThumb() //???
            updateLeafPeers(visitor)
        }
    }

    public func leafTitle() -> String {
        String(format: "%.2f", expanded)
    }
    public func treeTitle() -> String {
        String(format: "%.2f", expanded)
    }
    public func thumbOffset() -> CGSize {
        panelVm.isVertical
        ? CGSize(width: 1, height: (1-thumbNext[0]) * panelVm.runway)
        : CGSize(width: thumbNext[0] * panelVm.runway, height: 1)
    }
    public func syncNow(_ visitor: Visitor) {
        let expanded = scale(thumbNow[0], from: 0...1, to: range)
        menuSync?.setAny(named: nodeType.name, expanded, visitor)
        refreshView()
    }
    public func syncNext(_ visitor: Visitor) {
        let expanded = scale(thumbNext[0], from: 0...1, to: range)
        menuSync?.setAny(named: nodeType.name, expanded, visitor)
        thumbNow = thumbNext
        refreshView()
    }
}
