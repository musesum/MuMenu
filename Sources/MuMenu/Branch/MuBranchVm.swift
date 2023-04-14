// Created by warren on 10/16/21.

import SwiftUI

public class MuBranchVm: Identifiable, ObservableObject {
    public let id = MuNodeIdentity.getId()
    static func == (lhs: MuBranchVm, rhs: MuBranchVm) -> Bool { lhs.id == rhs.id }
    static func == (lhs: MuBranchVm, rhs: MuBranchVm?) -> Bool { lhs.id == (rhs?.id ?? -1) }

    @Published var show: Bool = false
    @Published var opacity: CGFloat = 1 /// branch may be partially occluded

    var branchShift: CGSize { treeVm.treeShift.clamped(to: shiftRange) }
    var shiftRange: RangeXY = (0...1, 0...1)
    var titleShift: CGSize = .zero

    var treeVm: MuTreeVm /// my tree; which unfolds a hierarchy of branches
    var nodeVms: [MuNodeVm]   /// all the node View Models on this branch
    var nodeSpotVm: MuNodeVm? /// current node, nodeSpotVm.branchVm is next branch
    var panelVm: MuPanelVm    /// background + stroke model for BranchView

    private var branchPrev: MuBranchVm?
    private var boundStart: CGRect = .zero
    private var boundsPrior: CGSize = .zero

    var boundsNow: CGRect = .zero /// current bounds after shifting
    var boundsPad: CGRect = .zero /// extended bounds for detecting touch
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

            let nodeVm = MuNodeVm.cached(node, self, prevNodeVm)
            nodeVms.append(nodeVm)
            if nodeVm.spotlight || node.nodeType.isControl {
                nodeSpotVm = nodeVm
            }
        }
    }
   
    /// add a branch to selected node and follow next node
    func expandBranch() {

        guard let nodeSpotVm = nodeSpotVm else { return }

        if nodeSpotVm.node.children.count > 0 {
            
            MuBranchVm
                .cached(nodes: nodeSpotVm.node.children,
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

    func nearestNode(_ touchNow: CGPoint) -> MuNodeVm? {

        if let nodeSpotVm {
            if nodeSpotVm.containsPoint(touchNow) ||
                nodeSpotVm.nodeType.isControl {
                return nodeSpotVm
            }
        }
        for nodeVm in nodeVms {
            let distance = nodeVm.center.distance(touchNow)
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
           leafVm.branchVm.contains(touchNow) {
            return leafVm
        }
        for nodeVm in nodeVms {
            if let leafVm = nodeVm as? MuLeafVm,
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

        switch treeVm.cornerAxis.bound {
            case .lowX: shiftRange = (min(0,-pw)...0, 0...0)
            case .uprX: shiftRange = (0...max(0, pw), 0...0)
            case .lowY: shiftRange = (0...0, min(0,-ph)...0)
            case .uprY: shiftRange = (0...0, 0...max(0, ph))
        }
        shiftBranch()

        let rad = Layout.radius
        switch treeVm.cornerAxis.cornax {
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
        // refresh MuTreeView with updated treeBounds
        treeVm.treeShift = treeVm.treeShift
        return opacity
    }

    func contains(_ point: CGPoint) -> Bool {
        return boundsPad.contains(point)
    }

}
