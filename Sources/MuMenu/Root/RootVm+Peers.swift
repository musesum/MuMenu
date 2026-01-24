//  created by musesum on 1/2/23.


import UIKit
import MuPeers
import MuFlo // PrintLog


extension RootVm: @MainActor PeersDelegate {

    public func received(data: Data, from: DataFrom) {

        let decoder = JSONDecoder()
        if let item = try? decoder.decode(MenuItem.self, from: data) {
            MenuTouch.remoteItem(item)
        }
    }

    public func shareItem(_ item: MenuItem) {
        guard item.policy.contains(.share) else { return }
        Task.detached {
            await Peers.shared.sendItem(.menuFrame) {
                do {
                    return try JSONEncoder().encode(item)
                } catch {
                    PrintLog(error.localizedDescription)
                    return nil
                }
            }
        }
    }

}

