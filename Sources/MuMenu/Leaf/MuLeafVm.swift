//  Created by warren on 6/21/22.

import Foundation
import SwiftUI
import Par

public enum Toggle { case on, off }

/// extend MuNodeVm to show title and thumb position
public class MuLeafVm: MuNodeVm {
    
    var menuSync: MuMenuSync?
    var leafProto: MuLeafProtocol?
    var animateLeaf: TimeInterval = 1 //???
    
    /// normalized to 0...1
    var thumbNow  = Thumb(repeatElement(0, count: 2))
    var thumbNext = Thumb(repeatElement(0, count: 2))
    var timer: Timer?
    
    func updateLeafPeers(_ visitor: Visitor) {
        if visitor.isLocal() {
            let leafItem = MenuLeafItem(self, thumbNext)
            let menuItem = MenuItem(leaf: leafItem, rootVm.corner, .moved)
            rootVm.sendItemToPeers(menuItem)
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
    func updateRunway(_ bounds: CGRect) {
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

    var animSteps = TimeInterval.zero
    
    func animateThumb() {
        animSteps = animateLeaf * 60 // DisplayLink.shared.fps
        DisplayLink.shared.delegates[self.hash] = self
    }
}
extension MuLeafVm: DisplayLinkDelegate {

    public func nextFrame() -> Bool {
        for i in 0..<thumbNext.count {
            let now = thumbNow[i]
            let next = thumbNext[i]
            let delta = (next - now)
            let increment = animSteps <= 1 ? delta : delta / animSteps
            thumbNow[i] = (now + increment)
        }
        animSteps = max(0, animSteps - 1)
        if animSteps > 1 {
            DispatchQueue.main.async {
                self.leafProto?.syncNow(Visitor(self.hash))
            }
        } else {
            DispatchQueue.main.async {
                self.leafProto?.syncNext(Visitor(self.hash))
            }
        }
        return animSteps >= 1
    }
}
