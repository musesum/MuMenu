#if !os(watchOS)
//  created by musesum on 12/5/22.


import SwiftUI
import MuPeers
import MuFlo

public class LeafPeerVm: LeafVm {

    private static let bonjourKey = "peers.bonjour"

    /// bonjour switch, kept across launches. Off cancels the listener, the
    /// browser and every live link; on re-arms them with the tapeProto the app
    /// registered at launch. A fresh install starts on, which is how the app
    /// behaved before the switch existed
    @Published public var bonjourOn = LeafPeerVm.keptBonjour {
        didSet {
            UserDefaults.standard.set(bonjourOn, forKey: Self.bonjourKey)
            applyBonjour()
        }
    }

    private static var keptBonjour: Bool {
        UserDefaults.standard.object(forKey: bonjourKey) == nil
        ? true
        : UserDefaults.standard.bool(forKey: bonjourKey)
    }

    override public func touchLeaf(_ : TouchState, _ : Visitor) {}
    override public func treeTitle() -> String { "" }
    override public func leafTitle() -> String { "\(Peers.shared.peerId)" }
    override public func syncVal(_ : Visitor) {}

    override init (_ menuTree: MenuTree,
                   _ branchVm: BranchVm,
                   _ prevVm: NodeVm?,
                   _ runTypes: [LeafRunwayType]) {

        super.init(menuTree, branchVm, prevVm, runTypes)
        // a switch left off outlives the launch that turns peers on: the menu
        // builds before the app registers its tapeProto, so the kept state is
        // put back on the next turn of the loop, behind that registration
        DispatchQueue.main.async { [weak self] in self?.applyBonjour() }
    }

    /// the switch, live. Both legs serialize through the same `peersTask`
    /// inside Peers, so a fast off-on-off ends where the last press asked
    private func applyBonjour() {
        if bonjourOn {
            Peers.shared.setupPeers()
        } else {
            Peers.shared.cancelPeers()
        }
    }
}
#endif
