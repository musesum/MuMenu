// Created by warren 10/13/21.

import SwiftUI

public class MuRootVm: ObservableObject, Equatable {
    let id = MuNodeIdentity.getId()
    public static func == (lhs: MuRootVm, rhs: MuRootVm) -> Bool { return lhs.id == rhs.id }
    
    /// what is the finger touching
    @Published var touchElement = MuTouchElement.none
    var beginTouchElement = MuTouchElement.none
    
    /// captures touch events to dispatch to this root
    public let touchVm: MuTouchVm
    
    /// which menu elements are shown on View
    var viewElements: Set<MuTouchElement> = [.root, .trunks]
    
    /// `touchBegin` snapshot of viewElements.
    /// To prevent touchEnded from hiding elements that were shown during `touchBegin`
    var beginViewElements: Set<MuTouchElement> = []
    
    var corner: MuCorner        /// corner where root begins, ex: `[south,west]`
    var treeVms = [MuTreeVm]()  /// vertical or horizontal stack of branches
    var treeSpotVm: MuTreeVm?   /// most recently used tree
    var rootOffset: CGSize = .zero
    public var nodeSpotVm: MuNodeVm?   /// current last touched or hovered node

    let peers = PeersController.shared

    /// update tree from new spot
    func updateSpot(_ newSpotVm: MuNodeVm,
                    _ fromRemote: Bool) {

        self.nodeSpotVm = newSpotVm
        newSpotVm.refreshBranch()
        newSpotVm.branchVm.treeVm.showTree("branch", fromRemote)
        newSpotVm.refreshStatus()
        if !fromRemote {
            sendNodeToPeers(newSpotVm, touchState.phase)
        }
    }

    public init(_ corner: MuCorner) {
        
        self.corner = corner
        self.touchVm = MuTouchVm(corner)
    }
    public func updateTreeVms(_ treeVms: [MuTreeVm]) {
        self.treeVms.append(contentsOf: treeVms)
        touchVm.setRoot(self)
        updateTreeOffsets()
    }
    

