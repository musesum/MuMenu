//  Created by warren on 1/2/23.


import UIKit

extension MuRootVm {

    func sendItemToPeers(_ item: MenuItem) {

        if peers.hasPeers {
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
