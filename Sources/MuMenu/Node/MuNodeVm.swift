// Created by warren on 10/17/21.

import SwiftUI

public class MuNodeVm: Identifiable, Equatable, ObservableObject {
    public let id =  MuNodeIdentity.getId()
    public static func == (lhs: MuNodeVm, rhs: MuNodeVm) -> Bool { return lhs.id == rhs.id }

    /// publish changing value of leaf (or order of node, later)
    @Published var editing: Bool = false

    /// publish when selected or is under cursor
    @Published var spotlight = false

    func spot(on: Bool) {
        if on == spotlight { return }
        if on == true {
            node.touch()
        }
        spotlight = on
    }
    var nodeType: MuNodeType  /// node, val, vxy, seg, tog, tap
    let node: MuNode          /// each model MuNode maybe on several MuNodeVm's
    var panelVm: MuPanelVm    /// the panel that this node belongs to
    var branchVm: MuBranchVm  /// branch that this node is on
    var nextBranchVm: MuBranchVm? /// branch this node generates
    var prevNodeVm: MuNodeVm?     /// parent nodeVm in hierarchy

    var myTouchBeginTime = TimeInterval(0)
    var myTouchBeginCount = 0

    var center = CGPoint.zero /// current position

    init (_ node: MuNode,
          _ branchVm: MuBranchVm,
          _ prevVm: MuNodeVm? = nil) {

        self.node = node
        self.nodeType = node.nodeType
        self.branchVm = branchVm
        self.prevNodeVm = prevVm
        self.panelVm = MuPanelVm(nodes: [node],
                                 treeVm: branchVm.treeVm)
        prevVm?.nextBranchVm = branchVm
    }
    
    func copy() -> MuNodeVm {
        let nodeVm = MuNodeVm(node, branchVm, self)
        return nodeVm
    }

    /// spotlight self, parent, grand, etc. in branch
    func superSpotlight() {
        if branchVm.nodeSpotVm != self {

            branchVm.nodeSpotVm?.spotlight = false
            branchVm.nodeSpotVm = self
            branchVm.show = true
            spotlight = true
        }
        prevNodeVm?.superSpotlight()
    }

    func updateCenter(_ fr: CGRect) {
        center = CGPoint(x: fr.origin.x + fr.size.width/2,
                         y: fr.origin.y + fr.size.height/2)
    }

    func contains(_ point: CGPoint) -> Bool {
        center.distance(point) < Layout.diameter
    }

    /// evenly space branches leading up to current branch's position
    func refreshBranch() {

        superSpotlight()
        branchVm.expandBranch()
        branchVm.treeVm.refreshTree(branchVm)
    }

    func refreshStatus() {

        var before = [MuNodeVm]()
        var after = [MuNodeVm]()

        func deepBefore(_ nodeVm: MuNodeVm?) {
            if let nodeVm {
                deepBefore(nodeVm.prevNodeVm)
                before.append(nodeVm)
            }
        }
        func deepAfter(_ nodeVm: MuNodeVm) {
            if let nodeVm = nodeVm.nextBranchVm?.nodeSpotVm {
                after.append(nodeVm)
                deepAfter(nodeVm)
            }
        }
        deepBefore(self)
        deepAfter(self)
        MuStatusVm.shared.update(before: before, after: after)
    }

    func refreshView() {
        editing = editing
    }

    /// reset leaf to default value
    func maybeTapLeaf() {
        if nodeType.isLeaf,
           let leafVm = self as? MuLeafVm,
           let nodeProto = leafVm.nodeProto {

            nodeProto.resetDefault()
            leafVm.refreshValue()
            refreshView()
        }
    }
    /// update all descendants
    func tapAllDescendants() {
        maybeTapLeaf()
        for nodeVm in nextBranchVm?.nodeVms ?? [] {
            nodeVm.tapAllDescendants()
        }
    }
    /// update only chain of spotlight nodes
    func tapSpotlights() {
        maybeTapLeaf()
        nextBranchVm?.nodeSpotVm?.tapSpotlights()
    }
    /// handle repeated touchBegin counts on self
    func touching(_ touchState: MuTouchState) {

        let timeDelta = touchState.timeBegin - myTouchBeginTime
        if timeDelta < touchState.tapThreshold {
            myTouchBeginCount += 1
        } else {
            myTouchBeginCount = 0
        }
        myTouchBeginTime = touchState.timeBegin
        switch myTouchBeginCount {
            case 0: break
            case 1: tapSpotlights()
            case 2,3: tapAllDescendants() 
            default: return
        }
        print("(\(touchState.touchBeginCount),\(myTouchBeginCount))", terminator: "  ")
    }
}

