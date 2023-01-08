//  Created by warren on 12/14/22.


import Foundation

extension MuTreeVm { // +Show

    func showTree(start: Int? = nil,
                  depth: Int? = nil,
                  via: String = "refresh") {
        
        let nextIndex = start ?? startIndex
        let nextDepth = depth ?? 9
        var newBranches = [MuBranchVm]()
        var index = 0
        var depthNow = 0
        
        var branch: MuBranchVm! = branchVms.first
        while branch != nil {
            if depthNow < nextDepth {
                branch.willShow = true
                if index >= nextIndex {
                    depthNow += 1
                }
            } else {
                branch.willShow = false
            }
            index += 1
            
            newBranches.append(branch)
            branch = branch.nodeSpotVm?.nextBranchVm ?? nil
        }
        branchVms = newBranches

        for branch in newBranches {
            branch.updateShiftRange()
            branch.show = branch.willShow
        }

        startIndex = nextIndex
        depthShown = depthNow
        shiftTree(to: startIndex)
        logShowTree()
        
        func logShowTree() {
            
            print("\(via.pad(7))\(cornerAxis.corner.indicator())\(isVertical ? "V" : "H") (s \(nextIndex) d \(nextDepth)) ", terminator: " ")
            
            for branch in branchVms {
                print("\(branch.title.pad(7)):\(branch.show ? 1 : 0)", terminator: " ")
            }
            print("=== (s \(startIndex) d \(depthShown))  shift: \(treeShifted)")
        }
    }
}
