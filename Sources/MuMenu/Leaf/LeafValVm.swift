//  created by musesum on 12/10/21.

import SwiftUI
import MuFlo

/// 1d slider control
public class LeafValVm: LeafVm {

    lazy var range: ClosedRange<Double> = {
        ranges.values.first ?? 0...1
    }()

    /// scale up normalized to defined range
    var expanded: Double {
        guard let thumb = runways.thumb(.runVal) else { return 0 }
        let v = panelVm.isVertical ? thumb.value.y : thumb.value.x
        let double = scale(v, from: 0...1, to: range)
        return double
    }

    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState, _ visit: Visitor) {
        runways.touchLeaf(self,touchState) // no quantize
        syncVal(visit)
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

        if !visit.type.has(.tween) {

            let v = expanded

            if visit.type.has([.model,.bind,.midi,.remote]) {

                menuTree.model˚.setAnyExprs([("x", v),("y", v)], .sneak, visit)

            } else if visit.type.has([.user,.midi]) {

                menuTree.model˚.setAnyExprs([("x", v),("y",v)], .fire, visit)
                updateLeafPeers(visit)
            }
        }
        if !menuTree.model˚.hasPlugins {
            thumb.tween = thumb.value
        }
        refreshView()
    }

}


