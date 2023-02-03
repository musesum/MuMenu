//  Created by warren on 9/10/22.


import Foundation
import MuPar

extension MuLeafTogVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {

        thumbNext[0] = menuSync?.getMenuAny(named: nodeType.name) as? Double ?? 0
        visit.nowHere(self.hash)
        if visit.from.user {
            updateLeafPeers(visit)
            syncNext(visit)
        }
    }
    
    public func updateLeaf(_ any: Any,_ visit: Visitor) {
        visit.nowHere(hash)
        editing = true
        switch any {
            case let v as Double:   thumbNext[0] = (v    < 1.0 ? 0 : 1)
            case let v as [Double]: thumbNext[0] = (v[0] < 1.0 ? 0 : 1)
            default: break
        }
        editing = false
        syncNext(visit)
        updateLeafPeers(visit)
    }

    public func leafTitle() -> String {
        node.title
    }
    public func treeTitle() -> String {
        return thumbNext[0] == 1.0 ? "on" : "off"
    }
    public func thumbOffset() -> CGSize {
        panelVm.isVertical
        ? CGSize(width: 1, height: (1-thumbNext[0]) * panelVm.runway)
        : CGSize(width: thumbNext[0] * panelVm.runway, height: 1)
    }
    public func syncNext(_ visit: Visitor) {
        menuSync?.setMenuAny(named: nodeType.name, thumbNext[0], visit)
        refreshView()
    }
    
}
