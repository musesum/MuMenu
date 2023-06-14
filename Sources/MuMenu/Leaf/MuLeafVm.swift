//  Created by warren on 6/21/22.

import Foundation
import SwiftUI
import MuPar
import MuTime // NextFrame

public enum Toggle { case on, off }

/// extend MuNodeVm to show title and thumb position
public class MuLeafVm: MuNodeVm {
    
    var menuSync: MuMenuSync?
    var leafProto: MuLeafProtocol?
    
    /// normalized to 0...1
    var thumbVal  = Thumb(repeatElement(0, count: 2))
    var thumbDelta = CGPoint.zero
    var timer: Timer?
    
    func updateLeafPeers(_ visit: Visitor) {
        if visit.isLocal() {
            let leafItem = MenuLeafItem(self, thumbVal)
            let menuItem = MenuItem(leaf: leafItem, rootVm.corner, .moved)
            rootVm.sendItemToPeers(menuItem)
        }
    }
    override init (_ node: MuFloNode,
                   _ branchVm: MuBranchVm,
                   _ prevVm: MuNodeVm? = nil) {
        
        super.init(node, branchVm, prevVm)
        
        // some leaves spawn a child view
        menuSync = node.menuSync ?? prevVm?.node.menuSync
    }
    
    /// bounds for control surface, used to determin if touch is inside control area
    var runwayBounds = CGRect.zero
    
    /// updated by View after auto-layout
    func updateRunway(_ bounds: CGRect) {
        runwayBounds = bounds
    }
    /// does control surface contain point
    override func containsPoint(_ point: CGPoint) -> Bool {
        let contained = runwayBounds.contains(point)
        return contained
    }
    public func touchLeaf(_ touchState: MuTouchState,
                          _ visit: Visitor) {
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
