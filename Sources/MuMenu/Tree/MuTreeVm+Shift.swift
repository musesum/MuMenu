//  Created by warren on 12/14/22.


import Foundation
extension MuTreeVm { // + Shift


    func shiftExpand() {
        treeShifting = .zero
        treeShifted = .zero
    }

    func shiftTree(_ rootVm: MuRootVm,
                   _ touchState: MuTouchState,
                   minZero: Bool = false) {

        if touchState.phase == .ended {
            if touchState.touchEndedCount > 0 {
                shiftExpand()
            } else {
                treeShifted = treeShifting
            }
            return
        }

        treeShifting = shiftConstrained()
        // log("\ntreeShifting", [treeShifting, "root", rootVm.touchVm.parkIconXY])
        for branchVm in branchVms {
            branchVm.shiftBranch()
        }

        /// constrain shifting only towards root's corner
        func shiftConstrained() -> CGSize {
            let beginΔ = minZero ? .zero : touchState.pointBeginΔ
            let beginLimit =  (axis == .vertical
                               ? CGSize(width:  beginΔ.x, height: 0)
                               : CGSize(width: 0, height: beginΔ.y) )

            var constrain = treeShifted + beginLimit

            if axis == .vertical {
                constrain.width =  (corner.contains(.left)
                                    ? min(0, constrain.width)
                                    : max(0, constrain.width))
            } else { // .horizontal
                constrain.height = (corner.contains(.upper)
                                    ? min(0, constrain.height)
                                    : max(0, constrain.height))
            }
            return constrain
        }
    }

}
