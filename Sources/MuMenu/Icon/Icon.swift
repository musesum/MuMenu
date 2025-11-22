//  created by musesum on 7/29/22.

import Foundation
import UIKit

public enum IconType { case none, cursor, image, svg, symbol, text }


extension UIImage {
    @MainActor
    static func named(_ name: String) -> UIImage? {
        if let image = UIImage(named: name) {
            return image
        }
        for bundle in Menus.bundles {
            if let image = UIImage(named: name, in: bundle, with: nil) {
                return image
            }
        }
        return nil
    }
}


typealias IconTypeName = (IconType, String)

public class Icon {

    let iconOn: IconTypeName?
    let iconOff: IconTypeName?
    let nodeType: NodeType

    var nameOn  : String    { iconOn .map(\.1) ?? ""}
    var nameOff : String    { iconOff.map(\.1) ?? nameOn }
    var typeOn  : IconType  { iconOn .map(\.0) ?? .none }
    var typeOff : IconType  { iconOff.map(\.0) ?? .none }

    @MainActor
    var imageOn: UIImage? {
        if let iconOn {
            switch typeOn {
            case .image, .svg:
                return UIImage.named(nameOn)
            default: break
            }
        }
        return nil
    }
    @MainActor
    var imageOff: UIImage? {
        if let iconOff {
            switch typeOff {
            case .image, .svg:
                return UIImage.named(nameOff)
            default: break
            }
        }
        return imageOn
    }


    init(_ iconOn   : IconTypeName?,
         _ iconOff  : IconTypeName? = nil,
         _ nodeType : NodeType = .none) {

        self.iconOn   = iconOn
        self.iconOff  = iconOff
        self.nodeType = nodeType
    }

    init(_ iconType : IconType,
         _ iconName : String,
         _ nodeType : NodeType = .none) {

        self.iconOn   = (iconType, iconName)
        self.iconOff  = nil
        self.nodeType = nodeType
    }
}

