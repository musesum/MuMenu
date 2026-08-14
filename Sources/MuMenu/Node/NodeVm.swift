// created by musesum on 10/17/21.

import SwiftUI
import MuFlo // strHash
#if !os(watchOS)
import MuVision // Chiral
#endif

@MainActor
public class NodeVm: Identifiable, ObservableObject {

    public let menuTree: MenuTree /// maybe shared on other branches
    public var nodeType: NodeType /// node, val, vxy, seg, tog
    public var branchVm: BranchVm /// branch that this node is on
    public var center = CGPoint.zero /// current center position
    public var menuType: MenuType

    internal var nextBranchVm: BranchVm? /// branch this node generates
    internal var panelVm: PanelVm        /// the panel that this node belongs to
    private var prevNodeVm: NodeVm?     /// parent nodeVm in hierarchy
    public internal(set) var rootVm: RootVm

    @Published var refresh: Int = 0
    @Published var zIndex: CGFloat = 0 /// stack current spotlight node on top of others
    @Published var origin = true

    @Published public var _spotlight: Bool = false /// publish when selected or is under cursor
    public var spotlight: Bool {
        get { self._spotlight }
        set { _spotlight = newValue
            if let spotFlo = menuTree.chiralSpot[menuType.chiral]  {
                let oldVal: Double = spotFlo.val("on") ?? -1
                let newVal: Double = newValue ? 1 : 0
                if oldVal != newVal {
                    //DebugLog { P("🔦 \(spotFlo.path(99))(on \(newVal.digits(0)))") }
                    spotFlo.setNameNums([("on", newVal)], .sneak, Visitor(0))
                }
            }
        }
    }

    func spot(on: Bool) {
        if on == spotlight { return }
        if on == true { menuTree.flo.updateTime() }
    }

    public var nodeHash: Int {
        return Int(menuTree.path.strHash())
    }

    public var nodeVmPath: [NodeVm] {
        var path = [NodeVm]()
        if let prevNodeVm {
            path.append(contentsOf: prevNodeVm.nodeVmPath)
        }
        path.append(self)
        return path
    }

    /// If this node is the sole parent of a single leaf child, return that
    /// leaf. Used by watch lift-tap: landing on a non-leaf node that has
    /// exactly one leaf child is treated as landing on the leaf itself.
    public var soleChildLeaf: LeafVm? {
        guard let next = nextBranchVm,
              next.nodeVms.count == 1,
              let leaf = next.nodeVms.first as? LeafVm else {
            return nil
        }
        return leaf
    }

    public func treeTitle() -> String { menuTree.flo.name  }
    public func leafTitle() -> String { "" }

    /// a shown leaf may pin its tree open, opting out of the fade timers
    public var disablesAutoFade: Bool { false }

    public init (_ menuTree: MenuTree, // shared Menu Model
                 _ branchVm: BranchVm,
                 _ prevVm: NodeVm?) {

        self.menuTree = menuTree
        self.rootVm = branchVm.treeVm.rootVm
        self.nodeType = menuTree.nodeType
        self.branchVm = branchVm
        self.menuType = branchVm.treeVm.menuType
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
        #if os(watchOS)
        // Value-bearing leaves (val/xy/xyz/seg) render their actual panel
        // views on watchOS now — those panels are 39–71pt wide, far larger
        // than the legacy Menu.diameter (13pt) radius the iOS check uses.
        // Use the panel's full bounds so a touch anywhere on the rendered
        // leaf registers as "on this node".
        let panelSize = panelVm.innerPanel(.none)
        let halfW = panelSize.width  / 2 + Menu.padding
        let halfH = panelSize.height / 2 + Menu.padding
        let dx = abs(point.x - center.x)
        let dy = abs(point.y - center.y)
        return dx <= halfW && dy <= halfH
        #else
        return center.distance(point) < (Menu.radius + Menu.padding)
        #endif
    }
    
    /// evenly space branches leading up to current branch's position
    public func refreshBranch() {
        superSpotlight()
        branchVm.expandBranch()
    }
    public func refreshView() {
        objectWillChange.send()
        refresh += 1 // animated tween via published edit var
        branchVm.show = branchVm.show
    }

    /// was touchedOrigin()
    func updateNodeValue(_ visit: Visitor = Visitor(0,.user)) {
        rootVm.showTrees(/* fromRemote */ false)

        switch nodeType {
        case .xy, .xyz, .xyzw : update(withPrior: true)
        case .val, .seg : updateDefault()
        default         : update(withPrior: false)
        }
        if visit.isLocal(), let leafVm = self as? LeafVm {
            leafVm.runways.setThumbFlo(menuTree.flo)
            leafVm.updateLeafPeers(visit)
        }
        func updateDefault() {
            menuTree.flo.activate([], Visitor(0, .user))
        }
        func update(withPrior: Bool) {
            guard let exprs = menuTree.flo.exprs else { return }
            let visit = Visitor(0, .user)
            let state = menuTree.flo.scalarState

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

extension NodeVm: @MainActor Equatable {
    public static func == (lhs: NodeVm, rhs: NodeVm) -> Bool {
        return lhs.nodeHash == rhs.nodeHash
    }
}
extension NodeVm { // + Spotlight

    /// update only chain of spotlight nodes
    public func updateSpotNodes() {
        if let childSpot = nextBranchVm?.nodeSpotVm {
           childSpot.updateSpotNodes()
        } else {
            updateNodeValue()
        }
    }
}

#if false
extension NodeVm { // log visitor
    static public func logVisits(_ visitor: Visitor) {
        for visit in visitor.visited {
            if let any = FloIdAny[visit] {
                switch any {
                case let flo as Flo:  print ("\(visit): Flo \(flo.name)")
                case let nodeVm as NodeVm:  print ("\(visit): NodeVm \(nodeVm.treeTitle()))")
                case let pipeNode as PipeNode:  print ("\(visit): PipeNode \(pipeNode.pipeNode˚.name)")
                case let edge as MuFlo.Edge:  print ("\(visit): Edge \(edge.script())")
                case let exprs as Exprs:  print ("\(visit): Exprs \(exprs.name)")
                default : print ("\(visit): ??")
                }
            }
        }
    }
}
#endif
