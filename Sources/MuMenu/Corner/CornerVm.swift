// created by musesum on 10/31/21.

import SwiftUI
import MuFlo

/// corner node which follows touch
@Observable public class CornerVm: Identifiable {

    public var id = Visitor.nextId()
    var ringIconXY = CGPoint.zero /// current position
    var parkIconXY = CGPoint.zero     /// fixed position of icon

    var rootVm: RootVm?
    var logoNodeVm: NodeVm?  /// fixed root node in corner in which to drag from
    var ringNodeVm: NodeVm?  /// drag from root with duplicate node icon
    var touchState = TouchState() /// begin,moved,end state plus t count

    var rootNodeΔ = CGSize.zero /// offset between rootNode and touchNow
    private var spotNodeΔ = CGSize.zero /// offset between touch point and center in coord
    var dragNodeΔ: CGSize { /// weird kludge to compsate for small right offset
        if let rootVm, rootVm.cornerOp.right,
           ringIconXY != parkIconXY {
            return CGSize(width: -Layout.padding2, height: 0)
        } else {
            return .zero
        }

    }

    public var corner: CornerOp

    init(_ corner: CornerOp) {
        self.corner = corner
    }

    public func setRoot(_ rootVm: RootVm) {

        // choose an arbirary tree to allow for branc
        guard let treeVm = rootVm.treeVms.first else { return }
        self.rootVm = rootVm

        let branchVm = BranchVm.cached(treeVm: treeVm)
        let name = rootVm.cornerOp.indicator()
        let cornerFlo = Flo(name)

        let iconLogo = Icon(.cursor, Layout.iconLogo)
        let cornerLogo = MenuTree(cornerFlo, .none, iconLogo)
        logoNodeVm = NodeVm(cornerLogo, branchVm, nil)

        let iconRing = Icon(.cursor, Layout.iconRing)
        let cornerRing = MenuTree(cornerFlo, .none, iconRing)
        ringNodeVm = NodeVm(cornerRing, branchVm, nil)

        branchVm.addRootNodeVm(logoNodeVm)
        branchVm.addRootNodeVm(ringNodeVm)
    }
    
    public func updateDragXY(_ touchXY: CGPoint) {
        
        if !touchState.touching  { begin(touchXY, fromRemote: false) }
        else if touchXY == .zero { ended(touchXY, fromRemote: false) }
        else                     { moved(touchXY, fromRemote: false) }
        
        alignCursor(touchXY)
    }
    public func updateLongPressXY(_ touchXY: CGPoint) {

        touchState.longPoint(touchXY)
        alignCursor(touchXY)
    }
    public func updateTouchXY(_ touchXY: CGPoint,
                              _ phase: Int) {

        switch phase.uiPhase() {
            case .began: begin(touchXY, fromRemote: false)
            case .moved: moved(touchXY, fromRemote: false)
            default:     ended(touchXY, fromRemote: false)
        }
        alignCursor(touchXY)
    }
    func begin(_ touchXY: CGPoint, fromRemote: Bool) {
        touchState.beginPoint(touchXY)
        rootVm?.touchBegin(touchState, fromRemote)
        // log("touch", [touchNow], terminator: " ")
    }
    
    func moved(_ touchXY: CGPoint, fromRemote: Bool)  {
        
        touchState.movedPoint(touchXY)
        
        if let rootVm {
            
            if touchState.isFast, //may child branch to skip
               rootVm.nodeSpotVm?.nextBranchVm?.nodeSpotVm != nil {
                log("🏁", terminator: " ")
            } else {
                rootVm.touchMoved(touchState, fromRemote)
            }
        }
    }
    
    func ended(_ touchXY: CGPoint, fromRemote: Bool) {
        touchState.ended()
        rootVm?.touchEnded(touchState, fromRemote)
        ringIconXY = parkIconXY
        spotNodeΔ = .zero // no spotNode to align with
        rootNodeΔ = .zero // go back to rootNode
    }
    /// updated on startup or change in screen orientation
    func updateRootIcon(_ from: CGRect) {
        parkIconXY = rootVm?.cornerXY(in: from) ?? .zero
        ringIconXY = parkIconXY
    }
    
    /// either center dragNode icon on spotNode or track finger
    func alignCursor(_ touchXY: CGPoint) {
        
        #if os(visionOS)
        let origin = CGPoint.zero
        #else
        let origin = bounds.origin
        #endif

        guard let rootVm else {
            return ringIconXY = touchXY - origin
        }
        if !touchState.touching ||
            rootVm.touchType.isIn([.root, .canopy]) ||
            rootVm.nodeSpotVm?.nodeType.isControl ?? false {

            ringIconXY = parkIconXY  // park the dragIcon

        } else if let spotCenter = rootVm.nodeSpotVm?.center {

            ringIconXY = spotCenter - origin

        } else {

            ringIconXY = touchXY - origin
        }
    }
    var bounds = CGRect.zero
    func updateBounds(_ bounds: CGRect) {
        self.bounds = bounds
        //log("RootVm",[bounds])
    }

    func touchingRoot(_ touchNow: CGPoint) -> Bool {
        if let logoNodeVm,
           logoNodeVm.runwayContains(touchNow) {
            return true
        }
        return false
    }
}
