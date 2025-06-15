// created by musesum 10/27/21.
import SwiftUI
import MuFlo

enum ShowTree: String { case hide, canopy, show }

public class TreeVm: Identifiable, Equatable, ObservableObject {

    public static func == (lhs: TreeVm, rhs: TreeVm) -> Bool { return lhs.id == rhs.id }
    public static var sideAxis = [String: TreeVm]()
    public var id = Visitor.nextId()
    @Published var branchVms = [BranchVm]()

    @Published var treeShift = CGSize.zero { didSet { updateTreeBounds() } }
    var treeShifted = CGSize.zero

    @Published var treeBounds: CGRect = .zero
    var treeBoundsPad: CGRect = .zero

    @Published var showTree: ShowTree = .show
    var hideAnimationTimer: Timer?

    @Published var interval: TimeInterval = 2.0

    var rootVm: RootVm
    var branchSpotVm: BranchVm?
    var trunk: Trunk
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
            //print(branchVm.title.pad(10) + (isVertical ? " V" : " H"), terminator: " ") 
            rect = rect.extend(branchVm.boundsNow)
        }
        treeBounds = rect
        treeBoundsPad = treeBounds.pad(Layout.padding2)
    }
    
    public init(_ rootVm: RootVm,
                _ trunk: Trunk) {

        self.rootVm = rootVm
        self.trunk = trunk
        TreeVm.sideAxis[trunk.menuOp.key] = self
    }
    
    public func addBranchVm(_ branchVm: BranchVm) {
        self.branchVms.append(branchVm)
        for branchVm in branchVms {
            branchVm.updateTree(self)
        }
    }
    
}
