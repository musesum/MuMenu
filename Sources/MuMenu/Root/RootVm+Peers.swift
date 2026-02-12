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
    public func resetItem(_ item: PlayItem) {
        //...... maybe ignore?
    }
    public func playItem(_ item: PlayItem, from: DataFrom) {
        received(data: item.data, from: from)
    }
    public func shareItem(_ item: Any) {
        guard let item = item as? MenuItem,
            item.policy.contains(.share) else { return }
        Task.detached {
            await Peers.shared.sendItem(.menuItem) {
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

