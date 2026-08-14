// created by musesum 10/27/21.

import SwiftUI
import Combine
import MuFlo

@MainActor
public class TreeVm: @MainActor Identifiable, @MainActor Equatable, ObservableObject, @unchecked Sendable {

    public static func == (lhs: TreeVm, rhs: TreeVm) -> Bool { return lhs.id == rhs.id }
    nonisolated(unsafe) public static var sideAxis = [String: TreeVm]()
    public var id = Visitor.nextId()
    @Published var branchVms = [BranchVm]()

    @Published var treeShift = CGSize.zero { didSet { updateTreeBounds() } }
    var treeShifted = CGSize.zero

    @Published var treeBounds: CGRect = .zero

    @Published public internal(set) var showTree = ShowTime(.hidden) /// growTree shows it

    var rootVm: RootVm
    var branchSpotVm: BranchVm?
    var menuType: MenuType
    var treeOffset = CGSize.zero // offset of menu tree from corner
    var depthShown = 0 // levels of branches shown
    var startIndex = 0
    private var stateSink: AnyCancellable?
    private var screenSink: AnyCancellable?
    private var screenBounds = CGRect.zero

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
            var branchBounds = branchVm.boundsNow
            if menuType.vertical {
                branchBounds.origin.y = max(0, branchBounds.origin.y - 20)
            }
            rect = rect.extend(branchBounds)
        }
        treeBounds = rect
        rootVm.hideOverlapped(self)
    }

    /// touch containment = union of VISIBLE branch bounds. Never the hull
    /// rect: a tall trunk beside a short wide leaf leaves
    /// an empty hull corner that would swallow canvas touches
    func treeContains(_ point: CGPoint) -> Bool {
        for branchVm in branchVms
        where branchVm.show && branchVm.opacity >= 0.1 {
            if branchVm.contains(point) { return true }
        }
        return false
    }

    public init(_ rootVm: RootVm,
                _ menuType: MenuType) {

        self.rootVm = rootVm
        self.menuType = menuType
        TreeVm.sideAxis[menuType.key] = self

        // re-shown tree re-enters the overlap check (remote setState / toggleTree paths change no bounds)
        stateSink = showTree.$state.sink { [weak self] state in
            guard let self else { return }
            DispatchQueue.main.async {
                if state.hidden {
                    // a closed tree re-anchors its panels to the corner
                    self.reanchorPanels()
                } else if state.showing {
                    self.updateTreeBounds()
                }
            }
        }
        #if os(iOS)
        // rotation re-anchors panels; keyboard-shrunk containers keep screen bounds and pass through
        screenSink = MenuScreen.shared.size.sink { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let bounds = UIScreen.main.bounds
                if self.screenBounds != bounds {
                    self.screenBounds = bounds
                    self.reanchorPanels()
                }
            }
        }
        #endif
    }

    /// the single panelOrigin zeroer; closed trees and rotated screens land here
    func reanchorPanels() {
        for branchVm in branchVms { branchVm.panelOrigin = .zero }
    }
    
    /// true when a shown branch carries a leaf which pins the tree open
    var disablesAutoFade: Bool {
        for branchVm in branchVms where branchVm.show {
            for nodeVm in branchVm.nodeVms where nodeVm.disablesAutoFade {
                return true
            }
        }
        return false
    }

    public func addBranchVm(_ branchVm: BranchVm) {
        self.branchVms.append(branchVm)
        for branchVm in branchVms {
            branchVm.updateTree(self)
        }
    }
    
}
