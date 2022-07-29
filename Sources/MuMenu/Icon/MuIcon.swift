//
//  File.swift
//  
//
//  Created by warren on 7/29/22.
//

import Foundation

public enum MuIconType { case none, cursor, image, symbol, abbrv }

public class MuIcon {
    var type = MuIconType.none
    var named = ""

    public init(_ type: MuIconType, named: String) {
        self.type = type
        self.named = named
    }

}
