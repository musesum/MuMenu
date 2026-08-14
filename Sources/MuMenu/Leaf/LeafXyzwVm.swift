//  created by musesum on 7/11/26.

import SwiftUI
import MuFlo

/// 4-axis XYZW control: x on top, y/z vertical runways beside a dual-thumb
/// pad, w slider on the bottom row aligned with x (Refactor.h 2026-07-11).
/// The pad hosts two thumbs — runXY (x,y) and runWZ (w in x-slot, z in
/// y-slot); `runways.activePad` picks which pair the pad drags (filled
/// thumb), the other renders dotted and taps swap the roles.
public class LeafXyzwVm: LeafXyzVm {

    override public func treeTitle() -> String {
        guard let thumb = runways.thumb(.runXY),
              let thumbWZ = runways.thumb(.runWZ) else { return "xyzw??" }
        let item   = runways.touching ? thumb.value   : thumb.tween
        let itemWZ = runways.touching ? thumbWZ.value : thumbWZ.tween
        let x = expand(named: "x", item.x).digits(-2)
        let y = expand(named: "y", item.y).digits(-2)
        let z = expand(named: "z", itemWZ.y).digits(-2)
        let w = expand(named: "w", itemWZ.x).digits(-2)
        return ("x:\(x) y:\(y) z:\(z) w:\(w)")
    }

    public var wNorm: Double {
        guard let thumb = runways.thumb(.runWZ) else { return 0 }
        return thumb.value.x
    }

    /// comps the current touch actually drives — a user fire must write ONLY
    /// these: firing untouched comps re-triggers every edge map hanging off
    /// them (e.g. camera.mix w/z → canvas.color palette snap = screen flash
    /// on every camera-blend drag)
    private func touchedNames() -> [String] {
        switch runways.touchType() {
        case .runX  : return ["x"]
        case .runY  : return ["y"]
        case .runZ  : return ["z"]
        case .runW  : return ["w"]
        case .runXY : return ["x", "y"]
        case .runWZ : return ["w", "z"]
        // .none (no runway hit, or an untyped peer thumb) fires NOTHING —
        // a full-four fallback would re-clobber every edge map (the flash)
        default     : return []
        }
    }

    /// called via user touch or via model update
    override public func syncVal(_ visit: Visitor) {

        guard visit.newVisit(leafHash) else { return }
        guard let thumb = runways.thumb(.runXY),
              let thumbWZ = runways.thumb(.runWZ) else { return }

        if visit.type.has([.tween, .midi]) {
            // ignore
        } else {

            let nameNums: [(String, Double)] = [
                ("x", expand(named: "x", thumb.value.x)),
                ("y", expand(named: "y", thumb.value.y)),
                ("z", expand(named: "z", thumbWZ.value.y)),
                ("w", expand(named: "w", thumbWZ.value.x)),
            ]

            if visit.type.has([.model,.bind]) {
                // full-width, silent — keeps leaf and flo coherent, fires nothing
                menuTree.flo.setNameNums(nameNums, .sneak, visit)

            } else if visit.type.has([.user, .remote]) {

                let touched = touchedNames()
                let scoped = nameNums.filter { touched.contains($0.0) }
                menuTree.flo.setNameNums(scoped, .fire, visit)
                updateLeafPeers(visit)

            } else {
                print("🔺Xyzw visit.type \(visit.type.description)")
            }
        }

        if !menuTree.flo.hasPlugins {
            thumb.tween = thumb.value
            thumbWZ.tween = thumbWZ.value
            runways.thumb(.runW)?.tween = runways.thumb(.runW)?.value ?? .zero
            runways.thumb(.runZ)?.tween = runways.thumb(.runZ)?.value ?? .zero
        }
        refreshView()
    }
}
