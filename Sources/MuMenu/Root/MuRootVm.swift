// Created by warren 10/13/21.

import SwiftUI
import MuPar // Visitor

public class MuRootVm: ObservableObject, Equatable {
    let id = MuNodeIdentity.getId()
    public static func == (lhs: MuRootVm, rhs: MuRootVm) -> Bool { return lhs.id == rhs.id }
    
    /// what is the finger touching
    @Published var touchType = MuTouchType.none
    var touchTypeBegin = MuTouchType.none
    
    /// captures touch events to dispatch to this root
    public let touchVm: MuTouchVm
    
    /// which menu elements are shown on View
    var viewOps: Set<MuTouchType> = [.root, .trunks]
    
    /// `touchBegin` snapshot of viewElements.
    /// To prevent touchEnded from hiding elements that were shown during `touchBegin`
    var beginViewOps: Set<MuTouchType> = []
    
    var corner: CornerOps        /// corner where root begins, ex: `[south,west]`
    var treeVms = [MuTreeVm]()  /// vertical or horizontal stack of branches
    var treeSpotVm: MuTreeVm?   /// most recently used tree
    var rootOffset: CGSize = .zero
    public var nodeSpotVm: MuNodeVm?   /// current last touched or hovered node

    var peers: PeersController?
    var lastShownBranchVms = [MuBranchVm]() 

    /// update tree from new spot
    func updateSpot(_ newSpotVm: MuNodeVm,
                    _ fromRemote: Bool) {

        self.nodeSpotVm = newSpotVm
        newSpotVm.refreshBranch()
        newSpotVm.branchVm.treeVm.showTree("branch", fromRemote)
        newSpotVm.refreshStatus()

        if !fromRemote {
            let phase = touchState.phase
            let nodeItem = MenuNodeItem(newSpotVm)
            let menuItem = MenuItem(node: nodeItem, corner, phase)
            sendItemToPeers(menuItem)
        }
    }

    public init(_ corner: CornerOps) {
        
        self.corner = corner
        self.touchVm = MuTouchVm(corner)
        self.peers = PeersController.shared
    }
    public func updateTreeVms(_ treeVms: [MuTreeVm]) {
        self.treeVms.append(contentsOf: treeVms)
        touchVm.setRoot(self)
        updateTreeOffsets()
    }
    

    func updateTreeOffsets() {

        // xy top left to bottom right cornders
        let x0 = Layout.padding2
        let y0 = Layout.padding2
        let x1 = x0 + Layout.diameter + Layout.padding * 3
        let y1 = y0 + Layout.diameter + Layout.padding * 3

        // setup vertical, horizontal, and root offsets
        var vs = CGSize.zero // vertical offset
        var hs = CGSize.zero // horizontal offset
        var rs = CGSize.zero // root icon offset
        func v(_ w:CGFloat,_ h:CGFloat) { vs = CGSize(width:w,height:h) }
        func h(_ w:CGFloat,_ h:CGFloat) { hs = CGSize(width:w,height:h) }
        func r(_ w:CGFloat,_ h:CGFloat) { rs = CGSize(width:w,height:h) }

        // corner offsets are different for ipad
        let pad = UIDevice.current.userInterfaceIdiom == .pad

        switch corner {
            case [.lower, .right]: v(-x0,-y1); h(-x1,-y0); pad ? r(0, 0) : r(-x0,-y0)
            case [.lower, .left ]: v( x0,-y1); h( x1,-y0); pad ? r(0, 0) : r( x0,-y0)
            case [.upper, .right]: v(-x0, y1); h(-x1, y0); pad ? r(0,y0) : r(-x0,  0)
            case [.upper, .left ]: v( x0, y1); h( x1, y0); pad ? r(0,y0) : r( x0,  0)
            default: break
        }
        rootOffset = rs
        for treeVm in treeVms {
            treeVm.treeOffset = (treeVm.isVertical ? vs : hs)
        }
    }
    
