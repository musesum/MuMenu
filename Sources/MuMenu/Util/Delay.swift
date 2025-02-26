//  created by musesum on 12/3/21.

import Foundation
/// execute a block at some time in the future
public func Schedule(_ future: TimeInterval, block: @escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + future) {
        block()
    }
}
