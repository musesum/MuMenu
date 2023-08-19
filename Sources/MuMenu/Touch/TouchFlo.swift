
import QuartzCore
import UIKit
import MuFlo
import MuVisit
import MuMetal

public class TouchFlo {

    private var root     : Flo?
    private var tilt˚    : Flo? ; var tilt    = false
    private var press˚   : Flo? ; var press   = true
    private var size˚    : Flo? ; var size    = CGFloat(1)
    private var index˚   : Flo? ; var index   = UInt32(127)
    private var prev˚    : Flo? ; var prev    = CGPoint.zero
    private var next˚    : Flo? ; var next    = CGPoint.zero
    private var force˚   : Flo? ; var force   = CGFloat(0)
    private var radius˚  : Flo? ; var radius  = CGFloat(0)
    private var azimuth˚ : Flo? ; var azimuth = CGPoint.zero
    private var fill˚    : Flo? ; var fill    = Float(-1)
    private var dotOn˚   : Flo? // addDot(f, .began)
    private var dotOff˚  : Flo? // addDot(f, .ended)

    //???

    init() {
    }

    public func parseRoot(_ root: Flo) {

        self.root = root

        let sky    = root.bind("sky"   )
        let input  = sky .bind("input" )

        let draw   = sky .bind("draw"  )
        let brush  = draw.bind("brush" )
        let line   = draw.bind("line"  )
        let screen = draw.bind("screen")

        tilt˚    = input .bind("tilt"   ){ f,_ in self.tilt    = f.bool    }
        press˚   = brush .bind("press"  ){ f,_ in self.press   = f.bool    }
        size˚    = brush .bind("size"   ){ f,_ in self.size    = f.cgFloat }
        index˚   = brush .bind("index"  ){ f,_ in self.index   = f.uint32  }
        prev˚    = line  .bind("prev"   ){ f,_ in self.prev    = f.cgPoint }
        next˚    = line  .bind("next"   ){ f,_ in self.next    = f.cgPoint }
        force˚   = input .bind("force"  ){ f,_ in self.force   = f.cgFloat }
        radius˚  = input .bind("radius" ){ f,_ in self.radius  = f.cgFloat }
        azimuth˚ = input .bind("azimuth"){ f,_ in self.azimuth = f.cgPoint }
        fill˚    = screen.bind("fill"   ){ f,_ in self.fill    = f.float   }
        dotOn˚   = draw  .bind("dot.on" ){ f,_ in self.addDot(f, .began)   }
        dotOff˚  = draw  .bind("dot.off"){ f,_ in self.addDot(f, .ended)   }
    }

    public func setViewSize(_ size: CGSize) {
        viewSize = size

    }
    func addDot(_ flo: Flo,_ phase: UITouch.Phase) {
        if let exprs = flo.exprs,
           let x = exprs.nameAny["x"] as? FloValScalar,
           let y = exprs.nameAny["y"] as? FloValScalar,
           let z = exprs.nameAny["z"] as? FloValScalar {

            let margin = CGFloat(48)
            let xs = CGFloat(2388/2)
            let ys = CGFloat(1668/2)
            let xx = CGFloat(x.twe) / 12
            let yy = 1 - CGFloat(y.twe / 12)
            let xxx = CGFloat(xx * xs) + margin
            let yyy = CGFloat(yy * ys) - margin
            let point = CGPoint(x: xxx, y: yyy)
            let radius = Float(z.twe/2 + 1)

            let key = "drawDot".hash
            let item = TouchCanvasItem(key, point, radius, .zero, .zero, phase, Visitor(.midi))
            TouchCanvas.addCanvasItem(item, isRemote: false)
        }
    }

  
    /**
     Either fill or draw inside texture
     - returns: true if filled, false if drawn
     */


    // duplicate in MuMetal::MetAspect
    public func viewPointToTexture(_ p: CGPoint, viewSize: CGSize, texSize: CGSize) -> CGPoint {

        let fill = fillClip(from: texSize, to: viewSize)
        let norm = fill.normalize()
        let x0 = p.x / viewSize.width
        let y0 = p.y / viewSize.height
        let x1 = (x0 + norm.minX) * norm.width * texSize.width
        let y1 = (y0 + norm.minY) * norm.height * texSize.height
        return CGPoint(x: x1, y: y1)
    }

    func drawFill(_ fill: UInt32) {
        guard let texBuf else { return }
        
        let w = Int(texSize.width)
        let h = Int(texSize.height)
        let count = w * h // count

        for i in 0 ..< count {
            texBuf[i] = fill
        }
    }
    func drawData() {

        let w = Int(texSize.width)
        let h = Int(texSize.height)
        let count = w * h // count

        if let data = TextureData["TouchDraw"] {
            data?.withUnsafeBytes { dataPtr in
                guard let texBuf else { return }
                let tex32Ptr = dataPtr.bindMemory(to: UInt32.self)
                for i in 0 ..< count {
                    texBuf[i] = tex32Ptr[i]
                }
            }
            TextureData["TouchDraw"] = nil
        }
    }
}
extension TouchFlo: TouchDrawDelegate {

   public func drawTexture(_ texBuf: UnsafeMutablePointer<UInt32>,
                            size: CGSize) -> Bool {

        self.texBuf = texBuf
        self.texSize = size

        if TextureData["TouchDraw"] != nil {
            fill = -1 // preempt fill after data
            drawData()
            return false
        } else if fill > 255 {
            let fill = UInt32(fill)
            drawFill(fill)
            self.fill = -1
            return false
        } else if fill >= 0 {
            let v8 = UInt32(fill * 255)
            let fill = (v8 << 24) + (v8 << 16) + (v8 << 8) + v8
            drawFill(fill)
            self.fill = -1
            return false
        } else {
            TouchCanvas.flushTouchCanvas()
            return false // didn't fill so don't duplicate 2nd texture
        }
    }
    // duplicate in MuMetal::MetAspect
    public func fillClip(from: CGSize, to: CGSize) -> CGRect {

        let ht = to.height      // height to
        let wt = to.width       // width to
        let rt = wt/ht          // ratio to

        let hf = from.height    // height from
        let wf = from.width     // width from
        let rf = wf/hf          // ratio from

        if rt < rf {

            let h = ht
            let w = wf * (ht/hf)
            let x = (w-wt) / 2
            let y = CGFloat(0)

            return CGRect(x: x, y: y, width: w, height: h)

        } else if rt > rf {

            let w = wt
            let h = hf * (wt/wf)
            let y = (h-ht) / 2
            let x = CGFloat(0)

            return CGRect(x: x, y: y, width: w, height: h)

        } else {

            return CGRect(x: 0, y: 0, width: wt, height: ht)
        }
    }

}
