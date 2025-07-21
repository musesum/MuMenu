// created by musesum on 7/16/25

import SwiftUI
import MuFlo

@MainActor
open class MenuState: ObservableObject {

    private var glass˚ : Flo?
    @Published public var glass = true
    @Published public var showMenu = true

#if !os(visionOS)
    public init(_ root˚: Flo) {
        glass˚ = root˚.bind("more.settings.glass") { f,_ in
            self.glass = f.bool
        }
    }
#else
    private var left˚  : Flo?
    private var right˚ : Flo?
    public var left = 0
    public var right = 0

    public init(_ root˚: Flo) {
        let menu = root˚.bind("hand.menu")

        left˚  = menu.bind("left" ) { f,_ in
            if let phase = f.intVal("phase"),
                phase == 0
            {
                Task { @MainActor in
                    self.leftPhase(phase)
                }
            }
        }
        right˚ = menu.bind("right") { f,_ in
            if let phase = f.intVal("phase"),
                phase == 0
            {
                Task { @MainActor in
                    self.rightPhase(phase)
                }
            }
        }
    }
    func leftPhase(_ phase: Int) {
        PrintLog("✋ left phase: \(phase)")
        showMenu = true
    }
    func rightPhase(_ phase: Int) {
        PrintLog("🤚 right phase: \(phase)")
        showMenu = true
    }
#endif
}
