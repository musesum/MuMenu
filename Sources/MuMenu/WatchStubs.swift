#if os(watchOS)
import SwiftUI
import MuFlo
import MuPeers

// Minimal MuHands stand-ins so MuMenu types referencing MuHands types
// still compile on watchOS, where MuHands is unavailable. All values
// are inert defaults — no actual hand tracking occurs on watchOS.

public enum TouchPhase: Int {
    case began  = 0
    case update = 1
    case ended  = 3

    public var begin  : Bool { self == .began  }
    public var update : Bool { self == .update }
    public var end    : Bool { self == .ended  }
}

public struct leftRight<T> {
    public var left: T
    public var right: T
    public init(_ left: T, _ right: T) {
        self.left = left
        self.right = right
    }
}

@MainActor
public final class HandsPhase: ObservableObject {

    @Published public var update: Int = 0
    public var state: leftRight<TouchPhase?> = .init(nil, nil)
    public var handsState: String { "" }

    public init(_ root˚: Flo) {}
}

// shareItem on watchOS broadcasts MenuItems to MuPeers — same payload
// format the iOS RootVm+Peers extension uses. Watch sends only; receive
// path stays gated until MenuTouch is ported.
extension RootVm {
    public func shareItem(_ item: Any) {
        guard let item = item as? MenuItem,
              item.policy.contains(.share) else { return }
        Task.detached {
            await Peers.shared.sendItem(.menuItem) {
                do {
                    return try JSONEncoder().encode(item)
                } catch {
                    PrintLog(error.localizedDescription)
                    return nil
                }
            }
        }
    }
}
#endif
