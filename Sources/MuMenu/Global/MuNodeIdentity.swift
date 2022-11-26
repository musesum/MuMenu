// Created by warren 10/17/21.

import SwiftUI

struct MuNodeIdentity {
    static var id = 0
    static func getId() -> Int {
        id += 1
        return id
    }
}

public struct MuTouchNumber {
    static var number = 1_000_000
    public static func getNext() -> Int {
        number += 1
        return number
    }
}

