//  created by musesum on 9/10/22.

import Foundation
import MuFlo

extension LeafTogVm: LeafProtocol {

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
    public func updateFromThumbs(_ thumbs: ValTween,
                                 _ visit: Visitor) {
        editing = true
        thumbVal.x =  thumbs.val.x < 1.0 ? 0 : 1     // scalar.x.val
        thumbTwe.x = (node.modelFlo.hasPlugins
                      ? thumbs.twe.x < 1.0 ? 0 : 1
                      : thumbVal.x)
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

            thumbVal.x = scalar.val < 1.0 ? 0 : 1      // scalar.val
            thumbTwe.x = (flo.hasPlugins
                           ? scalar.twe < 1.0 ? 0 : 1   // scalar.twe
                          : thumbVal.x)               // scalar.val
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
        ? thumbVal.x == 1.0 ? "on" : "off"
        : node.title
    }
    
    public func thumbValOffset(_ runwayType: RunwayType) -> CGSize {
        CGSize(width: 1, height: 1)
    }
    public func thumbTweOffset(_ runwayType: RunwayType) -> CGSize {
        CGSize(width: 1, height: 1)
    }
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(hash) else { return }

        if  !visit.from.tween,
            !visit.from.bind {

            node.modelFlo.setAny(thumbVal.x, .activate, visit)
            updateLeafPeers(visit)
        }
        refreshView()
    }
    
}
