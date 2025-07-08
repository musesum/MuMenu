// created by musesum 10/13/21.

import SwiftUI
import MuPeers
import MuFlo
import MuVision

public class RootVm: @unchecked Sendable, ObservableObject, Equatable {

    public static func == (lhs: RootVm, rhs: RootVm) -> Bool { return lhs.id == rhs.id }
    let id = Visitor.nextId()
    let archiveVm: ArchiveVm
    let peers: Peers

    /// what is the finger touching now?
    @Published var touchType = TouchType.none
    /// what was finger touching at began phase?
    var touchTypeBegin = TouchType.none

    /// starting corner to dispatch 
    public let cornerVm: CornerVm!
    
    /// which menu elements are shown on View
    var viewOps: Set<TouchType> = [.root, .trunks]
    
    /// `touchBegin` snapshot of viewElements.
    /// To prevent touchEnded from hiding elements that were shown during `touchBegin`
    var beginViewOps: Set<TouchType> = []
    
    public var cornerType: MenuType /// corner where root begins, ex: `[down,left]`
    var treeVms = [TreeVm]() /// vertical or horizontal stack of branches
    var treeSpotVm: TreeVm? /// most recently used tree

    var autoHideMenu = true
    var autoHideTimer: Timer?
    var autoHideInterval = TimeInterval(12)

    var touchState = TouchState()

    public var nodeSpotVm: NodeVm?   /// current last touched or hovered node

    public init(_ cornerType : MenuType  ,
                _ archiveVm  : ArchiveVm ,
                _ peers      : Peers     ) {

        self.cornerType = cornerType
        self.cornerVm = CornerVm(cornerType)
        self.archiveVm = archiveVm
        self.peers = peers
        peers.setDelegate(self, for: .menuFrame)
    }
    deinit {
        peers.removeDelegate(self)
    }
    public func addTreeVm(_ treeVm: TreeVm) {
        self.treeVms.append(treeVm)
        cornerVm.setRoot(self)
        updateTreeOffsets()
    }

    func reshowTree(_ fromRemote: Bool) {
        for treeVm in treeVms {
            treeVm.reshowTree(fromRemote)
        }
    }
    func hideBranches(_ touchType: TouchType, _ fromRemote: Bool) {
        autoHideTimer?.invalidate()
        for treeVm in treeVms {
            treeVm.hideTree(touchType, fromRemote)
        }
        viewOps = [.root]
    }
    
    func showFirstTree(fromRemote: Bool = false) {
        if let treeVm = treeVms.first {
            treeSpotVm = treeVm
            treeVm.showTree(depth: 9, "first", fromRemote)
            viewOps = [.root,.branch]
        }
    }

}
