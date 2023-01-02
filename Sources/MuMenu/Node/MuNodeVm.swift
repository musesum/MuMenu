// Created by warren on 10/17/21.

import SwiftUI
import Par // strHash

public class MuNodeVm: Identifiable, Equatable, ObservableObject {

    public static func == (lhs: MuNodeVm, rhs: MuNodeVm) -> Bool { return lhs.hash == rhs.hash }
    
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

    public let node: MuNode /// each model MuNode maybe on several MuNodeVm's
    public var nodeType: MuMenuType  /// node, val, vxy, seg, tog, tap

    var panelVm: MuPanelVm    /// the panel that this node belongs to
    public var branchVm: MuBranchVm  /// branch that this node is on
    var nextBranchVm: MuBranchVm? /// branch this node generates
    var prevNodeVm: MuNodeVm?     /// parent nodeVm in hierarchy
    
    var myTouchBeginTime = TimeInterval(0)
    var myTouchBeginCount = 0
    lazy var rootVm: MuRootVm = { branchVm.treeVm.rootVm! } ()

    public var center = CGPoint.zero /// current position

    /// path and hash get updated through MuNodeDispatch::bindDispatch
    lazy var path: String? = {
        var path = ""
        if let corner = branchVm.treeVm.rootVm?.corner {
            path = corner.str() + "."
        } else {
            print("⁉️ MuNodeVm rootVm corner")
        }
        if let nodePath = node.path {
            path += nodePath
        }else {
            print("⁉️ MuNodeVm.node.path == nil")
        }
        return path
    }()

    public lazy var hash: Int = {
        path?.strHash() ?? -1
    }()

    public lazy var nodeVmPath: [MuNodeVm] = {
        var path = [MuNodeVm]()
        if let prevNodeVm {
            path.append(contentsOf: prevNodeVm.nodeVmPath)
        }
        path.append(self)
        return path
    }()
    

    public init (_ node: MuNode,
                 _ branchVm: MuBranchVm,
                 _ prevVm: MuNodeVm?) {
        
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
    
    func containsPoint(_ point: CGPoint) -> Bool {
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

    func lastShownNodeVm() -> MuNodeVm? {
        return branchVm.treeVm.branchVms.last?.nodeSpotVm
    }

}

