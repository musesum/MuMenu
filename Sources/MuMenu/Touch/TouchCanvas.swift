//  Created by warren on 2/5/19.

import UIKit
import MuFlo // digits
import MuVisit
import MuPeer
import MuTime // DoubleBuffer


public typealias TouchDrawPoint = ((CGPoint, CGFloat)->())
public typealias TouchDrawRadius = ((TouchCanvasItem)->(CGFloat))

open class TouchCanvas {

    static public var touchRepeat = true /// repeat touch, even when not moving finger
    static var drawPoint: TouchDrawPoint?
    static var drawRadius: TouchDrawRadius?
    static var canvasKey = [Int: TouchCanvas]()

    private let buffer = DoubleBuffer<TouchCanvasItem>(internalLoop: false)
    private var lastItem: TouchCanvasItem? // repeat last touch until isDone
    private var touchCubic = TouchCubic()
    private var indexNow = 0
    private var isDone = false
    private var filterForce = CGFloat(0) // Apple Pencil begins at 0.333; filter the blotch
    private var isRemote: Bool

    public init(isRemote: Bool) {

        self.isRemote = isRemote
        buffer.flusher = self
    }

    func addTouchItem(_ key: Int,
                      _ touch: UITouch) {

        let force = touch.force
        let radius = touch.majorRadius
        let nextXY = touch.preciseLocation(in: nil)
        let phase = touch.phase
        let azimuth = touch.azimuthAngle(in: nil)
        let altitude = touch.altitudeAngle

        let item = makeTouchItem(key, force, radius, nextXY, phase, azimuth, altitude, Visitor(.canvas))
        buffer.append(item)
        if PeersController.shared.hasPeers {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(item)
                PeersController.shared.sendMessage(data, viaStream: true)
            } catch {
                print(error)
            }
        }
    }

    func makeTouchItem(_ key     : Int,
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

extension TouchCanvas: BufferFlushDelegate {

    public typealias Item = TouchCanvasItem

    public func flushItem<Item>(_ item: Item) -> Bool {
        guard let item = item as? TouchCanvasItem else {
            return false }
        lastItem = item

        let radius = TouchCanvas.drawRadius?(item) ?? 10
        let point = item.cgPoint
        isDone = item.isDone()

        touchCubic.addPointRadius(point, radius, isDone)
        touchCubic.drawPoints(TouchCanvas.drawPoint)
        return isDone
    }

    func flushTouches()  {

        if buffer.isEmpty,
           TouchCanvas.touchRepeat,
           let lastItem {
            // finger is stationary repeat last movement
            _ = flushItem(lastItem)
        } else {
            isDone = buffer.flushBuf()
        }
    }
}

extension TouchCanvas {

    public static func beginTouch(_ touch: UITouch) -> Bool {
        let touchCanvas = TouchCanvas(isRemote: false)
        let key = touch.hash
        canvasKey[key] = touchCanvas
        touchCanvas.addTouchItem(key, touch)
        return true
    }
    public static func updateTouch(_ touch: UITouch) -> Bool {
        let key = touch.hash
        if let touchCanvas = canvasKey[key] {
            touchCanvas.addTouchItem(key, touch)
            return true
        }
        return false
    }
    static public func remoteItem(_ item: TouchCanvasItem) {
        if let canvas = canvasKey[item.key] {
            canvas.buffer.append(item)
        } else {
            let canvas = TouchCanvas(isRemote: true)
            canvasKey[item.key] = canvas
            canvas.buffer.append(item)
        }
    }
    public static func addCanvasItem(_ item: TouchCanvasItem,
                                     isRemote: Bool) {
        let key = item.key
        if canvasKey[key] == nil {
            canvasKey[key] = TouchCanvas(isRemote: isRemote)
        }
        canvasKey[key]?.buffer.append(item)
    }
    public static func flushTouchCanvas() {

        for (key, canvas) in canvasKey {
            canvas.flushTouches()
            if canvas.isDone {
                canvasKey.removeValue(forKey: key)
            }
        }
    }

}
