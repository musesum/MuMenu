//
//  File.swift
//  
//
//  Created by warren on 1/2/23.
//

import Foundation

extension MuRootVm {
    
    func sendToPeers(_ nodeVm: MuNodeVm,
                     _ thumb: [Double]) {
        
        if peers.hasPeers {
            do {
                let item = MenuRemoteItem(
                    nodeVm    : nodeVm,
                    startIndex: treeSpotVm?.startIndex ?? 0,
                    thumb     : thumb,
                    phase     : touchState?.phase ?? .began)
                
                let encoder = JSONEncoder()
                let data = try encoder.encode(item)
                peers.sendMessage(data, viaStream: true)
            } catch {
                print(error)
            }
        }
    }
    
    
    
}
