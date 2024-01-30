//  created by musesum on 6/21/22.

import Foundation
import SwiftUI
import MuFlo
public enum Toggle { case on, off }

/// extend MuNodeVm to show title and thumb position
public class LeafVm: NodeVm {
    
    var leafProto: LeafProtocol?
    
    /// normalized to 0...1
    var thumbVal  = Thumb(repeatElement(0, count: 2)) // destination value
    var thumbTwe  = Thumb(repeatElement(0, count: 2)) // current tween value
    var thumbDelta = CGPoint.zero
    var timer: Timer?
    
    func updateLeafPeers(_ visit: Visitor) {
        if visit.isLocal() {
            var thumbs: Thumbs = [[0,0],[0,0]]
            thumbs[0][0] = thumbVal[0] // scalar.x.val
            thumbs[0][1] = thumbTwe[0] // scalar.x.twe
            thumbs[1][0] = thumbVal[1] // scalar.y.val
            thumbs[1][1] = thumbTwe[1] // scalar.y.twe

            let leafItem = MenuLeafItem(self, thumbs)
            let menuItem = MenuItem(leaf: leafItem, rootVm.cornerOp, .moved)
            rootVm.sendItemToPeers(menuItem)
        }
    }
    override init (_ node: FloNode,
                   _ branchVm: BranchVm,
                   _ prevVm: NodeVm? = nil) {
        
        super.init(node, branchVm, prevVm)
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
    public func touchLeaf(_ touchState: TouchState,
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
