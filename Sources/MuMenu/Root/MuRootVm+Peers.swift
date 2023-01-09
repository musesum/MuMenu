//  Created by warren on 1/2/23.


import UIKit

extension MuRootVm {
    
    func sendLeafToPeers(_ leafVm: MuLeafVm,
                         _ thumb: [Double],
                         _ phase: UITouch.Phase) {
        
        if peers.hasPeers {
            do {
                let phase = touchState.phase
                let item = MenuItem(leafVm, thumb, phase)
                let encoder = JSONEncoder()
                let data = try encoder.encode(item)
                peers.sendMessage(data, viaStream: true)
            } catch {
                print(error)
            }
        }
    }
    
    func sendNodeToPeers(_ nodeVm: MuNodeVm,
                         _ phase: UITouch.Phase) {

        if peers.hasPeers {
            do {
                let item = MenuItem(nodeVm, [0,0], phase)

                let encoder = JSONEncoder()
                let data = try encoder.encode(item)
                peers.sendMessage(data, viaStream: true)
            } catch {
                print(error)
            }
        }
    }


    
}
