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
        guard item.floOps.share else { return }
        Task {
            await peers.sendItem(.menuFrame, item.time) {
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

