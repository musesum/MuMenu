//
//  File.swift
//  
//
//  Created by warren on 9/10/22.

import SwiftUI
import Par

extension MuLeafTapVm: MuLeafProtocol {

    
    public func refreshValue() {
        // no change
    }

    public func updateLeaf(_ any: Any, _ visitor: Visitor) {
        if visitor.newVisit(hash) {
            editing = true
            switch any {
                case let v as Double:   thumb[0] = v
                case let v as [Double]: thumb[0] = v[0]
                default: break
            }
            editing = false
            updateSync(visitor)
        }
    }


    public func leafTitle() -> String {
        if editing {
            return editing ? "1" :  "0"
        } else {
            return node.title
        }
    }
    public func thumbOffset() -> CGSize {
        CGSize(width: 0, height:  panelVm.runway)
    }
}
