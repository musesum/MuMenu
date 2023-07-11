//  Created by warren on 9/10/22.

import Foundation
import MuFlo
import MuVisit

extension MuLeafTogVm: MuLeafProtocol {

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
        thumbVal[0] = thumbs[0][0] < 1.0 ? 0 : 1     // scalar.x.val
        thumbTwe[0] = (node.modelFlo.hasPlugins
                       ? thumbs[0][1] < 1.0 ? 0 : 1  // scalar.x.twe
                       : thumbVal[0]) // scalar.x.val
        editing = false
        syncVal(visit)
    }
    public func updateFromModel(_ flo: Flo,
                                _ visit: Visitor) {

        guard !visit.wasHere(hash) else { return }

        editing = true

        if let exprs = flo.exprs,
           let scalar = (exprs.nameAny["_0"] as? FloValScalar ??
                    exprs.nameAny.values.first as? FloValScalar) {

            thumbVal[0] = scalar.val < 1.0 ? 0 : 1      // scalar.val
            thumbTwe[0] = (flo.hasPlugins
                           ? scalar.twe < 1.0 ? 0 : 1   // scalar.twe
                           : thumbVal[0])               // scalar.val
        } else {
            print("⁉️ unknown update type")
        }
        editing = false
        syncVal(visit)
    }


    public func leafTitle() -> String {
        node.title
    }
    public func treeTitle() -> String {
        editing
        ? thumbVal[0] == 1.0 ? "on" : "off"
        : node.title
    }
    
    public func thumbValOffset() -> CGSize {
        CGSize(width: 1, height: 1)
    }
    public func thumbTweOffset() -> CGSize {
        CGSize(width: 1, height: 1)
    }
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(hash) else { return }

        if  !visit.from.tween,
            !visit.from.bind {

            node.modelFlo.setAny(thumbVal[0], .activate, visit)
            updateLeafPeers(visit)
        }
        refreshView()
    }
    
}
