import QuartzCore

class CubicXYR: CubicXY {

    var r = CubicPoly()

    func sqrtDistance(_ f0: CGFloat, _ f1: CGFloat) -> CGFloat {

        let delta = abs(f1 - f0)
        return  pow(delta * delta, 0.5)
    }

    func makeCoeficients(_ p: Pnt4, _ f: Flt4) {

        super.makeCoeficients(p) // get 2d coeficients for xy

        // make 1d coeficients for r
        var d01 = sqrtDistance(f.0, f.1) // distance between f0 and f1
        var d12 = sqrtDistance(f.1, f.2) // distance between f1 and f2
        var d23 = sqrtDistance(f.2, f.3) // distance between f2 and f3

        // safety check for repeated points
        if d12 < 1e-4 { d12 = 1.0 }
        if d01 < 1e-4 { d01 = d12 }
        if d23 < 1e-4 { d23 = d12 }

        r = CubicPoly.MakeCatmullRom(f)
    }
}
