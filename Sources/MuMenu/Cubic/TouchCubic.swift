
import QuartzCore

public struct TouchCubic {

    var pnt4 = Pnt4(.zero, .zero, .zero, .zero) // 4 control points in 2d space for position
    var rad4 = Flt4(0, 0, 0, 0) // 4 control floats in 1d for radius

    var x = CubicPoly()
    var y = CubicPoly()
    var r = CubicPoly()

    var index = 0

    public init() {
    }
    mutating func clearAll() {
        pnt4 = Pnt4(.zero, .zero, .zero, .zero)
        rad4 = Flt4(0, 0, 0, 0)
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
    public mutating func addPointRadius(_ point: CGPoint,
                                        _ radius: CGFloat,
                                        _ isDone: Bool) {
        switch index {
        case 0:  pnt4 = (point , point , point , point) // a a a a  a-a
        case 1:  pnt4 = (pnt4.0, pnt4.1, point , point) // a a b b  a-b
        case 2:  pnt4 = (pnt4.0, pnt4.2, pnt4.3, point) // a b b c  b-b
        default: pnt4 = (pnt4.1, pnt4.2, pnt4.3, point) // a b c d  b-c
        }

        switch index {                                       // 0 1 2 3  draw
            case 0:  rad4 = (radius, radius, radius, radius) // a a a a  a-a
            case 1:  rad4 = (rad4.0, rad4.1, radius, radius) // a a b b  a-b
            case 2:  rad4 = (rad4.0, rad4.2, rad4.3, radius) // a b b c  b-b
            default: rad4 = (rad4.1, rad4.2, rad4.3, radius) // a b c d  b-c
        }

        index = isDone ? 0 : index + 1

        x.makeCoeficients((pnt4.0.x, pnt4.1.x, pnt4.2.x, pnt4.3.x))
        y.makeCoeficients((pnt4.0.y, pnt4.1.y, pnt4.2.y, pnt4.3.y))
        r.makeCoeficients(rad4)
    }
    // get the maximum linear interval beteen p4's p[2] and p[3]
    func maximumMidInterval() -> CGFloat {
        let deltaX = abs(pnt4.2.x - pnt4.3.x)
        let deltaY = abs(pnt4.2.y - pnt4.3.y)
        return fmax(deltaX, deltaY)
    }

    public func drawPoints(_ drawPoint: TouchDrawPoint?)  {
        guard let drawPoint else { return }

        // choose longest interval between x and y axis for filling arc
        let xd = abs(pnt4.1.x - pnt4.2.x) // x distance
        let yd = abs(pnt4.1.y - pnt4.2.y) // y distance
        let longest = max(1, xd, yd)   // longest distance
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
