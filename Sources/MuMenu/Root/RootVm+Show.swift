// created by musesum on 6/13/25

import MuFlo // PrintLog

extension RootVm {

    func updateHandsPhase() {

        // is this phase for my corner?
        let state = handsPhase.state
        let phase = (cornerType.left ? state.left
                     : cornerType.right ? state.right : nil)

        if let phase {
            let title = "RootVm     "+handsPhase.handsState
            TimeLog(title, interval: 1 ) { P(title+"\(self.cornerType.icon) \(self.touchType.symbol)") }
            switch phase {
            case .began: handBegan()
            case .ended: handEnded()
            default:     break
            }
        }
        func handBegan() {
            var hidden = true
            for menuVm in menuVms {
                if menuVm.isShowing {
                    hidden = false
                    break
                }
            }
            if hidden {
                showTrees(false)
            }
        }
        func handEnded() {
            for treeVm in treeVms {
                if !treeVm.showTree.state.hidden {
                    startAutoFades()
                }
            }
        }

    }
    public func startAutoFades() {
        if let treeSpotVm {
            treeSpotVm.showTree.startAutoFade()
        } else {
            for treeVm in treeVms {
                treeVm.showTree.startAutoFade()
            }
        }
    }
    func showTrees(_ fromRemote: Bool) {
        if let treeSpotVm {
            treeSpotVm.showTree.showNow()
        } else {
            for treeVm in treeVms {
                treeVm.showTree.showNow()
            }
        }
    }
    func toggleBranches(_ fromRemote: Bool) {
        if let treeSpotVm {
            let showTree = treeSpotVm.showTree
           showTree.toggleTree()
            if !fromRemote {
                NoDebugLog { P("toggleBranches showTime: \(showTree.state)") }
                let treesItem = MenuTreesItem(self)
                let menuItem = MenuItem(trees: treesItem)
                shareItem(menuItem)
            }
        } else {
            for treeVm in treeVms {
                treeVm.showTree.hideNow()
            }
        }
    }

    func showTrunks(_ fromRemote: Bool) {
        if treeVms.count == 1 {
            showFirstTree(fromRemote: true)
        } else {
            for treeVm in treeVms {
                treeVm.growTree(depth: 1, "trunk", fromRemote)
            }
            treeSpotVm = nil
            nodeSpotVm = nil
            viewOps = [.root, .trunks]
        }
    }
    func showBranches(_ fromRemote: Bool) {
        if let treeSpotVm {
            treeSpotVm.growTree(depth: 9, "spot+", fromRemote)
            viewOps = [.root, .branch]
        } else {
            showTrunks(fromRemote)
        }
    }
}
