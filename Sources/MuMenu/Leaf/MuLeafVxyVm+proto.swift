//  Created by warren on 9/10/22.

import SwiftUI
import MuFlo

extension MuLeafVxyVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        updateFromModel(node.modelFlo, visit)
        refreshPeers(visit)
    }
    
    public func refreshPeers(_ visit: Visitor) {
        guard !visit.from.tween else { return }
        visit.nowHere(hash)
        syncVal(Visitor(hash))
    }

    /// always from remote
    public func updateFromThumbs(_ thumbs: Thumbs,
                                 _ visit: Visitor) {
        editing = true
        thumbVal[0] = thumbs[0][0]      // scalar.x.val
        thumbVal[1] = thumbs[1][0]      // scalar.y.val
        if node.modelFlo.hasPlugins {
            thumbTwe[0] = thumbs[0][1]  // scalar.x.twe
            thumbTwe[1] = thumbs[1][1]  // scalar.y.twe
        } else {
            thumbTwe[0] = thumbVal[0]   // scalar.x.val
            thumbTwe[1] = thumbVal[1]   // scalar.y.val
        }
        editing = false
        syncVal(visit)
    }
    /// update from model - not touch 
    public func updateFromModel(_ flo: Flo,
                                _ visit: Visitor) {

        guard !visit.wasHere(hash) else { return }

        editing = true
        if let exprs = flo.exprs,
           let x = exprs.nameAny["x"] as? FloValScalar,
           let y = exprs.nameAny["y"] as? FloValScalar {
            thumbVal = [x.normalized(.val), y.normalized(.val)]
            thumbTwe = (flo.hasPlugins
                        ?  [x.normalized(.twe), y.normalized(.twe)]
                        : [thumbVal[0], thumbVal[1]])
        } else {
            print("⁉️ unknown update type")
        }
        editing = false
        syncVal(visit)
    }

    public func leafTitle() -> String {
        String(format: "x:%.2f  y:%.2f",
               expand(named: "x", thumbVal[0]),
               expand(named: "y", thumbVal[1]))
    }

    public func treeTitle() -> String {
        node.title
    }

    public func thumbValOffset() -> CGSize {
        return CGSize(width:     thumbVal[0]  * panelVm.runway,
                      height: (1-thumbVal[1]) * panelVm.runway)
    }
    public func thumbTweOffset() -> CGSize {
        return CGSize(width:     thumbTwe[0]  * panelVm.runway,
                      height: (1-thumbTwe[1]) * panelVm.runway)
        
    }
    
    public func thumbCenter() -> CGPoint {
        CGPoint(x:     thumbVal[0]  * panelVm.runway + panelVm.thumbRadius,
                y:  (1-thumbVal[1]) * panelVm.runway + panelVm.thumbRadius)
    }

    /// called via user touch or via model update
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(hash) else { return }

        if  !visit.from.tween,
            !visit.from.bind {

            let x = expand(named: "x", thumbVal[0])
            let y = expand(named: "y", thumbVal[1])
            node.modelFlo.setAny([("x", x),("y", y)], .activate, visit)
            updateLeafPeers(visit)
        }
        if !node.modelFlo.hasPlugins {
            thumbTwe[0] = thumbVal[0]
            thumbTwe[1] = thumbVal[1]
        }
        refreshView()
    }

}
