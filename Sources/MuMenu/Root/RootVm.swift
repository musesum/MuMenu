// created by musesum 10/13/21.

import SwiftUI
import MuPeers
import MuFlo
import MuVision

public class RootVm: @unchecked Sendable, ObservableObject, Equatable {

    public static func == (lhs: RootVm, rhs: RootVm) -> Bool { return lhs.id == rhs.id }
    let id = Visitor.nextId()
    let archiveVm: ArchiveVm
    let peers: Peers

    /// is the finger touching

    @Published var touchType = TouchType.none
    var touchTypeBegin = TouchType.none
    /// captures touch events to dispatch to this root
    public let cornerVm: CornerVm!
    
    /// which menu elements are shown on View
    var viewOps: Set<TouchType> = [.root, .trunks]
    
    /// `touchBegin` snapshot of viewElements.
    /// To prevent touchEnded from hiding elements that were shown during `touchBegin`
    var beginViewOps: Set<TouchType> = []
    
    public var menuOp: MenuOp /// corner where root begins, ex: `[south,west]`
    var treeVms = [TreeVm]() /// vertical or horizontal stack of branches
    var treeSpotVm: TreeVm? /// most recently used tree
    var rootOffset: CGSize = .zero

    var autoHideMenu = true
    var autoHideTimer: Timer?
    var autoHideInterval = TimeInterval(12)
    var touchState = TouchState()

    public var nodeSpotVm: NodeVm?   /// current last touched or hovered node

    /// update tree from new spot
    func updateSpot(_ newSpotVm: NodeVm,
                    _ fromRemote: Bool) {

        self.nodeSpotVm = newSpotVm
        newSpotVm.refreshBranch()
        newSpotVm.branchVm.treeVm.showTree("branch", fromRemote)
        if !fromRemote {
            let phase = touchState.phase
            let nodeItem = MenuNodeItem(newSpotVm)
            let menuItem = MenuItem(node: nodeItem, menuOp, phase)
            sendItemToPeers(menuItem)
        }
    }

    public init(_ menuOp: MenuOp,
                _ archiveVm: ArchiveVm,
                _ peers: Peers) {

        self.menuOp = menuOp
        self.cornerVm = CornerVm(menuOp)
        self.archiveVm = archiveVm
        self.peers = peers
        peers.setDelegate(self, for: .menuFrame)
    }
    deinit {
        peers.removeDelegate(self)
    }
    public func addTreeVm(_ treeVm: TreeVm) {
        self.treeVms.append(treeVm)
        cornerVm.setRoot(self)
        updateTreeOffsets()
    }
    private func updateTreeOffsets() {

        let margins = idiomMargins()
        // xy top left to bottom right corners
        let x0 = margins.width
        let y0 = margins.height
        let x1 = x0 + Layout.diameter + Layout.padding * 3
        let y1 = y0 + Layout.diameter + Layout.padding * 3

        // setup vertical, horizontal, and root offsets
        var vs = CGSize.zero // vertical offset
        var hs = CGSize.zero // horizontal offset
        var rs = CGSize.zero // root icon offset
        func v(_ w:CGFloat,_ h:CGFloat) { vs = CGSize(width:w,height:h) }
        func h(_ w:CGFloat,_ h:CGFloat) { hs = CGSize(width:w,height:h) }
        func r(_ w:CGFloat,_ h:CGFloat) { rs = CGSize(width:w,height:h) }

        switch menuOp.corner {
        case .downRight: v(-x0,-y1); h(-x1,-y0); r(0, 0)
        case .downLeft: v( x0,-y1); h( x1,-y0); r(0, 0)
        case .upRight: v(-x0, y1); h(-x1, y0); r(0, 0)
        case .upLeft: v( x0, y1); h( x1, y0); r(0, 0)
        default: break
        }
        rootOffset = rs
        for treeVm in treeVms {
            treeVm.treeOffset = (treeVm.trunk.menuOp.vertical ? vs : hs)
        }
    }
    private func idiomMargins() -> CGSize {
        let idiom = UIDevice.current.userInterfaceIdiom
        let padding2 = Layout.padding2

        let w: CGFloat
        switch idiom {
        case .pad    : w = padding2
        case .phone  : w = 0
        case .vision : w = padding2 * 2
        default      : w = 0
        }

        let h: CGFloat
        switch idiom {
        case .pad    : h = menuOp.down ? padding2 : 0
        case .phone  : h = menuOp.up   ? padding2 : 0
        case .vision : h = padding2 * 2
        default      : h = 0
        }
        return CGSize(width: w, height: h)
    }
    internal func cornerXY(in frame: CGRect) -> CGPoint {

        let margins = idiomMargins()
        let x = margins.width
        let y = margins.height

        let w = frame.size.width
        let h = frame.size.height
        let s = Layout.padding
        let r = Layout.diameter / 2
        
        switch menuOp.corner {
        case .downRight: return CGPoint(x: w-x-r-s, y: h-y-r-s)
        case .downLeft : return CGPoint(x:   x+r+s, y: h-y-r-s)
        case .upRight: return CGPoint(x: w-x-r-s, y:   y+r+s)
        case .upLeft: return CGPoint(x:   x+r+s, y:   y+r+s)
        default: return .zero
        }
    }
    internal func hitTest(_ point: CGPoint) -> NodeVm? {
        for treeVm in treeVms {
            if treeVm.treeBoundsPad.contains(point) {
                for branchVm in treeVm.branchVms {
                    if branchVm.show, branchVm.contains(point) {
                        if let nodeVm =  branchVm.nearestNode(point) {
                            return nodeVm
                        }
                    }
                }
                if let nodeVm = treeVm.branchSpotVm?.nodeSpotVm {
                    return nodeVm
                }
            }
        }
        return nil
    }
    
