// Created by warren on 7/19/19.
//  Copyright © 2019 DeepMuse All rights reserved.

import Foundation
import QuartzCore
import UIKit

public typealias RangeXY = (ClosedRange<CGFloat>, ClosedRange<CGFloat>)

extension CGRect {

    public func horizontal() -> Bool {
        return size.width > size.height
    }

   public func between(_ p: CGPoint) -> CGPoint {

        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height
    
        let pp = CGPoint(x: max(x, min(p.x, x + w)),
                         y: max(y, min(p.y, y + h)))
        return pp
    }
    public func between(_ p: CGRect, _ insets: UIEdgeInsets = .zero) -> CGRect {

        let x = origin.x + insets.left
        let y = origin.y + insets.right
        let w = size.width - insets.left - insets.right
        let h = size.height - insets.top - insets.bottom

        var px = p.origin.x
        var py = p.origin.y
        var pw = p.size.width
        var ph = p.size.height

        if pw > w { pw = w }
        if ph > h { ph = h }
        if px < insets.left { px = insets.left }
        if py < insets.top { py = insets.top }
        if px + pw > x + w { px = x + w - pw }
        if py + ph > y + h { py = y + h - ph }

        let pp = CGRect(x: px, y: py, width: pw, height: ph)

        return pp
    }
    public var center: CGPoint { get   {
        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height
        let pp = CGPoint(x: x + w/2, y: y + h/2)
        return pp
        }
    }

    /// scale up for a point p normalized between 0...1
    public func scaleUpFrom01(_ p: CGPoint) -> CGPoint {

        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height

        let pp = CGPoint(x: x + p.x * w,
                         y: y + p.y * h)
        return pp
    }

    /// scale down to a point p normalized between 0...1
    public func normalizeTo01(_ p: CGPoint) -> CGPoint {

        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height

        let pp = between(p)
        let xx = w == 0 ? 0 : (pp.x - x) / w
        let yy = h == 0 ? 0 : (pp.y - y) / h
        let ppp = CGPoint(x: xx,  y: yy)
        return ppp
    }

    func cornerDistance() -> CGFloat {

        let w = size.width
        let h = size.height

        let d = sqrt((w*w)+(h*h))
        return d
    }


    /// before and after are two finger pinch bounding rectangle.
    /// while pinching, rescale the current rect
    /// while shifting center shift rootd on direction of pinch
    func reScale(before: CGRect, after: CGRect) -> CGRect {

        let scale = after.cornerDistance() / before.cornerDistance()
        let delta = after.center - before.center

        let x = origin.x
        let y = origin.y
        let w = size.width
        let h = size.height

        let r = CGRect(x: x - delta.x,
                       y: y - delta.y,
                       width: w * scale,
                       height: h * scale)
        return r
    }

    public func pad (_ pad: CGFloat) -> CGRect {
        let xx = origin.x - pad
        let yy = origin.y - pad
        let ww = width + pad * 2
        let hh = height + pad * 2
        let s = CGRect(x: xx, y: yy, width: ww, height: hh)
        return s
    }

    public static func + (lhs: CGRect, rhs: CGPoint) -> CGRect {
        let xx = lhs.origin.x + rhs.x
        let yy = lhs.origin.y + rhs.y
        let ww = lhs.width
        let hh = lhs.height
        let s = CGRect(x: xx, y: yy, width: ww, height: hh)
        return s
    }
    public static func - (lhs: CGRect, rhs: CGPoint) -> CGRect {
        let xx = lhs.origin.x + rhs.x
        let yy = lhs.origin.y + rhs.y
        let ww = lhs.width
        let hh = lhs.height
        let s = CGRect(x: xx, y: yy, width: ww, height: hh)
        return s
    }
}

extension CGPoint {

