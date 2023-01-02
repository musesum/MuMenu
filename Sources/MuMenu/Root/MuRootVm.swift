
//  MuRootVm.swift
// Created by warren 10/13/21.

import SwiftUI

public class MuRootVm: ObservableObject, Equatable {
    let id = MuNodeIdentity.getId()
    public static func == (lhs: MuRootVm, rhs: MuRootVm) -> Bool { return lhs.id == rhs.id }
    
    /// what is the finger touching
    @Published var touchElement = MuElement.none
    var beginTouchElement = MuElement.none
    
    /// captures touch events to dispatch to this root
    public let touchVm = MuTouchVm()
    
    /// which menu elements are shown on View
    var viewElements: Set<MuElement> = [.root, .trunks]
    // { willSet { if viewElements != newValue { log(":", [beginViewElements,"⟶",newValue], terminator: " ") } } }
    
    /// `touchBegin` snapshot of viewElements.
    /// To prevent touchEnded from hiding elements that were shown during `touchBegin`
    var beginViewElements: Set<MuElement> = []
    
    var corner: MuCorner        /// corner where root begins, ex: `[south,west]`
    var treeVms = [MuTreeVm]()  /// vertical or horizontal stack of branches
    var treeSpotVm: MuTreeVm?   /// most recently used tree
    public var nodeSpotVm: MuNodeVm?   /// current last touched or hovered node

    let peers = PeersController.shared

    func updateSpot(_ newSpotVm: MuNodeVm,
                    _ fromRemote: Bool) {
        
        if self.nodeSpotVm != newSpotVm  {
            self.nodeSpotVm = newSpotVm
            newSpotVm.refreshBranch()
            newSpotVm.refreshStatus()
            if !fromRemote {
                sendToPeers(newSpotVm, [0,0])
            }
        }
    }

    func sendToPeers(_ nodeVm: MuNodeVm,
                     _ thumb: [Double]) {

        if peers.hasPeers {
            do {
                let menuKey = (
                    nodeVm.nodeType.isLeaf
                    ? "leaf".hash
                    : "node".hash)

                let item = TouchMenuItem(
                    menuKey   : menuKey,
                    cornerStr : corner.str(),
                    nodeType  : nodeVm.nodeType,
                    treePath  : nodeVm.node.hashPath,
                    treeNow   : nodeVm.node.hash,
                    thumb     : thumb,
                    phase     : touchState?.phase ?? .began)

                let encoder = JSONEncoder()
                let data = try encoder.encode(item)
                peers.sendMessage(data, viaStream: true)
            } catch {
                print(error)
            }
        }
    }


    public init(_ corner: MuCorner, treeVms: [MuTreeVm]) {
        
        self.corner = corner
        self.treeVms = treeVms
        treeSpotVm = treeVms.first
        touchVm.setRoot(self)
        updateTreeOffsets()
        for treeVm in treeVms {
            treeVm.rootVm = self
        }
    }
    
    
    /**
     Adjust MuTree offsets on iPhone and iPad. Needed to avoid false positives, now that springboard has added a corner hotspot for launching the notes app. Also, adjust pilot offsets for home node and for flying.
     */
    func updateTreeOffsets() {
        
        let idiom = UIDevice.current.userInterfaceIdiom
        let margin = 2 * Layout.padding
        let x = (idiom == .pad ? margin : 0)
        let y = ( (corner.contains(.upper) && idiom == .phone) ||
                  (corner.contains(.lower) && idiom == .pad)) ? margin : 0
        let xx = x + Layout.diameter + margin
        let yy = y + Layout.diameter + margin
        
        var vOfs = CGSize.zero // vertical offset
        var hOfs = CGSize.zero // horizontal offset
        func vert(_ w: CGFloat, _ h: CGFloat) { vOfs = CGSize(width: w, height: h) }
        func hori(_ w: CGFloat, _ h: CGFloat) { hOfs = CGSize(width: w, height: h) }
        
        switch corner {
            case [.lower, .right]: vert(-x,-yy); hori(-xx,-y)
            case [.lower, .left ]: vert( x,-yy); hori( xx,-y)
            case [.upper, .right]: vert(-x, yy); hori(-xx, y)
            case [.upper, .left ]: vert( x, yy); hori( xx, y)
            default: break
        }
        
        for treeVm in treeVms {
            treeVm.treeOffset = (treeVm.isVertical ? vOfs : hOfs)
        }
    }
    
