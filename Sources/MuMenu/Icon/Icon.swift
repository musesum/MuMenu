//  created by musesum on 7/29/22.

import Foundation
#if !os(watchOS)
import UIKit
#endif

public enum IconType { case none, cursor, image, svg, symbol, text }

typealias IconTypeName = (IconType, String)

#if !os(watchOS)
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
#endif

public class Icon {

    let iconOn: IconTypeName?
    let iconOff: IconTypeName?
    let nodeType: NodeType

    public var nameOn  : String    { iconOn .map(\.1) ?? ""}
    public var nameOff : String    { iconOff.map(\.1) ?? nameOn }
    public var typeOn  : IconType  { iconOn .map(\.0) ?? .none }
    public var typeOff : IconType  { iconOff.map(\.0) ?? .none }

    #if !os(watchOS)
    @MainActor
    var imageOn: UIImage? {
        if let _ = iconOn {
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
        if let _ = iconOff {
            switch typeOff {
            case .image, .svg:
                return UIImage.named(nameOff)
            default: break
            }
        }
        return imageOn
    }
    #endif

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
