//  Created by warren on 6/21/22.

import SwiftUI
import Par

/// extend MuNodeVm to show title and thumb position
public class MuLeafVm: MuNodeVm {
    
    var menuSync: MuMenuSync?
    var leafProto: MuLeafProtocol?

    /// normalized to 0...1
    var thumb = [Double](repeatElement(0, count: 2))
    
    func updatePeers(_ visitor: Visitor) {
        if visitor.isLocal() {
            rootVm.sendToPeers(self, thumb)
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
        // log("runwayBounds", [runwayBounds], terminator: " ")
    }
    /// does control surface contain point
    override func containsPoint(_ point: CGPoint) -> Bool {
        let contained = runwayBounds.contains(point)
        print(contained ? "+" : "-", terminator: "") //???
        return contained
    }
}
