//  Created by warren on 9/10/22.


import Foundation
import MuPar

extension MuLeafValVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {

        thumbNext[0] = normalizeNamed(nodeType.name)
        range = menuSync?.getMenuRange(named: nodeType.name) ?? 0...1

        if !visit.from.tween {
            
            visit.nowHere(self.hash)
            animateThumb()
            updateLeafPeers(visit)
        } else {
            thumbNow = thumbNext
        }
    }

    /// update from model - not touch
    public func updateLeaf(_ any: Any,_ visit: Visitor) {

        if !visit.from.tween,
            visit.newVisit(hash) {
            
            editing = true
            switch any {
                case let v as Double:   thumbNext[0] = v
                case let v as [Double]: thumbNext[0] = v[0]
                default: break
            }
            editing = false
            animateThumb() //???
            updateLeafPeers(visit)
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
    public func syncNow(_ visit: Visitor) {
        let expanded = scale(thumbNow[0], from: 0...1, to: range)
        menuSync?.setMenuAny(named: nodeType.name, expanded, visit)
        refreshView()
    }
    public func syncNext(_ visit: Visitor) {
        let expanded = scale(thumbNext[0], from: 0...1, to: range)
        menuSync?.setMenuAny(named: nodeType.name, expanded, visit)
        thumbNow = thumbNext
        refreshView()
    }
}
