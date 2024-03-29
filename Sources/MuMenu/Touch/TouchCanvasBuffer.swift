//  created by musesum on 8/22/23.

import UIKit
import MuFlo
import MuPeer
import MuHand

open class TouchCanvasBuffer {

    // repeat last touch until isDone
    private var lastItem: TouchCanvasItem?

    // each finger or brush gets its own double buffer
    private let buffer = DoubleBuffer<TouchCanvasItem>(internalLoop: false)
    private var indexNow = 0
    private var touchCanvas: TouchCanvas
    private var isDone = false
    private var touchCubic = TouchCubic()

    public init(_ touch: UITouch,
                _ touchCanvas: TouchCanvas) {

        self.touchCanvas = touchCanvas
        buffer.delegate = self

        addTouchItem(touch)
    }

    public init(_ touchItem: TouchCanvasItem,
                _ touchCanvas: TouchCanvas) {

        self.touchCanvas = touchCanvas
        buffer.delegate = self

        addTouchCanvasItem(touchItem)
    }


    public init(_ jointFlo: JointFlo,
                _ touchCanvas: TouchCanvas) {

        self.touchCanvas = touchCanvas
        buffer.delegate = self

        addTouchHand(jointFlo)
    }

    public func addTouchHand(_ jointFlo: JointFlo) {

        let force = CGFloat(jointFlo.pos.z) * -200
        let radius = force
        let nextXY = CGPoint(x: CGFloat( jointFlo.pos.x * 400 + 800),
                             y: CGFloat(-jointFlo.pos.y * 400 + 800))

        let phase = jointFlo.phase
        let azimuth = CGFloat.zero
        let altitude = CGFloat.zero

        //logTouch(phase, nextXY, radius)

        let item = makeTouchCanvasItem(jointFlo.hash, force, radius, nextXY, phase, azimuth, altitude, Visitor(.canvas))

        if PeersController.shared.hasPeers {

            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(item)
                PeersController.shared.sendMessage(data, viaStream: true)
            } catch {
                print(error)
            }
        }
        buffer.append(item)

    }


    // TODO:  separate out //??
    var posX: ClosedRange<CGFloat>?
    var posY: ClosedRange<CGFloat>?
    var radi: ClosedRange<CGFloat>?

    func logTouch(_ phase: UITouch.Phase,
                  _ nextXY: CGPoint,
                  _ radius: CGFloat) {

        switch phase {
        case .began: logNow("\n👍🟢") ; resetRanges()
        case .moved: logNow("🫰🔷")   ; setRanges()
        case .ended: logNow("🖐️🛑")   ; setRanges() ; logRanges()
        default    : print("🖐️⁉️")
        }
        func logNow(_ msg: String) {
            //print("\(msg)(\(nextXY.x.digits(0...2)), \(nextXY.y.digits(0...2)), \(radius.digits(0...2)))", terminator: " ")
        }
        func resetRanges() {
            posX = nil
            posY = nil
            radi = nil
            setRanges()
        }
        func setRanges() {
            if posX == nil {
                posX = nextXY.x...nextXY.x
            } else if let xx = posX {
                posX = min(xx.lowerBound, nextXY.x)...max(xx.upperBound, nextXY.x)
            }
            if posY == nil {
                posY = nextXY.y...nextXY.y
            } else if let yy = posY {
                posY = min(yy.lowerBound, nextXY.y)...max(yy.upperBound, nextXY.y)
            }
            if radi == nil {
                radi = radius...radius
            } else if let rr = radi {
                radi = min(rr.lowerBound, radius)...max(rr.upperBound, radius)
            }
        }
        func logRanges() {
            if let posX, let  posY, let radi {
                let xStr = "\(posX.lowerBound.digits(0...2))...\(posX.upperBound.digits(0...2))"
                let yStr = "\(posY.lowerBound.digits(0...2))...\(posY.upperBound.digits(0...2))"
                let rStr = "\(radi.lowerBound.digits(0...2))...\(radi.upperBound.digits(0...2))"

                print("\n👐 (\(xStr), \(yStr), \(rStr))")
            }
        }
    }

    public func addTouchCanvasItem(_ touchItem: TouchCanvasItem) {
        buffer.append(touchItem)
    }

    public func addTouchItem(_ touch: UITouch) {

        let force = touch.force
        let radius = touch.majorRadius
        let nextXY = touch.preciseLocation(in: nil)
        let phase = touch.phase
        let azimuth = touch.azimuthAngle(in: nil)
        let altitude = touch.altitudeAngle

        //logTouch(phase, nextXY, radius)

        let item = makeTouchCanvasItem(touch.hash, force, radius, nextXY, phase, azimuth, altitude, Visitor(.canvas))


        if PeersController.shared.hasPeers {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(item)
                PeersController.shared.sendMessage(data, viaStream: true)
            } catch {
                print(error)
            }
        }
        buffer.append(item)
    }
    public func makeTouchCanvasItem(
        _ key     : Int,
        _ force   : CGFloat,
        _ radius  : CGFloat,
        _ nextXY  : CGPoint,
        _ phase   : UITouch.Phase,
        _ azimuth : CGFloat,
        _ altitude: CGFloat,
        _ visit   : Visitor) -> TouchCanvasItem {

            let alti = (.pi/2 - altitude) / .pi/2
            let azim = CGVector(dx: -sin(azimuth) * alti, dy: cos(azimuth) * alti)
            var force = Float(force)
            var radius = Float(radius)

            if let lastItem {

                let forceFilter = Float(0.90)
                force = (lastItem.force * forceFilter) + (force * (1-forceFilter))

                let radiusFilter = Float(0.95)
                radius = (lastItem.radius * radiusFilter) + (radius * (1-radiusFilter))
                //print(String(format: "* %.3f -> %.3f", lastItem.force, force))
            } else {
                force = 0 // bug: always begins at 0.5
            }
            let item = TouchCanvasItem(key, nextXY, radius, force, azim, phase, visit)
            return item
        }

}
extension TouchCanvasBuffer: DoubleBufferDelegate {

    public typealias Item = TouchCanvasItem

    @discardableResult
    public func flushItem<Item>(_ item: Item) -> Bool {
        guard let item = item as? TouchCanvasItem else { return false }

        lastItem = item

        let radius = touchCanvas.touchFlo.updateRadius(item)
        let point = item.cgPoint
        isDone = item.isDone()

        touchCubic.addPointRadius(point, radius, isDone)
        touchCubic.drawPoints(touchCanvas.touchFlo.drawPoint)
        return isDone
    }

    func flushTouches() -> Bool {

        if buffer.isEmpty,
           TouchCanvas.shared.touchRepeat,
           let lastItem {
            // finger is stationary repeat last movement
            flushItem(lastItem)
        } else {
            isDone = buffer.flushBuf()
        }
        return isDone

    }

}
