import QuartzCore

typealias Pnt4 = (CGPoint,CGPoint,CGPoint,CGPoint)
typealias Flt4 = (CGFloat,CGFloat,CGFloat,CGFloat)

struct CubicPoly {

    var vals = Flt4(0,0,0,0) // points to smooth
    var coef = Flt4(0,0,0,0) // coeficients for cubic
    var index = 0 // current position within series

    var distance: CGFloat {
        abs(vals.2 - vals.3)
    }

    func getInter(_  inter: CGFloat) -> CGFloat {

        let inter2 = inter * inter
        let inter3 = inter2 * inter
        let val = coef.0 + (coef.1 * inter) + (coef.2 * inter2) + (coef.3 * inter3)
        return val
    }

    /// Compute coefficients for a cubic polynomial --  Catmull-Rom spline: interpolation
    ///
    ///     p(s) = coef.0 + coef.1 * s + coef.2 * s^2 + coef.3 * s^3 //such that
    ///     p(0) = x0, p(1) = x1 // and
    ///     p'(0) = t0, p'(1) = t1.
    ///
    mutating func makeCoeficients() {

        // make 1d coeficients for r
        var d01 = sqrtDistance(vals.0, vals.1) // distance between f0 and f1
        var d12 = sqrtDistance(vals.1, vals.2) // distance between f1 and f2
        var d23 = sqrtDistance(vals.2, vals.3) // distance between f2 and f3

        // safety check for repeated points
        if d12 < 1e-4 { d12 = 1.0 }
        if d01 < 1e-4 { d01 = d12 }
        if d23 < 1e-4 { d23 = d12 }

        let f0 = vals.1
        let f1 = vals.2
        let t0 = 0.5 * (vals.2 - vals.0)
        let t1 = 0.5 * (vals.3 - vals.1)

        coef.0 = f0
        coef.1 = t0
        coef.2 = -3*f0 + 3*f1 - 2*t0 - t1
        coef.3 =  2*f0 - 2*f1 +   t0 + t1

        func sqrtDistance(_ f0: CGFloat, _ f1: CGFloat) -> CGFloat {

            let delta = abs(f1 - f0)
            return pow(delta * delta, 0.5)
        }
    }
    public mutating func addVal(_ val: CGFloat,
                                _ isDone: Bool) {
        switch index {
        case 0:  vals = (val   , val   , val   , val) // a a a a  a-a
        case 1:  vals = (vals.0, vals.1, val   , val) // a a b b  a-b
        case 2:  vals = (vals.0, vals.2, vals.3, val) // a b b c  b-b
        default: vals = (vals.1, vals.2, vals.3, val) // a b c d  b-c
        }
        index = isDone ? 0 : index + 1
        makeCoeficients()
    }

        

}
