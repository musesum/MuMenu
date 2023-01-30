//
//  File.swift
//  
//
//  Created by warren on 9/10/22.

import SwiftUI
import MuPar

extension MuLeafTapVm: MuLeafProtocol {

    public func refreshValue(_ visit: Visitor) {
        visit.nowHere(self.hash)
        if visit.from.user {
            updateLeafPeers(visit)
            syncNext(visit)
        } else {
            thumbNow = thumbNext
        }
    }

    public func updateLeaf(_ any: Any, _ visit: Visitor) {

        if !visit.from.tween,
            visit.newVisit(hash) {

            editing = true
            switch any {
                case let v as Double:   thumbNext[0] = v
                case let v as [Double]: thumbNext[0] = v[0]
                default: break
            }
            editing = false
            syncNext(visit)
            updateLeafPeers(visit)
        }
    }


    public func leafTitle() -> String {
        if editing {
            return editing ? "1" :  "0"
        } else {
            return node.title
        }
    }
    public func treeTitle() -> String {
        if editing {
            return editing ? "1" :  "0"
        } else {
            return node.title
        }
    }
    public func thumbOffset() -> CGSize {
        CGSize(width: 0, height:  panelVm.runway)
    }

    public func syncNow(_ visit: Visitor) {
        syncNext(visit)
    }
    public func syncNext(_ visit: Visitor) {
        menuSync?.setMenuAny(named: nodeType.name, thumbNext[0], visit)
        refreshView()
    }
}
