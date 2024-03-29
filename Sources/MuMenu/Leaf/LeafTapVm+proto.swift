//  created by musesum on 9/10/22.

import SwiftUI
import MuFlo

extension LeafTapVm: LeafProtocol {

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
        thumbVal = thumbs.val // scalar.x.val
        thumbTwe = (node.modelFlo.hasPlugins ? thumbs.twe : thumbVal) 
        editing = false
        syncVal(visit)
    }
    public func updateFromModel(_ flo: Flo,
                                _ visit: Visitor) {
        guard !visit.wasHere(hash) else { return }

        editing = true

        if let exprs = flo.exprs,
           let v = (exprs.nameAny["_0"] as? FloValScalar ??
                    exprs.nameAny.values.first as? FloValScalar) {

            thumbVal.x = v.normalized(.val)
            thumbTwe.x = (flo.hasPlugins
                           ? v.normalized(.twe)
                           : thumbVal.x)
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
        let runway = panelVm.runway(runwayType)
        return CGSize(width: 0, height:  runway)
    }
    public func thumbTweOffset(_ runwayType: RunwayType) -> CGSize {
        let runway = panelVm.runway(runwayType)
        return CGSize(width: 0, height: runway)
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
