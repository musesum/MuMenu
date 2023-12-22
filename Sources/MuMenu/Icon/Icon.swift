//  created by musesum on 7/29/22.

import Foundation
import UIKit

public enum IconType { case none, cursor, image, svg, symbol, text }

public class Icon {

    public static var altBundle: Bundle?

    var iconType = IconType.none
    var named = ""
    var image: UIImage? {
        (iconType == .image || iconType == .svg)
        ? (UIImage(named: named) ??
           UIImage(named: named, in: Icon.altBundle, with: nil))
        : nil
    }
    var type: NodeType


    public init(_ iconType: IconType,
                _ named: String,
                _ type: NodeType = .none) {
        
        self.iconType = iconType
        self.named = named
        self.type = type
    }
}
