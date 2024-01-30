// created by musesum on 10/17/21.

import SwiftUI
import MuFlo // strHash


public class NodeVm: Identifiable, ObservableObject {
    public static var IdNode = [Int: NodeVm]()

    /// publish changing value of leaf (or order of node, later)
    @Published var editing: Bool = false
    
    /// publish when selected or is under cursor
    @Published var spotlight = false

    /// stack current spotlight node on top of others
    @Published var zIndex: CGFloat = 0

    func spot(on: Bool) {
        if on == spotlight { return }
        if on == true { node.touch() }
    }

    public let node: FloNode       /// maybe shared on other branches
    public var nodeType: NodeType  /// node, val, vxy, seg, tog, tap
    public var branchVm: BranchVm  /// branch that this node is on

    var nextBranchVm: BranchVm? /// branch this node generates
    var panelVm: PanelVm        /// the panel that this node belongs to
    var prevNodeVm: NodeVm?     /// parent nodeVm in hierarchy
    
    var myTouchBeginTime = TimeInterval(0)
    var myTouchBeginCount = 0
    var myTouchEndedTime = TimeInterval(0)
    var myTouchEndedCount = 0
    var rootVm: RootVm

    public var center = CGPoint.zero /// current position

    /// path and hash get updated through MuNodeDispatch::bindDispatch
    public lazy var path: String? = {
        var path = ""
        let corner = rootVm.cornerOp

        if let nodePath = node.path {
            path += nodePath
        } else {
            print("⁉️ MuNodeVm.node.path == nil")
        }
        return path
    }()

    public lazy var hash: Int = {
        let id = path?.strHash() ?? -1
        NodeVm.IdNode[id] = self
        return id
    }()

    public lazy var nodeVmPath: [NodeVm] = {
        var path = [NodeVm]()
        if let prevNodeVm {
            path.append(contentsOf: prevNodeVm.nodeVmPath)
        }
        path.append(self)
        return path
    }()
    

    public init (_ node: FloNode,
                 _ branchVm: BranchVm,
                 _ prevVm: NodeVm?) {
        
        self.node = node
        self.rootVm = branchVm.treeVm.rootVm
        self.nodeType = node.nodeType
        self.branchVm = branchVm
        self.prevNodeVm = prevVm
        self.panelVm = PanelVm(nodes: [node],
                                 treeVm: branchVm.treeVm)

        prevVm?.nextBranchVm = branchVm
    }
    
    func copy() -> NodeVm {
        let nodeVm = NodeVm(node, branchVm, self)
        return nodeVm
    }
    
    /// spotlight self, parent, grand, etc. in branch
    func superSpotlight() {
        
        branchVm.nodeSpotVm?.spotlight = false
        branchVm.nodeSpotVm = self
        branchVm.show = true
        spotlight = true
        
        prevNodeVm?.superSpotlight()
    }
    
    func updateCenter(_ fr: CGRect) {
        center = CGPoint(x: fr.origin.x + fr.size.width/2,
                         y: fr.origin.y + fr.size.height/2)
    }
    
    func containsPoint(_ point: CGPoint) -> Bool {
        center.distance(point) < (Layout.radius + Layout.padding)
    }
    
    /// evenly space branches leading up to current branch's position
    func refreshBranch() {
        
        superSpotlight()
        branchVm.expandBranch()
    }

    func refreshView() {
        editing = editing
        branchVm.show = branchVm.show
    }

    func lastShownNodeVm() -> NodeVm? {
        return branchVm.treeVm.branchVms.last?.nodeSpotVm
    }
}

extension NodeVm: Equatable {
    public static func == (lhs: NodeVm, rhs: NodeVm) -> Bool {
        return lhs.hash == rhs.hash
    }

}
