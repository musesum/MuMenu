//  created by musesum on 6/21/22.

import Foundation
import SwiftUI
import MuFlo

public enum OnOff { case on, off }

/// extend NodeVm to show title and thumb position
public class LeafVm: NodeVm {
    var runways: LeafRunways!
    var ranges = [String : ClosedRange<Double>]()

    lazy var leafPath: String = { branchVm.treeVm.menuType.key + "." + menuTree.path }()
    public lazy var leafHash: Int = { Int(leafPath.strHash()) }()

    init (_ menuTree: MenuTree,
          _ branchVm: BranchVm,
          _ prevVm: NodeVm?,
          _ runTypes: [LeafRunwayType]) {

        super.init(menuTree, branchVm, prevVm)
        runways = LeafRunways(panelVm, runTypes)
        // callback when flo is activated
        menuTree.flo.addClosure { flo, visit in
            self.updateFromFlo(flo, visit)
        }
        setRanges()
        updateFromFlo(menuTree.flo, Visitor(0, .bind))
    }

    /// display label for a slider thumb; nil = IconSideView's runway letter.
    /// Subclasses remap slots whose meaning differs from the flo component
    /// (LeafVfVm: y slot shows "v", w slot shows "f").
    public func thumbLabel(_ runwayType: LeafRunwayType) -> String? { nil }

    public func setRanges() {
        // set ranges
        if let exprs = menuTree.flo.exprs {
            for name in ["x","y","z","w"] {
                if let scalar = exprs.nameAny[name] as? Scalar {
                    ranges[name] = scalar.range()
                }
            }
        } else {
            let scalars = menuTree.flo.scalars()
            for scalar in scalars {
                ranges[scalar.name] = scalar.range()
            }
        }
    }
    public func touchLeaf(_ touchState: TouchState, _ visit: Visitor) {
        runways.touchLeaf(self, touchState) //...  , quantize: 4
        syncVal(visit)
    }
    
    public func spot(_ tog: OnOff) {
        switch tog {
        case .on  : spotlight = true
        case .off : spotlight = false
        }
    }
    public func branchSpot(_ tog: OnOff) {
        switch tog {
        case .on  : branchVm.treeVm.branchSpotVm = branchVm
        case .off : branchVm.treeVm.branchSpotVm = nil
        }
    }
    /// value from another device, not direct touch
    public func remoteThumb(_ leafItem: MenuLeafItem, _ visit: Visitor) {
        let remoteThumb = leafItem.leafThumb
        let remoteOrigin = leafItem.origin
        guard let thumb = runways.thumb(remoteThumb.type) else { return }
        runways.setTouchType(remoteThumb.type) // scoped user/remote fires follow the moved runway
        thumb.value = remoteThumb.value
        if !menuTree.flo.hasPlugins {
            thumb.tween = thumb.value
        }
        origin = remoteOrigin
        syncVal(visit)
    }
    /// update from flo, including tweens -- not touch
    public func updateFromFlo(_ flo: Flo, _ visit: Visitor) {
        guard !visit.wasHere(leafHash) else { return }
        runways.setThumbFlo(flo)
        syncVal(visit)
    }
   @MainActor
    public func syncVal(_ visit: Visitor) {
        print("⁉️ \(#function) override me")
    }
    func updateLeafPeers(_ visit: Visitor) {
        if visit.isLocal(),
           let thumb = runways.thumb() {

            let leafItem = MenuLeafItem(self, thumb, origin)
            let menuItem = MenuItem(leaf: leafItem, .moved)
            rootVm.shareItem(menuItem)
        }
    }

    /// convert normalized `0...1` to Flo range
    /// such as  `x`, `y` in `repeat (xy, x -1…1=0, y -1…1=0)`
    func expand(named: String, _ value: CGFloat) -> Double {
        let range = ranges[named] ?? 0...1
        let result = scale(Double(value), from: 0...1, to: range)
        return result
    }

    /// Public API for external gesture surfaces (e.g. watchOS DeepWatch) to
    /// write normalized 0…1 axis values directly. Updates the runway thumb
    /// values so the existing LeafXyView/LeafXyzView render the thumb in the
    /// new position, then syncs to the underlying flo (.fire policy).
    public func setNormalized(_ nameNorms: [(String, Double)]) {
        for (name, norm) in nameNorms {
            let v = max(0, min(1, norm))
            switch name {
            case "x":
                runways.thumb(.runX)?.value.x = v
                runways.thumb(.runX)?.tween.x = v
                runways.thumb(.runXY)?.value.x = v
                runways.thumb(.runXY)?.tween.x = v
            case "y":
                runways.thumb(.runY)?.value.y = v
                runways.thumb(.runY)?.tween.y = v
                runways.thumb(.runXY)?.value.y = v
                runways.thumb(.runXY)?.tween.y = v
            case "z":
                runways.thumb(.runZ)?.value.z = v
                runways.thumb(.runZ)?.tween.z = v
                runways.thumb(.runXY)?.value.z = v
                runways.thumb(.runXY)?.tween.z = v
                if runways.hasWZ { // runWZ pad thumb carries z in its y-slot
                    runways.thumb(.runWZ)?.value.y = v
                    runways.thumb(.runWZ)?.tween.y = v
                }
            case "w": // runW thumb carries w in its x-slot
                runways.thumb(.runW)?.value.x = v
                runways.thumb(.runW)?.tween.x = v
                if runways.hasWZ { // runWZ pad thumb carries w in its x-slot
                    runways.thumb(.runWZ)?.value.x = v
                    runways.thumb(.runWZ)?.tween.x = v
                }
            default: break
            }
        }
        let expanded: [(String, Double)] = nameNorms.map { (name, norm) in
            let clamped = max(0, min(1, norm))
            return (name, expand(named: name, CGFloat(clamped)))
        }
        menuTree.flo.setNameNums(expanded, .fire, Visitor(0, .user))
        // refreshView is @MainActor — call synchronously so the thumb
        // position redraw lands in the same frame as the value change.
        refreshView()
    }

    /// Exposes the stored global-visual runway bounds set by LeafBezelView.updateBounds.
    /// Used by watchOS WatchLeafController to map touch coordinates to runway values.
    public func runwayBounds(_ type: LeafRunwayType) -> CGRect? {
        runways.bounds(type)
    }
}
