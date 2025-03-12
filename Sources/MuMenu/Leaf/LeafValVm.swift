//  created by musesum on 12/10/21.

import SwiftUI
import MuFlo

/// 1d slider control
public class LeafValVm: LeafVm {

    var range: ClosedRange<Double> = 0...1
    
    /// normalize to and from scalar range
    override public func setRanges() {
        if let exprs = menuTree.model˚.exprs {
            if let x = exprs.nameAny["x"] as? Scalar {
                range = x.range()
            } else if let y = exprs.nameAny["y"] as? Scalar {
                range = y.range()
            } else if let scalar = exprs.nameAny.values.first as? Scalar {
                range = scalar.range()
            }
        }
    }

    /// scale up normalized to defined range
    var expanded: Double {
        guard let thumb = runways.thumb() else { return 0 }
        return scale(thumb.value.x, from: 0...1, to: range)
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
        guard let thumb = runways.thumb() else { return  }

        switch visit.type {
        case .tween: break
        case .bind:
            thumb.value.x = menuTree.model˚.val("x") ?? 0
            thumb.value.y = menuTree.model˚.val("y") ?? 0
        default:
            // only differnce with LeafSegVm
            let v = panelVm.isVertical ? thumb.value.y : thumb.value.x
            let expanded = scale(v, from: 0...1, to: range)
            menuTree.model˚.setAnyExprs(expanded, .fire, visit)
            updateLeafPeers(visit)
        }
        if !menuTree.model˚.hasPlugins {
            thumb.tween = thumb.value
        }
        refreshView()
    }

}


