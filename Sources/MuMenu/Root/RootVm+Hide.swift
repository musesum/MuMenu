// created by musesum on 6/13/25

import Foundation

extension RootVm {
    
    public func startAutoFades() {
        if let treeSpotVm {
            treeSpotVm.showState.startAutoFade()
        } else {
            for treeVm in treeVms {
                treeVm.showState.startAutoFade()
            }
        }
    }

    func toggleBranches() {
        if let treeSpotVm {
           treeSpotVm.showState.toggleTree()
        } else {
            for treeVm in treeVms {
                treeVm.showState.hideTree()
            }
        }
    }
    func showTrees(_ fromRemote: Bool) {
        if let treeSpotVm {
            treeSpotVm.showState.showTree()
        } else {
            for treeVm in treeVms {
                treeVm.showState.showTree()
            }
        }
    }
    func showTrunks(_ fromRemote: Bool) {
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
    func showBranches(_ fromRemote: Bool) {
        if let treeSpotVm {
            treeSpotVm.showTree(depth: 9, "spot+", fromRemote)
            viewOps = [.root, .branch]
        } else {
            showTrunks(fromRemote)
        }
    }
}
