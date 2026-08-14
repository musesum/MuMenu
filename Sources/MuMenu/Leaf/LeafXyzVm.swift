//  created by musesum on 5/10/22.

import SwiftUI
import MuFlo

/// 2d XY control
public class LeafXyzVm: LeafVm {

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
        guard let thumb = runways.thumb() else { return "xyz??" }
        let item = runways.touching ? thumb.value : thumb.tween
        let x = expand(named: "x", item.x).digits(-2)
        let y = expand(named: "y", item.y).digits(-2)
        let z = expand(named: "z", item.z).digits(-2)
        return ("x:\(x) y:\(y) z:\(z)")
    }

    /// Public read-only access to current normalized axis values for
    /// external gesture surfaces (e.g. watchOS WatchLeafXyzController).
    public var xNorm: Double {
        guard let thumb = runways.thumb(.runXY) else { return 0 }
        return thumb.value.x
    }
    public var yNorm: Double {
        guard let thumb = runways.thumb(.runXY) else { return 0 }
        return thumb.value.y
    }
    public var zNorm: Double {
        guard let thumb = runways.thumb(.runZ) else { return 0 }
        return thumb.value.z
    }

    /// called via user touch or via model update
    override public func syncVal(_ visit: Visitor) {
        
        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb(.runXY) else { return  }

        if visit.type.has([.tween, .midi]) {
            // ignore
        } else {
        
            let x = expand(named: "x", thumb.value.x)
            let y = expand(named: "y", thumb.value.y)
            let z = expand(named: "z", thumb.value.z)

            if visit.type.has([.model,.bind]) {

                menuTree.flo.setNameNums([("x", x),("y", y), ("z", z)], .sneak, visit)

            } else if visit.type.has([.user, .remote]) {

                menuTree.flo.setNameNums([("x", x),("y", y), ("z", z)], .fire, visit)
                updateLeafPeers(visit)

            } else {
                print("🔺Xyz visit.type \(visit.type.description)")
            }
        }

        if !menuTree.flo.hasPlugins {
            thumb.tween = thumb.value
        }
        refreshView()
    }

}
