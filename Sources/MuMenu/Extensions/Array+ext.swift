//  Created by warren on 12/20/22.


import Foundation

extension Array where Element == Double {

    public static func - (lhs: [Double], rhs: [Double]) -> [Double] {
        var result = [Double]()
        for index in 0 ..< lhs.count {
            let left = lhs[index]
            let right = index < rhs.count ? rhs[index] : 0
            result.append(left - right)
        }
        return result
    }
    public static func * (lhs: [Double], rhs: [Double]) -> [Double] {
        var result = [Double]()
        for  index in 0 ..< lhs.count {
            let left = lhs[index]
            let right = index < rhs.count ? rhs[index] : 0
            result.append(left * right)
        }
        return result
    }
    public static func * (lhs: [Double], rhs: Double) -> [Double] {
        var result = [Double]()
        for  left in lhs {
            result.append(left * rhs)
        }
        return result
    }

    public func distance(_ from: [Double]) -> Double {
        let result = sqrt( (self[0]-from[0]) * (self[0]-from[0]) +
                           (self[1]-from[1]) * (self[1]-from[1]) )
        return result
    }
}
