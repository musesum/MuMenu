// created by musesum on 6/19/25

import SwiftUI
import MuPeers
import MuFlo
import MuVision

extension RootVm { // + State

    internal func updateRoot(_ fromRemote: Bool) {

        let touchNow = touchState.pointNow

        // stay exclusively on .leaf or .edit mode
        switch touchType {
        case .canopy : logRoot("shift Canopy"); return shiftCanopy()
        case .shift  : logRoot("shift Branch"); return shiftBranches()
        case .leaf   : logRoot("edit Leaf"   ); return editLeaf(nodeSpotVm)
        default      : break // logRoot(menuType.description)
        }
        if      beganLeaf() { logRoot("beganLeaf  🍁") } // tap leaf node
        else if endedTog()  { logRoot("endedTog   🔘") } // endedleaf node
        else if hoverNode() { logRoot("hoverNode  ⚪️") } // over the spot node
        else if hoverRoot() { logRoot("hoverRoot  🫚") } // over the root node
        else if hoverTree() { logRoot("hoverTree  🌲") } // new node on same tree
        else if hoverAlt()  { logRoot("hoverAlt   🌴") } // alternate tree
        else if beganCanopy(){logRoot("beganCanopy 🌳") } // hovering over canvas
        else {  hoverSpace(); logRoot("hover Space 🪐") } // hovering over canvas

        func logRoot(_ msg: String = "",_ t: String = "") {

            TimeLog(touchType.symbol, interval: 0) {
                let touchType = self.touchType
                let touchState = self.touchState
                let phase = touchState.phase

                var count: Int
                switch phase {
                case .began : count = touchState.touchBeginCount
                case .ended : count = touchState.touchEndedCount
                default     : count = 0
                }
                let countStr = count > 0 ? "".superScript(count) : ""

                print("\(touchType.symbol) \(phase.symbol)\(countStr) \(msg)")
            }

        }

        func beganLeaf() -> Bool {
            guard let treeSpotVm else { return false }

            if touchState.phase == .began,
               let branchVm = treeSpotVm.nearestBranch(touchNow),
               let leafVm = branchVm.nearestNode(touchNow) as? LeafVm {

                nodeSpotVm = leafVm
                if leafVm.nodeType.isControl {
                    editLeaf(leafVm)
                }
                return true
            }
            return false
        }
        func endedTog() -> Bool {
            guard let togVm = nodeSpotVm as? LeafTogVm else { return false }
            if touchState.phase == .ended,
               touchState.touchEndedCount == 1,
               togVm.runways.contains(touchNow) {

                touchType = .node
                togVm.touchLeaf(touchState, Visitor(0, .user))
                return true
            }
            return false
        }

        func hoverLeaf() -> Bool {

            guard let leafVm = nodeSpotVm as? LeafVm else { return false }
            if leafVm.nodeType.isControl,
               touchType.isNotIn([.node, .space]),
               leafVm.branchVm.contains(touchNow) {

                updateTreeSpot(leafVm.branchVm.treeVm, leafVm, "shift")
                shiftBranches() // inside branch containing runway
                return true
            }
            return false
        }

        func hoverNode() -> Bool {
            guard let nodeSpotVm else { return false  }
            if nodeSpotVm.contains(touchNow) {
                touchType = .node
                    treeSpotVm?.showTree(depth: 9, "hoverNode" + "+", fromRemote)
                    nodeSpotVm.updateSpotNodes()
                return true
            }
            return false
        }
        func hoverRoot() -> Bool {
            if !cornerVm.touchingRoot(touchNow) {
                if touchTypeBegin == .root {
                    // when dragging root over branches, expand tree
                    treeSpotVm?.expandTree(fromRemote)
                    // do this only once
                    touchTypeBegin = .none
                }
                return false
            }

            switch touchState.touchEndedCount {
            case 0:
                if !touchState.phase.done {
                    if touchType != .root {
                        touchType = .root

                        let isShowing = viewOps.hasAny([.branch,.trunks])
                        if  !isShowing { spotBranches() }
                    }
                }
            case 1:
                touchType = .none
                let wasShown = beginViewOps.hasAny([.branch,.trunks])
                if  wasShown { hideBranches(.root, fromRemote) }
                else         { spotBranches() }
            case 2:
                let wasShown = beginViewOps.hasAny([.branch,.trunks])
                if  wasShown { spotBranches() }
                nodeSpotVm?.updateSpotNodes()

            default: break

            }
            return true
        }

        func hoverTree() -> Bool {
            for treeVm in treeVms {

                if let branchVm = treeVm.nearestBranch(touchNow),
                   let nodeVm = branchVm.nearestNode(touchNow) {

                    updateTreeSpot(treeVm, nodeVm, "tree")

                    if beganLeaf() ||
                        hoverLeaf() {
                        // already set touchElement
                    } else if !viewOps.contains(.branch) {

                        viewOps = [.root,.branch]
                        touchType = .branch
                    }
                    return true
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

            } else if let leafVm = nodeSpotVm as? LeafVm  {

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
        func beganCanopy() -> Bool {
            if touchState.phase == .began,
               let treeSpotVm,
               treeSpotVm.treeBounds.contains(touchState.pointNow) {

                touchType = .canopy
                treeSpotVm.shiftTree(touchState, fromRemote)
                return true
            }
            return false
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

        // 􀥲􀝰
        func editLeaf(_ nodeVm: NodeVm?) {
            guard let leafVm = nodeVm as? LeafVm else { return }
            touchType = .leaf
            leafVm.touchLeaf(touchState, Visitor(0, .user))
            if leafVm.nodeType == .tog {
                //....
            } else {
                leafVm.spot(touchState.phase.done ? .off : .on)
                leafVm.branchSpot(.off)
            }
        }

        func showTrunks() {
            if treeVms.count == 1 {
                showFirstTree(fromRemote: true)
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
                treeSpotVm.showTree(depth: 9, "spot+", fromRemote)
            } else {
                showTrunks()
            }
        }
    }
}
