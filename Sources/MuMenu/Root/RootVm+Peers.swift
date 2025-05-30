//  created by musesum on 1/2/23.


import UIKit
import MuPeers

extension RootVm {

    func sendItemToPeers(_ item: MenuItem) {

        Task {
            await peers.sendItem() {
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
