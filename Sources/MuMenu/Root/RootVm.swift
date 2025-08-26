// created by musesum 10/13/21.

import SwiftUI
import Combine
import MuPeers
import MuFlo
import MuVision
import MuHands
@MainActor
public class RootVm: @unchecked Sendable, ObservableObject, @MainActor Equatable {

    private var cancellables = Set<AnyCancellable>()
    @ObservedObject var handsPhase: HandsPhase

    public static func == (lhs: RootVm, rhs: RootVm) -> Bool { return lhs.id == rhs.id }
    let id = Visitor.nextId()
    let archiveVm: ArchiveVm
    let share: Share

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

    var treeVms = [TreeVm]() /// vertical or horizontal stack of branches
    var treeSpotVm: TreeVm? /// most recently used tree
    var touchState = TouchState()

    // all menu corners
    let menuVms: MenuVms
    var _menuSpotVm: MenuVm?
    var menuSpot: MenuVm? {
        if let _menuSpotVm { return _menuSpotVm }
        for menuVm in menuVms {
            if menuVm.cornerType == cornerType {
                _menuSpotVm = menuVm
                return menuVm
            }
        }
        PrintLog("RootVm::menuSpot[\(menuSpot?.cornerType.icon ?? "??")] not found")
        return nil
    }
    public var nodeSpotVm: NodeVm?   /// current last touched or hovered node
    private var handState: leftRight<TouchPhase> = .init(.ended, .ended)
    
    public init(_ cornerType : MenuType,
                _ menuVms    : MenuVms,
                _ archiveVm  : ArchiveVm,
                _ handsPhase : HandsPhase,
                _ share      : Share) {

        self.cornerType = cornerType
        self.menuVms = menuVms
        self.cornerVm = CornerVm(cornerType)
        self.archiveVm = archiveVm
        self.handsPhase = handsPhase
        self.share = share

        handsPhase.$update.sink { _ in
            self.updateHandsPhase()
        }.store(in: &cancellables)
        
        share.peers.addDelegate(self, for: .menuFrame)
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

}

