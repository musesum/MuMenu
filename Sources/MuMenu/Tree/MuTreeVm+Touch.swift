//  Created by warren on 12/14/22.

import Foundation

extension MuTreeVm {

    func nearestTrunk(_ touchNow: CGPoint) -> MuBranchVm? {
        if let firstBranch = branchVms.first,
           firstBranch.show,
           firstBranch.boundsPad.contains(touchNow) {
            return firstBranch
        }
        return nil
    }
    func nearestBranch(_ touchNow: CGPoint) -> MuBranchVm? {

        let opacityThreshold = 0.6

        if let branchSpot = branchSpotVm,
           branchSpot.boundsPad.contains(touchNow),
           branchSpot.branchOpacity > opacityThreshold,
           branchSpot.show {

            return branchSpot
        }

        for branchVm in branchVms {
            if branchVm.show == true,
               branchVm.branchOpacity > opacityThreshold,
               branchVm.boundsPad.contains(touchNow) {
                branchSpotVm = branchVm
                return branchVm
            }
        }
        branchSpotVm = nil
        return nil
    }

}
