//  Created by warren on 9/10/22.

import SwiftUI
import MuPar

extension MuLeafTapVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
       refreshPeers(visit)
    }
    public func refreshPeers(_ visit: Visitor) {
        visit.nowHere(self.hash)
        if visit.from.user {
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
        node.title
    }
    public func treeTitle() -> String {
        editing
        ? thumbVal[0] == 1.0 ? "on" : "off"
        : node.title
    }
    public func thumbOffset() -> CGSize {
        CGSize(width: 0, height:  panelVm.runway)
    }

    public func syncNext(_ visit: Visitor) {
        menuSync?.setMenuExprs(node.modelFlo.exprs, thumbVal[0], visit)
        refreshView()
    }
}
