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
    
    public var cornerType: MenuType /// corner where root begins, ex: `[down,left]`
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
            let menuItem = MenuItem(node: nodeItem, phase)
            sendItemToPeers(menuItem)
        }
    }

    public init(_ cornerType : MenuType  ,
                _ archiveVm  : ArchiveVm ,
                _ peers      : Peers     ) {

        self.cornerType = cornerType
        self.cornerVm = CornerVm(cornerType)
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


    internal func updateRoot(_ fromRemote: Bool) {

        let touchNow = touchState.pointNow

        // stay exclusively on .leaf or .edit mode
        switch touchType {
        case .canopy : logRoot("shift Canopy"); return shiftCanopy()
        case .shift  : logRoot("shift Branch"); return shiftBranches()
        case .leaf   : logRoot("edit Leaf"   ); return editLeaf(nodeSpotVm)
        case .tog    : logRoot("edit Tog"    ); return editTog(nodeSpotVm)
        default      : break // logRoot(menuType.description)
        }
        if      hoverLeaf() { logRoot("hover Leaf 🍁") } // new node on same tree
        else if hoverSpot() { logRoot("hover Node ⚪️") } // over the spot node
        else if hoverRoot() { logRoot("hover Root 🫚") } // over the root node
        else if hoverTree() { logRoot("hover Tree 🌳") } // new node on same tree
        else if hoverAlt()  { logRoot("hover Alt  🌴") } // alternate tree
        else {  hoverSpace(); logRoot("hover Space 🪐") } // hovering over canvas

        func logRoot(_ msg: String = "",_ t: String = "") {
            MuLog.TimeLog(touchType.symbol, interval: 1) {
                P("\(self.touchType.symbol)  \(msg)")
            }
        }

        func hoverLeaf() -> Bool {

            guard let treeSpotVm else { return false }

            if touchState.phase == .began,
               let branchVm = treeSpotVm.nearestBranch(touchNow),
               let leafVm = branchVm.nearestNode(touchNow) as? LeafVm {

                nodeSpotVm = leafVm
                updateTreeSpot(treeSpotVm, leafVm, "leaf")
                //?? shiftCanopy()
                updateTreeSpot(leafVm.branchVm.treeVm, leafVm, "edit")
                if leafVm.nodeType.isControl {
                    editLeaf(leafVm)
                }
                return true
            }

            guard let leafVm = nodeSpotVm as? LeafVm else { return false }

            if leafVm.runways.contains(touchNow),
               touchState.phase == .ended,
                   leafVm.nodeType == .tog {

                    editTog(leafVm)
                    return true
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

