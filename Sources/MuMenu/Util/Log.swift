// Created by warren on 10/5/21.

import SwiftUI
import MuFlo // .digits
import MuVisit

public func log(_ title: String,
                format: String = "%.0f",
                _ items: [Any] = [],
                length: Int = 0,
                terminator: String = "\n") {
    
    var text = title
    for item in items {
        var delim = ""
        switch item {
            case let v as CGFloat : text += String(format: "(\(format)) ", v)
            case let v as Float   : text += String(format: "(\(format)) ", v)
            case let v as CGPoint : text += String(format: "∙(\(format), \(format)) ", v.x, v.y)
            case let v as CGSize  : text += String(format: "∘(\(format), \(format)) ", v.width, v.height)
            case let v as CGRect  : text += String(format: "▭(\(format),\(format); \(format),\(format)) ", v.origin.x, v.origin.y, v.size.width, v.size.height)

            case let v as MuTouchType: text += "\(v.symbol)"
            case let v as Set<MuTouchType>: text += "\(MuTouchType.symbols(v))"
            case let v as String: text += v

            case let v as Int: text += " \(v)"

            case let v as [Int]:
                text += " ["
                for vv in v {
                    text += (delim + "\(vv)")
                    delim = ","
                }
                text += "] "

            case let v as [CGFloat]:
                text += " ["
                for vv in v {
                    text += (delim + "\(Int(vv))")
                    delim = ","
                }
                text += "] "

            case let v as Double:

                text += v.digits(1...3) + " "

            case let v as [Double]:
                
                text += " ["
                for vv in v {
                    text += (delim + "\(vv.digits(1...3))")
                    delim = ","
                }
                text += "] "

            case let v as Bool:
                text += v ? "true " : "false "

            case let (x,y) as RangeXY:

                let xs = String(format: "%.0f…%.0f", x.lowerBound, x.upperBound)
                let ys = String(format: "%.0f…%.0f", y.lowerBound, y.upperBound)
                let xPad = String(format: "%@", xs)// xs.padding(toLength: 8, withPad: " ", startingAt: 0)
                let yPad = String(format: "%@", ys)//ys.padding(toLength: 8, withPad: " ", startingAt: 0)
                text += "(\(xPad) \(yPad))"

            default: break
        }
    }
    if length > 0 {
       print(text.padding(toLength: length, withPad: " ", startingAt: 0), terminator: " ")
    } else {
        print(text, terminator: terminator)
    }

}

func logTouch(_ time: TimeInterval,
         _ symbol: String) {

    print(String(format: "\n%.2f \(symbol)", time))
}

public func log(_ visit: Visitor) {
    var logs = [String]()
    for visited in visit.visited {
        if let flo = Flo.IdFlo[visited] {
            logs.append(flo.path(99) + ":\(flo.id)")
        } else if let val = FloExprs.IdFloVal[visited] {
            logs.append(val.flo.path(99) + "(\(val.name)):\(val.id)")
        } else if let exprs = FloExprs.IdExprs[visited] {
            logs.append(exprs.flo.path(99) + "(\(exprs.name)):\(exprs.id)")
        } else if let nodeVm = MuNodeVm.IdNode[visited] {
            logs.append(nodeVm.path ?? "⁉️")
        } else {
            logs.append(String(visited))
        }
    }
    print(visit.log)
    for log in logs {
        print(log)
    }
}
