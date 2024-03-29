//  created by musesum on 6/21/22.

import Foundation
import SwiftUI
import MuFlo

public enum Toggle { case on, off }


public enum RunwayType { case none, x, y, xy, xyz, z }

/// extend MuNodeVm to show title and thumb position
public class LeafVm: NodeVm {

    var leafProto: LeafProtocol?

    /// normalized to 0...1
    var thumbVal: SIMD3<Double> = .zero // destination value
    var thumbTwe: SIMD3<Double> = .zero /// current tween value
    var thumbDelta: SIMD2<Double> = .zero 
    var timer: Timer?

    /// bounds for control surface, used to determin if touch is inside control area
    var runwayBounds = [RunwayType: CGRect]()

    func thumbNormRadius() -> Double {
        if let rect = runway(.xy) {
            let radius = Layout.diameter / max(rect.height,rect.width) / 2
            return radius
        }
        return 1
    }
    func runway(_ runwayType: RunwayType) -> CGRect? {

        switch runwayType {
        case .x   : return closestRunway([.x   , .xy ])
        case .y   : return closestRunway([.y   , .xy ])
        case .xy  : return closestRunway([.xy  , .xyz])
        case .xyz : return closestRunway([.xyz , .xy ])
        case .z   : return closestRunway([.z   , .xy ])
        default   : return nil
        }
        func closestRunway(_ types: [RunwayType]) -> CGRect? {
            for type in types {
                if let rect = runwayBounds[type] {
                    return rect
                }
            }
            return nil
        }
    }
    func updateLeafPeers(_ visit: Visitor) {
        if visit.isLocal() {
            let thumbs = ValTween(thumbVal, thumbTwe)

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
    

    
    /// updated by View after auto-layout
    func updateRunway(_ type: RunwayType,
                      _ bounds: CGRect) {

        runwayBounds[type] = bounds
    }
    /// does control surface contain point
    override func containsPoint(_ point: CGPoint) -> Bool {
        for rect in runwayBounds.values {
            if rect.contains(point) { return true }
        }
        return false
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
