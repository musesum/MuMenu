#if !os(watchOS)
//  created by musesum on 8/13/26

import Foundation
import MuFlo

/// The event collector between the flo tree and the graph page.
///
/// A flo write arrives on whatever thread fired it — the CoreMIDI thread for a
/// played note, the main thread for a dragged control, the peer link's own
/// thread for either one arriving from another device — so nothing here is
/// actor isolated and every field is taken under the lock. One hop per window
/// carries the gathered ids to the page, which keeps a held pitch bend to
/// twenty posts a second however many messages it sends.
final class GraphPulse: @unchecked Sendable {

    /// the window a burst of events is gathered over, in seconds
    static let gap = 0.05

    private let lock = NSLock()
    private var pending = Set<Int>()
    private var flushing = false        /// a hop is already booked
    private var listening = false       /// the channel is on and the page is up
    private let post: @MainActor @Sendable ([Int]) -> Void

    init(post: @escaping @MainActor @Sendable ([Int]) -> Void) {
        self.post = post
    }

    /// the gate. Off drops what was gathered, so switching back on starts clean
    var live: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return listening
        }
        set {
            lock.lock()
            listening = newValue
            if !newValue { pending.removeAll() }
            lock.unlock()
        }
    }

    /// one flo said its value out loud
    func add(_ id: Int) {
        lock.lock()
        guard listening else { lock.unlock(); return }
        pending.insert(id)
        let book = !flushing
        if book { flushing = true }
        lock.unlock()

        guard book else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.gap) { [self] in
            let ids = take()
            guard !ids.isEmpty else { return }
            MainActor.assumeIsolated { post(ids) }
        }
    }

    private func take() -> [Int] {
        lock.lock()
        defer { lock.unlock() }
        flushing = false
        let ids = Array(pending)
        pending.removeAll()
        return ids
    }
}
#endif
