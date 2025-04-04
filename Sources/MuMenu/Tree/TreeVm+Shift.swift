//  created by musesum on 12/14/22.

import Foundation
import MuFlo

@MainActor
extension TreeVm { // + Shift

    public func shiftNearest() {

        var lowestDelta = CGFloat.infinity
        var w = CGFloat.zero
        var h = CGFloat.zero

        switch corner.bound {
            case .lowerX:
                for branchVm in branchVms {
                    let lowX = branchVm.shiftRange.0.lowerBound
                    let delta = abs(lowX - treeShift.width)

                    if lowestDelta > delta {
                        lowestDelta = delta
                        w = lowX
                    }
                }
            case .upperX:
                for branchVm in branchVms {
                    let uprX = branchVm.shiftRange.0.upperBound
                    let delta =  abs(uprX - treeShift.width)
                    if lowestDelta > delta {
                        lowestDelta = delta
                        w = uprX
                    }
                }
            case .lowerY:
                for branchVm in branchVms {
                    let lowY = branchVm.shiftRange.1.lowerBound
                    let delta =  abs(lowY - treeShift.height)
                    if lowestDelta > delta {
                        lowestDelta = delta
                        h = lowY
                    }
                }

            case .upperY:
                for branchVm in branchVms {
                    let uprY = branchVm.shiftRange.1.upperBound
                    let delta =  abs(uprY - treeShift.height)
                    if lowestDelta > delta {
                        lowestDelta = delta
                        h = uprY
                    }
                }
        }
        treeShift = CGSize(width: w, height: h)
        treeShifted = treeShift
        //log("shiftNearest ", ["shifting", treeShift, "inward: ", goingInward ])
    }

    func shiftTree(_ touchState: TouchState?,
                   _ fromRemote: Bool) {

        if let touchState, touchState.phase == .ended {
            shiftNearest()
        } else if let shiftRange = branchVms.last?.shiftRange {
            /// constrain shifting only towards root's corner
            let moved = touchState?.moved ?? .zero
            treeShift = (treeShifted + moved).clamped(to: shiftRange)
        }
        updateBranches(fromRemote)
    }
    func shiftExpandLast(_ fromRemote: Bool) {
        treeShift = .zero
        treeShifted  = .zero
        updateBranches(fromRemote)
    }

    func shiftTree(to index: Int) {

        if index < branchVms.count, index >= 0 {
           let startBranchVm = branchVms[index]
            treeShift = corner.outerLimit(of: startBranchVm.shiftRange)
            treeShifted = treeShift
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
