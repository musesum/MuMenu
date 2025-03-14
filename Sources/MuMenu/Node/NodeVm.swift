// created by musesum on 10/17/21.

import SwiftUI
import MuFlo // strHash
import MuVision // Chiral

public class NodeVm: Identifiable, ObservableObject {

    public static var IdNode = [Int: NodeVm]()

    public let menuTree: MenuTree /// maybe shared on other branches
    public var nodeType: NodeType /// node, val, vxy, seg, tog
    public var branchVm: BranchVm /// branch that this node is on
    public var center = CGPoint.zero /// current center position

    internal var nextBranchVm: BranchVm? /// branch this node generates
    internal var panelVm: PanelVm        /// the panel that this node belongs to
    private var prevNodeVm: NodeVm?     /// parent nodeVm in hierarchy
    internal var rootVm: RootVm
    private var chiral: Chiral

    @Published var refresh: Int = 0
    @Published var zIndex: CGFloat = 0 /// stack current spotlight node on top of others
    @Published var origin = true

    /// publish when selected or is under cursor
    @Published var _spotlight: Bool = false
    var spotlight: Bool {
        get { self._spotlight }
        set { _spotlight = newValue
            if let spotFlo = menuTree.chiralSpot[chiral]  { 
                let oldVal: Double = spotFlo.val("on") ?? -1
                let newVal: Double = newValue ? 1 : 0
                if oldVal != newVal {
                    //DebugLog { P("🔦 \(spotFlo.path(99))(on \(newVal.digits(0)))") }
                    spotFlo.setVal("on", newVal, .sneak)
                }
            }
        }
    }

    func spot(on: Bool) {
        if on == spotlight { return }
        if on == true { menuTree.touch() }
    }



    public var nodeHash: Int {
        let id = menuTree.path.strHash()
        NodeVm.IdNode[id] = self
        return id
    }

    public var nodeVmPath: [NodeVm] {
        var path = [NodeVm]()
        if let prevNodeVm {
            path.append(contentsOf: prevNodeVm.nodeVmPath)
        }
        path.append(self)
        return path
    }

    public func treeTitle() -> String { menuTree.title  }
    public func leafTitle() -> String { "" }

    public init (_ menuTree: MenuTree, // shared Menu Model
                 _ branchVm: BranchVm,
                 _ prevVm: NodeVm?) {
        
        self.menuTree = menuTree
        self.rootVm = branchVm.treeVm.rootVm
        self.nodeType = menuTree.nodeType
        self.branchVm = branchVm
        self.chiral = branchVm.chiral
        self.prevNodeVm = prevVm

        self.panelVm = PanelVm(branchVm  : branchVm,
                               menuTrees : [menuTree],
                               treeVm    : branchVm.treeVm,
                               columns   : 1)

        prevVm?.nextBranchVm = branchVm
    }
    
    func copy() -> NodeVm {
        let nodeVm = NodeVm(menuTree, branchVm, self)
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
    
    func updateCenter(_ frame: CGRect) {
        center = CGPoint(x: frame.origin.x + frame.size.width/2,
                         y: frame.origin.y + frame.size.height/2)
    }
    
    func contains(_ point: CGPoint) -> Bool {
        center.distance(point) < (Layout.radius + Layout.padding)
    }
    
    /// evenly space branches leading up to current branch's position
    func refreshBranch() {
        superSpotlight()
        branchVm.expandBranch()
    }

    func refreshView() {
        Task { @MainActor in
            refresh += 1 // animated tween via published edit var
            branchVm.show = branchVm.show
        }
    }

    func lastShownNodeVm() -> NodeVm? {
        return branchVm.treeVm.branchVms.last?.nodeSpotVm
    }

    func tapLeaf() {
        PrintLog("tap: \(nodeType.description)")
    }

    func touchedOrigin() {
        rootVm.endAutoHide(false)
        switch nodeType {
        case .xy, .xyz: update(withPrior: true)
        default:        update(withPrior: false)
        }
        func update(withPrior: Bool) {
            guard let exprs = menuTree.model˚.exprs else { return }
            let visit = Visitor(0, .user)
            let state = menuTree.model˚.scalarState

            if origin { // button showing O for origin
                if state.onOrigin {
                    if state.hasPrior {
                        // moved from prior to origin to revert prior
                        exprs.setPrior(visit)
                        origin = false
                    } else {
                        // ignore button when on origin and no prior
                    }
                } else if state.offOrigin {
                    // this should never happen, return to origin
                    exprs.setOrigin(visit)
                    origin = true
                } else if state.hasPrior {
                    exprs.setPrior(visit)
                    origin = false
                }
            } else { // showing ∆ for delta
                if state.onOrigin {
                    exprs.setOrigin(visit)
                    origin = true
                } else if state.offOrigin {
                    // this should never happen, return to origin
                    exprs.setOrigin(visit)
                    origin = true
                } else if state.hasPrior {
                    exprs.setPrior(visit)
                    origin = true
                }
            }
        }
    }
}

extension NodeVm: Equatable {
    public static func == (lhs: NodeVm, rhs: NodeVm) -> Bool {
        return lhs.nodeHash == rhs.nodeHash
    }

}
