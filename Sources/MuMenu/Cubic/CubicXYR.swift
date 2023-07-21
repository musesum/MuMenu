import QuartzCore

class CubicXYR: CubicXY {

    var r = CubicPoly()

    func sqrtDistance(_ f0: CGFloat, _ f1: CGFloat) -> CGFloat {

        let delta = abs(f1 - f0)
        return pow(delta * delta, 0.5)
    }

    func makeCoeficients(_ p: Pnt4, _ f: Flt4) {

        super.makeCoeficients(p) // get 2d coeficients for xy
        r.makeCoeficients(f)
    }
}
