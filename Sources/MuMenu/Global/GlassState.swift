// created by musesum on 7/25/25

import SwiftUI  
import MuFlo

open class GlassState: ObservableObject {

    private var glass˚ : Flo?
    @Published public var glass = true

    public init(_ root˚: Flo) {
        glass˚ = root˚.bind("more.glass") { f,_ in
            self.glass = f.bool
        }
    }
}

open class PanicState: ObservableObject {

    private var panic˚: Flo?
    private var nextFrame: NextFrame

    public init(_ root˚: Flo,
                _ nextFrame: NextFrame) {
        self.nextFrame = nextFrame
        self.panic˚ = root˚.bind("more.panic") { f,_ in
            self.nextFrame.addBetweenFrame {
                Reset.reset()
            }
        }
    }

}

