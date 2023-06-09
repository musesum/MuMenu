import QuartzCore

struct CubicPoly {

    var coef = Flt4(0,0,0,0)

    func getFloat(_  t: CGFloat) -> CGFloat {
        
        let t2 = t * t
        let t3 = t2 * t
        let r = coef.0 + coef.1 * t + coef.2 * t2 + coef.3 * t3
        return r
    }

    /// Compute coefficients for a cubic polynomial
    ///
    ///     p(s) = coef.0 + coef.1 * s + coef.2 * s^2 + coef.3 * s^3 //such that
    ///     p(0) = x0, p(1) = x1 // and
    ///     p'(0) = t0, p'(1) = t1.
    ///
    static func MakeCubicPoly(_ f0: CGFloat,
                              _ f1: CGFloat,
                              _ t0: CGFloat,
                              _ t1: CGFloat) -> CubicPoly {

        var poly = CubicPoly()

        poly.coef.0 = f0
        poly.coef.1 = t0
        poly.coef.2 = -3*f0 + 3*f1 - 2*t0 - t1
        poly.coef.3 =  2*f0 - 2*f1 +   t0 + t1
        return poly
    }

    func getPoint(_ t: CGFloat,
                  _ xy: CubicXY) -> CGPoint {

        let p = CGPoint(x: xy.x.getFloat(t),
                        y: xy.y.getFloat(t))
        return p
    }

    /// standard Catmull-Rom spline: interpolation
    static func MakeCatmullRom(_ f: Flt4) -> CubicPoly {

        let poly = MakeCubicPoly(f.1, f.2, 0.5 * (f.2-f.0), 0.5 * (f.3-f.1))
        return poly
    }
}
