// created by musesum 10/27/21.
import SwiftUI
import MuFlo

public var CornerAxisTreeVm = [CornerAxisId: TreeVm]()

public class TreeVm: Identifiable, Equatable, ObservableObject {
    
    public let id = Visitor.nextId()
    public static func == (lhs: TreeVm, rhs: TreeVm) -> Bool { return lhs.id == rhs.id }

    @Published var branchVms = [BranchVm]()

    @Published var treeShift = CGSize.zero { didSet { updateTreeBounds() } }
    var treeShifted = CGSize.zero

    @Published var treeBounds: CGRect = .zero
    var treeBoundsPad: CGRect = .zero

    var rootVm: RootVm
    var branchSpotVm: BranchVm?
    var cornerAxis: CornerAxis
    let isVertical: Bool
    var treeOffset = CGSize.zero // offset of menu tree from corner
    var depthShown = 0 // levels of branches shown
    var startIndex = 0

    /// convex hull around all branches of tree
    ///
    ///  - note: used for separating touches out from Canvas
    ///  
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
        treeBoundsPad = treeBounds.pad(Layout.padding2)
    }
    
    public init(_ rootVm: RootVm,
                _ cornerAxis: CornerAxis) {

        self.rootVm = rootVm
        self.cornerAxis = cornerAxis
        self.isVertical = cornerAxis.axis == .vertical
        CornerAxisTreeVm[cornerAxis.cornax.rawValue] = self
    }
    
    public func addBranchVms(_ branchVms: [BranchVm]) {
        self.branchVms.append(contentsOf: branchVms)
        for branchVm in branchVms {
            branchVm.updateTree(self)
        }
    }

}
