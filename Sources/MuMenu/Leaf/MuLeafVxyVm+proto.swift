//  Created by warren on 9/10/22.

import SwiftUI
import Par

extension MuLeafVxyVm: MuLeafProtocol {

    public func refreshValue() {
        if let nameRanges = menuSync?.getRanges(named: ["x","y"]) {
            for (name,range) in nameRanges {
                ranges[name] = range
            }
        }
        let xx = normalizeNamed("x",ranges["x"])
        let yy = normalizeNamed("y",ranges["y"])
        thumb = [xx,yy]
    }

    /// update from model - not touch
    public func updateLeaf(_ any: Any, _ visitor: Visitor) {
        if visitor.newVisit(hash) {
            editing = true
            if let v = any as? [Double], v.count == 2 {
                    thumb = [v[0],v[1]]
            } else {
                print("⁉️ unknown update type")
            }
            editing = false
            updateSync(visitor)
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
               expand(named: "x", thumb[0]),
               expand(named: "y", thumb[1]))
    }


    public func thumbOffset() -> CGSize {
        CGSize(width:     thumb[0]  * panelVm.runway,
               height: (1-thumb[1]) * panelVm.runway)
    }

}
