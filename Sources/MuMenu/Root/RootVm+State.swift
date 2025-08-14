// created by musesum on 6/19/25

import SwiftUI
import MuPeers
import MuFlo
import MuVision

extension RootVm { // + State

    /// update tree from new spot
    func updateSpot(_ newSpotVm: NodeVm?,
                    _ fromRemote: Bool) {

        guard let newSpotVm else { return }
        self.nodeSpotVm = newSpotVm
        newSpotVm.refreshBranch()
        if !fromRemote {
            let phase = touchState.phase
            let nodeItem = MenuNodeItem(newSpotVm)
            let menuItem = MenuItem(node: nodeItem, phase)
            shareItem(menuItem)
        }
    }

    internal func updateRoot(_ fromRemote: Bool) {

        let touchNow = touchState.pointNow

        // stay exclusively on .leaf or .edit mode
        switch touchType {
        case .canopy : logRoot("shiftCanopy"  ); return shiftCanopy()
        case .leaf   : logRoot("editLeaf"     ); return editLeaf(nodeSpotVm)
        default      : break // logRoot(menuType.description)
        }
        if      beganLeaf()  { logRoot("beganLeaf ↦ 🍁") } // touch began on leaf
        else if endedTog()   { logRoot("endedTog ⇥ 🔘") } // touch ended on toggle
        else if hoverNode()  { logRoot("hoverNode ⟳ ⚪️") } // over the spot node
        else if hoverRoot()  { logRoot("hoverRoot ⟳ 🫚") } // over the root node
        else if hoverTree()  { logRoot("hoverTree ⟳ 🌲") } // new node on same tree
        else if hoverAlt()   { logRoot("hoverAlt ⟳ 🌴") } // alternate tree
        else if beganCanopy(){ logRoot("beganCanopy ↦ 🌳") } // hovering over canvas
        else {  hoverSpace();  logRoot("hoverSpace ⟳ 🪐") } // hovering over canvas

        func logRoot(_ msg: String = "",_ t: String = "") {

            NoTimeLog(touchType.symbol, interval: 0) {
                let touchType = self.touchType
                let touchState = self.touchState
                let phase = touchState.phase

                var count: Int
                switch phase {
                case .began : count = touchState.touchBeganCount
                case .ended : count = touchState.touchEndedCount
                default     : count = 0
                }
                let countStr = count > 0 ? "".superScript(count) : ""

                print("\(touchType.symbol) \(phase.symbol)\(countStr) \(msg)")
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
        func beganLeaf() -> Bool {

            guard let leafVm = treeSpotVm?.nearestNode(touchNow) as? LeafVm else { return false }

            if touchState.phase == .began {

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

        func hoverNode() -> Bool {
            guard let nodeSpotVm else { return false}
            if nodeSpotVm.contains(touchNow) {
                touchType = .node
                treeSpotVm?.growTree(depth: 9, "hoverNode" + "+", fromRemote)
                if touchState.touchEndedCount == 2 {
                    touchType = .root
                    nodeSpotVm.updateSpotNodes()
                }
                return true
            }
            return false
        }

        func hoverRoot() -> Bool {

            // user may drag away from root to explore
            if !cornerVm.touchingRoot(touchNow) {
                // when dragging from root, then expand tree
                if touchTypeBegin == .root {
                    treeSpotVm?.expandTree(fromRemote)
                    touchTypeBegin = .none
                }
                return false
            }
            // user is touching root
            switch touchState.touchEndedCount {
            case 0: // ᴮ begin touching root
                if !touchState.phase.done {
                    if touchType != .root {
                        touchType = .root

                        let isShowing = viewOps.hasAny([.branch,.trunks])
                        if  !isShowing {
                            showBranches(fromRemote)
                        }
                    }
                }
            case 1: // ᴱ¹ end tap once
                touchType = .none
                toggleBranches(fromRemote)
            case 2: // ᴱ² end tap twice
                nodeSpotVm?.updateSpotNodes()
            case 4: // ᴱ⁴ tap 4 times to clear buffers
                archiveVm.nextFrame.addBetweenFrame {
                    Reset.reset()
                }
            default: break
            }
            return true
        }

        func hoverTree() -> Bool {
            for treeVm in treeVms {

                if let nodeVm = treeVm.nearestNode(touchNow) {

                    updateTreeSpot(treeVm, nodeVm, "tree")
                    nodeSpotVm = nodeVm

                    if let leafVm = nodeVm as? LeafVm {

                        if touchState.phase == .began,
                           leafVm.nodeType.isControl {

                            editLeaf(leafVm)

                        }
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
                    treeVm.growTree(depth: 9, via + "+", fromRemote)
                } else {
                    treeVm.growTree(depth: 0, via + "-", fromRemote)
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
                leafVm.branchVm.treeVm.growTree(depth: 9, "space", fromRemote)
                viewOps = [.root, .branch]
            }
        }

        func shiftCanopy() {
            if touchState.phase.done {
                treeSpotVm?.shiftNearest()
                touchType = .root
            } else if cornerVm.touchingRoot(touchNow) {
                showTrunks(fromRemote)
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
                // leave spot on of single node button
            } else {
                leafVm.spot(touchState.phase.done ? .off : .on)
                leafVm.branchSpot(.off)
            }
        }
    }
}
