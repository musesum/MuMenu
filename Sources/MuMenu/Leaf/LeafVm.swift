//  created by musesum on 6/21/22.

import Foundation
import SwiftUI
import MuFlo

public enum OnOff { case on, off }

/// extend MuNodeVm to show title and thumb position
public class LeafVm: NodeVm {
    var runways: LeafRunways!
    var ranges = [String : ClosedRange<Double>]()

    lazy var leafPath: String = { branchVm.chiral.icon + "." + menuTree.path }()
    public lazy var leafHash: Int = { leafPath.strHash() }()

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

    public func setRanges() {
        // set ranges
        if let exprs = menuTree.flo.exprs {
            for name in ["x","y","z"] {
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
        runways.touchLeaf(self, touchState) //....  , quantize: 4
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
    public func remoteThumb(_ remoteThumb: LeafThumb, _ visit: Visitor) {
        guard let thumb = runways.thumb(remoteThumb.type) else { return }
        thumb.value = remoteThumb.value
        if !menuTree.flo.hasPlugins {
            thumb.tween = thumb.value
        }
        syncVal(visit)
    }
    /// update from flo, including tweens -- not touch
    public func updateFromFlo(_ flo: Flo, _ visit: Visitor) {
        guard !visit.wasHere(leafHash) else { return }
        runways.setThumbFlo(flo)
        syncVal(visit)
    }
   
    public func syncVal(_ visit: Visitor) {
        print("*** \(#function) override me")
    }
    func updateLeafPeers(_ visit: Visitor) {
        if visit.isLocal(),
           let thumb = runways.thumb() {

            let leafItem = MenuLeafItem(self, thumb)
            let menuItem = MenuItem(leaf: leafItem, rootVm.cornerOp, .moved)
            rootVm.sendItemToPeers(menuItem)
        }
    }

    /// convert normalized `0...1` to Flo range
    /// such as  `x`, `y` in `repeat (xy, x -1…1~0, y -1…1~0)`
    func expand(named: String, _ value: CGFloat) -> Double {
        let range = ranges[named] ?? 0...1
        let result = scale(Double(value), from: 0...1, to: range)
        return result
    }
}
