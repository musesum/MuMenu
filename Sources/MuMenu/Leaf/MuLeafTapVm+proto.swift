//
//  File.swift
//  
//
//  Created by warren on 9/10/22.

import SwiftUI
import Par

extension MuLeafTapVm: MuLeafProtocol {

    public func refreshValue(tapped: Bool) {
        let visitor = Visitor(hash)
        if tapped {
            updateLeafPeers(visitor)
            syncNext(visitor)
        }

    }

    public func updateLeaf(_ any: Any, _ visitor: Visitor) {
        if visitor.newVisit(hash) {
            editing = true
            switch any {
                case let v as Double:   thumbNext[0] = v
                case let v as [Double]: thumbNext[0] = v[0]
                default: break
            }
            editing = false
            syncNext(visitor)
            updateLeafPeers(visitor)
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

    public func syncNow(_ visitor: Visitor) {
        print("syncNow animation not used for discreet values")
    }
    public func syncNext(_ visitor: Visitor) {
        menuSync?.setAny(named: nodeType.name, thumbNext[0], visitor)
        refreshView()
    }
}
