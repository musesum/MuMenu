//  created by musesum on 1/2/23.


import UIKit
import MuPeer

extension RootVm {

    func  sendItemToPeers(_ item: MenuItem) {

        if let peers, peers.hasPeers {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(item)
                peers.sendMessage(data, viaStream: true)
            } catch {
                print(error)
            }
        }
    }

}

extension RootVm: PeersControllerDelegate {

    public func didChange() {
    }

    public func received(data: Data,
                         viaStream: Bool) -> Bool {

        let decoder = JSONDecoder()
        if let item = try? decoder.decode(MenuItem.self, from: data) {
            MenuTouch.remoteItem(item)
            return true
        }
        return false
    }

}
