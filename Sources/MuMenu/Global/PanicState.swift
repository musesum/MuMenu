// created by musesum on 7/25/25

import SwiftUI  
import MuFlo

open class PanicState: ObservableObject {

    private var panic˚: Flo?

    public init(_ root˚: Flo) {
        self.panic˚ = root˚.bind("tape.panic") { f,_ in
            NextFrame.shared.addBetweenFrame {
                Reset.reset()
            }
        }
    }

}

