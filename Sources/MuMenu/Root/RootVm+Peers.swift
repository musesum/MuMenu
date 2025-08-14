//  created by musesum on 1/2/23.


import UIKit
import MuPeers
import MuFlo // PrintLog

extension RootVm: @MainActor PeersDelegate {

    public func received(data: Data) {

        let decoder = JSONDecoder()
        if let item = try? decoder.decode(MenuItem.self, from: data) {
            MenuTouch.remoteItem(item)
        }
    }

    public func shareItem(_ item: MenuItem) {

        Task {
            await share.peers.sendItem(.menuFrame) {
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

