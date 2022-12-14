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

    public func setRoot(_ rootVm: MuRootVm) {
        guard let treeVm = rootVm.treeSpotVm else { return }
        self.rootVm = rootVm
        
        let cornerNode = MuCornerNode("⚫︎")
        let branchVm = MuBranchVm.cached(treeVm: treeVm)
        rootNodeVm = MuNodeVm(cornerNode, branchVm, nil)
        branchVm.addNodeVm(rootNodeVm)

        dragNodeVm = rootNodeVm?.copy()
        if rootVm.corner.contains(.right) {
            let rightOffset: CGFloat = -(2 * Layout.padding)
            dragNodeΔ = CGSize(width: rightOffset, height: 0)
        }
    }


    /// called either by SwiftUI MenuView DragGesture or UIKIt touchesUpdate
    public func touchMenuUpdate(_ touchPoint: CGPoint) {

        if !touchState.touching     { begin() }
        else if touchPoint == .zero { ended() }
        else                        { moved() }

        alignDragIcon(touchPoint)

        func begin() {
            touchState.begin(touchPoint)
            rootVm?.touchBegin(touchState)
            // log("touch", [touchNow], terminator: " ")
        }

        func moved() {
            touchState.moved(touchPoint)

            if let rootVm {

                if touchState.isFast,
                   // has a child branch to skip
                   rootVm.nodeSpotVm?.nextBranchVm?.nodeSpotVm != nil {
                    // log("🏁", terminator: " ")
                } else {
                    rootVm.touchMoved(touchState)
                }
            }
        }

        func ended() {
            touchState.ended()
            rootVm?.touchEnded(touchState)
            dragIconXY = parkIconXY
            spotNodeΔ = .zero // no spotNode to align with
            rootNodeΔ = .zero // go back to rootNode
        }
    }

    /// updated on startup or change in screen orientation
    func updateRootIcon(_ from: CGRect) {
        parkIconXY = rootVm?.cornerXY(in: from) ?? .zero
        dragIconXY = parkIconXY
        //log("*** rootIconXY: ", [from,rootIconXY])
    }
    
    /// either center dragNode icon on spotNode or track finger
    func alignDragIcon(_ touchMenu: CGPoint) {

        guard let rootVm else {
            return dragIconXY = touchMenu - bounds.origin
        }
        if !touchState.touching ||
            rootVm.touchElement == .root ||
            rootVm.nodeSpotVm?.nodeType.isLeaf ?? false {

            // park the dragIcon
            dragIconXY = parkIconXY

        } else if let nodeSpot = rootVm.nodeSpotVm {

            dragIconXY = nodeSpot.center - bounds.origin

        } else {

            dragIconXY = touchMenu - bounds.origin
        }
    }
    var bounds = CGRect.zero
    func updateBounds(_ bounds: CGRect) {
        self.bounds = bounds
        // log("RootVm",[bounds])
    }
}
