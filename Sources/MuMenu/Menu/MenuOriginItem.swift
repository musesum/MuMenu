//  MenuOriginItem.swift
//  Created by DeepMuse on 2025-01-06

import Foundation

/// Represents an origin/delta state change for a node control
public struct MenuOriginItem: Codable {
    let nodeType: NodeType    // Type of control (.val, .xy, .xyz, .seg)
    let center: CGPoint       // destination thumb position
    let sideAxis: Int         // Which tree side/axis
    let hashPath: [Int]       // Array of hashes representing the path to the node
    let hashNow: Int          // Hash of the currently selected node
    let isOrigin: Bool        // true = showing origin, false = showing delta
}
