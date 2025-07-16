//  created by musesum on 12/14/22.


import Foundation
import MuFlo // logging

extension TreeVm { // +Show

    func showTree(start: Int? = nil,
                  depth: Int,
                  _ via: String,
                  _ fromRemote: Bool) {

        DebugLog { P("𖢞 \(self.menuType.icon) \(via):\(depth)") }

        showState.showTree()


        let nextIndex = start ?? startIndex
        var newBranches = [BranchVm]()
        var index = 0
        var depthNow = 0

        var branch: BranchVm! = branchVms.first
        while branch != nil {
            if depthNow < depth {
                branch.show = true
                if index >= nextIndex {
                    depthNow += 1
                }
            } else {
                branch.show = false
            }
            index += 1
            
            newBranches.append(branch)
            branch = branch.nodeSpotVm?.nextBranchVm ?? nil
        }
        branchVms = newBranches

        for branchVm in branchVms {
            branchVm.updateShiftRange()
        }

        startIndex = nextIndex
        depthShown = depthNow
        shiftTree(to: startIndex)

        if !fromRemote {
            let rootItem = MenuRootItem(rootVm)
            let menuItem = MenuItem(root: rootItem)
            rootVm.sendItemToPeers(menuItem)
        }
    }
    func lastShown() -> BranchVm? {
        let lastIndex = startIndex + depthShown - 1
        if depthShown > 0,
           lastIndex < branchVms.count {

            return branchVms[lastIndex]
        } else {
            return nil
        }
    }
}
