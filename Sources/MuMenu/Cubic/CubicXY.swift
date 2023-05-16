import QuartzCore

typealias Pnt4 = (CGPoint,CGPoint,CGPoint,CGPoint)
typealias Flt4 = (CGFloat,CGFloat,CGFloat,CGFloat)

class CubicXY {

    var x = CubicPoly()
    var y = CubicPoly()

    /// squareroot distance
    func sqrtDistance(_ p: CGPoint, _ q: CGPoint) -> CGFloat {

        let dx = q.x - p.x
        let dy = q.y - p.y
        return pow(dx*dx + dy*dy, 0.5) // TODO: should 0.25 be 0.5?
    }

    func makeCoeficients(_ p: Pnt4) {

        var d01 = sqrtDistance(p.0, p.1) // distance between p0 and p1
        var d12 = sqrtDistance(p.1, p.2) // distance between p1 and p2
        var d23 = sqrtDistance(p.2, p.3) // distance between p2 and p3

        // safety check for repeated points
        if (d12 < 1e-4) { d12 = 1.0 }
        if (d01 < 1e-4) { d01 = d12 }
        if (d23 < 1e-4) { d23 = d12 }
        let x_ = Flt4(p.0.x, p.1.x, p.2.x, p.3.x)
        let y_ = Flt4(p.0.y, p.1.y, p.2.y, p.3.y)

        x = CubicPoly.MakeCatmullRom(x_)
        y = CubicPoly.MakeCatmullRom(y_)
    }

    func getInterPoint(_ inter: CGFloat) -> CGPoint {
        let xx = x.getFloat(inter)
        let yy = y.getFloat(inter)
        return CGPoint(x: xx, y: yy)
    }
}


