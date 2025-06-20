//  created by musesum on 1/2/23.


import UIKit
import MuPeers


extension RootVm: PeersDelegate {

    public func didChange() {}

    public func received(data: Data) {

        let decoder = JSONDecoder()
        if let item = try? decoder.decode(MenuItem.self, from: data) {
            MenuTouch.remoteItem(item)
        }
    }
    /// not part of  PeersDelegate protocol,
    /// but maybe it should be
    func sendItemToPeers(_ item: MenuItem) {

        Task {
            await peers.sendItem(.menuFrame) {
                do {
                    return try JSONEncoder().encode(item)
                } catch {
                    print(error)
                    return nil
                }
            }
        }
    }

}

