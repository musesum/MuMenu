// created by musesum on 11/23/24

//import SwiftUI
//import MuFlo
//import MuVision
//
//public struct MenuTrunk {
//
//
//
//    public init (_ rootMenu: MenuTree,
//                 _ menuType: MenuType) {
//
//        self.rootMenu = rootMenu
//        self.menuType = menuType
//    }
//
//    mutating func bounded(from: RangeXY) -> CGFloat {
//        switch menuType.progression {
//        case .VL: return from.0.lowerBound
//        case .VR: return from.0.upperBound
//        case .HU: return from.1.lowerBound
//        case .HD: return from.1.upperBound
//        }
//    }
//
//    mutating func outerLimit(of range: RangeXY) -> CGSize {
//        let x: CGFloat
//        let y: CGFloat
//        switch menuType.progression  {
//        case .VL: x = range.0.lowerBound; y = 0
//        case .VR: x = range.0.upperBound; y = 0
//        case .HU: x = 0 ; y = range.1.lowerBound
//        case .HD: x = 0 ; y = range.1.upperBound
//        }
//        return CGSize(width: x, height: y)
//    }
//}
