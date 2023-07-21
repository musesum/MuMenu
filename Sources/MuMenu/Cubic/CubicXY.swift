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

        x.makeCoeficients((p.0.x, p.1.x, p.2.x, p.3.x))
        y.makeCoeficients((p.0.y, p.1.y, p.2.y, p.3.y))
    }

    func getInterPoint(_ inter: CGFloat) -> CGPoint {
        let xx = x.getFloat(inter)
        let yy = y.getFloat(inter)
        return CGPoint(x: xx, y: yy)
    }
}


