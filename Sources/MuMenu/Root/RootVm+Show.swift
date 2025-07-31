// created by musesum on 6/13/25

import MuFlo // PrintLog

extension RootVm {
    
    public func startAutoFades() {
        if let treeSpotVm {
            treeSpotVm.showTree.startAutoFade()
        } else {
            for treeVm in treeVms {
                treeVm.showTree.startAutoFade()
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
                sendItemToPeers(menuItem)
            }
        } else {
            for treeVm in treeVms {
                treeVm.showTree.hideNow()
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