    public static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let p = CGPoint(x: lhs.x - rhs.x,
                        y: lhs.y - rhs.y)
        return p
    }
    public static func - (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        let p = CGPoint(x: lhs.x - rhs.width,
                        y: lhs.y - rhs.height)
        return p
    }

    public static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        let p = CGPoint(x: lhs.x + rhs.x,
                        y: lhs.y + rhs.y)
        return p
    }
    public static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
        let p = CGPoint(x: lhs.x + rhs.width,
                        y: lhs.y + rhs.height)
        return p
    }
    public static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {

        let xx = lhs.x / rhs
        let yy = lhs.y / rhs
        let p = CGPoint(x: xx, y: yy)
        return p
    }

    public static func / (lhs: CGPoint, rhs: CGPoint) -> CGPoint {

        let xx = rhs.x > 0 ? lhs.x / rhs.x : 0
        let yy = rhs.y > 0 ? lhs.y / rhs.y : 0
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    
    public static func / (lhs: CGPoint, rhs: CGSize) -> CGPoint {

        let xx = rhs.width  > 0 ? lhs.x / rhs.width  : 0
        let yy = rhs.height > 0 ? lhs.y / rhs.height : 0
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    public static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {

        let xx = lhs.x * rhs
        let yy = lhs.y * rhs
        let p = CGPoint(x: xx, y: yy)
        return p
    }
    public func distance(_ from: CGPoint) -> CGFloat {
        let result = sqrt( (x-from.x) * (x-from.x) + (y-from.y) *  (y-from.y) )
        return result
    }
    
    /// round to nearest grid
    public func grid(_ divisions: CGFloat) -> CGPoint {
        if divisions > 0 {
            return  CGPoint(x: round(x * divisions) / divisions,
                            y: round(y * divisions) / divisions)
        }
        return self
    }
    public func string(_ format: String = "%2.0f,%-2.0f") -> String {
        return String(format: format, x, y) // touch delta
    }
    public init(_ size: CGSize) {
        self.init()
        x = size.width
        y = size.height
    }
    public func doubles() -> [Double] {
        return [Double(x), Double(y)]
    }
}

extension CGSize {
    
    public init(_ xy: CGPoint) {
        self.init()
        self.width = xy.x
        self.height = xy.y
    }
    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        let ww = lhs.width - rhs.width
        let hh = lhs.height - rhs.height
        let s = CGSize(width: ww, height: hh)
        return s
    }
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        let ww = lhs.width + rhs.width
        let hh = lhs.height + rhs.height
        let s = CGSize(width: ww, height: hh)
        return s
    }
    public static func + (lhs: CGSize, rhs: CGFloat) -> CGSize {
        let ww = lhs.width + rhs
        let hh = lhs.height + rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }
    
    public static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
        
        let ww = lhs.width / rhs
        let hh = lhs.height / rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }
    public static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        
        let ww = lhs.width * rhs
        let hh = lhs.height * rhs
        let s = CGSize(width: ww, height: hh)
        return s
    }
    public static func - (lhs: CGSize, rhs: CGPoint) -> CGSize {
        let ww = lhs.width - rhs.x
        let hh = lhs.height - rhs.y
        let s = CGSize(width: ww, height: hh)
        return s
    }
    
    public static func + (lhs: CGSize, rhs: CGPoint) -> CGSize {
        let ww = lhs.width + rhs.x
        let hh = lhs.height + rhs.y
        let s = CGSize(width: ww, height: hh)
        return s
    }
    
    public func string(_ format: String = "%2.0f,%-2.0f") -> String {
        return String(format: format, width, height) // touch delta
    }
    
    public func clamp(_ widthvalue: ClosedRange<CGFloat>,
                      _ heightvalue: ClosedRange<CGFloat>) -> CGSize {
        
        return CGSize(width:  width.clamped(to: widthvalue),
                      height: height.clamped(to: heightvalue) )
    }
    /// fit smaller self's smaller rect inside to's rect
    /// may overlay lower right edges, but not upper left
    public func clamped(to: RangeXY) -> CGSize {
        let (xClamp,yClamp) = to
        
        let ww = self.width.clamped(to: xClamp)
        let hh = self.height.clamped(to: yClamp)
        
        let size = CGSize(width: ww, height: hh)
        return size
    }
}
extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {

        hasher.combine(width*9999)
        hasher.combine(height)
        _ = hasher.finalize()
    }
}
