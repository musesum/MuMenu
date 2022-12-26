// Created by warren on 10/16/21.

import SwiftUI

public class MuBranchVm: Identifiable, ObservableObject {
    public let id = MuNodeIdentity.getId()
    static func == (lhs: MuBranchVm, rhs: MuBranchVm) -> Bool { lhs.id == rhs.id }
    static func == (lhs: MuBranchVm, rhs: MuBranchVm?) -> Bool { lhs.id == (rhs?.id ?? -1) }

    @Published var show = true
    var duration: CGFloat { Layout.animate  }
    var branchOpacity: CGFloat = 1 // branch may be partially occluded
    var viewOpacity: CGFloat { show ? branchOpacity : 0 }

    public var treeVm: MuTreeVm       /// my tree; which unfolds a hierarchy of branches
    var nodeVms: [MuNodeVm]    /// all the node View Models on this branch
    var nodeSpotVm: MuNodeVm?  /// current node, nodeSpotVm.branchVm is next branch
    var panelVm: MuPanelVm     /// background + stroke model for BranchView

    var branchPrev: MuBranchVm?
    var boundsPrior: CGSize = .zero
    var boundsNow: CGRect = .zero /// current bounds after shifting
    var boundsPad: CGRect = .zero /// extended bounds for capturing finger drag
    var zindex: CGFloat = 0       /// zIndex within sub/super branches

    var title: String {
        let nameFirst = nodeVms.first?.node.title ?? ""
        let nameLast  = nodeVms.last?.node.title ?? ""
        return nameFirst + "…" + nameLast
    }

    static func titleForNodes(_ nodes: [MuNode]) -> String {
        let nameFirst = nodes.first?.title ?? ""
        let nameLast  = nodes.last?.title ?? ""
        return nameFirst + "…" + nameLast
    }

    public init(nodes: [MuNode] = [],
                treeVm: MuTreeVm,
                branchPrev: MuBranchVm? = nil,
                prevNodeVm: MuNodeVm?,
                zindex: CGFloat = 0) {

        self.nodeVms = []
        self.treeVm = treeVm
        self.branchPrev = branchPrev
        self.zindex = zindex

        self.panelVm = MuPanelVm(nodes: nodes,
                                 treeVm: treeVm)
        buildNodeVms(from: nodes,
                     prevNodeVm: prevNodeVm)

        updateTree(treeVm)
    }

    private func buildNodeVms(from nodes: [MuNode],
                              prevNodeVm: MuNodeVm?) {

        for node in nodes {

            let nodeVm = MuNodeVm.cached(node.nodeType, node, self, prevNodeVm)
            nodeVms.append(nodeVm)
            if nodeVm.spotlight || node.nodeType.isLeaf {
                nodeSpotVm = nodeVm
            }
        }
    }
   
    /// add a branch to selected node and follow next node
    func expandBranch() {

        guard let nodeSpotVm = nodeSpotVm else { return }

        if nodeSpotVm.node.children.count > 0 {
            
            MuBranchVm.cached(nodes: nodeSpotVm.node.children,
                              treeVm: treeVm,
                              branchPrev: self,
                              prevNodeVm: nodeSpotVm,
                              zindex: zindex+1)
            .expandBranch()
        }
    }

    /** May be updated after init for root tree inside update Root
     */
    func updateTree(_ treeVm: MuTreeVm?) {
        guard let treeVm else { return }
        self.treeVm = treeVm
    }

    func addNodeVm(_ nodeVm: MuNodeVm?) {
        guard let nodeVm else { return }
        if nodeVms.contains(nodeVm) { return }
        nodeVms.append(nodeVm)
    }

    func findNearestNode(_ touchNow: CGPoint) -> MuNodeVm? {

        if let nodeSpotVm {
            if nodeSpotVm.containsPoint(touchNow) ||
                nodeSpotVm.nodeType.isLeaf {
                return nodeSpotVm
            }
        }
        for nodeVm in nodeVms {
            let distance = nodeVm.center.distance(touchNow)
            // log("D",[distance], terminator: " ")
            if distance < Layout.diameter {
                nodeSpotVm?.spotlight = false
                nodeSpotVm = nodeVm
                nodeSpotVm?.spot(on: true)
                nodeVm.superSpotlight()
                return nodeVm
            }
        }
        return nil
    }
    
    /** check touch point is inside a leaf's branch

        - note: already checked inclide a leaf's runway
        so expand check to inlude the title area
     */
    func findNearestLeaf(_ touchNow: CGPoint) -> MuLeafVm? {

        // is hovering over same node as before
        if let leafVm = nodeSpotVm as? MuLeafVm,
           leafVm.branchVm.boundsNow.contains(touchNow) {
            return leafVm
        }
        for nodeVm in nodeVms {
            if let leafVm = nodeVm as? MuLeafVm,
               leafVm.branchVm.boundsNow.contains(touchNow) {
                nodeSpotVm = leafVm
                nodeSpotVm?.spot(on: true)
                leafVm.superSpotlight()
                return leafVm
            }
        }
        return nil
    }

    /// update from MuBranchView
    func updateBranchBounds(_ from: CGRect) {
        if boundsNow != from {
            boundsNow = panelVm.updatePanelBounds(from)
            boundsPad = boundsNow.pad(Layout.padding)
            updateShiftRange()
        }
        if boundStart == .zero {
            updateShiftRange()
        }
    }
    private var boundStart: CGRect = .zero
    @Published var branchShift: CGSize = .zero

    private var shiftRange: RangeXY = (0...1, 0...1)

    func updateShiftRange() {
        guard let touchVm = treeVm.rootVm?.touchVm else { return }
        boundStart = boundsNow - CGPoint(treeVm.treeShifting)
        let boundsPriorSize = branchPrev?.boundsPrior ?? .zero
        let boundsPrevSize = branchPrev?.boundStart.size ?? .zero
        let priorPadding = branchPrev == nil ? 0 : Layout.padding * 2

        boundsPrior = boundsPriorSize + boundsPrevSize + priorPadding

        let rxy = touchVm.parkIconXY
        let rx = rxy.x - Layout.radius
        let ry = rxy.y - Layout.radius

        let pw = boundsPrior.width
        let ph = boundsPrior.height

        shiftRange = (treeVm.axis == .vertical
                      ? (treeVm.corner.contains(.left)
                         ? (min(0, rx-pw)...0, 0...0)
                         : (0...max(0, pw), 0...0))
                      : (treeVm.corner.contains(.upper)
                         ? (0...0, min(0,ry-ph)...0)
                         : (0...0, 0...max(0, ph))))
        shiftBranch()
        // logBounds()
    }

    func logBounds() {
        log(title.pad(17), [shiftRange], length: 30)
        log("now", [boundsNow], length: 22)
        log("prior", [boundsPrior], length: 17)
        log("shift", [branchShift], length: 15)
        log("opacity",format: "%.2f", [branchOpacity])
        //log("outer", [panelVm.outer], length: 16)
        //log("level", [level])
    }

    func shiftBranch() {

        let treeShifting = treeVm.treeShifting
        if boundsNow == .zero { return }
        branchShift = treeShifting.clamped(to: shiftRange)
        let clampDelta = branchShift-treeShifting

        if nodeVms.first?.nodeType.isLeaf ?? false {
            branchOpacity = 1 // always show leaves
        } else {
            let ww = abs(clampDelta.width) / boundStart.width
            let hh = abs(clampDelta.height) / boundStart.height
            branchOpacity = min(1-ww,1-hh)
        }
    }
    
}



