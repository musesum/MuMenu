//  created by musesum on 12/14/22.


import Foundation

@MainActor
extension TreeVm { // +Show

    func startHideAnimation(_ interval: TimeInterval,
                            _ done: @escaping () -> Void) {
//....        if showTree != .show { return }
//        self.showTree = .canopy
//
//        hideAnimationTimer = Timer.scheduledTimer(withTimeInterval: interval,
//                                                  repeats: true) { [weak self] timer in
//            guard let self else { return }
//
//            switch self.showTree {
//            case .show   : self.showTree = .canopy
//            case .canopy : self.showTree = .hide; done()
//            case .hide   : self.showTree = .show; timer.invalidate()
//            }
//            //print("\(#function) \(self.showTree.rawValue) interval: \(interval)")
//        }
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
        showTree = .show 
        showTree(depth: 9, "reshow", fromRemote)
    }

    func showTree(start: Int? = nil,
                  depth: Int? = nil,
                  _ via: String,
                  _ fromRemote: Bool) {
        
        let nextIndex = start ?? startIndex
        let nextDepth = depth ?? 9
        var newBranches = [BranchVm]()
        var index = 0
        var depthNow = 0

        var branch: BranchVm! = branchVms.first
        while branch != nil {
            if depthNow < nextDepth {
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
            #if true
            //print(cornerItem.corner.indicator()+(isVertical ? "|" : "━"), terminator: "")
            #elseif true
            //print("\(via.pad(7))\(cornerItem.corner.indicator())\(isVertical ? "V" : "H") (s \(nextIndex) d \(nextDepth)) ", terminator: " ")
            
            for branch in branchVms {
                print("\(branch.title.pad(7)):\(branch.cubemap ? 1 : 0)", terminator: " ")
            }
            print("=== (s \(startIndex) d \(depthShown))  shift: \(treeShifted)")
            #endif
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
