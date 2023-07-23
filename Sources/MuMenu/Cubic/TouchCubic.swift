
import QuartzCore

public struct TouchCubic {

    var x = CubicPoly() // point x
    var y = CubicPoly() // point y
    var r = CubicPoly() // radius

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
    public mutating func addPointRadius(_ point  : CGPoint,
                                        _ radius : CGFloat,
                                        _ isDone : Bool   ) {
        x.addVal(point.x, isDone)
        y.addVal(point.y, isDone)
        r.addVal(radius , isDone)
    }
    // get the maximum linear interval beteen p4's p[2] and p[3]
    func maximumMidInterval() -> CGFloat {
        return fmax(x.distance, y.distance)
    }

    public func drawPoints(_ drawPoint: TouchDrawPoint?)  {
        guard let drawPoint else { return }

        // choose longest interval between x and y axis for filling arc
        let longest = max(1, x.distance, y.distance)   // longest distance
        let increment = 1.0 / longest  // cover every pixel

        // iterate between 0 and 1
        for inter: CGFloat in stride(from: 0, to: 1, by: increment) {

            let xx = x.getInter(inter)
            let yy = y.getInter(inter)
            let rr = r.getInter(inter)
            drawPoint(CGPoint(x: xx, y: yy), rr)
        }
    }
}
