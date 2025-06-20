// created by musesum 10/27/21.
import SwiftUI
import MuFlo

enum TreeState: String { case hideTree, canopy, showTree }

public class TreeVm: Identifiable, Equatable, ObservableObject {

    public static func == (lhs: TreeVm, rhs: TreeVm) -> Bool { return lhs.id == rhs.id }
    public static var sideAxis = [String: TreeVm]()
    public var id = Visitor.nextId()
    @Published var branchVms = [BranchVm]()

    @Published var treeShift = CGSize.zero { didSet { updateTreeBounds() } }
    var treeShifted = CGSize.zero

    @Published var treeBounds: CGRect = .zero
    var treeBoundsPad: CGRect = .zero

    @Published var treeState: TreeState = .showTree
    var hideAnimationTimer: Timer?

    @Published var interval: TimeInterval = 2.0

    var rootVm: RootVm
    var branchSpotVm: BranchVm?
    var menuType: MenuType
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
                _ menuType: MenuType) {

        self.rootVm = rootVm
        self.menuType = menuType
        TreeVm.sideAxis[menuType.key] = self
    }
    
    public func addBranchVm(_ branchVm: BranchVm) {
        self.branchVms.append(branchVm)
        for branchVm in branchVms {
            branchVm.updateTree(self)
        }
    }
    
}
