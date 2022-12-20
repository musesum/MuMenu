//  Created by warren on 6/21/22.

import SwiftUI

/// extend MuNodeVm to show title and thumb position
public class MuLeafVm: MuNodeVm {
    
    var menuSync: MuMenuSync?
    
    /// normalized to 0...1
    var thumb = [Double](repeatElement(0, count: 2))
    
    func updatePeers() {
        rootVm.updatePeers(self, thumb: thumb)
    }

    override init (_ node: MuNode,
                   _ branchVm: MuBranchVm,
                   _ prevVm: MuNodeVm? = nil) {
        
        super.init(node, branchVm, prevVm)
        
        // some leaves spawn a child view
        menuSync = node.menuSync ?? prevVm?.node.menuSync
    }
    
    
    /// updated textual title of control value
    @objc public dynamic func valueText() -> String {
        print("*** need to override MuLeafVm.status")
        return "oops"
    }
    
    /// updated position of thumb inside control
    @objc public dynamic func thumbOffset() -> CGSize {
        print("*** need to override thumbOffset")
        return .zero
    }
    
    /// updated position of thumb inside control
    @objc public dynamic func updateLeaf(_ any: Any) {
        print("*** need to override updateLeaf")
    }

    /// synchronize with model
    @objc public dynamic func updateSync() {
        print("*** need to override MuLeafVm.status")
    }
    /// updated position of thumb inside control
    @objc public dynamic func refreshValue() {
        print("*** need to override refreshValue")
    }
    
    /// bounds for control surface, used to determin if touch is inside control area
    var runwayBounds = CGRect.zero
    
    /// updated by View after auto-layout
    func updateRunwayBounds(_ bounds: CGRect) {
        runwayBounds = bounds
        // log("runwayBounds", [runwayBounds], terminator: " ")
    }
    /// does control surface contain point
    override func contains(_ point: CGPoint) -> Bool {
        return runwayBounds.contains(point)
    }
}
