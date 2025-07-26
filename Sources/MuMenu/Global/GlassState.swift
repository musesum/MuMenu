// created by musesum on 7/25/25

import SwiftUI  
import MuFlo

open class GlassState: ObservableObject {

    private var glass˚ : Flo?
    @Published public var glass = true

    public init(_ root˚: Flo) {
        glass˚ = root˚.bind("more.settings.glass") { f,_ in
            self.glass = f.bool
        }
    }

}

