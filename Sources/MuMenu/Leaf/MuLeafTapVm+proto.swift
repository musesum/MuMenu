//
//  File.swift
//  
//
//  Created by warren on 9/10/22.

import SwiftUI
import Par

extension MuLeafTapVm: MuLeafProtocol {

    public func touchLeaf(_ touchState: MuTouchState) {
        if touchState.phase == .began {
            thumb[0] = 1
            editing = true
        } else if touchState.phase.isDone() {
            thumb[0] = 0
            editing = false
        }
        updateSync(Visitor())
    }

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

    private func updateSync(_ visitor: Visitor) {
        menuSync?.setAny(named: nodeType.name, thumb[0], visitor)
        updatePeers(visitor)
    }
    public func valueText() -> String {
        editing ? "1" :  "0"
    }
    public func thumbOffset() -> CGSize {
        CGSize(width: 0, height:  panelVm.runway)
    }
}
