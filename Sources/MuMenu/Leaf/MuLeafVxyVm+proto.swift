//  Created by warren on 9/10/22.

import SwiftUI
import MuPar

extension MuLeafVxyVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        let scalars = node.modelFlo.scalars()
        if scalars.count >= 2 {
            thumbNext[0] = scale(scalars[0].val, from: scalars[0].range(), to: 0...1)
            thumbNext[1] = scale(scalars[1].val, from: scalars[1].range(), to: 0...1)
        } else {
            print("⁉️ refreshValue: scalar not found")
            thumbNext[0] = 0
        }
        refreshPeers(visit)
    }
    public func refreshPeers(_ visit: Visitor) {
        visit.nowHere(self.hash)
        if visit.from.user {
            syncNext(Visitor(self.hash))
            updateLeafPeers(visit)
        }
    }

    /// update from model - not touch
    public func updateLeaf(_ any: Any, _ visit: Visitor) {
        visit.nowHere(hash)
        editing = true
        if let v = any as? [Double], v.count == 2 {
            thumbNext = [v[0],v[1]]
        } else {
            print("⁉️ unknown update type")
        }
        editing = false
        syncNext(visit)
        updateLeafPeers(visit)
    }

    public func leafTitle() -> String {
        String(format: "x:%.2f  y:%.2f",
               expand(named: "x", thumbNext[0]),
               expand(named: "y", thumbNext[1]))
    }

    public func treeTitle() -> String {
        node.title
    }


    public func thumbOffset() -> CGSize {
        return CGSize(width:     thumbNext[0]  * panelVm.runway,
                      height: (1-thumbNext[1]) * panelVm.runway)
    }
    public func thumbCenter() -> CGPoint {
        CGPoint(x:     thumbNext[0]  * panelVm.runway + panelVm.thumbRadius,
                y:  (1-thumbNext[1]) * panelVm.runway + panelVm.thumbRadius)
    }

    /// called via user touch or via model update
    public func syncNext(_ visit: Visitor) {
        let x = expand(named: "x", thumbNext[0])
        let y = expand(named: "y", thumbNext[1])
        menuSync?.setMenuExprs(node.modelFlo.exprs, [("x", x),("y", y)], visit)
        refreshView()
    }

}
