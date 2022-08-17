//
//  File.swift
//  
//
//  Created by warren on 7/29/22.
//

import Foundation
import UIKit

public enum MuIconType { case none, cursor, image, symbol, abbrv }

public class MuIcon {
    public static var altBundle: Bundle?
    var type = MuIconType.none
    var named = ""
    var image: UIImage? {
        type == .image
        ? (UIImage(named: named) ??
           UIImage(named: named, in: MuIcon.altBundle, with: nil))
        : nil
    }


    public init(_ type: MuIconType, named: String) {
        self.type = type
        self.named = named
    }
}
