// created by musesum on 8/7/26

import SwiftUI
import Combine

/// the menu container size, posted by MenuView's geometry reader.
/// The current value replays, so a panel built later still clamps
@MainActor
final class MenuScreen {

    static let shared = MenuScreen()

    /// zero until the first geometry pass
    let size = CurrentValueSubject<CGSize, Never>(.zero)

    private init() {}

    /// an unchanged size posts nothing, so layout churn wakes no reader
    func post(_ now: CGSize) {
        guard now != size.value else { return }
        size.send(now)
    }
}
