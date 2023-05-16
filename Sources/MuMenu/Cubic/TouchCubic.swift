
import QuartzCore

public struct TouchCubic {

    var p = Pnt4(.zero, .zero, .zero, .zero) // 4 control points in 2d space for position
    var r = Flt4(0, 0, 0, 0) // 4 control floats in 1d for radius
    var cubicXYR = CubicXYR() // coeficients for control poinnts
    var index = 0

    public init() {
    }
    mutating func clearAll() {
        p = Pnt4(.zero, .zero, .zero, .zero)
        r = Flt4(0, 0, 0, 0)
        index = 0
    }

    /// Add cubic poly points.Problem is that control points are drawn in real time.
    /// So need to make special cases for 1st control points.
    /// For example for the first point a, b, c, d, e :
    ///
    ///          control   draw
    ///          position  from
    ///       t  0 1 2 3
    ///       0: a a a a  a to a
    ///       1: a a b b  a to b
    ///       2: a b b c  b to b (redundant)
    ///       3: a b c d  b to c
    ///       4: b c d e  c to d // continue for f, g, ...
    ///
    public mutating func addPointRadius(_ p_: CGPoint,
                                        _ r_: CGFloat,
                                        _ isDone: Bool) {
        let p0 = p.0
        let p1 = p.1
        let p2 = p.2
        let p3 = p.3

        let r0 = r.0
        let r1 = r.1
        let r2 = r.2
        let r3 = r.3

        switch index {
        case 0:  p = (p_, p_, p_, p_) // a a a a  a-a
        case 1:  p = (p0, p1, p_, p_) // a a b b  a-b
        case 2:  p = (p0, p2, p3, p_) // a b b c  b-b
        default: p = (p1, p2, p3, p_) // a b c d  b-c
        }
        //print(scriptPoints())

        switch index {                                               // 0 1 2 3  draw
            case 0:  r = (r_, r_, r_, r_) // a a a a  a-a
            case 1:  r = (r0, r1, r_, r_) // a a b b  a-b
            case 2:  r = (r0, r2, r3, r_) // a b b c  b-b
            default: r = (r1, r2, r3, r_) // a b c d  b-c
        }

        if isDone { // reset index at end of stroke
            // do not use the p0...p3 r0...r3 references, as they point to an old locations
            p = (p.0, p.1, p.3, p.3)
            r = (r.0, r.1, r.3, r.3)
            index = 0 // reset index to beginning of next stroke
        } else { // or continue to next index point
            index += 1
        }
        cubicXYR.makeCoeficients(p, r)
    }
    // get the maximum linear interval beteen p4's p[2] and p[3]
    func maximumMidInterval() -> CGFloat {
        let deltaX = abs(p.2.x - p.3.x)
        let deltaY = abs(p.2.y - p.3.y)
        return fmax(deltaX, deltaY)
    }

    // return point (xx, yy) from z1, which is in 0...1
    func getXY(_ z1: CGFloat) -> CGPoint {
        let xx = cubicXYR.x.getFloat(z1)
        let yy = cubicXYR.y.getFloat(z1)
        return CGPoint(x: xx, y: yy)
    }
    // return radius rr interpolated from z1, which is in 0...1
    func getR(_ z1: CGFloat) -> CGFloat {
        let rr = cubicXYR.r.getFloat(z1)
        return rr
    }
    func scriptPoints() -> String {

        let s = String(format:"%i: (%3.f,%3.f):%.f  (%3.f,%3.f):%.f  (%3.f,%3.f):%.f  (%3.f,%3.f):%.f",
                       index,
                       p.0.x, p.0.y, r.0,
                       p.1.x, p.1.y, r.1,
                       p.2.x, p.2.y, r.2,
                       p.3.x, p.3.y, r.3)
        return s
    }

    public func drawPoints(_ drawPoint: TouchDrawPoint?)  {

        // if index<2 { return }

        let p1 = p.1
        let p2 = p.2

        // choose longest interval between x and y axis for filling arc
        let iterations = max(1, max(abs(p1.x - p2.x), abs(p1.y - p2.y)))
        let increment = 1.0 / iterations

        // iterate between 0 and 1
        for z1: CGFloat in stride(from: 0, to: 1, by: increment) {

            let p = getXY(z1)
            let r = getR(z1)

            drawPoint?(p, r)
        }
    }
}
