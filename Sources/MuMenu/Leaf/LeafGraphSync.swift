#if !os(watchOS)
//  created by musesum on 8/12/26

import Foundation
import MuPeers

/// the graph leaf's cross-device state: the controls the overview column
/// carries, and the layout the hand leaves behind. It rides `gestureItem`,
/// the wire's own control-event kind, so no framer case is minted for it
public struct GraphSyncItem: Codable, Sendable {

    public var depth: Double        /// Depth slider stop, `depthMost` for the horizon
    public var mode: String         /// Focus, Context or All
    public var community: Double    /// dendrogram cut, 0 for off
    public var menu: Bool           /// menu-sync channel
    public var icon: Bool           /// icon channel
    public var colors: [String: Bool]  /// legend filters: name, in, out, sync
    /// [id, x, y] per node; empty when the message carries controls only
    public var nodes: [[Double]]
    /// live-event channel; absent from a build that had no such channel
    public var live: Bool?

    public init(depth: Double,
                mode: String,
                community: Double,
                menu: Bool,
                icon: Bool,
                colors: [String: Bool],
                nodes: [[Double]],
                live: Bool? = nil) {
        self.depth = depth
        self.mode = mode
        self.community = community
        self.menu = menu
        self.icon = icon
        self.colors = colors
        self.nodes = nodes
        self.live = live
    }
}

/// The delivery side runs on main — every link hands its messages over inside
/// a `Task { @MainActor }` — so the conformance is isolated the way RootVm's is
extension LeafGraphVm: @MainActor PeersDelegate {

    public func received(data: Data, from: DataFrom) {
        guard let item = try? JSONDecoder().decode(GraphSyncItem.self, from: data)
        else { return }
        applyGraphSync(item)
    }

    /// a peer arriving takes one push, from the lower peerId only, so two
    /// devices meeting do not both push and cross. A leaf that was never
    /// opened has nothing but its defaults to offer and stays quiet, which is
    /// what keeps a device that has been driven from being reset by one that
    /// has not
    public func joined(from: DataFrom) {
        guard case let .remote(peer) = from,
              Peers.shared.peerId < peer,
              runScript != nil else { return }
        sendGraphSync(layoutNodes())
    }

    public func shareItem(_: Any) { }
    public func resetItem(_: PlayItem) { }
    public func playItem(_: PlayItem, from: DataFrom) { }
    public func dropped(from: DataFrom) { }
}
#endif
