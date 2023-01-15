//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm { // + Shift

    private func shiftNearest() -> CGSize {

        var lowestDelta = CGFloat.infinity
        var w = CGFloat.zero
        var h = CGFloat.zero

        switch cornerAxis.bound {
            case .lowX:
                for branchVm in branchVms {
                    let lowX = branchVm.shiftRange.0.lowerBound
                    let delta = abs(lowX - treeShifting.width)

                    if lowestDelta > delta {
                        lowestDelta = delta
                        w = lowX
                    }
                }
            case .uprX:
                for branchVm in branchVms {
                    let uprX = branchVm.shiftRange.0.upperBound
                    let delta =  abs(uprX - treeShifting.width)
                    if lowestDelta > delta {
                        lowestDelta = delta
                        w = uprX
                    }
                }
            case .lowY:
                for branchVm in branchVms {
                    let lowY = branchVm.shiftRange.1.lowerBound
                    let delta =  abs(lowY - treeShifting.height)
                    if lowestDelta > delta {
                        lowestDelta = delta
                        h = lowY
                    }
                }

            case .uprY:
                for branchVm in branchVms {
                    let uprY = branchVm.shiftRange.1.upperBound
                    let delta =  abs(uprY - treeShifting.height)
                    if lowestDelta > delta {
                        lowestDelta = delta
                        h = uprY
                    }
                }
        }
        return CGSize(width: w, height: h)
        //log("shiftNearest ", ["shifting", treeShifting, "inward: ", goingInward ])
    }

    func shiftTree(_ touchState: MuTouchState?,
                   _ fromRemote: Bool) {

        if let touchState, touchState.phase == .ended {
            treeShifting = shiftNearest()
            treeShifted = treeShifting
        } else if let shiftRange = branchVms.last?.shiftRange {
            /// constrain shifting only towards root's corner
            let moved = touchState?.moved ?? .zero
            treeShifting = (treeShifted + moved).clamped(to: shiftRange)
        }
        updateBranches(fromRemote)
    }
    func shiftExpandLast(_ fromRemote: Bool) {

        // print("*** shiftExpandLast")
        treeShifting = .zero
        treeShifted  = .zero
        updateBranches(fromRemote)
    }

    func shiftTree(to index: Int) {

        if index < branchVms.count, index >= 0 {
           let startBranchVm = branchVms[index]
            treeShifting = cornerAxis.outerLimit(of: startBranchVm.shiftRange)
            treeShifted = treeShifting
        }
    }

    func updateBranches(_ fromRemote: Bool) {

        var isHidden = true // tucked in from shifting inward
        var index = 0
        for branchVm in branchVms {
            let opacity = branchVm.shiftBranch()
            if isHidden, opacity > 0.5 {
                startIndex = index
                isHidden = false
            }
            index += 1
        }
        if !fromRemote {
            let rootItem = MenuRootItem(rootVm)
            let menuItem = MenuItem(root: rootItem)
            rootVm.sendItemToPeers(menuItem)
        }
    }
    
}
