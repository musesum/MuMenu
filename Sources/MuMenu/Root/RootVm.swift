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
    public var cornerOp: CornerOp /// corner where root begins, ex: `[south,west]`
    var treeVms = [TreeVm]() /// vertical or horizontal stack of branches
    var treeSpotVm: TreeVm? /// most recently used tree
    var rootOffset: CGSize = .zero

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
            let menuItem = MenuItem(node: nodeItem, cornerOp, phase)
            sendItemToPeers(menuItem)
        }
    }

    public init(_ cornerOp: CornerOp,
                _ archiveVm: ArchiveVm,
                _ peers: Peers) {

        self.cornerOp = cornerOp
        self.cornerVm = CornerVm(cornerOp)
        self.archiveVm = archiveVm
        self.peers = peers
        peers.setDelegate(self, for: .menu)
    }

    deinit {
        peers.removeDelegate(self)
    }

    public func updateTreeVms(_ treeVm: TreeVm) {
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

        switch cornerOp {
            case [.lower, .right]: v(-x0,-y1); h(-x1,-y0); r(0, 0)
            case [.lower, .left ]: v( x0,-y1); h( x1,-y0); r(0, 0)
            case [.upper, .right]: v(-x0, y1); h(-x1, y0); r(0, 0)
            case [.upper, .left ]: v( x0, y1); h( x1, y0); r(0, 0)
            default: break
        }
        rootOffset = rs
        for treeVm in treeVms {
            treeVm.treeOffset = (treeVm.isVertical ? vs : hs)
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
        case .pad    : h = cornerOp.lower ? padding2 : 0
        case .phone  : h = cornerOp.upper ? padding2 : 0
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
        
        switch cornerOp {
            case [.lower, .right]: return CGPoint(x: w-x-r-s, y: h-y-r-s)
            case [.lower, .left ]: return CGPoint(x:   x+r+s, y: h-y-r-s)
            case [.upper, .right]: return CGPoint(x: w-x-r-s, y:   y+r+s)
            case [.upper, .left ]: return CGPoint(x:   x+r+s, y:   y+r+s)
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
    internal func touchBegin(_ touchState: TouchState, _ fromRemote: Bool) {

        self.touchState = touchState
        beginViewOps = viewOps
        updateRoot(fromRemote)
        if let nodeSpotVm {
            updateSpot(nodeSpotVm, fromRemote)
        }
        touchTypeBegin = touchType
        endAutoHide(fromRemote)
    }
    internal func touchMoved(_ touchState: TouchState, _ fromRemote: Bool) {

        self.touchState = touchState
        updateRoot(fromRemote)
    }
    internal func touchEnded(_ touchState: TouchState, _ fromRemote: Bool) {
        
        self.touchState = touchState
        startAutoHide(fromRemote)
        updateRoot(fromRemote)
        
        /// turn off spotlight for leaf after edit
        /// keep on for .tog, .tap so that double tapping on root will repeat
        if let nodeSpotVm {
            if nodeSpotVm.nodeType.isControl {
                nodeSpotVm.spotlight = false
            }
        }
        treeSpotVm?.branchSpotVm = nil
        touchType = .none

        if !fromRemote, let nodeSpotVm {
            let nodeItem = MenuNodeItem(nodeSpotVm)
            let menuItem = MenuItem(node: nodeItem, cornerOp, touchState.phase)
            sendItemToPeers(menuItem)
        }

    }
    public func startAutoHide(_ fromRemote: Bool) {
        #if os(visionOS)
        #else
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: autoHideInterval, repeats: false) { timer in
            self.hideBranches(.none, fromRemote)
        }
        #endif
    }
    public func endAutoHide(_ fromRemote: Bool) {
        autoHideTimer?.invalidate()
        reshowTree(fromRemote)
    }
    private func updateRoot(_ fromRemote: Bool) {

        let touchNow = touchState.pointNow

        // stay exclusively on .leaf or .edit mode
        switch touchType {
            case .canopy : logRoot("􀝰"); return shiftCanopy()
            case .shift  : logRoot("􀝰"); return shiftBranches()
            case .leaf   : logRoot("􀝰"); return editLeaf(nodeSpotVm)
            case .tog    : logRoot("􀝰"); return editTog(nodeSpotVm)
            default      : break
        }

        if      hoverNodeSpot() { logRoot("N") } // over the same branch node
        else if hoverRootNode() { logRoot("R") } // over the root (home) node
        else if hoverTreeNow()  { logRoot("T") } // new node on same tree
        else if hoverTreeAlts() { logRoot("A") } // alternate tree
        else {  hoverSpace()    ; logRoot("S") } // hovering over canvas

        func logRoot(_ s: String = "") {
            //MuLog.RunPrint( touchType.symbol+s, terminator: " ")
        }

        // ⓝL
        func hoverLeafNode() -> Bool {
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

        func hoverNodeSpot() -> Bool {

            if let center = nodeSpotVm?.center,
               center.distance(touchNow) < Layout.insideNode {

                if hoverLeafNode() {
                    // touchType set of .leaf or .tog
                } else {
                    touchType = .node
                    if touchState.touchEndedCount == 2 {
                        nodeSpotVm?.tapNode(touchState)
                    }
                }
                return true
            }
            return false
        }
        func hoverRootNode() -> Bool {

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
                nodeSpotVm?.tapNode(touchState)

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
        func hoverTreeNow() -> Bool {
            for treeVm in treeVms {
                
                if let branchVm = treeVm.nearestBranch(touchNow),
                   let nodeVm = branchVm.nearestNode(touchNow) {

                    updateTreeSpot(treeVm, nodeVm, "tree")

                    if hoverLeafNode() {
                        // already set touchElement
                    } else if !viewOps.contains(.branch) {

                        viewOps = [.root,.branch]
                        touchType = .branch
                    }
                    return true
                }
            }
            if touchState.phase == .began {
                for treeVm in treeVms {
                    if treeVm.treeBoundsPad.contains(touchNow) {
                        nodeSpotVm = nil
                        treeSpotVm = treeVm
                        shiftCanopy()
                        return true
                    }
                }
            }
            return false
        }
        func updateTreeSpot(_ treeVm: TreeVm,
                            _ nearestNode: NodeVm,
                            _ via: String) {

            treeSpotVm = treeVm // set new tree
            
            for treeVm in treeVms {
                if treeVm == treeSpotVm {
                    treeVm.showTree(depth: 9, via+"+", fromRemote)
                } else {
                    treeVm.showTree(depth: 0, via+"-", fromRemote)
                }
            }
            updateSpot(nearestNode, fromRemote)
        }
        func hoverTreeAlts() -> Bool {
            // hovering over hidden trunk of another tree?
            for treeVm in treeVms {
                if treeVm != treeSpotVm,
                   let nearestTrunk = treeVm.nearestTrunk(touchNow),
                   let nearestNode = nearestTrunk.nearestNode(touchNow) {
                    
                    updateTreeSpot(treeVm, nearestNode, "alt")
                    
                    viewOps = [.root,.branch]
                    touchType = .branch
                    return true
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
                showSoloTree(fromRemote)
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
    func showSoloTree(_ fromRemote: Bool) {
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
