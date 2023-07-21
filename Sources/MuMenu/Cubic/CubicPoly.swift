import QuartzCore

typealias Pnt4 = (CGPoint,CGPoint,CGPoint,CGPoint)
typealias Flt4 = (CGFloat,CGFloat,CGFloat,CGFloat)

struct CubicPoly {

    var coef = Flt4(0,0,0,0)

    func getInter(_  t: CGFloat) -> CGFloat {
        
        let t2 = t * t
        let t3 = t2 * t
        let r = coef.0 + coef.1 * t + coef.2 * t2 + coef.3 * t3
        return r
    }

    /// Compute coefficients for a cubic polynomial --  Catmull-Rom spline: interpolation
    ///
    ///     p(s) = coef.0 + coef.1 * s + coef.2 * s^2 + coef.3 * s^3 //such that
    ///     p(0) = x0, p(1) = x1 // and
    ///     p'(0) = t0, p'(1) = t1.
    ///
    mutating func updateCoef(_ f0: CGFloat,
                             _ f1: CGFloat,
                             _ t0: CGFloat,
                             _ t1: CGFloat) {
        coef.0 = f0
        coef.1 = t0
        coef.2 = -3*f0 + 3*f1 - 2*t0 - t1
        coef.3 =  2*f0 - 2*f1 +   t0 + t1
    }

    func sqrtDistance(_ f0: CGFloat, _ f1: CGFloat) -> CGFloat {

        let delta = abs(f1 - f0)
        return pow(delta * delta, 0.5)
    }

    mutating func makeCoeficients(_ f: Flt4) {

        // make 1d coeficients for r
        var d01 = sqrtDistance(f.0, f.1) // distance between f0 and f1
        var d12 = sqrtDistance(f.1, f.2) // distance between f1 and f2
        var d23 = sqrtDistance(f.2, f.3) // distance between f2 and f3

        // safety check for repeated points
        if d12 < 1e-4 { d12 = 1.0 }
        if d01 < 1e-4 { d01 = d12 }
        if d23 < 1e-4 { d23 = d12 }

        updateCoef(f.1, f.2, 0.5 * (f.2-f.0), 0.5 * (f.3-f.1))
    }
}
