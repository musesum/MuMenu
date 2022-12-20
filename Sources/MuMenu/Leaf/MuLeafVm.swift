//  Created by warren on 6/21/22.

import SwiftUI

/// extend MuNodeVm to show title and thumb position
public class MuLeafVm: MuNodeVm {

    var menuSync: MuMenuSync?
    var thumb = [Double](repeatElement(0, count: 2)) /// normalized to 0...1

    override init (_ node: MuNode,
                   _ branchVm: MuBranchVm,
                   _ prevVm: MuNodeVm? = nil) {
        
        super.init(node, branchVm, prevVm)

        // some leaves spawn a child view
        menuSync = node.menuSync ?? prevVm?.node.menuSync
    }


    /// updated textual title of control value
    @objc dynamic func valueText() -> String {
        print("*** need to override MuLeafVm.status")
        return "oops"
    }

    /// updated position of thumb inside control
    @objc dynamic func thumbOffset() -> CGSize {
        print("*** need to override thumbOffset")
        return .zero
    }

    /// updated position of thumb inside control
    @objc dynamic func updateLeaf(_ any: Any) -> Any {
        print("*** need to override updateLeaf")
        return any
    }

    /// updated position of thumb inside control
    @objc dynamic func refreshValue() {
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
