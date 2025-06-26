//  created by musesum on 7/29/22.

import Foundation
import UIKit

public enum IconType { case none, cursor, image, svg, symbol, text }


extension UIImage {
    static func named(_ name: String) -> UIImage? {
        if let img = UIImage(named: name) {
            return img
        } else {
            for bundle in Icon.altBundles {
                if let img = UIImage(named: name, in: bundle, with: nil) {
                    return img
                }
            }
        }
        return nil
    }
}



public class Icon {

    nonisolated(unsafe) public static var altBundles = [Bundle]()

    var iconType = IconType.none
    var icoName = ""
    var image: UIImage? {
        if  iconType == .image || iconType == .svg {
            if let img = UIImage(named: icoName) {
                return img
            } else {
                for bundle in Icon.altBundles {
                    if let img = UIImage(named: icoName, in: bundle, with: nil) {
                        return img
                    }
                }
            }
        }
        return nil
    }

    var type: NodeType

    public init(_ iconType: IconType,
                _ icoName: String,
                _ type: NodeType = .none) {
        
        self.iconType = iconType
        self.icoName = icoName
        self.type = type
    }
}
