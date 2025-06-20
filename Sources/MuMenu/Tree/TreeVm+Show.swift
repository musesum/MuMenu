//  created by musesum on 12/14/22.


import Foundation
import MuFlo // logging

extension TreeVm { // +Show

    func startHideAnimation(_ interval: TimeInterval,
                            _ done: @escaping () -> Void) {
        if treeState != .showTree { return }
        self.treeState = .canopy

        hideAnimationTimer = Timer.scheduledTimer(withTimeInterval: interval,
                                                  repeats: true) { [weak self] timer in
            guard let self else { return }

            switch self.treeState {
            case .showTree  : self.treeState = .canopy
            case .canopy    : self.treeState = .hideTree; done()
            case .hideTree  : self.treeState = .showTree; timer.invalidate()
            }
            //print("\(#function) \(self.showTree.rawValue) interval: \(interval)")
        }
    }

    func hideTree(_ touchType: TouchType,
                  _ fromRemote: Bool) {

        self.interval = touchType == .root ? 0.5 : 2.0
        startHideAnimation(interval) {
            self.showTree(depth: 0, "hide", fromRemote)
        }
    }
    func reshowTree(_ fromRemote: Bool) {
        hideAnimationTimer?.invalidate()
        treeState = .showTree 
    }

    func showTree(start: Int? = nil,
                  depth: Int,
                  _ via: String,
                  _ fromRemote: Bool) {

        PrintLog("𖢞 \(menuType.icon) \(via):\(depth)")

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
        logShowTree()

        if !fromRemote {
            let rootItem = MenuRootItem(rootVm)
            let menuItem = MenuItem(root: rootItem)
            rootVm.sendItemToPeers(menuItem)
        }
        func logShowTree() {
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
