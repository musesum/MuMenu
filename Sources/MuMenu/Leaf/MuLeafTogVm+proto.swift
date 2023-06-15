//  Created by warren on 9/10/22.


import Foundation
import MuFlo
import MuPar

extension MuLeafTogVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        if let scalar = node.modelFlo.scalars().first {
            let val = scalar.val
            thumbVal[0] = val
        } else {
            print("⁉️ refreshValue: scalar not found")
            thumbVal[0] = 0
        }
        refreshPeers(visit)
    }
    public func refreshPeers(_ visit: Visitor) {
        visit.nowHere(self.hash)
        if visit.from.user {
            syncVal(Visitor(self.hash))
            updateLeafPeers(visit)
        }
    }
    public func updateFromModel(_ any: Any,_ visit: Visitor) {
        visit.nowHere(hash)
        editing = true
        switch any {
            case let v as Double:   thumbVal[0] = (v    < 1.0 ? 0 : 1)
            case let v as [Double]: thumbVal[0] = (v[0] < 1.0 ? 0 : 1)
            default: break
        }
        editing = false
        syncVal(visit)
        updateLeafPeers(visit)
    }

    public func leafTitle() -> String {
        node.title
    }
    public func treeTitle() -> String {
        editing
        ? thumbVal[0] == 1.0 ? "on" : "off"
        : node.title
    }
    
    public func thumbOffset() -> CGSize {
        CGSize(width: 1, height: 1)
    }
    public func syncVal(_ visit: Visitor) {
        if visit.newVisit(hash) {
            node.modelFlo.setAny(thumbVal[0], .activate, visit)
            refreshView()
        }
    }
    
}
