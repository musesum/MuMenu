// Created by warren 10/27/21.
import SwiftUI


public var CornerAxisTreeVm = [Int: MuTreeVm]()

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
    var startIndex = 0

    var treeBounds: CGRect {
        var rect = CGRect.zero
        if depthShown == 0 { return .zero }

        for branchVm in branchVms {
            if branchVm.show == false { continue }
            // print(branchVm.title.pad(10) + (isVertical ? " V" : " H"), terminator: " ")
            let bounds = branchVm.boundsNow

            rect = rect.extend(bounds)
        }
        return rect
    }
    
    public init(_ rootVm: MuRootVm,
                _ cornerAxis: CornerAxis) {

        self.rootVm = rootVm
        self.cornerAxis = cornerAxis
        self.isVertical = cornerAxis.axis == .vertical
        let key = CornerAxis.Key(cornerAxis.corner.rawValue,
                                 cornerAxis.axis.rawValue)
        CornerAxisTreeVm[key] = self
    }
    
    public func addBranchVms(_ branchVms: [MuBranchVm]) {
        self.branchVms.append(contentsOf: branchVms)
        for branchVm in branchVms {
            branchVm.updateTree(self)
        }
    }

}
