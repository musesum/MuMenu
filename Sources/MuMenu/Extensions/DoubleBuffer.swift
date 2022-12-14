//  Created by warren on 12/16/22.

import Foundation

public protocol BufferFlushDelegate {
    associatedtype Item
    mutating func flushItem<Item>(_ item: Item) -> Bool
}

public class DoubleBuffer<Item> {

    private var buf0 = [Item]()
    private var buf1 = [Item]()
    private var bufs: [[Item]]
    private var indexNow = 0
    private var timer: Timer?

    public var flusher: (any BufferFlushDelegate)?

    public var isEmpty: Bool {
        bufs[indexNow].isEmpty
    }

    /// canvas manages loop from metal frame callback
    public init(internalLoop: Bool) {
        self.bufs = [buf0,buf1]
        if internalLoop {
            self.bufferLoop()
        }
    }
    deinit {
        timer?.invalidate()
    }

    public func flush() -> Bool {
        guard var flusher else { return false }
        if bufs[indexNow].count == 0 { return false }

        let indexFlush = indexNow // flush what used to be nextBuffer
        indexNow = indexNow ^ 1   // flip double buffer
        var isDone = false
        for item in bufs[indexFlush] {
            isDone = flusher.flushItem(item)
        }
        bufs[indexFlush].removeAll()
        return isDone
    }

    public func append(_ item: Item) {
        bufs[indexNow].append(item)
    }

    func bufferLoop() {

        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            let isDone = self.flush()
            if isDone {
                timer.invalidate()
            }
        }
    }
}
