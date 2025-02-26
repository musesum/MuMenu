// created by musesum on 10/16/21.

import SwiftUI
import MuFlo
import MuVision

public class BranchVm: Identifiable, ObservableObject {

    public let id = Visitor.nextId()
    static func == (lhs: BranchVm, rhs: BranchVm)  -> Bool { lhs.id == rhs.id }
    static func == (lhs: BranchVm, rhs: BranchVm?) -> Bool { lhs.id == (rhs?.id ?? -1) }

    @Published var show: Bool = false
    @Published var opacity: CGFloat = 1 /// branch may be partially occluded

    var branchShift: CGSize {
            treeVm.treeShift.clamped(to: shiftRange)
    }
    var shiftRange: RangeXY = (0...1, 0...1)
    var titleShift: CGSize = .zero

    var treeVm: TreeVm      /// my tree; which unfolds a hierarchy of branches
    var nodeVms: [NodeVm]   /// all the node View Models on this branch
    var nodeSpotVm: NodeVm? /// current node, nodeSpotVm.branchVm is next branch
    var panelVm: PanelVm!   /// background + stroke model for BranchView

    private var branchPrev: BranchVm?
    private var boundStart: CGRect = .zero
    private var boundsPrior: CGSize = .zero

    var boundsNow: CGRect = .zero /// current bounds after shifting
    var boundsPad: CGRect = .zero /// extended bounds for detecting touch
    var zindex: CGFloat = 0       /// zIndex within sub/super branches
    var columns = 1

    var title: String {
        let nameFirst = nodeVms.first?.menuTree.title ?? ""
        let nameLast  = nodeVms.last?.menuTree.title ?? ""
        return nameFirst + "…" + nameLast
    }
    var chiral: Chiral { treeVm.corner.chiral }

    static func titleForNodes(_ menuTrees: [MenuTree]) -> String {
        let nameFirst = menuTrees.first?.title ?? ""
        let nameLast  = menuTrees.last?.title ?? ""
        return nameFirst + "…" + nameLast
    }

    public init(menuTrees: [MenuTree] = [],
                treeVm: TreeVm,
                branchPrev: BranchVm? = nil,
                prevNodeVm: NodeVm?,
                zindex: CGFloat = 0) {

        self.nodeVms = []
        self.treeVm = treeVm
        self.branchPrev = branchPrev
        self.zindex = zindex
        self.columns = prevNodeVm?.menuTree.model˚.intVal("columns") ?? 1
        
        self.panelVm = PanelVm(branchVm: self,
                               menuTrees: menuTrees,
                               treeVm: treeVm,
                               columns: columns)

        buildNodeVms(menuTrees: menuTrees,
                     prevNodeVm: prevNodeVm)

        updateTree(treeVm)
    }

    private func buildNodeVms(menuTrees: [MenuTree],
                              prevNodeVm: NodeVm?) {

        for menuTree in menuTrees {
            let nodeVm = NodeVm.makeNodeVm(menuTree, self, prevNodeVm)
            nodeVms.append(nodeVm)
            if nodeVm.spotlight || menuTree.nodeType.isControl {
                nodeSpotVm = nodeVm
            }
        }
    }
   
    /// add a branch to selected node and follow next node
    func expandBranch() {

        guard let nodeSpotVm else { return }
        
        if nodeSpotVm.menuTree.children.count > 0 {
            BranchVm
                .cached(menuTrees: nodeSpotVm.menuTree.children,
                        treeVm: treeVm,
                        branchPrev: self,
                        prevNodeVm: nodeSpotVm,
                        zindex: zindex+1)
                .expandBranch()
        }
    }

    /** May be updated after init for root tree inside update Root
     */
    func updateTree(_ treeVm: TreeVm?) {
        guard let treeVm else { return }
        self.treeVm = treeVm
    }

    func addRootNodeVm(_ nodeVm: NodeVm?) {
        guard let nodeVm else { return }
        if nodeVms.contains(nodeVm) { return }
        nodeVms.append(nodeVm)
    }

