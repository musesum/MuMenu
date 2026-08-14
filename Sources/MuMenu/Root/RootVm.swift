// created by musesum 10/13/21.

import SwiftUI
import Combine
import MuFlo
#if !os(watchOS)
import MuPeers
import MuVision
import MuHands
#endif
@MainActor
public class RootVm: @unchecked Sendable, ObservableObject, @MainActor Equatable {

    private var cancellables = Set<AnyCancellable>()
    @ObservedObject var handsPhase: HandsPhase

    public static func == (lhs: RootVm, rhs: RootVm) -> Bool { return lhs.id == rhs.id }
    let id = Visitor.nextId()
    let archiveVm: ArchiveVm

    /// what is the finger touching now?
    @Published var touchType = TouchType.none
    /// what was finger touching at began phase?
    var touchTypeBegin = TouchType.none

    /// starting corner to dispatch 
    public let cornerVm: CornerVm!
    
    /// which menu elements are shown on View
    var viewOps: Set<TouchType> = [.root, .trunks]
    /// state during touchBegin
    var beginViewOps: Set<TouchType> = []
    
    public var cornerType: MenuType /// corner where root begins, ex: `[down,left]`

    public internal(set) var treeVms = [TreeVm]() /// vertical or horizontal stack of branches
    var treeSpotVm: TreeVm? /// most recently used tree
    var touchState = TouchState()

    // all menu corners, backfilled by Menus.init after both exist
    var menuVms: MenuVms
    var _menuSpotVm: MenuVm?
    var menuSpot: MenuVm? {
        if let _menuSpotVm { return _menuSpotVm }
        for menuVm in menuVms {
            if menuVm.cornerType == cornerType {
                _menuSpotVm = menuVm
                return menuVm
            }
        }
        //PrintLog("RootVm::menuSpot[\(_menuSpotVm?.cornerType.icon ?? "??")] not found")
        return nil
    }
    /// current last touched or hovered node
    public var nodeSpotVm: NodeVm? {
        didSet { MenuLineage.shared.post(nodeSpotVm) } // read-only seam for the graph leaf
    }
    private var handState: leftRight<TouchPhase> = .init(.ended, .ended)
    
    public init(_ cornerType : MenuType,
                _ logoName   : String,
                _ menuVms    : MenuVms,
                _ archiveVm  : ArchiveVm,
                _ handsPhase : HandsPhase) {

        self.cornerType = cornerType
        self.menuVms = menuVms
        self.cornerVm = CornerVm(cornerType, logoName)
        self.archiveVm = archiveVm
        self.handsPhase = handsPhase

        handsPhase.$update.sink { _ in
            self.updateHandsPhase()
        }.store(in: &cancellables)

        #if !os(watchOS)
        Peers.shared.addDelegate(self, for: .menuItem)
        #endif
    
        #if canImport(WatchConnectivity) && (os(iOS) || os(watchOS))
        _ = WatchSync.shared
        #endif
    }
    public func addTreeVm(_ treeVm: TreeVm) {
        self.treeVms.append(treeVm)
        cornerVm.setRoot(self)
        updateTreeOffsets()
    }

    func showFirstTree(fromRemote: Bool = false) {
        if let treeVm = treeVms.first {
            treeSpotVm = treeVm
            treeVm.growTree(depth: 9, "first", fromRemote)
            viewOps = [.root]
        }
    }

    /// when overlapping, hide other
    func hideOverlapped(_ growing: TreeVm) {
        guard growing.showTree.state != .hidden,
              !growing.showTree.collapsing,
              growing.treeBounds != .zero else { return }
        for menuVm in menuVms where menuVm.rootVm !== self {
            for tree in menuVm.rootVm.treeVms {
                if tree.showTree.state != .hidden,
                   tree.treeBounds != .zero,
                   growing.treeBounds.intersects(tree.treeBounds) {
                    tree.showTree.fadeNow()
                }
            }
        }
    }

}

