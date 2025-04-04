//  created by musesum on 12/14/22.

import Foundation

@MainActor
extension TreeVm {

    func nearestTrunk(_ touchNow: CGPoint) -> BranchVm? {
        let trunkIndex = startIndex + depthShown - 1
        if depthShown > 0,
           trunkIndex < branchVms.count {
           let branchVm = branchVms[trunkIndex]
            if branchVm.contains(touchNow) {
                return branchVm
            }
        }
        return nil
    }
    func nearestBranch(_ touchNow: CGPoint) -> BranchVm? {

        guard depthShown > 0 else { return nil }
        let opacityThreshold = 0.6

        if let branchSpotVm,
           branchSpotVm.contains(touchNow),
           branchSpotVm.opacity > opacityThreshold,
           branchSpotVm.show {

            return branchSpotVm
        }

        for branchVm in branchVms {
            if branchVm.show == true,
               branchVm.opacity > opacityThreshold,
               branchVm.contains(touchNow) {
                branchSpotVm = branchVm
                return branchVm
            }
        }
        branchSpotVm = nil
        return nil
    }

}
