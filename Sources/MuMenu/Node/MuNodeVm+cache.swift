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
                       _ prevNodeVm: MuNodeVm?,
                       icon: String = "") -> MuNodeVm {

        switch nodeType {
            case .vxy:  return MuLeafVxyVm(node, branchVm, prevNodeVm)
            case .val:  return MuLeafValVm(node, branchVm, prevNodeVm)
            case .seg:  return MuLeafSegVm(node, branchVm, prevNodeVm)
            case .tog:  return MuLeafTogVm(node, branchVm, prevNodeVm)
            case .tap:  return MuLeafTapVm(node, branchVm, prevNodeVm)
            case .peer: return MuLeafPeerVm(node, branchVm, prevNodeVm)
            default:    return MuNodeVm(node, branchVm, prevNodeVm)
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
