//  Created by warren on 12/14/22.


import Foundation

extension MuTreeVm { // +Show

    func showTree(start: Int? = nil,
                  depth: Int? = nil,
                  _ via: String,
                  _ fromRemote: Bool) {
        
        let nextIndex = start ?? startIndex
        let nextDepth = depth ?? 9
        var newBranches = [MuBranchVm]()
        var index = 0
        var depthNow = 0
        
        var branch: MuBranchVm! = branchVms.first
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
            //print(cornerAxis.corner.indicator()+(isVertical ? "|" : "━"), terminator: "")
            #elseif true
            //print("\(via.pad(7))\(cornerAxis.corner.indicator())\(isVertical ? "V" : "H") (s \(nextIndex) d \(nextDepth)) ", terminator: " ")
            
            for branch in branchVms {
                print("\(branch.title.pad(7)):\(branch.show ? 1 : 0)", terminator: " ")
            }
            print("=== (s \(startIndex) d \(depthShown))  shift: \(treeShifted)")
            #endif
        }
    }
    func lastShown() -> MuBranchVm? {
        let lastIndex = startIndex + depthShown - 1
        if depthShown > 0,
           lastIndex < branchVms.count {

            return branchVms[lastIndex]
        } else {
            return nil
        }
    }
    var reverse: Bool { get {
        self.isVertical
        ? rootVm.corner.lower ? true : false
        : rootVm.corner.right ? true : false
    }}
}
