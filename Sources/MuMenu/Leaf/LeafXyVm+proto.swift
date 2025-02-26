//  created by musesum on 9/10/22.

import SwiftUI
import MuFlo

extension LeafXyVm: LeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        updateFromModel(menuTree.model˚, visit)
        refreshPeers(visit)
    }

    public func refreshPeers(_ visit: Visitor) {
        guard !visit.type.tween else { return }
        visit.nowHere(leafHash)
        syncVal(Visitor(leafHash))
    }

    /// always from remote
    public func remoteValTween(_ valTween: ValTween,
                                 _ visit: Visitor) {
        editing = true
        thumb.value = valTween.value
        thumb.tween = (menuTree.model˚.hasPlugins ? valTween.tween : thumb.value)
        editing = false
        syncVal(visit)
    }
    /// update from model - not touch
    public func updateFromModel(_ flo: Flo,
                                _ visit: Visitor) {

        guard !visit.wasHere(leafHash) else { return }

        editing = true
        if let exprs = flo.exprs,
           let x = exprs.nameAny["x"] as? Scalar,
           let y = exprs.nameAny["y"] as? Scalar {

            thumb.value = SIMD3<Double>(x: x.normalized(.value),
                                       y: y.normalized(.value),
                                       z: 0)

            thumb.tween = (flo.hasPlugins
                          ? SIMD3<Double>(x: x.normalized(.tween),
                                          y: y.normalized(.tween),
                                          z: 0)
                          : thumb.value)
        } else {
            PrintLog("⁉️ unknown update type")
        }
        editing = false
        syncVal(visit)
    }

    public func leafTitle() -> String {
        ""
    }

    public func treeTitle() -> String {
        let x = expand(named: "x", thumb.value.x).digits(-2)
        let y = expand(named: "y", thumb.value.y).digits(-2)
        return ("x:\(x) y:\(y)")
    }

    public func thumbValueOffset(_ runway: Runway) -> CGSize {
        let run = panelVm.runLength(runway)
        let runX =      thumb.value.x  * run
        let runY = (1 - thumb.value.y) * run
        let runZ = (1 - thumb.value.z) * run

        var size: CGSize
        switch runway {
        case .runX : size = CGSize(width: runX, height: 1)
        case .runY : size = CGSize(width: 1, height: runY)
        case .runZ : size = CGSize(width: 1, height: runZ)
        default : size = CGSize(width: runX, height: runY)
        }
        return size
    }

    public func thumbTweenOffset(_ runway: Runway) -> CGSize {
        let length = panelVm.runLength(runway)
        let runX =      thumb.tween.x  * length
        let runY = (1 - thumb.tween.y) * length
        let runZ = (1 - thumb.tween.z) * length

        switch runway {
        case .runX : return CGSize(width: runX, height: 1)
        case .runY : return CGSize(width: 1, height: runY)
        case .runZ : return CGSize(width: 1, height: runZ)
        default : return CGSize(width: runX, height: runY)
        }
    }
    public func thumbCenter(_ runway: Runway) -> SIMD2<Double> {
        let length = panelVm.runLength(runway)
        return SIMD2<Double>(
            x: (  thumb.value.x) * length + panelVm.thumbRadius,
            y: (1-thumb.value.y) * length + panelVm.thumbRadius)
    }

    /// called via user touch or via model update
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }

        if  !visit.type.tween,
            !visit.type.bind {

            let x = expand(named: "x", thumb.value.x)
            let y = expand(named: "y", thumb.value.y)
            menuTree.model˚.setAnyExprs([("x", x),("y", y)], .fire, visit)
            updateLeafPeers(visit)
        }
        if !menuTree.model˚.hasPlugins {
            thumb.tween = thumb.value
        }
        refreshView()
    }

}
