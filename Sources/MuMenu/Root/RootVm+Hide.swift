// created by musesum on 6/13/25

import Foundation

extension RootVm {
    
    public func startAutoFades() {
        if let treeSpotVm {
            treeSpotVm.treeShow.startAutoFade()
        } else {
            for treeVm in treeVms {
                treeVm.treeShow.startAutoFade()
            }
        }
    }

    func toggleBranches() {
        if let treeSpotVm {
           treeSpotVm.treeShow.toggleTree()
        } else {
            for treeVm in treeVms {
                treeVm.treeShow.hideTree()
            }
        }
    }
    func showTrees(_ fromRemote: Bool) {
        if let treeSpotVm {
            treeSpotVm.treeShow.showTree()
        } else {
            for treeVm in treeVms {
                treeVm.treeShow.showTree()
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
