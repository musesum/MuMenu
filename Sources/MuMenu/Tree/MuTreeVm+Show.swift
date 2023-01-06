//  Created by warren on 12/14/22.


import Foundation

extension MuTreeVm { // +Show

    func showTree(start: Int? = nil,
                  depth: Int,
                  via: String) {

        let nextIndex = start ?? startIndex

        print("\(via.pad(7))\(isVertical ? "V" : "H") (s \(nextIndex) d \(depth)) ", terminator: " ")

        var newBranchVms = [MuBranchVm]()
        var index = 0
        var depthNow = 0

        for branch in branchVms {

            if depthNow < depth {
                newBranchVms.append(branch)
                branch.show = true
                if index >= nextIndex {
                    depthNow += 1
                }
            } else {
                branch.show = false
            }
            index += 1

            print("\(branch.title):\(branch.show ? 1 : 0)", terminator: " ")
        }

        startIndex = nextIndex
        depthShown = depthNow

        if depthShown > 0 {
            for branch in newBranchVms {
                branch.updateShiftRange()
            }
        }
        branchVms = newBranchVms

        print("=== (s \(startIndex) d \(depthShown))  shift: \(treeShifted)")
    }
}
