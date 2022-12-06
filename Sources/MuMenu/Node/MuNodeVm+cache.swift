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
                       _ prevVm: MuNodeVm? = nil,
                       icon: String = "") -> MuNodeVm {

        switch nodeType {
            case .vxy: return MuLeafVxyVm(node, branchVm, prevVm)
            case .val: return MuLeafValVm(node, branchVm, prevVm)
            case .seg: return MuLeafSegVm(node, branchVm, prevVm)

            case .tog: return MuLeafTogVm(node, branchVm, prevVm)
            case .tap: return MuLeafTapVm(node, branchVm, prevVm)
                
            case .peer: return MuLeafPeerVm(node, branchVm, prevVm)

            default:   return MuNodeVm(node, branchVm, prevVm)
        }
    }
}

extension MuNodeVm {

    func path() -> String {
        if let prior = prevNodeVm?.path() {
            return prior + "." + node.title
        } else {
            return node.title
        }
    }

    func path(child: String) -> String {
        let prior = path()
        if prior.isEmpty {
            return child
        } else {
            return prior + "." + child
        }
    }

    func hash() -> Int {
        let path = path()
        var hasher = Hasher()
        hasher.combine(path)
        let hash = hasher.finalize()
        //print(path + String(format: ": %i", hash))
        return hash
    }

    func hash(child: String) -> Int {
        let path = path(child: child)
        var hasher = Hasher()
        hasher.combine(path)
        let hash = hasher.finalize()
        //print(path + String(format: ": %i", hash))
        return hash
    }
}

extension MuNodeVm: Hashable {

    public func hash(into hasher: inout Hasher) {
        let path = path()
        hasher.combine(path)
        _ = hasher.finalize()
        //print(path + String(format: ": %i", result))
    }

}
