// created by musesum on 7/16/25

import SwiftUI
import MuFlo
import MuHands// LeftRight

#if os(visionOS)

public enum PinchState: Int {
    case begin   = 0
    case update  = 1
    case end     = 2

}

@MainActor
open class PinchPhase: ObservableObject {

    //..... @Published public var showPhase = 0
    @Published public var state: leftRight<PinchState> = .init(.end, .end)

    private var left˚  : Flo?
    private var right˚ : Flo?
    public var left = 0
    public var right = 0

    public init(_ root˚: Flo) {
        let pinch = root˚.bind("hand.pinch" )

        left˚ = pinch.bind("left" ) { f,_ in
            if let phase = f.intVal("phase"),
               let state = PinchState(rawValue: phase) {
                self.leftPhase(state)
            }
        }
        right˚ = pinch.bind("right") { f,_ in
            if let phase = f.intVal("phase"),
               let state = PinchState(rawValue: phase) {
                self.rightPhase(state)
            }
        }
    }
    func leftPhase(_ state: PinchState) {
        if [.begin, .end].contains(state) {
            PrintLog("✋ left phase: \(state.rawValue)")
        }
        Task { @MainActor in
            self.state = .init(state, self.state.right)
        }
    }
    func rightPhase(_ state: PinchState) {
        if [.begin, .end].contains(state)  {
            PrintLog("🤚 right phase: \(state.rawValue)")
        }
        Task { @MainActor in
            self.state = .init(self.state.left, state)
        }
    }
}
#endif

