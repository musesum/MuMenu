//  Created by warren on 6/21/22.

import SwiftUI
import Par

public enum Toggle { case on, off }

/// extend MuNodeVm to show title and thumb position
public class MuLeafVm: MuNodeVm {
    
    var menuSync: MuMenuSync?
    var leafProto: MuLeafProtocol?

    /// normalized to 0...1
    var thumb = [Double](repeatElement(0, count: 2))
    
    func updateLeafPeers(_ visitor: Visitor) {
        if visitor.isLocal() {
            rootVm.sendLeafToPeers(self, thumb, .moved)
            _ = branchVm.treeVm.followHashPath(node.hashPath, node.hash) //???
        }

    }

    override init (_ node: MuNode,
                   _ branchVm: MuBranchVm,
                   _ prevVm: MuNodeVm? = nil) {
        
        super.init(node, branchVm, prevVm)
        
        // some leaves spawn a child view
        menuSync = node.menuSync ?? prevVm?.node.menuSync
    }

    /// bounds for control surface, used to determin if touch is inside control area
    var runwayBounds = CGRect.zero

    /// updated by View after auto-layout
    func updateRunwayBounds(_ bounds: CGRect) {
        runwayBounds = bounds
    }
    /// does control surface contain point
    override func containsPoint(_ point: CGPoint) -> Bool {
        let contained = runwayBounds.contains(point)
        return contained
    }
    public func touchLeaf(_ touchState: MuTouchState,
                          visitor: Visitor = Visitor()) {
        print("*** MuLeafVm::touchLeaf override me")
    }

    public func spot(_ tog: Toggle) {
        switch tog {
            case .on: spotlight = true
            case .off: spotlight = false
        }
    }
    public func branchSpot(_ tog: Toggle) {
        switch tog {
            case .on:  branchVm.treeVm.branchSpotVm = branchVm
            case .off: branchVm.treeVm.branchSpotVm = nil
        }
    }

}
