//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// 2d XY control
public class LeafXyzVm: LeafVm {
    
    var ranges = [String : ClosedRange<Double>]()

    override init (_ menuTree: MenuTree,
                   _ branchVm: BranchVm,
                   _ prevVm: NodeVm?) {
        
        super.init(menuTree, branchVm, prevVm)

        // set ranges
        if let exprs = menuTree.model˚.exprs,
           let x = exprs.nameAny["x"] as? Scalar,
           let y = exprs.nameAny["y"] as? Scalar,
           let z = exprs.nameAny["z"] as? Scalar {

            ranges["x"] = x.range()
            ranges["y"] = y.range()
            ranges["z"] = z.range()
            
        } else {
            let scalars = menuTree.model˚.scalars()
            for scalar in scalars {
                ranges[scalar.name] = scalar.range()
            }
        }
        let visit = Visitor(0, .bind) //.. .model
        updateFromFlo(menuTree.model˚, visit)
        syncVal(visit)
    }

    /// ticks above and below nearest tick,
    /// but never on panel border or thumb border
   func ticks() -> [CGSize] {
        var result = [CGSize]()
        let lengthXY = self.panelVm.runwayXY
        let span = CGFloat(0.25)
        
        for w in stride(from: CGFloat(0), through: 1, by: span) {
            for h in stride(from: CGFloat(0), through: 1, by: span) {

                let tick = CGSize(width:  w * lengthXY.x,
                                  height: h * lengthXY.y)
                result.append(tick)
            }
        }
        return result
    }

    func expand(named: String, _ value: CGFloat) -> Double {

        let range = ranges[named] ?? 0...1
        let result = scale(Double(value), from: 0...1, to: range)
        return result
    }

    /// user touch gesture inside runway
    override public func touchLeaf(_ touchState: TouchState,
                                   _ visit: Visitor) {

        editing = runways.touchLeaf(touchState)
        syncVal(visit)
    }
    /// user double tapped a parent node
    override func tapLeaf() {
        resetOrigin()
    }
    override public func leafTitle() -> String { return "" }
    override public func treeTitle() -> String {
        guard let thumb = runways.thumb() else { return "xyz??" }
        let x = expand(named: "x", thumb.value.x).digits(-2)
        let y = expand(named: "y", thumb.value.y).digits(-2)
        let z = expand(named: "z", thumb.value.z).digits(-2)
        return ("x:\(x) y:\(y) z:\(z)")
    }
    /// update from model - not touch
    override public func updateFromFlo(_ flo: Flo, _ visit: Visitor) {

        guard !visit.wasHere(leafHash) else { return }
        guard let thumb = runways.thumb() else { return }

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

    override public func thumbValueOffset(_ type: LeafRunwayType) -> CGSize {
        guard let thumb = runways.thumb(type),
              let bounds = runways.bounds(type) else { return .zero }
        let size = runways.expandThumb(thumb.value, type, bounds)
        return size
    }

    override public func thumbTweenOffset(_ type: LeafRunwayType) -> CGSize {
        guard let thumb = runways.thumb(type),
              let bounds = runways.bounds(type) else { return .zero }
        let size = runways.expandThumb(thumb.tween, type, bounds)
        return size
    }
    /// called via user touch or via model update
    override public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb() else { return }
        if  !visit.type.tween,
            !visit.type.bind {

            let x = expand(named: "x", thumb.value.x)
            let y = expand(named: "y", thumb.value.y)
            let z = expand(named: "z", thumb.value.z)
            menuTree.model˚.setAnyExprs([("x", x),("y", y), ("z", z)], .fire, visit)
            updateLeafPeers(visit)
        }
        if !menuTree.model˚.hasPlugins {
            thumb.tween = thumb.value
        }
        refreshView()
    }
}
