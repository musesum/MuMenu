//  created by musesum on 9/10/22.

import SwiftUI
import MuFlo

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
    public func updateFromThumbs(_ thumbs: Thumbs,
                                 _ visit: Visitor) {
        editing = true
        thumbVal[0] = thumbs[0][0]      // scalar.x.val
        thumbTwe[0] = (node.modelFlo.hasPlugins
                       ? thumbs[0][1]   // scalar.x.twe
                       : thumbVal[0])   // scalar.x.val
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

            thumbVal[0] = v.normalized(.val)
            thumbTwe[0] = (flo.hasPlugins
                           ? v.normalized(.twe)
                           : thumbVal[0])
        } else {
            print("⁉️ unknown update type")
        }
        editing = false
        syncVal(visit)
    }

    public func leafTitle() -> String {
        range.upperBound > 1
        ? String(format: "%.f", scale(thumbVal[0], from: 0...1, to: range))
        : String(format: "%.1f", thumbVal[0])
    }
    public func treeTitle() -> String {
        node.title
    }
    public func thumbValOffset() -> CGSize {
        panelVm.isVertical
        ? CGSize(width: 1, height: (1-thumbVal[0]) * panelVm.runway)
        : CGSize(width: thumbVal[0] * panelVm.runway, height: 1)
    }
    public func thumbTweOffset() -> CGSize {
        panelVm.isVertical
        ? CGSize(width: 1, height: (1-thumbTwe[0]) * panelVm.runway)
        : CGSize(width: thumbTwe[0] * panelVm.runway, height: 1)
    }
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(hash) else { return }

        if  !visit.from.tween,
            !visit.from.bind {

            let expanded = scale(Double(nearestTick), from: 0...1, to: range)
            node.modelFlo.setAny(expanded, .activate, visit)
            updateLeafPeers(visit)
        }
        if !node.modelFlo.hasPlugins {
            thumbTwe[0] = thumbVal[0]
        }
        refreshView()
    }
}