    func nearestNode(_ touchNow: CGPoint) -> NodeVm? {

        if let nodeSpotVm {
            if nodeSpotVm.runwayContains(touchNow) ||
                nodeSpotVm.nodeType.isControl {
                return nodeSpotVm
            }
        }
        var candidate: NodeVm?
        for nodeVm in nodeVms {
            let distance = nodeVm.center.distance(touchNow)
            if distance < Layout.radius {
                if distance < candidate?.center.distance(touchNow) ?? .infinity {
                    candidate = nodeVm
                }
            }
            if let candidate {
                updateNodeSpot(candidate)
                return candidate
            }
        }
        return nil
    }
    func updateNodeSpot(_ candidate: NodeVm) {
        // update new nodespot
        nodeSpotVm?.spotlight = false
        nodeSpotVm = candidate
        nodeSpotVm?.spot(on: true)
        candidate.superSpotlight()
        // update zIndex for overlapping nodes
        var zIncrement = CGFloat(1)
        var zIndex = self.zindex + CGFloat(nodeVms.count)
        for nodeVm in nodeVms {
            nodeVm.zIndex = zIndex
            if nodeVm == candidate {
                zIncrement = -1
            }
            zIndex += zIncrement
        }
    }
    /** check touch point is inside a leaf's branch

        - note: already checked inside a leaf's runway
        so expand check to include the title area
     */
    func findNearestLeaf(_ touchNow: CGPoint) -> LeafVm? {

        // is hovering over same node as before
        if let leafVm = nodeSpotVm as? LeafVm,
           leafVm.branchVm.contains(touchNow) {
            return leafVm
        }
        for nodeVm in nodeVms {
            if let leafVm = nodeVm as? LeafVm,
               leafVm.branchVm.contains(touchNow) {
                nodeSpotVm = leafVm
                nodeSpotVm?.spot(on: true)
                leafVm.superSpotlight()
                return leafVm
            }
        }
        return nil
    }

    /// update from MuBranchView
    func updateBounds(_ fromBounds: CGRect) {
        if boundsNow != fromBounds {
            boundsNow = panelVm.updatePanelBounds(fromBounds)
            boundsPad = boundsNow.pad(Layout.padding)
            updateShiftRange()
        }
    }

    func updateShiftRange() {

        boundStart = boundsNow - CGPoint(treeVm.treeShift)
        let boundsPriorSize = branchPrev?.boundsPrior ?? .zero
        let boundsPrevSize = branchPrev?.boundStart.size ?? .zero
        let priorPadding = branchPrev == nil ? 0 : Layout.padding2

        boundsPrior = boundsPriorSize + boundsPrevSize + priorPadding
        let pw = boundsPrior.width
        let ph = boundsPrior.height

        switch treeVm.corner.bound {
            case .lowerX: shiftRange = (min(0,-pw)...0, 0...0)
            case .upperX: shiftRange = (0...max(0, pw), 0...0)
            case .lowerY: shiftRange = (0...0, min(0,-ph)...0)
            case .upperY: shiftRange = (0...0, 0...max(0, ph))
        }
        shiftBranch()

        let rad = Layout.radius
        switch treeVm.corner.cornerAxis {
            case .LLH,.ULH: titleShift = CGSize(width:  rad, height: 0)
            case .LRH,.URH: titleShift = CGSize(width: -rad, height: 0)
            case .LLV,.LRV: titleShift = .zero
            case .ULV,.URV: titleShift = .zero
        }
    }

    @discardableResult
    func shiftBranch() -> CGFloat {

        if boundsNow == .zero { return 0 }
        let clampDelta = branchShift - treeVm.treeShift
        let ww = abs(clampDelta.width) / boundStart.width
        let hh = abs(clampDelta.height) / boundStart.height
        opacity = min(1-ww,1-hh)
        // refresh TreeView with updated treeBounds
        treeVm.treeShift = treeVm.treeShift
        return opacity
    }

    func contains(_ point: CGPoint) -> Bool {
        return boundsPad.contains(point)
    }

}
