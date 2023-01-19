// Created by warren 10/27/21.
import SwiftUI


public var CornerAxisTreeVm = [Int: MuTreeVm]()

public class MuTreeVm: Identifiable, Equatable, ObservableObject {
    
    public let id = MuNodeIdentity.getId()
    public static func == (lhs: MuTreeVm, rhs: MuTreeVm) -> Bool { return lhs.id == rhs.id }

    @Published var branchVms = [MuBranchVm]()
    @Published var treeShift = CGSize.zero {
        didSet { updateTreeBounds() } }
    @Published var treeBounds: CGRect = .zero
    var treeBoundsPad: CGRect = .zero
    var treeBoundsGhost: CGRect = .zero //??? 
    
    var treeShifted = CGSize.zero
    
    var rootVm: MuRootVm
    var branchSpotVm: MuBranchVm?
    var cornerAxis: CornerAxis
    let isVertical: Bool
    var treeOffset = CGSize.zero // offset of menu tree from corner
    var depthShown = 0 // levels of branches shown
    var startIndex = 0

    func updateTreeBounds() {
        var rect = CGRect.zero
        if depthShown == 0 {
            treeBounds = .zero
            return
        }
        for branchVm in branchVms {
            if (branchVm.opacity < 0.1 ||
                branchVm.show == false) {
                continue
            }
            // print(branchVm.title.pad(10) + (isVertical?" V":" H"), terminator: " ")
            rect = rect.extend(branchVm.boundsNow)
        }
        treeBounds = rect
        treeBoundsPad = treeBounds.pad(Layout.padding * 2)
        treeBoundsGhost = treeBoundsGhost.extend(treeBoundsPad)
    }
    
    public init(_ rootVm: MuRootVm,
                _ cornerAxis: CornerAxis) {

        self.rootVm = rootVm
        self.cornerAxis = cornerAxis
        self.isVertical = cornerAxis.axis == .vertical
        CornerAxisTreeVm[cornerAxis.cornax.rawValue] = self
    }
    
    public func addBranchVms(_ branchVms: [MuBranchVm]) {
        self.branchVms.append(contentsOf: branchVms)
        for branchVm in branchVms {
            branchVm.updateTree(self)
        }
    }

}
