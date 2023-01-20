//  Created by warren on 9/10/22.


import Foundation
import Par

extension MuLeafTogVm: MuLeafProtocol {

    public func refreshValue(tapped: Bool) {
        thumbNext[0] = menuSync?.getAny(named: nodeType.name) as? Double ?? 0
        let visitor = Visitor(hash)
        if tapped {
            updateLeafPeers(visitor)
            syncNext(visitor)
        }

    }
    
    public func updateLeaf(_ any: Any,_ visitor: Visitor) {
        if visitor.newVisit(hash) {
            editing = true
            switch any {
                case let v as Double:   thumbNext[0] = (v    < 1.0 ? 0 : 1)
                case let v as [Double]: thumbNext[0] = (v[0] < 1.0 ? 0 : 1)
                default: break
            }
            editing = false
            thumbNow = thumbNext
            syncNext(visitor)
            updateLeafPeers(visitor)
        }
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
    public func syncNow(_ visitor: Visitor) {
        print("syncNow animation not used for discreet values")
    }
    public func syncNext(_ visitor: Visitor) {
        menuSync?.setAny(named: nodeType.name, thumbNext[0], visitor)
        thumbNow = thumbNext
        refreshView()
    }
    
}