    func cornerXY(in frame: CGRect) -> CGPoint {
        
        let idiom = UIDevice.current.userInterfaceIdiom
        let margin = 2 * Layout.padding
        let x = (idiom == .pad ? margin : 0)
        let y = ((corner.contains(.upper) && idiom == .phone) ||
                 (corner.contains(.lower) && idiom == .pad))  ? margin : 0
        let w = frame.size.width
        let h = frame.size.height
        let s = Layout.padding
        let r = Layout.diameter / 2
        
        switch corner {
            case [.lower, .right]: return CGPoint(x: w - x - r - s, y: h - y - r - s)
            case [.lower, .left ]: return CGPoint(x:     x + r + s, y: h - y - r - s)
            case [.upper, .right]: return CGPoint(x: w - x - r - s, y:     y + r + s)
            case [.upper, .left ]: return CGPoint(x:     x + r + s, y:     y + r + s)
            default: return .zero
        }
    }
    
    func hitTest(_ point: CGPoint) -> MuNodeVm? {
        for treeVm in treeVms {
            for branchVm in treeVm.branchVms {
                if branchVm.show, branchVm.boundsNow.contains(point) {
                    return branchVm.findNearestNode(point)
                }
            }
        }
        return nil
    }
    var touchState: MuTouchState?

    func touchBegin(_ touchState: MuTouchState,
                    _ fromRemote: Bool) {

        self.touchState = touchState
        beginViewElements = viewElements
        updateRoot(fromRemote)
        nodeSpotVm?.touching(touchState)
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
                sendToPeers(nodeSpotVm, leafVm.thumb)
            } else {
                sendToPeers(nodeSpotVm, [0,0])
            }
        }
    }
    
    private func updateRoot(_ fromRemote: Bool) {
        guard let touchState else { return }
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
                    
                } else if leafVm.branchVm.boundsNow.contains(touchNow) {
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
                    treeSpotVm?.shiftExpandLast() //????
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
                    else         { showBranches() }
                case 2:
                    let wasShown = beginViewElements.hasAny([.branch,.trunks])
                    if  wasShown { showBranches() }
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
                        else          { showBranches() }
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
                        // log("~", terminator: "")
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
        func hoverTreeAlts()-> Bool {
            // hovering over hidden trunk of another tree?
            for treeVm in treeVms {
                if treeVm != treeSpotVm,
                   let nearestTrunk = treeVm.nearestTrunk(touchNow),
                   let nearestNode = nearestTrunk.findNearestNode(touchNow) {
                    
                    treeSpotVm = treeVm // set new tree
                    
                    for treeVm in treeVms {
                        if treeVm == treeSpotVm {
                            treeVm.showBranches(depth: 999)
                        } else {
                            treeVm.showBranches(depth: 0)
                        }
                    }
                    updateSpot(nearestNode, fromRemote)
                    
                    // log("≈", terminator: "")
                    viewElements = [.root,.branch]
                    touchElement = .branch
                    return true
                }
            }
            return false
        }
        func hoverSpace() {
            touchElement = .space
            nodeSpotVm = nil
        }
        
        //  show/hide/stack -----------
        
        func shiftBranches() {
            guard let leafVm = nodeSpotVm as? MuLeafVm else { return }
            // begin touch on title section to possibly stack branches
            touchElement = .shift
            leafVm.spot(.off)
            leafVm.branchSpot(.on)
            treeSpotVm?.shiftTree(touchState)
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
                    treeVm.showBranches(depth: 1)
                }
                treeSpotVm = nil
                // log("+ᛘ", terminator: "")
                viewElements = [.root, .trunks]
            }
        }
        func showSoloTree() {
            if let treeVm = treeVms.first {
                treeSpotVm = treeVm
                treeVm.showBranches(depth: 999)
                // log("+𐂷", terminator: "")
                viewElements = [.root,.branch]
            }
        }
        func showBranches() {
            if let treeSpotVm {
                for treeVm in treeVms {
                    if treeVm == treeSpotVm {
                        treeVm.showBranches(depth: 999)
                    } else {
                        treeVm.showBranches(depth: 0)
                    }
                    // log("+𐂷", terminator: "")
                    viewElements = [.root,.branch]
                }
            } else {
                showTrunks()
            }
        }
    }
    public func hideBranches() {
        for treeVm in treeVms {
            treeVm.showBranches(depth: 0)
        }
        treeSpotVm = nil
        // log("-𐂷", terminator: "")
        viewElements = [.root]
    }
}
