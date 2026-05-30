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
                    ranges[name] = range
                    break
                }
            }
        } else {
            let scalars = menuTree.flo.scalars()
            for scalar in scalars {
                ranges[scalar.name] = scalar.range()
            }
        }
    }

    public var isVertical: Bool { panelVm.menuType.vertical }

    /// Current normalized 0…1 value for display (reads value, not tween).
    public var valNorm: Double {
        guard let thumb = runways.thumb(.runVal) else { return 0 }
        return panelVm.menuType.vertical ? thumb.value.y : thumb.value.x
    }

    /// Set a normalized 0…1 value directly (e.g. from a watchOS full-face gesture).
    /// Routes through syncVal so the flo fires and the view refreshes.
    public func setValNormalized(_ normVal: Double) {
        let v = max(0, min(1, normVal))
        guard let thumb = runways.thumb(.runVal) else { return }
        if panelVm.menuType.vertical { thumb.value.y = v } else { thumb.value.x = v }
        syncVal(Visitor(0, .user))
    }

    override public func treeTitle() -> String {
        // Read the .runVal thumb explicitly so callers that don't go through
        // touchLeaf (e.g. watchOS WatchLeafYController) still get the right value.
        guard let thumb = runways.thumb(.runVal) else { return "" }
        let vertical = panelVm.menuType.vertical
        let value = vertical ? thumb.value.y : thumb.value.x
        let tween = vertical ? thumb.tween.y : thumb.tween.x
        let touching = runways.touching
        let active = touching ? value : tween
        return range.upperBound > 1
            ? String(format: "%.1f", scale(active, from: 0...1, to: range))
            : String(format: "%.2f", active)
    }

    override public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb(.runVal) else { return  }

        // value of thumb on either vertical or horizonal axis
        let val = (panelVm.menuType.vertical
                   ? thumb.value.y
                   : thumb.value.x)
        
        syncVal2(visit, thumb, val)
    }
    func syncVal2(_ visit: Visitor, _ thumb: LeafThumb, _ val: Double) {
        if visit.type.has([.tween, .midi]) {
            // ignore
        } else {
            var nameNums = [(String, Double)]()
            for name in ranges.keys {
                let nameVal = (name, expand(named: name, val))
                nameNums.append(nameVal)
            }

            if visit.type.has([.model, .bind]) {
                menuTree.flo.setNameNums(nameNums, .sneak, visit)
            } else if visit.type.has([.user, .remote]) {
                menuTree.flo.setNameNums(nameNums, .fire, visit)
                updateLeafPeers(visit)
            }
        }
        if !menuTree.flo.hasPlugins {
            thumb.tween = thumb.value
        }
        Task { @MainActor in
            self.refreshView()
        }
    }

}


