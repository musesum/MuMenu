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

    /// constrain shifting only towards root's corner
    private func shiftConstrain(_ moved: CGPoint) {
        guard branchVms.count > 0 else { return }

        var outerBranch: MuBranchVm
        switch cornerAxis.bound {

            case .lowX: outerBranch = branchVms.last!
            case .uprX: outerBranch = branchVms.last!
            case .lowY: outerBranch = branchVms.last!
            case .uprY: outerBranch = branchVms.last!
        }
        treeShifting = (treeShifted + moved).clamped(to: outerBranch.shiftRange)
        switch cornerAxis.bound {
                
            case .lowX: goingInward = moved.x < 0
            case .uprX: goingInward = moved.x > 0
            case .lowY: goingInward = moved.y < 0
            case .uprY: goingInward = moved.y > 0
        }
        // log("\nshiftConstrain ", [ "shifted", treeShifted, "shifting", treeShifting, "moved", moved, "inward: ", goingInward ])
    }

    func shiftTree(_ touchState: MuTouchState?,
                   _ fromRemote: Bool) {

        guard let lastBranchVm = branchVms.last else { return }

        if let touchState, touchState.phase == .ended {
            treeShifting = (touchState.touchEndedCount > 0
                            ? (goingInward
                                ? cornerAxis.outerLimit(of: lastBranchVm.shiftRange)
                                : .zero) // .zero fully expands
                            : shiftNearest())

            goingInward = false
            treeShifted = treeShifting
        } else {
            shiftConstrain(touchState?.moved ?? .zero)
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
