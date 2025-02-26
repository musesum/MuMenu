//  created by musesum on 9/10/22.

import SwiftUI
import MuFlo

extension LeafXyzVm: LeafProtocol {

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
        thumb.tween = (menuTree.model˚.hasPlugins
                       ? thumb.tween
                       : thumb.value)
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
           let y = exprs.nameAny["y"] as? Scalar,
           let z = exprs.nameAny["z"] as? Scalar {

            thumb.value = [x.normalized(.value),
                           y.normalized(.value),
                           z.normalized(.value)]
            thumb.tween = (flo.hasPlugins
                           ?  [x.normalized(.tween),
                               y.normalized(.tween),
                               z.normalized(.tween)]
                           : thumb.value)
        } else {
            PrintLog("⁉️ unknown update type")
        }
        editing = false
        syncVal(visit)
    }

    public func leafTitle() -> String {
      return ""
    }

    public func treeTitle() -> String {
        let x = expand(named: "x", thumb.value.x).digits(-2)
        let y = expand(named: "y", thumb.value.y).digits(-2)
        let z = expand(named: "z", thumb.value.z).digits(-2)
        return ("x:\(x) y:\(y) z:\(z)")
    }

    public func thumbValueOffset(_ runway: Runway) -> CGSize {
        let length = panelVm.runLength(runway)
        let runX =      thumb.value.x  * length
        let runY = (1 - thumb.value.y) * length
        let runZ = (1 - thumb.value.z) * length

        var size: CGSize
        switch runway {
        case .runX : size = CGSize(width: runX, height: 1)
        case .runY : size = CGSize(width: 1, height: runY)
        case .runZ : size = CGSize(width: 1, height: runZ)
        default    : size = CGSize(width: runX, height: runY)
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

        let center = SIMD2<Double>(
            x: (  thumb.value.x) * bounds.minX + panelVm.thumbRadius,
            y: (1-thumb.value.y) * bounds.minY + panelVm.thumbRadius)
        DebugLog { P("thumb \(self.thumb.value.digits(-2)) center \(center.digits(-2))") }
        return center
    }

    /// called via user touch or via model update
    public func syncVal_OLD(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }

        if  !visit.type.tween,
            !visit.type.bind {

            let x = expand(named: "x", thumb.value.x)
            let y = expand(named: "y", thumb.value.y)
            let z = expand(named: "z", thumb.value.z)
            menuTree.model˚.setAnyExprs([("x", x),("y", y),("z", z)], .fire, visit)
            updateLeafPeers(visit)
        }
        if !menuTree.model˚.hasPlugins {
            thumb.tween = thumb.value
        }
        refreshView()
    }

    /// called via user touch or via model update
    public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }

        if  !visit.type.tween,
            !visit.type.bind {

            updateThumbXY()
            updateLeafPeers(visit)
        }
        refreshView()

        func updateThumbXY() {
            guard let thumbXY = runwayThumb[.runXY] else { return }
            switch runway {
            case .runX, .runU, .runW, .runS:
                thumbXY.value.x = thumb.value.x
            case .runY, .runV, .runZ, .runT:
                thumbXY.value.y = thumb.value.y
            default: break
            }

            let x = expand(named: "x", thumbXY.value.x)
            let y = expand(named: "y", thumbXY.value.y)
            let z = expand(named: "z", thumbXY.value.z)
            menuTree.model˚.setAnyExprs([("x", x),("y", y),("z", z)], .fire, visit)

            if !menuTree.model˚.hasPlugins {
                thumbXY.tween = thumbXY.value
            }
        }
    }
}
