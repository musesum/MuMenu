// created by musesum on 6/15/25

import SwiftUI
import MuPeers
import MuFlo
import MuVision

extension RootVm { // + Layout

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

        func v(_ w:CGFloat,_ h:CGFloat) { vs = CGSize(width:w,height:h) }
        func h(_ w:CGFloat,_ h:CGFloat) { hs = CGSize(width:w,height:h) }

        switch cornerType.corner {
        case .SE : v(-x0,-y1); h(-x1,-y0)
        case .SW : v( x0,-y1); h( x1,-y0)
        case .NE : v(-x0, y1); h(-x1, y0)
        case .NW : v( x0, y1); h( x1, y0)
        default: break
        }

        for treeVm in treeVms {
            treeVm.treeOffset = (treeVm.menuType.vertical ? vs : hs)
        }
    }
    private func idiomMargins() -> CGSize {
        
        let padding2 = Layout.padding2
        let w: CGFloat
        let h: CGFloat
        #if os(iOS)
        w = 0
        h = cornerType.north ? padding2 : 0
        #elseif os(iPadOS)
        w = padding2
        h = cornerType.south ? padding2 : 0
        #elseif os(visionOS)
        w = padding2 * 2
        h = padding2 * 2
        #else
        w = 0
        h = 0
        #endif
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
        case .SE : return CGPoint(x: w-x-r-s, y: h-y-r-s)
        case .SW : return CGPoint(x:   x+r+s, y: h-y-r-s)
        case .NE : return CGPoint(x: w-x-r-s, y:   y+r+s)
        case .NW : return CGPoint(x:   x+r+s, y:   y+r+s)
        default  : return .zero
        }
    }
}
