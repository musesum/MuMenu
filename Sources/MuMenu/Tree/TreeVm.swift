// created by musesum 10/27/21.
import SwiftUI
import MuFlo

class ShowState: ObservableObject, @unchecked Sendable {
    @Published private var state: State = .showing

    private enum State: String {
        case hidden, fadeOut, showing
    }
    var opacity: CGFloat {
        switch state {
        case .hidden  : return 0.00
        case .showing : return 1.00
        case .fadeOut : return 0.05
        }
    }

    let autoFadeInterval: TimeInterval = 4.0
    let fadeOutInterval: TimeInterval = 8.0
    let animInterval: TimeInterval = 0.25
    let tapInterval: TimeInterval = 0.5

    var animation: Animation {
        switch state {
        case .hidden  : return Animate(animInterval)
        case .showing : return Animate(animInterval)
        case .fadeOut : return Animate(fadeOutInterval)
        }
    }

    var autoFadeTimer: Timer?
    var fadeOutTimer: Timer?
    var fadeInTimer: Timer?
    var showStartTime: TimeInterval = 0.0

    func clearTimers() {
        autoFadeTimer?.invalidate()
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
    }

    public func startAutoFade() {

        clearTimers()
        PrintLog("\(#function) from state: \(state.rawValue)" )
        if state == .hidden {
            print("??")
        }

        autoFadeTimer = Timer.scheduledTimer(
            withTimeInterval: autoFadeInterval,
            repeats: false) { _ in

                self.fadeOut()
            }
    }
    func fadeOut() {
        clearTimers()
        PrintLog("\(#function) from state: \(state.rawValue)" )
        state = .fadeOut

        fadeOutTimer = Timer.scheduledTimer(
            withTimeInterval: fadeOutInterval,
            repeats: false) {_ in

                self.hideTree()
            }
    }
    func hideTree() {
        clearTimers()
        PrintLog("\(#function) from state: \(state.rawValue)" )
        state = .hidden
    }

    func showTree() {
        clearTimers()
        PrintLog("\(#function) from state: \(state.rawValue)" )
        if state == .hidden {
            showStartTime = Date().timeIntervalSince1970
        }
        state = .showing
        startAutoFade()
    }

    func toggleTree() {
        let timeNow = Date().timeIntervalSince1970
        let timeElapsed: TimeInterval = timeNow - showStartTime
        if timeElapsed < tapInterval {
            PrintLog("\(#function) timeElapsed \(timeElapsed.digits(2)) < fadeInInterval now state: \(state.rawValue)" )
            return //.....
        }

        switch state {
        case .showing, .fadeOut : hideTree()
        case .hidden            : showTree()
        }
        PrintLog("\(#function) timeElapsed \(timeElapsed.digits(2)) state: \(state.rawValue)" )
    }
}

public class TreeVm: Identifiable, Equatable, ObservableObject, @unchecked Sendable {

    public static func == (lhs: TreeVm, rhs: TreeVm) -> Bool { return lhs.id == rhs.id }
    nonisolated(unsafe) public static var sideAxis = [String: TreeVm]()
    public var id = Visitor.nextId()
    @Published var branchVms = [BranchVm]()

    @Published var treeShift = CGSize.zero { didSet { updateTreeBounds() } }
    var treeShifted = CGSize.zero

    @Published var treeBounds: CGRect = .zero
    var treeBoundsPad: CGRect = .zero

    @Published var showState = ShowState()

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
            var branchBounds = branchVm.boundsNow
            if menuType.vertical {
                branchBounds.origin.y = max(0, branchBounds.origin.y - 20)
            }
            rect = rect.extend(branchBounds)
        }
        treeBounds = rect
        treeBoundsPad = treeBounds.pad(Menu.padding2)
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