    func updateTreeOffsets() {

        // xy top left to bottom right cornders
        let x0 = Layout.padding * 2
        let y0 = Layout.padding * 2
        let x1 = x0 + Layout.diameter + Layout.padding * 3
        let y1 = y0 + Layout.diameter + Layout.padding * 3

        // setup vertical, horizontal, and root offsets
        var vs = CGSize.zero // vertical offset
        var hs = CGSize.zero // horizontal offset
        var rs = CGSize.zero // root icon offset
        func v(_ w: CGFloat, _ h: CGFloat) { vs = CGSize(width: w, height: h) }
        func h(_ w: CGFloat, _ h: CGFloat) { hs = CGSize(width: w, height: h) }
        func r(_ w: CGFloat, _ h: CGFloat) { rs = CGSize(width: w, height: h) }

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
        let y = ((corner.contains(.upper) && idiom == .phone) ||
                 (corner.contains(.lower) && idiom == .pad)) ? margin : 0
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
            for branchVm in treeVm.branchVms {
                if branchVm.show, branchVm.boundsPad.contains(point) {
                    return branchVm.findNearestNode(point)
                }
            }
        }
        return nil
    }
    var touchState: MuTouchState!
    func touchBegin(_ touchState: MuTouchState,
                    _ fromRemote: Bool) {

        self.touchState = touchState
        beginViewElements = viewElements
        updateRoot(fromRemote)
        if let nodeSpotVm {
            nodeSpotVm.touching(touchState)
            updateSpot(nodeSpotVm, fromRemote)
        }
        MuStatusVm.statusLine(touchElement == .edit ? .on : .off)
        beginTouchElement = touchElement
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
        if let nodeSpotVm, nodeSpotVm.nodeType.isLeaf {
            nodeSpotVm.spotlight = false
        }
        treeSpotVm?.branchSpotVm = nil
        touchElement = .none
        MuStatusVm.statusLine(.off)
        if !fromRemote, let nodeSpotVm {
            if let leafVm = nodeSpotVm as? MuLeafVm {
                sendLeafToPeers(leafVm, leafVm.thumb, touchState.phase)
            } else {
                sendNodeToPeers(nodeSpotVm, touchState.phase) 
            }
        }
    }
    
    private func updateRoot(_ fromRemote: Bool) {

        let touchNow = touchState.pointNow
        
        // stay exclusively on .leaf or .edit mode
        switch touchElement {
            case .shift: return shiftBranches()
            case .edit:  return editLeaf(nodeSpotVm)
            default: break
        }
        if        touchLeafNode() { // editing leaf or shifting branch
        } else if hoverNodeSpot() { // is over the same branch node
        } else if hoverRootNode() { // is tapping or over the root (home) node
        } else if hoverTreeNow()  { // shifted to new node on same tree
        } else if hoverTreeAlts() { // shifted to space reserved for alternate tree
        } else {  hoverSpace()    } // hovering over canvas
        
        // log(touchElement.symbol, terminator: "")
        
        func touchLeafNode() -> Bool {
            if touchState.phase == .began,
               let leafVm = nodeSpotVm as? MuLeafVm {
                
                if leafVm.runwayBounds.contains(touchNow) {
                    editLeaf(leafVm) // inside runway
                    return true
                    
                } else if leafVm.branchVm.boundsPad.contains(touchNow) {
                    shiftBranches() // inside branch containing runway
                    return true
                }
            }
            return false
        }
        
        func hoverNodeSpot() -> Bool {

            if let center = nodeSpotVm?.center,
               center.distance(touchNow) < Layout.insideNode {

                touchElement = .node
                return true
            }
            return false
        }
        func hoverRootNode() -> Bool {
            
            let touchingRoot = touchVm.rootNodeVm?.containsPoint(touchNow) ?? false
            if !touchingRoot {
                if beginTouchElement == .root {
                    // when dragging root over branches, expand tree
                    treeSpotVm?.shiftExpandLast(touchState, fromRemote)
                    // do this only once
                    beginTouchElement = .none
                }
                return false
            }
            switch touchState.touchEndedCount {
                case 1:
                    touchElement = .none
                    let wasShown = beginViewElements.hasAny([.branch,.trunks])
                    if  wasShown { hideBranches() }
                    else         { spotBranches() }
                case 2:
                    let wasShown = beginViewElements.hasAny([.branch,.trunks])
                    if  wasShown { spotBranches() }
                    nodeSpotVm?.touching(touchState)
                case 3:
                    if let firstBranch = treeSpotVm?.branchVms.first,
                       let firstSpotVm = firstBranch.nodeSpotVm {
                        firstSpotVm.touching(touchState)
                    }
                default:
                    if touchElement != .root {
                        touchElement = .root
                        let isShowing = viewElements.hasAny([.branch,.trunks])
                        if  isShowing { showTrunks() }
                        else          { spotBranches() }
                    }
            }
            return true
        }
        func hoverTreeNow() -> Bool {
            // check current set of menus
            guard let treeSpotVm else { return false }
            if let nearestBranch = treeSpotVm.nearestBranch(touchNow) {
                
                if let nearestNodeVm = nearestBranch.findNearestNode(touchNow) {
                    
                    updateSpot(nearestNodeVm, fromRemote)
                    if touchLeafNode() {
                        // already set touchElement
                    } else if !viewElements.contains(.branch) {

                        viewElements = [.root,.branch]
                        touchElement = .branch
                    }
                    return true
                    
                } else if let nearestLeafVm = nearestBranch.findNearestLeaf(touchNow) {
                    // special case where not touching on leaf runway but is touching headline
                    if touchState.phase == .began {

                        updateSpot(nearestLeafVm, fromRemote)
                        touchElement = .shift
                        return true
                    }
                }
            }
            return false
        }
        func hoverTreeAlts() -> Bool {
            // hovering over hidden trunk of another tree?
            for treeVm in treeVms {
                if treeVm != treeSpotVm,
                   let nearestTrunk = treeVm.nearestTrunk(touchNow),
                   let nearestNode = nearestTrunk.findNearestNode(touchNow) {
                    
                    treeSpotVm = treeVm // set new tree
                    
                    for treeVm in treeVms {
                        if treeVm == treeSpotVm {
                            treeVm.showTree(depth: 9, "alt+", fromRemote)
                        } else {
                            treeVm.showTree(depth: 0, "alt-", fromRemote)
                        }
                    }
                    updateSpot(nearestNode, fromRemote)
                    viewElements = [.root,.branch]
                    touchElement = .branch
                    return true
                }
            }
            return false
        }

        //  MARK: - show/hide/stack

        func hoverSpace() {
            touchElement = .space
            if let leafVm = nodeSpotVm as? MuLeafVm {
                leafVm.branchVm.treeVm.showTree(start: 0, depth: 9, "space", fromRemote)
            }
        }

        func shiftBranches() {
            guard let leafVm = nodeSpotVm as? MuLeafVm else { return }
            // begin touch on title section to possibly stack branches
            touchElement = .shift
            leafVm.spot(.off)
            leafVm.branchSpot(.on)
            treeSpotVm?.shiftTree(touchState, fromRemote)
        }
        
        func editLeaf(_ nodeVm: MuNodeVm?) {
            guard let leafVm = nodeSpotVm as? MuLeafVm else { return }
            if touchElement != .edit {
                touchElement = .edit
                let touchDone = touchState.phase.isDone()
                leafVm.spot(touchDone ? .off : .on)
                leafVm.branchSpot(.off)
            }
            leafVm.touchLeaf(touchState)

            // hide status line
            MuStatusVm.statusLine(.off)
        }

        func showTrunks() {
            if treeVms.count == 1 {
                showSoloTree()
            } else {
                for treeVm in treeVms {
                    treeVm.showTree(depth: 1, "trunk", fromRemote)
                }
                treeSpotVm = nil
                nodeSpotVm = nil
                viewElements = [.root, .trunks]
            }
        }
        func showSoloTree() {
            if let treeVm = treeVms.first {
                treeSpotVm = treeVm
                treeVm.showTree(depth: 9, "solo", fromRemote)
                viewElements = [.root,.branch]
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
                    viewElements = [.root,.branch]
                }
            } else {
                showTrunks()
            }
        }
        func hideBranches() {
            for treeVm in treeVms {
                treeVm.showTree(depth: 0, "hide", fromRemote)
            }
            treeSpotVm = nil
            nodeSpotVm = nil
            viewElements = [.root]
        }
    }
}
