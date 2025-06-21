//  created by musesum on 12/14/22.

import Foundation
import MuFlo

extension TreeVm {

    func TreeLog(_ msg: String) {
        NoDebugLog { P(msg, terminator:"")}
    }
    func nearestTrunk(_ touchNow: CGPoint) -> BranchVm? {
        let trunkIndex = startIndex + depthShown - 1
        if depthShown > 0,
           trunkIndex < branchVms.count {
           let branchVm = branchVms[trunkIndex]
            if branchVm.contains(touchNow) {

                TreeLog("T⃣")
                return branchVm
            }
        }
        return nil
    }
    func nearestNode(_ touchNow: CGPoint) -> NodeVm? {
        return nearestBranch(touchNow)?.nearestNode(touchNow) ?? nil
    }
    func nearestBranch(_ touchNow: CGPoint) -> BranchVm? {

        guard depthShown > 0 else { return nil }
        let opacityThreshold = 0.6

        if let branchSpotVm,
           branchSpotVm.contains(touchNow),
           branchSpotVm.opacity > opacityThreshold,
           branchSpotVm.show {

            TreeLog("b⃣")

            return branchSpotVm
        }

        for branchVm in branchVms {
            if branchVm.show == true,
               branchVm.opacity > opacityThreshold,
               branchVm.contains(touchNow) {

                branchSpotVm = branchVm
                TreeLog("B⃣")
                return branchVm
            }
        }
        branchSpotVm = nil
        return nil
    }

}
