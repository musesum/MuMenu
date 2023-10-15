//  created by musesum on 7/29/22.

import Foundation
import UIKit

public enum MuIconType { case none, cursor, image, svg, symbol, text }

public class MuIcon {

    public static var altBundle: Bundle?

    var iconType = MuIconType.none
    var named = ""
    var image: UIImage? {
        (iconType == .image || iconType == .svg)
        ? (UIImage(named: named) ??
           UIImage(named: named, in: MuIcon.altBundle, with: nil))
        : nil
    }
    var type: MuNodeType


    public init(_ iconType: MuIconType,
                _ named: String,
                _ type: MuNodeType = .none) {
        
        self.iconType = iconType
        self.named = named
        self.type = type
    }
}