    internal func updateRoot(_ fromRemote: Bool) {

        let touchNow = touchState.pointNow

        // stay exclusively on .leaf or .edit mode
        switch touchType {
        case .canopy : logRoot("shift Canopy"); return shiftCanopy()
        case .shift  : logRoot("shift Branch"); return shiftBranches()
        case .leaf   : logRoot("edit Leaf"   ); return editLeaf(nodeSpotVm)
        case .tog    : logRoot("edit Tog"    ); return editTog(nodeSpotVm)
        default      : break // logRoot(menuOp.description)
        }
        if      touchLeaf() { logRoot("touch Leaf 🍁") } // new node on same tree
        else if hoverLeaf() { logRoot("hover Leaf 🍁") } // new node on same tree
        else if hoverSpot() { logRoot("hover Node ⚪️") } // over the spot node
        else if hoverRoot() { logRoot("hover Root 🫚") } // over the root node

        else if hoverTree() { logRoot("hover Tree 🌳") } // new node on same tree
        else if hoverAlt()  { logRoot("hover Alt  🌴") } // alternate tree
        else {  hoverSpace(); logRoot("hover Space 🪐") } // hovering over canvas

        func logRoot(_ msg: String = "",_ t: String = "") {
            let symbol = touchType.symbol

            //if ["􀄭"].contains(symbol) { return }

            MuLog.TimeLog(symbol, interval: 1) {
                P("\(symbol)  \(msg)")
            }
        }

        func touchLeaf() -> Bool {
            if touchState.phase == .began,
               let treeSpotVm,
               let branchVm = treeSpotVm.nearestBranch(touchNow),
               let leafVm = branchVm.nearestNode(touchNow) as? LeafVm {

                nodeSpotVm = leafVm
                updateTreeSpot(treeSpotVm, leafVm, "leaf") //....
                shiftCanopy()
                return true
            }
            return false
        }
        func hoverLeaf() -> Bool {
            guard let leafVm = nodeSpotVm as? LeafVm else { return false }

            if leafVm.runways.contains(touchNow) {

                if touchState.phase == .ended,
                   leafVm.nodeType == .tog {
                    editTog(leafVm)
                    return true
                }
                else if touchState.phase == .began {
                    updateTreeSpot(leafVm.branchVm.treeVm, leafVm, "edit")
                    if leafVm.nodeType.isControl {
                        editLeaf(leafVm)
                    }
                    return true
                }
            }
            if leafVm.nodeType.isControl,
               touchType.isNotIn([.node, .space]),
               leafVm.branchVm.contains(touchNow) {
                
                updateTreeSpot(leafVm.branchVm.treeVm, leafVm, "shift")
                shiftBranches() // inside branch containing runway
                return true
            }
            return false
        }

        func hoverSpot() -> Bool {
            if let center = nodeSpotVm?.center,
               center.distance(touchNow) < Layout.insideNode {

                touchType = .node
                if touchState.touchEndedCount == 2 {
                    nodeSpotVm?.updateSpotNodes()
                }
                return true
            }
            return false
        }
        func hoverRoot() -> Bool {

            if !cornerVm.touchingRoot(touchNow) {
                if touchTypeBegin == .root {
                    // when dragging root over branches, expand tree
                    treeSpotVm?.shiftExpandLast(fromRemote)
                    // do this only once
                    touchTypeBegin = .none
                }
                return false
            }

            switch touchState.touchEndedCount {
            case 1:
                touchType = .none
                let wasShown = beginViewOps.hasAny([.branch,.trunks])
                if  wasShown { hideBranches(.root, fromRemote) }
                else         { spotBranches() }
            case 2:
                let wasShown = beginViewOps.hasAny([.branch,.trunks])
                if  wasShown { spotBranches() }
                nodeSpotVm?.updateSpotNodes()

            default:
                if touchType != .root {
                    touchType = .root
                    let isShowing = viewOps.hasAny([.branch,.trunks])
                    if  isShowing { showTrunks() }
                    else          { spotBranches() }
                }
            }
            return true
        }

        func hoverTree() -> Bool {

            if let treeSpotVm,
               let branchVm = treeSpotVm.nearestBranch(touchNow),
               let nodeVm = branchVm.nearestNode(touchNow) {
                updateTreeSpot(treeSpotVm, nodeVm, "tree")
                return true
            }
            return false
        }
        func updateTreeSpot(_ treeVm: TreeVm,
                            _ nearestNode: NodeVm,
                            _ via: String) {

            treeSpotVm = treeVm // set new tree
            
            for treeVm in treeVms {
                if treeVm == treeSpotVm {
                    treeVm.showTree(depth: 9, via + "+", fromRemote)
                } else {
                    treeVm.showTree(depth: 0, via + "-", fromRemote)
                }
            }
            updateSpot(nearestNode, fromRemote)
        }
        func hoverAlt() -> Bool {
            // hovering over hidden trunk of another tree?
            for treeVm in treeVms {
                if treeVm != treeSpotVm {
                    if let branchVm = treeVm.branchVms.first,
                       branchVm.contains(touchNow),
                       let nearestNode = branchVm.nearestBranchNode(touchNow) {
                        updateTreeSpot(treeVm, nearestNode, "alt")
                        viewOps = [.root,.branch]
                        touchType = .branch
                        return true
                    }
                }
            }
            return false
        }
        
        //  MARK: - show/hide/stack
        
        func hoverSpace() {
            touchType = .space
            if let leafVm = nodeSpotVm as? LeafVm {
                leafVm.branchVm.treeVm.showTree(start: 0, depth: 9, "space", fromRemote)
            }
        }
        
        func shiftBranches() {
            if cornerVm.touchingRoot(touchNow) {
                showTrunks()
                touchType = .root
                return
            }
            if let leafVm = nodeSpotVm as? LeafVm  {

                // begin touch on title section to possibly stack branches
                touchType = .shift
                leafVm.spot(.off)
                leafVm.branchSpot(.on)
                treeSpotVm?.shiftTree(touchState, fromRemote)
            } else {
                touchState.beginPoint(touchNow)
                touchType = .root
            }
        }

        func shiftCanopy() {
            if touchState.phase.done {
                treeSpotVm?.shiftNearest()
                touchType = .root
            } else if cornerVm.touchingRoot(touchNow) {
                showTrunks()
                touchState.beginPoint(touchNow)
                touchType = .root
            } else {
                touchType = .canopy
                treeSpotVm?.shiftTree(touchState, fromRemote)
            }
        }

        // 􁏮􀝰
        func editTog(_ nodeVm: NodeVm?) {
            guard let leafVm = nodeVm as? LeafVm else { return }
            if touchType == .tog,
               !leafVm.runways.contains(touchNow) {
                // have moved off node
                nodeSpotVm = nil
                touchType = .none
                return
            } else {
                touchType = .tog
            }
            leafVm.touchLeaf(touchState, Visitor(0, .user))
        }
        // 􀥲􀝰
        func editLeaf(_ nodeVm: NodeVm?) {
            guard let leafVm = nodeVm as? LeafVm else { return }
            touchType = .leaf
            leafVm.touchLeaf(touchState, Visitor(0, .user))
            leafVm.spot(touchState.phase.done ? .off : .on)
            leafVm.branchSpot(.off)
        }
        
        func showTrunks() {
            if treeVms.count == 1 {
                showSoloTree(fromRemote: true)
            } else {
                for treeVm in treeVms {
                    treeVm.showTree(depth: 1, "trunk", fromRemote)
                }
                treeSpotVm = nil
                nodeSpotVm = nil
                viewOps = [.root, .trunks]
            }
        }
        func spotBranches() {
            if let treeSpotVm {
                for treeVm in treeVms {
                    if treeVm == treeSpotVm {
                        treeVm.showTree(depth: 9, "spot+", fromRemote)
                    } else {
                        treeVm.showTree(depth: 0, "spot-", fromRemote)
                    }
                    viewOps = [.root,.branch]
                }
            } else {
                showTrunks()
            }
        }
    }
    func reshowTree(_ fromRemote: Bool) {
        for treeVm in treeVms {
            treeVm.reshowTree(fromRemote)
        }
    }
    func hideBranches(_ touchType: TouchType, _ fromRemote: Bool) {
        autoHideTimer?.invalidate()
        for treeVm in treeVms {
            treeVm.hideTree(touchType, fromRemote)
        }
        viewOps = [.root]
    }
    func showSoloTree(fromRemote: Bool = false) {
        if let treeVm = treeVms.first {
            treeSpotVm = treeVm
            treeVm.showTree(depth: 9, "solo", fromRemote)
            viewOps = [.root,.branch]
        }
    }

}

extension RootVm: PeersDelegate {

    public func didChange() {}

    public func received(data: Data) {

        let decoder = JSONDecoder()
        if let item = try? decoder.decode(MenuItem.self, from: data) {
            MenuTouch.remoteItem(item)
        }
    }

}

