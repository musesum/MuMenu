//  created by musesum on 6/21/22.

import Foundation
import SwiftUI
import MuFlo

public enum OnOff { case on, off }

/// extend MuNodeVm to show title and thumb position
public class LeafVm: NodeVm {
    var runways: LeafRunways!

    lazy var leafPath: String = { branchVm.chiral.icon + "." + menuTree.path }()
    public lazy var leafHash: Int = { leafPath.strHash() }()

    func updateLeafPeers(_ visit: Visitor) {
        if visit.isLocal(),
           let thumb = runways.thumb()
        {
            let leafItem = MenuLeafItem(self, thumb)
            let menuItem = MenuItem(leaf: leafItem, rootVm.cornerOp, .moved)
            rootVm.sendItemToPeers(menuItem)
        }
    }
    override init (_ menuTree: MenuTree,
                   _ branchVm: BranchVm,
                   _ prevVm: NodeVm? = nil) {
        
        super.init(menuTree, branchVm, prevVm)
        menuTree.model˚.addClosure { flo, visit in
            self.updateFromFlo(flo, visit)
        }
        runways = LeafRunways(panelVm)
    }

    public func touchLeaf(_ touchState: TouchState,
                          _ visit: Visitor) {
        PrintLog("⁉️ MuLeafVm::touchLeaf override me")
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
        editing = true
        thumb.value = remoteThumb.value
        if !menuTree.model˚.hasPlugins {
            thumb.tween = thumb.value
        }
        editing = false
        syncVal(visit)
    }
    public func updateFromFlo(_ flo: Flo, _ visit: Visitor) {
        print("*** \(#function) override me")
    }
    public func thumbValueOffset(_ type: LeafRunwayType) -> CGSize {
        print("*** \(#function) override me")
        return .zero
    }
    public func thumbTweenOffset(_ type: LeafRunwayType) -> CGSize {
        print("*** \(#function) override me")
        return .zero
    }
    public func syncVal(_ visit: Visitor) {
        print("*** \(#function) override me")
    }
}
