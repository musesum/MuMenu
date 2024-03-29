//  created by musesum on 9/10/22.

import SwiftUI
import MuFlo
import MuExtensions
extension LeafSegVm: LeafProtocol {

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
        thumbVal = thumbs.val  
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
        range.upperBound > 1
        ? String(format: "%.f", scale(thumbVal.x, from: 0...1, to: range))
        : String(format: "%.1f", thumbVal.x)
    }
    public func treeTitle() -> String {
        node.title
    }
    public func thumbValOffset(_ runwayType: RunwayType) -> CGSize {
        let runway = panelVm.runway(runwayType)
        return (panelVm.isVertical
                ? CGSize(width: 1, height: (1-thumbVal.x) * runway)
                : CGSize(width: thumbVal.x * runway, height: 1))
    }
    public func thumbTweOffset(_ runwayType: RunwayType) -> CGSize {
        let runway = panelVm.runway(runwayType)
        return (panelVm.isVertical
                ? CGSize(width: 1, height: (1-thumbTwe.x) * runway)
                : CGSize(width: thumbTwe.x * runway, height: 1))
    }
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(hash) else { return }

        if  !visit.from.tween,
            !visit.from.bind {

            let expanded = scale(thumbVal.x.quantize(count), from: 0...1, to: range)
            node.modelFlo.setAny(expanded, .activate, visit)
            updateLeafPeers(visit)
        }
        if !node.modelFlo.hasPlugins {
            thumbTwe.x = thumbVal.x
        }
        refreshView()
    }
}
