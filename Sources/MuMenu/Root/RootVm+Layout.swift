// created by musesum on 6/15/25

import SwiftUI
import MuPeers
import MuFlo
import MuVision

extension RootVm { // layout

    internal func updateTreeOffsets() {

        let margins = idiomMargins()
        // xy top left to bottom right corners
        let x0 = margins.width
        let y0 = margins.height
        let x1 = x0 + Layout.diameter + Layout.padding * 3
        let y1 = y0 + Layout.diameter + Layout.padding * 3

        // setup vertical, horizontal, and root offsets
        var vs = CGSize.zero // vertical offset
        var hs = CGSize.zero // horizontal offset
        var rs = CGSize.zero // root icon offset
        func v(_ w:CGFloat,_ h:CGFloat) { vs = CGSize(width:w,height:h) }
        func h(_ w:CGFloat,_ h:CGFloat) { hs = CGSize(width:w,height:h) }
        func r(_ w:CGFloat,_ h:CGFloat) { rs = CGSize(width:w,height:h) }

        switch cornerType.corner {
        case .downRight : v(-x0,-y1); h(-x1,-y0); r(0, 0)
        case .downLeft  : v( x0,-y1); h( x1,-y0); r(0, 0)
        case .upRight   : v(-x0, y1); h(-x1, y0); r(0, 0)
        case .upLeft    : v( x0, y1); h( x1, y0); r(0, 0)
        default: break
        }
        rootOffset = rs
        for treeVm in treeVms {
            treeVm.treeOffset = (treeVm.menuType.vertical ? vs : hs)
        }
    }
    private func idiomMargins() -> CGSize {
        let idiom = UIDevice.current.userInterfaceIdiom
        let padding2 = Layout.padding2

        let w: CGFloat
        switch idiom {
        case .pad    : w = padding2
        case .phone  : w = 0
        case .vision : w = padding2 * 2
        default      : w = 0
        }

        let h: CGFloat
        switch idiom {
        case .pad    : h = cornerType.down ? padding2 : 0
        case .phone  : h = cornerType.up   ? padding2 : 0
        case .vision : h = padding2 * 2
        default      : h = 0
        }
        return CGSize(width: w, height: h)
    }
    internal func cornerXY(in frame: CGRect) -> CGPoint {

        let margins = idiomMargins()
        let x = margins.width
        let y = margins.height

        let w = frame.size.width
        let h = frame.size.height
        let s = Layout.padding
        let r = Layout.diameter / 2

        switch cornerType.corner {
        case .downRight : return CGPoint(x: w-x-r-s, y: h-y-r-s)
        case .downLeft  : return CGPoint(x:   x+r+s, y: h-y-r-s)
        case .upRight   : return CGPoint(x: w-x-r-s, y:   y+r+s)
        case .upLeft    : return CGPoint(x:   x+r+s, y:   y+r+s)
        default         : return .zero
        }
    }
}
