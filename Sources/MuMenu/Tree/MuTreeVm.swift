// Created by warren 10/27/21.
import SwiftUI

public class MuTreeVm: Identifiable, Equatable, ObservableObject {
    public let id = MuNodeIdentity.getId()
    public static func == (lhs: MuTreeVm, rhs: MuTreeVm) -> Bool { return lhs.id == rhs.id }
    
    @Published var branchVms = [MuBranchVm]()
    @Published var treeShifting = CGSize.zero /// offset after shifting (by dragging leaf)
    var treeShifted = CGSize.zero
    
    var rootVm: MuRootVm?
    var branchSpotVm: MuBranchVm?
    var axis: Axis
    var corner: MuCorner
    
    var treeOffset = CGSize.zero
    
    var level = CGFloat(1) // starting level for branches
    var depthShown = 0 // levels of branches shown
    
    public init(axis: Axis, corner: MuCorner) {
        self.axis = axis
        self.corner = corner
    }
    
    public func addBranchVms(_ branchVms: [MuBranchVm]) {
        self.branchVms.append(contentsOf: branchVms)
        for branchVm in branchVms {
            branchVm.updateTree(self)
        }
        showBranches(depth: 0)
    }

    func refreshTree(_ branchVm: MuBranchVm) {

        var branchVm = branchVms.first
        var newBranches = [MuBranchVm]()
        while branchVm != nil {
            if let b = branchVm {
                b.show = true
                newBranches.append(b)
                branchVm = b.nodeSpotVm?.nextBranchVm
            }
        }
        branchVm = branchVms.first
        while branchVm != nil {
            if let b = branchVm {
                b.updateShiftRange()
                branchVm = b.nodeSpotVm?.nextBranchVm
            }
        }
        branchVms = newBranches
    }

  
}
