//
//  File.swift
//  
//
//  Created by warren on 9/7/22.

import SwiftUI

extension MuNodeVm {

    static func cached(_ nodeType: MuNodeType,
                       _ node: MuNode,
                       _ branchVm: MuBranchVm,
                       _ prevVm: MuNodeVm?,
                       icon: String = "") -> MuNodeVm {

        switch nodeType {
            case .vxy:  return MuLeafVxyVm(node, branchVm, prevVm)
            case .val:  return MuLeafValVm(node, branchVm, prevVm)
            case .seg:  return MuLeafSegVm(node, branchVm, prevVm)
            case .tog:  return MuLeafTogVm(node, branchVm, prevVm)
            case .tap:  return MuLeafTapVm(node, branchVm, prevVm)
            case .peer: return MuLeafPeerVm(node, branchVm, prevVm)
            default:    return MuNodeVm(node, branchVm, prevVm)
        }
    }
}

extension MuNodeVm: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
        _ = hasher.finalize()
        //print(path + String(format: ": %i", result))
    }

}
