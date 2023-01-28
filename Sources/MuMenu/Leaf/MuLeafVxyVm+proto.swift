//  Created by warren on 9/10/22.

import SwiftUI
import MuPar

extension MuLeafVxyVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        print("r", terminator: "⃝")

        if let nameRanges = menuSync?.getMenuRanges(named: ["x","y"]) {
            for (name,range) in nameRanges {
                ranges[name] = range
            }
        }
        let xx = normalizeNamed("x",ranges["x"])
        let yy = normalizeNamed("y",ranges["y"])
        
        thumbNext = [xx,yy]

        visit.nowHere(self.hash)
        if visit.from.user {
            animateThumb()
            updateLeafPeers(visit)
        } else {
            thumbNow = thumbNext
        }
    }

    /// update from model - not touch
    public func updateLeaf(_ any: Any, _ visit: Visitor) {
        if !visit.from.animate,
           visit.newVisit(hash) {
            print("u", terminator: "⃝")
            editing = true
            if let v = any as? [Double], v.count == 2 {
                thumbNext = [v[0],v[1]]
            } else {
                print("⁉️ unknown update type")
            }
            editing = false
            animateThumb()
            updateLeafPeers(visit)
        }
    }

    public func leafTitle() -> String {
        if editing {
            return treeTitle()
        } else {
            return node.title
        }
    }

    public func treeTitle() -> String {
        String(format: "x:%.2f  y:%.2f",
               expand(named: "x", thumbNext[0]),
               expand(named: "y", thumbNext[1]))
    }


    public func thumbOffset() -> CGSize {
        CGSize(width:     thumbNext[0]  * panelVm.runway,
               height: (1-thumbNext[1]) * panelVm.runway)
    }
    /// called via user touch or via model update
    public func syncNow(_ visit: Visitor) {
        print("n", terminator: "⃝")
        let x = expand(named: "x", thumbNow[0])
        let y = expand(named: "y", thumbNow[1])
        menuSync?.setMenuAnys([("x", x),("y", y)], visit)
        refreshView()
    }

    /// called via user touch or via model update
    public func syncNext(_ visit: Visitor) {
        print("x", terminator: "⃝")
        let x = expand(named: "x", thumbNext[0])
        let y = expand(named: "y", thumbNext[1])
        menuSync?.setMenuAnys([("x", x),("y", y)], visit)
        thumbNow = thumbNext
        refreshView()
    }

}
