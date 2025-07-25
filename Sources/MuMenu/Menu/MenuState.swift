// created by musesum on 7/16/25

import SwiftUI
import MuFlo

#if os(visionOS)

@MainActor
open class HandState: ObservableObject {

    @Published public var showPhase = 0

    private var left˚  : Flo?
    private var right˚ : Flo?
    public var left = 0
    public var right = 0

    public init(_ root˚: Flo) {
        let menu = root˚.bind("hand.menu")

        left˚ = menu.bind("left" )
        left˚?.addClosure { f,_ in
            if let phase = f.intVal("phase") {
                self.leftPhase(phase)
            }
        }
        right˚ = menu.bind("right")
        right˚?.addClosure { f,_ in
            if let phase = f.intVal("phase") {
                self.rightPhase(phase)
            }
        }
    }
    func leftPhase(_ phase: Int) {
        if phase == 0 || phase == 3 {
            PrintLog("✋ left phase: \(phase)")
        }
        Task { @MainActor in self.showPhase = phase }
    }
    func rightPhase(_ phase: Int) {
        if phase == 0 || phase == 3 {
            PrintLog("🤚 right phase: \(phase)")
        }
        Task { @MainActor in self.showPhase = phase }
    }
}
#endif

open class GlassState: ObservableObject {

    private var glass˚ : Flo?
    @Published public var glass = true

    public init(_ root˚: Flo) {
        glass˚ = root˚.bind("more.settings.glass") { f,_ in
            self.glass = f.bool
        }
    }

}

