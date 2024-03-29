//  created by musesum on 9/10/22.

import SwiftUI
import MuFlo

extension LeafXyzVm: LeafProtocol {

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
        thumbTwe = (node.modelFlo.hasPlugins ? thumbTwe : thumbVal)
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
           let y = exprs.nameAny["y"] as? FloValScalar,
           let z = exprs.nameAny["z"] as? FloValScalar {
            thumbVal = [x.normalized(.val), 
                        y.normalized(.val),
                        z.normalized(.val)]
            thumbTwe = (flo.hasPlugins
                        ?  [x.normalized(.twe),
                            y.normalized(.twe),
                            z.normalized(.twe)]
                        : thumbVal)
        } else {
            print("⁉️ unknown update type")
        }
        editing = false
        syncVal(visit)
    }

    public func leafTitle() -> String {
        String(format: "x %.2f  y %.2f  z %.2f",
               expand(named: "x", thumbVal.x),
               expand(named: "y", thumbVal.y),
               expand(named: "z", thumbVal.z))
    }

    public func treeTitle() -> String {
        node.title
    }

    public func thumbValOffset(_ runwayType: RunwayType) -> CGSize {
        let run = panelVm.runway(runwayType)
        let runX =      thumbVal.x  * run
        let runY = (1 - thumbVal.y) * run
        let runZ = (1 - thumbVal.z) * run

        var size: CGSize
        switch runwayType {
        case .x : size = CGSize(width: runX, height: 1)
        case .y : size = CGSize(width: 1, height: runY)
        case .z : size = CGSize(width: 1, height: runZ)
        default : size = CGSize(width: runX, height: runY)
        }
        return size
    }

    public func thumbTweOffset(_ runwayType: RunwayType) -> CGSize {
        let runway = panelVm.runway(runwayType)
        let runX =      thumbTwe.x  * runway
        let runY = (1 - thumbTwe.y) * runway
        let runZ = (1 - thumbVal.z) * runway

        switch runwayType {
        case .x : return CGSize(width: runX, height: 1)
        case .y : return CGSize(width: 1, height: runY)
        case .z : return CGSize(width: 1, height: runZ)
        default : return CGSize(width: runX, height: runY)
        }
    }

    public func thumbCenter(_ runwayType: RunwayType) -> SIMD2<Double> {
        let runway = panelVm.runway(runwayType)
        return SIMD2<Double>(
            x: (  thumbVal.x) * runway + panelVm.thumbRadius,
            y: (1-thumbVal.y) * runway + panelVm.thumbRadius)
    }


    /// called via user touch or via model update
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(hash) else { return }

        if  !visit.from.tween,
            !visit.from.bind {

            let x = expand(named: "x", thumbVal.x)
            let y = expand(named: "y", thumbVal.y)
            let z = expand(named: "z", thumbVal.z)
            node.modelFlo.setAny([("x", x),("y", y),("z", z)], .activate, visit)
            updateLeafPeers(visit)
        }
        if !node.modelFlo.hasPlugins {
            thumbTwe = thumbVal

        }
        refreshView()
    }

}
