//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// 2d XY control
public class LeafXyVm: LeafVm {

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

    override public func treeTitle() -> String {
        guard let thumb = runways.thumb() else { return "xy?" }
        let item = runways.touching ? thumb.value : thumb.tween
        let x = expand(named: "x", item.x).digits(-2)
        let y = expand(named: "y", item.y).digits(-2)
        return ("x:\(x) y:\(y)")
    }

    /// called via user touch or via model update
    override public func syncVal(_ visit: Visitor) {
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb(.runXY) else { return  }

        if visit.type == .tween {
            // ignore
        } else {
            
            let x = expand(named: "x", thumb.value.x)
            let y = expand(named: "y", thumb.value.y)
            
            if visit.type.has([.model,.bind,.remote]) {

                menuTree.model˚.setAnyExprs([("x", x),("y", y)], .sneak, visit)
                
            } else if visit.type.has([.user]) {
                
                menuTree.model˚.setAnyExprs([("x", x),("y", y)], .fire, visit)
                updateLeafPeers(visit)
                
            } else {
                print("🔺Xyz visit.type \(visit.type.description)")
            }
        }
        if !menuTree.model˚.hasPlugins {
            thumb.tween = thumb.value
        }
        refreshView()
    }
}
