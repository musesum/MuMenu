//  created by musesum on 9/10/22.

import SwiftUI
import MuFlo

extension LeafXyVm: LeafProtocol {

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
    /// update from model - not touch
    public func updateFromModel(_ flo: Flo,
                                _ visit: Visitor) {

        guard !visit.wasHere(hash) else { return }

        editing = true
        if let exprs = flo.exprs,
           let x = exprs.nameAny["x"] as? FloValScalar,
           let y = exprs.nameAny["y"] as? FloValScalar {

            thumbVal = SIMD3<Double>(x: x.normalized(.val),
                                     y: y.normalized(.val),
                                     z: 0)

            thumbTwe = (flo.hasPlugins
                        ? SIMD3<Double>(x: x.normalized(.twe),
                                        y: y.normalized(.twe),
                                        z: 0)
                        : thumbVal)
        } else {
            print("⁉️ unknown update type")
        }
        editing = false
        syncVal(visit)
    }

    public func leafTitle() -> String {

        String(format: "x:%.2f  y:%.2f",
               expand(named: "x", thumbVal.x),
               expand(named: "y", thumbVal.y))

    }

    public func treeTitle() -> String {
        node.title
    }

    public func thumbValOffset(_ runwayType: RunwayType) -> CGSize {
        let runway = panelVm.runway(runwayType)
        return CGSize(width:  CGFloat(  thumbVal.x) * runway,
                      height: CGFloat(1-thumbVal.y) * runway)
    }
    public func thumbTweOffset(_ runwayType: RunwayType) -> CGSize {
        let runway = panelVm.runway(runwayType)
        return CGSize(width:  CGFloat(  thumbTwe.x) * runway,
                      height: CGFloat(1-thumbTwe.y) * runway)

    }

    public func thumbCenter(_ runwayType: RunwayType) -> SIMD2<Double> {
        let runway = panelVm.runway(runwayType)
        let radius = panelVm.thumbDiameter(runwayType) / 2
        return SIMD2<Double>(x: (  thumbVal.x) * runway + radius,
                             y: (1-thumbVal.y) * runway + radius)
    }

    /// called via user touch or via model update
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(hash) else { return }

        if  !visit.from.tween,
            !visit.from.bind {

            let x = expand(named: "x", thumbVal.x)
            let y = expand(named: "y", thumbVal.y)
            node.modelFlo.setAny([("x", x),("y", y)], .activate, visit)
            updateLeafPeers(visit)
        }
        if !node.modelFlo.hasPlugins {
            thumbTwe = thumbVal
        }
        refreshView()
    }

}
