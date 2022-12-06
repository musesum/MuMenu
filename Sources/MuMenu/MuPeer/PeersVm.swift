
import SwiftUI

import MultipeerConnectivity

/// This is the View Model for PeersView
public class PeersVm: ObservableObject {

    public static let shared = PeersVm()

    /// myName and one secound counter
    @Published public var peersTitle = ""

    /// list of connected peers and their counter
    @Published public var peersList = ""

    public var peersController: PeersController
    private var peersCounter = [String: Int]()

    init() {
        peersController = PeersController.shared
        peersController.peersDelegates.append(self)
        oneSecondCounter()
    }
    deinit {
        peersController.remove(peersDelegate: self)
    }

    /// create a 1 second counter and send my count to all of my peers
    private func oneSecondCounter() {
        var count = Int(0)
        func loopNext() {
            count += 1
            peersController.sendMessage(["count": count] )
            peersTitle = "\(peersController.myName): \(count)"
        }
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true)  {_ in
            loopNext()
        }
    }
}
extension PeersVm: PeersControllerDelegate {

    public func didChange() {

        var peerList = ""

        for (name,state) in peersController.peerState {
            peerList += "\n" + state.icon() + name

            if let count = peersCounter[name]  {
                peerList += ": \(count)"
            }
        }
        self.peersList = peerList
    }


    public func received(message: [String: Any],
                  from peer: MCPeerID) {

        // filter for internal 1 second counter
        // other delegates may capture other messages
        if let count = message["count"] as? Int {
            peersCounter[peer.displayName] = count
            didChange()
        }
    }

}
