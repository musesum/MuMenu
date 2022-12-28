// Created by warren on 10/31/21.

import SwiftUI

/// Corner node which follows touch
public class MuTouchVm: ObservableObject {

    @Published var dragIconXY = CGPoint.zero /// current position
    public var parkIconXY = CGPoint.zero     /// fixed position of icon

    /// hide park icon while hovering elsewhere
    var parkIconAlpha: CGFloat {
        (dragIconXY == parkIconXY) || (dragIconXY == .zero) ? 1 : 0
    }
    var rootVm: MuRootVm?
    var rootNodeVm: MuNodeVm?  /// fixed root node in corner in which to drag from
    var dragNodeVm: MuNodeVm?  /// drag from root with duplicate node icon
    var touchState = MuTouchState() /// begin,moved,end state plus tap count

    private var rootNodeΔ = CGSize.zero /// offset between rootNode and touchNow
    private var spotNodeΔ = CGSize.zero /// offset between touch point and center in coord
    var dragNodeΔ: CGSize = .zero /// weird kludge to compsate for small right offset

    public var corner: MuCorner?  {
        rootVm?.corner
    }

    public func setRoot(_ rootVm: MuRootVm) {
        guard let treeVm = rootVm.treeSpotVm else { return }
        self.rootVm = rootVm
        
        let cornerNode = MuCornerNode("⚫︎") //???
        let branchVm = MuBranchVm.cached(treeVm: treeVm)
        rootNodeVm = MuNodeVm(cornerNode, branchVm, nil)
        branchVm.addNodeVm(rootNodeVm)

        dragNodeVm = rootNodeVm?.copy()
        if rootVm.corner.contains(.right) {
            let rightOffset: CGFloat = -(2 * Layout.padding)
            dragNodeΔ = CGSize(width: rightOffset, height: 0)
        }
    }
    
    public func updateDragXY(_ touchXY: CGPoint) {
        
        if !touchState.touching  { begin(touchXY, fromRemote: false) }
        else if touchXY == .zero { ended(touchXY, fromRemote: false) }
        else                     { moved(touchXY, fromRemote: false) }
        
        alignCursor(touchXY)
    }

    public func updateTouchXY(_ touchXY: CGPoint,
                              _ phase: Int) {

        let phase = UITouch.Phase(rawValue: phase)
        switch phase {
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
            
            if touchState.isFast,
               // has a child branch to skip
               rootVm.nodeSpotVm?.nextBranchVm?.nodeSpotVm != nil {
                // log("🏁", terminator: " ")
            } else {
                rootVm.touchMoved(touchState, fromRemote)
            }
        }
    }
    
    func ended(_ touchXY: CGPoint, fromRemote: Bool) {
        touchState.ended()
        rootVm?.touchEnded(touchState, fromRemote)
        dragIconXY = parkIconXY
        spotNodeΔ = .zero // no spotNode to align with
        rootNodeΔ = .zero // go back to rootNode
    }
    /// updated on startup or change in screen orientation
    func updateRootIcon(_ from: CGRect) {
        parkIconXY = rootVm?.cornerXY(in: from) ?? .zero
        dragIconXY = parkIconXY
        //log("*** rootIconXY: ", [from,rootIconXY])
    }
    
    /// either center dragNode icon on spotNode or track finger
    func alignCursor(_ touchXY: CGPoint) {

        guard let rootVm else {
            return dragIconXY = touchXY - bounds.origin
        }
        if !touchState.touching ||
            rootVm.touchElement == .root ||
            rootVm.nodeSpotVm?.nodeType.isLeaf ?? false {

            // park the dragIcon
            dragIconXY = parkIconXY

        } else if let nodeSpot = rootVm.nodeSpotVm {

            dragIconXY = nodeSpot.center - bounds.origin

        } else {

            dragIconXY = touchXY - bounds.origin
        }
    }
    var bounds = CGRect.zero
    func updateBounds(_ bounds: CGRect) {
        self.bounds = bounds
        // log("RootVm",[bounds])
    }
}
