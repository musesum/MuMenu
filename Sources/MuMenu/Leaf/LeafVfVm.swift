//  created by musesum on 7/12/26.

import SwiftUI
import MuFlo

/// 2-slider mic control on the XYZW frame: v (volume) rides the y slot,
/// f (band-pass filter) rides the w slot. The x/z slots are grayed
/// placeholders and the center pad is a display-only scope (LeafScopeView)
/// — no pad thumb, no runXY/runWZ runways ever exist on this leaf.
public class LeafVfVm: LeafVm {

    /// live PCM sample window for the scope's green line — injected by the
    /// app (e.g. SkyModel: `LeafVfVm.pcm = { micTap.mag }`) so MuMenu
    /// carries no MuAudio dependency; nil or empty draws a flat centerline
    nonisolated(unsafe) public static var pcm: (@Sendable () -> [Float])?

    /// normalized 0…1 slider positions for the scope overlay
    public var vNorm: Double { runways.thumb(.runY)?.value.y ?? 0 }
    public var fNorm: Double { runways.thumb(.runW)?.value.x ?? 0.5 }

    /// thumbs display the control's meaning (v, f), not the flo slot (y, w)
    override public func thumbLabel(_ runwayType: LeafRunwayType) -> String? {
        switch runwayType {
        case .runY : "v"
        case .runW : "f"
        default    : nil
        }
    }

    override public func treeTitle() -> String {
        guard let thumbY = runways.thumb(.runY),
              let thumbW = runways.thumb(.runW) else { return "vf??" }
        let itemY = runways.touching ? thumbY.value : thumbY.tween
        let itemW = runways.touching ? thumbW.value : thumbW.tween
        let v = expand(named: "y", itemY.y).digits(-2)
        let f = expand(named: "w", itemW.x).digits(-2)
        return ("v:\(v) f:\(f)")
    }

    /// comps the current touch drives — a user fire writes ONLY the touched
    /// slider (same scoping rule as LeafXyzwVm)
    private func touchedNames() -> [String] {
        switch runways.touchType() {
        case .runY : return ["y"] // v: volume
        case .runW : return ["w"] // f: band-pass
        default    : return []
        }
    }

    /// called via user touch or via model update
    override public func syncVal(_ visit: Visitor) {

        guard visit.newVisit(leafHash) else { return }
        guard let thumbY = runways.thumb(.runY),
              let thumbW = runways.thumb(.runW) else { return }

        if visit.type.has([.tween, .midi]) {
            // ignore
        } else {

            let nameNums: [(String, Double)] = [
                ("y", expand(named: "y", thumbY.value.y)),
                ("w", expand(named: "w", thumbW.value.x)),
            ]

            if visit.type.has([.model, .bind]) {
                // full-width, silent — keeps leaf and flo coherent, fires nothing
                menuTree.flo.setNameNums(nameNums, .sneak, visit)

            } else if visit.type.has([.user, .remote]) {

                let touched = touchedNames()
                let scoped = nameNums.filter { touched.contains($0.0) }
                menuTree.flo.setNameNums(scoped, .fire, visit)
                updateLeafPeers(visit)

            } else {
                print("🔺Vf visit.type \(visit.type.description)")
            }
        }

        if !menuTree.flo.hasPlugins {
            thumbY.tween = thumbY.value
            thumbW.tween = thumbW.value
        }
        refreshView()
    }
}
