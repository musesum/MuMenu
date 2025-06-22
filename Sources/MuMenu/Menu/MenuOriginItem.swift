//  MenuOriginItem.swift
//  Created by DeepMuse on 2025-01-06

import Foundation

/// Represents an origin/delta state change for a node control
public struct MenuOriginItem: Codable {
    let nodeType : NodeType // Type of control (.val, .xy, .xyz, .seg)
    let center   : CGPoint  // destination thumb position
    let menuType : MenuType // Menu position and orientation
    let wordPath : [String] // Array of strings representing the path to the node (flo.name and path)
    let wordNow  : String   // String of the currently selected node (flo.name)
    let isOrigin : Bool     // true = showing origin, false = showing delta
}
