// WatchSync — bridges Apple Watch ↔ paired iPhone using WatchConnectivity.
//
// Why: watchOS NECP policy blocks Network framework / Bonjour over the
// IPSec companion tunnel — MuPeers cannot reach the phone from the watch.
// (Verified by Apple DTS in DevForums 665196 / 706445 / 127232 + TN3135.)
// WCSession is Apple's purpose-built watch↔phone transport that traverses
// the same tunnel via a sanctioned API.
//
// Direction this iteration: watch → phone only.
//   watch leaf change → encode MenuItem → WCSession.sendMessageData
//     → iOS delegate decodes → MenuTouch.remoteItem (existing pipeline)
//     → also re-broadcast to MuPeers mesh so iPad/Mac receive the update.

#if canImport(WatchConnectivity) && (os(iOS) || os(watchOS))
import Foundation
import WatchConnectivity
import MuFlo // Visitor for remote-receive dispatch
#if !os(watchOS)
import MuPeers
#endif

@MainActor
public final class WatchSync: NSObject {

    public static let shared = WatchSync()

    private var session: WCSession?

    override init() {
        super.init()
        guard WCSession.isSupported() else {
            print("📲 WatchSync: WCSession not supported")
            return
        }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        self.session = s
        print("📲 WatchSync: activating WCSession")
    }

    /// Send raw JSON-encoded MenuItem data to the companion device.
    /// Real-time path when reachable; falls back to applicationContext when
    /// not. WCSession internally batches and prioritizes — no app-level
    /// coalescing needed.
    public func send(_ data: Data) {
        guard let session, session.activationState == .activated else {
            print("📲 WatchSync.send: not activated")
            return
        }
        if session.isReachable {
            session.sendMessageData(data, replyHandler: nil) { error in
                print("📲 WatchSync sendMessageData error: \(error.localizedDescription)")
            }
        } else {
            do {
                try session.updateApplicationContext(["menuItem": data])
            } catch {
                print("📲 WatchSync updateApplicationContext error: \(error.localizedDescription)")
            }
        }
    }
}

extension WatchSync: WCSessionDelegate {

    nonisolated public func session(_ session: WCSession,
                                    activationDidCompleteWith activationState: WCSessionActivationState,
                                    error: (any Error)?) {
        let state: String
        switch activationState {
        case .notActivated: state = "notActivated"
        case .inactive:     state = "inactive"
        case .activated:    state = "activated"
        @unknown default:   state = "unknown(\(activationState.rawValue))"
        }
        print("📲 WatchSync activation=\(state) error=\(error?.localizedDescription ?? "none")")
    }

    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {
        print("📲 WatchSync sessionDidBecomeInactive")
    }
    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        print("📲 WatchSync sessionDidDeactivate — reactivating")
        session.activate()
    }
    nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
        print("📲 WatchSync reachable=\(session.isReachable)")
    }
    #endif

    nonisolated public func session(_ session: WCSession,
                                    didReceiveMessageData messageData: Data) {
        Task { @MainActor in WatchSync.shared.handle(messageData) }
    }

    nonisolated public func session(_ session: WCSession,
                                    didReceiveApplicationContext applicationContext: [String : Any]) {
        guard let data = applicationContext["menuItem"] as? Data else { return }
        Task { @MainActor in WatchSync.shared.handle(data) }
    }

    @MainActor
    private func handle(_ data: Data) {
        guard let item = try? JSONDecoder().decode(MenuItem.self, from: data) else {
            print("📲 WatchSync ingress: failed to decode MenuItem")
            return
        }
        #if !os(watchOS)
        // Phone-side ingress: feed the existing MenuTouch buffer (it handles
        // .node/.leaf/.trees dispatch + remoteThumb application) and then
        // re-broadcast to the MuPeers mesh so iPad/Mac peers see the update.
        MenuTouch.remoteItem(item, from: .remote("watch"))
        let path = item.wordPathDotted
        Task.detached {
            await Peers.shared.sendItem(.menuItem, path: path) { return data }
        }
        #else
        // Watch-side ingress: mirror the iOS MenuTouch.flushItem dispatch,
        // minus the MenuItem buffer (no backpressure needed at the watch's
        // input rate). Both .node (spot focus) and .leaf (thumb value) flow.
        applyRemote(item)
        #endif
    }

    #if os(watchOS)
    @MainActor
    private func applyRemote(_ item: MenuItem) {
        let visit = Visitor(0, .remote)
        switch item.element {
        case .node:
            guard let nodeItem = item.item as? MenuNodeItem,
                  let treeVm = nodeItem.treeVm else { return }
            _ = treeVm.followWordPath(nodeItem.wordPath, nodeItem.wordNow)
        case .leaf:
            guard let leafItem = item.item as? MenuLeafItem,
                  let treeVm = leafItem.treeVm,
                  let nodeVm = treeVm.followWordPath(leafItem.wordPath, leafItem.wordNow),
                  let leafVm = nodeVm as? LeafVm else { return }
            leafVm.remoteThumb(leafItem, visit)
        case .trees:
            if let trees = item.item as? MenuTreesItem {
                for treeItem in trees.treeItems {
                    treeItem.remoteTree()
                }
            }
        default:
            break
        }
    }
    #endif
}
#endif