    func cornerXY(in frame: CGRect) -> CGPoint {
        
        let idiom = UIDevice.current.userInterfaceIdiom
        let margin = 2 * Layout.padding
        let x = (idiom == .pad ? margin : 0)
        let y = ((corner.upper && idiom == .phone) ||
                 (corner.lower && idiom == .pad)) ? margin : 0
        let w = frame.size.width
        let h = frame.size.height
        let s = Layout.padding
        let r = Layout.diameter / 2
        
        switch corner {
            case [.lower, .right]: return CGPoint(x: w-x-r-s, y: h-y-r-s)
            case [.lower, .left ]: return CGPoint(x:   x+r+s, y: h-y-r-s)
            case [.upper, .right]: return CGPoint(x: w-x-r-s, y:   y+r+s)
            case [.upper, .left ]: return CGPoint(x:   x+r+s, y:   y+r+s)
            default: return .zero
        }
    }
    
    func hitTest(_ point: CGPoint) -> MuNodeVm? {
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
    var touchState = MuTouchState()
    
    func touchBegin(_ touchState: MuTouchState,
                    _ fromRemote: Bool) {

        self.touchState = touchState
        beginViewOps = viewOps
        updateRoot(fromRemote)
        if let nodeSpotVm {
            nodeSpotVm.touchBegin(touchState)
            updateSpot(nodeSpotVm, fromRemote)
        }
        touchTypeBegin = touchType
    }
    
    func touchMoved(_ touchState: MuTouchState,
                    _ fromRemote: Bool) {

        self.touchState = touchState
        updateRoot(fromRemote)
    }
    func touchEnded(_ touchState: MuTouchState,
                    _ fromRemote: Bool) {
        
        self.touchState = touchState
        updateRoot(fromRemote)
        
        /// turn off spotlight for leaf after edit
        if let nodeSpotVm, nodeSpotVm.nodeType.isControl {
            nodeSpotVm.spotlight = false
        }
        treeSpotVm?.branchSpotVm = nil
        touchType = .none

        if !fromRemote, let nodeSpotVm {
            let nodeItem = MenuNodeItem(nodeSpotVm)
            let menuItem = MenuItem(node: nodeItem, corner, touchState.phase)
            sendItemToPeers(menuItem)
        }
    }
    func logRoot(_ s: String = "") {
        print(touchType.symbol+s, terminator: "")
    }
    private func updateRoot(_ fromRemote: Bool) {

        let touchNow = touchState.pointNow
        logRoot("")

        // stay exclusively on .leaf or .edit mode
        switch touchType {
            case .canopy : logRoot("􀝰 "); return shiftCanopy()
            case .shift  : logRoot("􀝰 "); return shiftBranches()
            case .leaf   : logRoot("􀝰 "); return editLeaf(nodeSpotVm)
            case .tog    : logRoot("􀝰 "); return editTog(nodeSpotVm)
            default: break
        }


        if      hoverNodeSpot() { logRoot("N ") } // over the same branch node
        else if hoverRootNode() { logRoot("R ") } // over the root (home) node
        else if hoverTreeNow()  { logRoot("T ") } // new node on same tree
        else if hoverTreeAlts() { logRoot("A ") } // alternate tree
        else {  hoverSpace()    ; logRoot("S ") } // hovering over canvas
        
        // log(touchType.symbol, terminator: "")

        // ⓝL
        func hoverLeafNode() -> Bool {

            if let leafVm = nodeSpotVm as? MuLeafVm {

                if touchState.phase == .began,
                   leafVm.runwayBounds.contains(touchNow) {

                    updateTreeSpot(leafVm.branchVm.treeVm, leafVm, "edit")
                    if leafVm.nodeType.isControl { editLeaf(leafVm) }
                    else if leafVm.nodeType.isTog { editTog(leafVm) }
                    return true

                }
                if leafVm.nodeType.isControl,
                   ![.node, .space].contains(touchType),
                   leafVm.branchVm.contains(touchNow) {

                    updateTreeSpot(leafVm.branchVm.treeVm, leafVm, "shift")
                    shiftBranches() // inside branch containing runway
                    return true
                }
                if leafVm.nodeType.isTog {
                    if leafVm.containsPoint(touchNow) {
                        editTog(leafVm)
                    } else if leafVm.branchVm.contains(touchNow) {
                        touchType = .node
                    } else {
                        updateTreeSpot(leafVm.branchVm.treeVm, leafVm, "shift")
                        shiftBranches() // inside branch containing runway
                    }
                    return true
                }
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
                }
                return true
            }
            return false
        }
        func hoverRootNode() -> Bool {

            if !touchVm.touchingRoot(touchNow) {
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
                    if  wasShown { hideBranches() }
                    else         { spotBranches() }
                case 2:
                    let wasShown = beginViewOps.hasAny([.branch,.trunks])
                    if  wasShown { spotBranches() }
                    nodeSpotVm?.touchBegin(touchState)
                case 3:
                    if let firstBranch = treeSpotVm?.branchVms.first,
                       let firstSpotVm = firstBranch.nodeSpotVm {
                        firstSpotVm.touchBegin(touchState)
                    }
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
        func updateTreeSpot(_ treeVm: MuTreeVm,
                            _ nearestNode: MuNodeVm,
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
            lastShownBranchVms.removeAll()
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
            if let leafVm = nodeSpotVm as? MuLeafVm {
                leafVm.branchVm.treeVm.showTree(start: 0, depth: 9, "space", fromRemote)
            }
        }
        
        func shiftBranches() {
            if touchVm.touchingRoot(touchNow) {
                showTrunks()
                touchType = .root
                return
            }
            if let leafVm = nodeSpotVm as? MuLeafVm  {

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
            if touchState.phase.isDone() {
                treeSpotVm?.shiftNearest()
                touchType = .root
            } else if touchVm.touchingRoot(touchNow) {
                showTrunks()
                touchState.beginPoint(touchNow)
                touchType = .root
            } else {
                touchType = .canopy
                treeSpotVm?.shiftTree(touchState, fromRemote)
            }
        }

        // 􁏮􀝰
        func editTog(_ nodeVm: MuNodeVm?) {
            guard let leafVm = nodeVm as? MuLeafVm else { return }

            if touchType == .tog,
               !leafVm.containsPoint(touchNow) {
                // have moved off node
                nodeSpotVm = nil
                touchType = .none
                return
            } else {
                touchType = .tog
            }
            leafVm.touchLeaf(touchState, Visitor(.user))
        }
        // 􀥲􀝰
        func editLeaf(_ nodeVm: MuNodeVm?) {
            guard let leafVm = nodeVm as? MuLeafVm else { return }

            touchType = .leaf
            leafVm.touchLeaf(touchState, Visitor(.user))
            leafVm.spot(touchState.phase.isDone() ? .off : .on)
            leafVm.branchSpot(.off)
        }
        
        func showTrunks() {
            if treeVms.count == 1 {
                showSoloTree()
            } else {
                lastShownBranchVms.removeAll()
                for treeVm in treeVms {
                    treeVm.showTree(depth: 1, "trunk", fromRemote)
                    if let lastShown = treeVm.lastShown() {
                        lastShownBranchVms.append(lastShown)
                    }
                }
                treeSpotVm = nil
                nodeSpotVm = nil
                viewOps = [.root, .trunks]
            }
        }
        func showSoloTree() {
            if let treeVm = treeVms.first {
                treeSpotVm = treeVm
                treeVm.showTree(depth: 9, "solo", fromRemote)
                viewOps = [.root,.branch]
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
        func hideBranches() {
            for treeVm in treeVms {
                treeVm.showTree(depth: 0, "hide", fromRemote)
            }
            viewOps = [.root]
        }
    }
    
}
