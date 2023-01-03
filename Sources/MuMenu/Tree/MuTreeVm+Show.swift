//  Created by warren on 12/14/22.


import Foundation

extension MuTreeVm { // +Show

    func showBranches(depth depthNext: Int) {

        var newBranches = [MuBranchVm]()

        logStart()
        if      depthShown < depthNext { expandBranches() }
        else if depthShown > depthNext { contractBranches() }
        logFinish()
        
        func expandBranches() {
            var countUp = 0
            for branch in branchVms {
                if countUp < depthNext {
                    newBranches.append(branch)
                    branch.show = true
                } else {
                    branch.show = false
                }
                countUp += 1
            }
            depthShown = min(countUp, depthNext)
        }
        func contractBranches() {
            var countDown = branchVms.count
            for branch in branchVms.reversed() {
                if countDown > depthNext,
                   branch.show == true {
                    branch.show = false
                }
                countDown -= 1
            }
            depthShown = depthNext
        }
        func logStart() {
            let symbol = (isVertical) ? "V⃝" : "H⃝"
            print ("\(symbol) \(depthShown)⇨\(depthNext)", terminator: "=")
        }
        func logFinish() {
            print (depthShown, terminator: " ")
        }
    }


}
