//  created by musesum on 12/10/21.

import SwiftUI
import MuFlo

/// 1d slider control
public class LeafValVm: LeafVm {

    lazy var range: ClosedRange<Double> = {
        ranges.values.first ?? 0...1
    }()

    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState, _ visit: Visitor) {
        runways.touchLeaf(self,touchState) // no quantize
        syncVal(visit)
    }
    /// for one dimensional slider, the user has a choice
    /// to label x,y,z which is passed on elsewhere
    /// so take the first occurance of x,y,z
    /// and set all ranges to that value
    override public func setRanges() {
        // set ranges
        if let exprs = menuTree.flo.exprs {
            for name in ["x","y","z"] {
                if let scalar = exprs.nameAny[name] as? Scalar {
                    let range = scalar.range()
                    ranges["x"] = range
                    ranges["y"] = range
                    ranges["z"] = range
                }
            }
        } else {
            let scalars = menuTree.flo.scalars()
            for scalar in scalars {
                ranges[scalar.name] = scalar.range()
            }
        }
    }

    override public func treeTitle() -> String {
        guard let thumb = runways.thumb() else { return "" }
        let value = panelVm.isVertical ? thumb.value.y : thumb.value.x
        let tween = panelVm.isVertical ? thumb.tween.y : thumb.tween.x
        return (range.upperBound > 1
                ? (runways.touching
                   ? String(format: "%.1f", scale(value, from: 0...1, to: range))
                   : String(format: "%.1f", scale(tween, from: 0...1, to: range)))
                : (runways.touching
                   ? String(format: "%.2f", value)
                   : String(format: "%.2f", tween)))
    }

    override public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb(.runVal) else { return  }

        if visit.type.has([.tween, .midi]) {
            // ignore
        } else {
    
            let x = expand(named: "x", thumb.value.x)
            let y = expand(named: "y", thumb.value.y)
            // for val and seg, both x and y are the same value
            let v = panelVm.isVertical ? y : x

            if visit.type.has([.model, .bind]) {
                menuTree.flo.setAnyExprs([("x", v),("y", v)], .sneak, visit)
            } else if visit.type.has([.user, .remote]) {
                menuTree.flo.setAnyExprs([("x", v),("y", v)], .fire, visit)
                updateLeafPeers(visit)
            }
        }
        if !menuTree.flo.hasPlugins {
            thumb.tween = thumb.value
        }
        refreshView()
    }

}


