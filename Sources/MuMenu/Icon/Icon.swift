//  created by musesum on 7/29/22.

import Foundation
import UIKit

public enum IconType { case none, cursor, image, svg, symbol, text }

public class Icon {

    public static var altBundles = [Bundle]()

    var iconType = IconType.none
    var icoName = ""
    var onName: String?
    var image: UIImage? {
        if  iconType == .image || iconType == .svg {
            if let img = UIImage(named: icoName) {
                return img
            } else {
                for bundle in Icon.altBundles {
                    if let img =  UIImage(named: icoName, in: bundle, with: nil) {
                        return img
                    }
                }
            }
        }
        return nil

    }
    var imageOn: UIImage? {
        if let onName{
            if let img = UIImage(named: onName) {
                return img
            } else {
                for bundle in Icon.altBundles {
                    if let img =  UIImage(named: onName, in: bundle, with: nil) {
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
                _ onName: String? = nil,
                _ type: NodeType = .none) {
        
        self.iconType = iconType
        self.icoName = icoName
        self.onName = onName
        self.type = type
    }
}
