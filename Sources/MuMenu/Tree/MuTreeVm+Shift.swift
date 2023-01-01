//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm { // + Shift

    func shiftExpandLast() {
        print("*** shiftExpandLast")
        treeShifting = .zero
        treeShifted  = .zero
    }

    private func shiftContract(_ branchVm: MuBranchVm?) {
        guard let branchVm else { return }

        treeShifting = cornerAxis.outerLimit(of: branchVm.shiftRange)
        log("shiftContract ", ["shifting", treeShifting, "inward: ", goingInward ])
        goingInward = false
    }

    private func shiftNearest() {

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
        treeShifting = CGSize(width: w, height: h)
        log("shiftNearest ", ["shifting", treeShifting, "inward: ", goingInward ])
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

        log("\nshiftConstrain ", [
            "shifted", treeShifted,
            "shifting", treeShifting,
                                  "moved", moved,
                                  "inward: ", goingInward
                                 ])

    }

    func shiftTree(_ touchState: MuTouchState) {

        if touchState.phase == .ended {
            if touchState.touchEndedCount > 0 {
                if goingInward {
                    shiftContract(branchVms.last)
                } else {
                    shiftExpandLast()
                }
            } else {
                shiftNearest()
            }
            treeShifted = treeShifting
        } else {
            shiftConstrain(touchState.moved)
        }

        for branchVm in branchVms {
            branchVm.shiftBranch()
        }
    }

}
