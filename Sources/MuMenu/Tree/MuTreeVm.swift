// Created by warren 10/27/21.
import SwiftUI



public class MuTreeVm: Identifiable, Equatable, ObservableObject {
    
    public let id = MuNodeIdentity.getId()
    public static func == (lhs: MuTreeVm, rhs: MuTreeVm) -> Bool { return lhs.id == rhs.id }
    
    @Published var branchVms = [MuBranchVm]()
    @Published var treeShifting = CGSize.zero /// offset after shifting (by dragging leaf)
    var treeShifted = CGSize.zero
    
    var rootVm: MuRootVm
    var branchSpotVm: MuBranchVm?
    var cornerAxis: CornerAxis
    let isVertical: Bool
    var treeOffset = CGSize.zero // offset of menu tree from corner
    var depthShown = 0 // levels of branches shown
    var goingInward = false
    var startIndex = 0
    
    public init(_ rootVm: MuRootVm,
                _ cornerAxis: CornerAxis) {

        self.rootVm = rootVm
        self.cornerAxis = cornerAxis
        self.isVertical = cornerAxis.axis == .vertical
    }
    
    public func addBranchVms(_ branchVms: [MuBranchVm]) {
        self.branchVms.append(contentsOf: branchVms)
        for branchVm in branchVms {
            branchVm.updateTree(self)
        }
        showTree(depth: 0, via: "add")
    }

    func refreshTree() {
        print("refresh\(isVertical ? "V" : "H") (s \(startIndex) d \(depthShown)) ", terminator: " ")

        var branchVm = branchVms.first
        var newBranches = [MuBranchVm]()

        while branchVm != nil {
            if let b = branchVm {
                b.show = true
                newBranches.append(b)
                branchVm = b.nodeSpotVm?.nextBranchVm
            }
        }
        for branch in newBranches {
            branch.updateShiftRange()
        }
        branchVms = newBranches
    }

//    func refreshTree(_ depthNext: Int) {
//
//        var indexNow = 0
//        var depthNow = 0
//
//        var branchVm = branchVms.first
//        var newBranches = [MuBranchVm]()
//
//        while depthNow >= depthNext,  branchVm != nil {
//            if let b = branchVm {
//                b.show = true
//                newBranches.append(b)
//                branchVm = b.nodeSpotVm?.nextBranchVm
//            }
//        }
//        for newBranch in newBranches {
//            newBranch.updateShiftRange()
//        }
//        branchVms = newBranches
//    }

  
}
