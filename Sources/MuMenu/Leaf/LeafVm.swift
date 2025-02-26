//  created by musesum on 6/21/22.

import Foundation
import SwiftUI
import MuFlo

public enum Toggle { case on, off }

public enum Runway: String {
    case none   =  "none"
    case runX   =  "x"
    case runY   =  "y"
    case runU   =  "u"
    case runV   =  "v"
    case runW   =  "w"
    case runZ   =  "z"
    case runS   =  "s"
    case runT   =  "t"
    case runXY  =  "xy"
    case runWZ  =  "wz"
    case runUV  =  "uv"
    case runST  =  "st"
    case runXYZ =  "xyz"

    var thumbRadius: Double {
        switch self {
        case .none   : 20
        case .runX, .runY, .runU, .runV, .runW, .runZ, .runS, .runT: 20
        case .runXY, .runWZ,  .runUV,  .runST, .runXYZ : 40
        }
    }
    func offset(_ point: CGPoint,_ bounds: CGRect) -> SIMD2<Double> {
        var offset = SIMD2<Double>(point - bounds.origin)
        switch self {
        case .runX, .runU, .runW, .runS: offset.y = 0
        case .runY, .runV, .runZ, .runT: offset.x = 0
        default: break
        }
        return offset
    }
}

class Thumb {
    /// normalized to 0...1
    var value: SIMD3<Double> = .zero /// destination value
    var tween: SIMD3<Double> = .zero /// current tween value
    var delta: SIMD2<Double> = .zero
    static let zero = Thumb()
}


/// extend MuNodeVm to show title and thumb position
public class LeafVm: NodeVm {
    
    var leafProto: LeafProtocol?

    /// bounds for control surface, used to determin if touch is inside control area
    var runwayBounds = [Runway: CGRect]()

    var runway = Runway.none
    var runwayThumb = [Runway: Thumb]()
    var bounds: CGRect { runwayBounds[runway] ?? CGRect.zero}
    var thumb: Thumb { runwayThumb[runway] ?? runwayThumb.values.first ?? Thumb.zero }

    lazy var leafPath: String = { branchVm.chiral.icon + "." + menuTree.path }()
    public lazy var leafHash: Int = { leafPath.strHash() }()

    var thumbNormRadius: Double {
        runway.thumbRadius / max(bounds.height,bounds.width) / 2.0
    }

    /// dispatch to inner control runway(s)
    func updateRunway(_ point: CGPoint) {
        for (runway, bounds) in runwayBounds {
            if bounds.contains(point) {
                self.runway = runway
                return 
            }
        }
        self.runway = .none
    }

    func updateLeafPeers(_ visit: Visitor) {
        if visit.isLocal(),
           let thumb = runwayThumb[runway]
        {
            let thumbs = ValTween(thumb.value, thumb.tween)

            let leafItem = MenuLeafItem(self, thumbs)
            let menuItem = MenuItem(leaf: leafItem, rootVm.cornerOp, .moved)
            rootVm.sendItemToPeers(menuItem)
        }
    }
    override init (_ menuTree: MenuTree,
                   _ branchVm: BranchVm,
                   _ prevVm: NodeVm? = nil) {
        
        super.init(menuTree, branchVm, prevVm)
    }
    
    /// updated by View after auto-layout
    func updateRunway(_ type: Runway,
                      _ bounds: CGRect) {
        DebugLog { P("updateRunway \(type.rawValue)\(bounds.digits())") }
        runwayBounds[type] = bounds
    }
    /// does control surface contain point
    override func runwayContains(_ point: CGPoint) -> Bool {
        for bounds in runwayBounds.values {
            if bounds.contains(point) { return true }
        }
        return false
    }
    public func touchLeaf(_ touchState: TouchState,
                          _ visit: Visitor) {
        PrintLog("⁉️ MuLeafVm::touchLeaf override me")
    }
    
    public func spot(_ tog: Toggle) {
        switch tog {
        case .on  : spotlight = true
        case .off : spotlight = false
        }
    }
    public func branchSpot(_ tog: Toggle) {
        switch tog {
        case .on  : branchVm.treeVm.branchSpotVm = branchVm
        case .off : branchVm.treeVm.branchSpotVm = nil
        }
    }
}
