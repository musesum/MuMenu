//  Created by warren on 2/5/19.

import UIKit
import MuFlo // digits
import MuVisit
import MuPeer
import MuTime // DoubleBuffer
import MuMetal

public typealias TouchDrawPoint = ((CGPoint, CGFloat)->())
public typealias TouchDrawRadius = ((TouchCanvasItem)->(CGFloat))

open class TouchCanvasBuffer {

    var lastItem: TouchCanvasItem? // repeat last touch until isDone
                                   // each finger or brush gets its own double buffer
    public let buffer = DoubleBuffer<TouchCanvasItem>(internalLoop: false)
    private var indexNow = 0
    private var touchCanvas: TouchCanvas
    private var isDone = false
    private var touchCubic = TouchCubic()

    public init(_ touch: UITouch,
                _ touchCanvas: TouchCanvas) {
        self.touchCanvas = touchCanvas
        buffer.flusher = self

        addTouchItem(touch)
        
    }

    public init(_ touchItem: TouchCanvasItem,
                _ touchCanvas: TouchCanvas) {
        self.touchCanvas = touchCanvas
        buffer.flusher = self

        addTouchCanvasItem(touchItem)

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

        func makeTouchCanvasItem(
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

}
extension TouchCanvasBuffer: BufferFlushDelegate {

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

open class TouchCanvas {

    static public let shared = TouchCanvas()
    static var touchBuffers = [Int: TouchCanvasBuffer]()
    public var touchRepeat = true /// repeat touch, even when not moving finger
    public var touchFlo = TouchFlo()

    public init() {

        PeersController.shared.peersDelegates.append(self)
    }
    deinit {
        PeersController.shared.remove(peersDelegate: self)
    }
}

extension TouchCanvas {

    public func beginTouch(_ touch: UITouch) -> Bool {
        TouchCanvas.touchBuffers[touch.hash] = TouchCanvasBuffer(touch, self)
        return true
    }
    public func updateTouch(_ touch: UITouch) -> Bool {
        if let touchBuffer = TouchCanvas.touchBuffers[touch.hash] {
            touchBuffer.addTouchItem(touch)
            return true
        }

        return false
    }
    public func remoteItem(_ item: TouchCanvasItem) {

        if let touchBuffer = TouchCanvas.touchBuffers[item.key] {
            touchBuffer.addTouchCanvasItem(item)
        } else {
            TouchCanvas.touchBuffers[item.key] = TouchCanvasBuffer(item, self)
        }
    }
    public static func flushTouchCanvas() {
        var removeKeys = [Int]()
        for (key, buf) in touchBuffers {
            let isDone = buf.flushTouches()
            if isDone { removeKeys.append(key) }
        }
        for key in removeKeys {
            touchBuffers.removeValue(forKey: key)
        }
    }

}


