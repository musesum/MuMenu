//  Created by warren on 9/10/22.

import SwiftUI
import MuPar

extension MuLeafVxyVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        let scalars = node.modelFlo.scalars()
        if scalars.count >= 2 {
            thumbVal[0] = scale(scalars[0].val, from: scalars[0].range(), to: 0...1)
            thumbVal[1] = scale(scalars[1].val, from: scalars[1].range(), to: 0...1)
        } else {
            print("⁉️ refreshValue: scalar not found")
            thumbVal[0] = 0
        }
        refreshPeersDifferent(visit)
    }
    public func refreshPeers(_ visit: Visitor) {
        visit.nowHere(self.hash)
        if visit.from.user {
            syncVal(Visitor(self.hash))
            updateLeafPeers(visit)
        }
    }
    //... different
    public func refreshPeersDifferent(_ visit: Visitor) {
        if !visit.from.tween//,
           //visit.from.user // good for remote, bad for xy
        {
            visit.nowHere(self.hash)
            syncVal(Visitor(self.hash))
            updateLeafPeers(visit)
        }
    }
    /// update from model - not touch
    public func updateFromModel(_ any: Any,
                                _ visit: Visitor) {

        visit.nowHere(hash)
        editing = true
        if let v = any as? [Double], v.count == 2 {
            thumbVal = [v[0],v[1]]
        } else {
            print("⁉️ unknown update type")
        }
        editing = false
        syncVal(visit)
        updateLeafPeers(visit)
    }

    public func leafTitle() -> String {
        String(format: "x:%.2f  y:%.2f",
               expand(named: "x", thumbVal[0]),
               expand(named: "y", thumbVal[1]))
    }

    public func treeTitle() -> String {
        node.title
    }


    public func thumbOffset() -> CGSize {
        return CGSize(width:     thumbVal[0]  * panelVm.runway,
                      height: (1-thumbVal[1]) * panelVm.runway)
    }
    public func thumbCenter() -> CGPoint {
        CGPoint(x:     thumbVal[0]  * panelVm.runway + panelVm.thumbRadius,
                y:  (1-thumbVal[1]) * panelVm.runway + panelVm.thumbRadius)
    }

    /// called via user touch or via model update
    public func syncVal(_ visit: Visitor) {
        if visit.newVisit(hash) {
            let x = expand(named: "x", thumbVal[0])
            let y = expand(named: "y", thumbVal[1])
            node.modelFlo.setAny([("x", x),("y", y)], .activate, visit)
            refreshView()
        }

    }

}
