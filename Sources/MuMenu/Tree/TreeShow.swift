// created by musesum on 7/16/25

import SwiftUI

class TreeShow: ObservableObject, @unchecked Sendable {
    @Published private var state: State = .showing

    private enum State: String {
        case hidden, fadeOut, showing
    }
    var opacity: CGFloat {
        switch state {
        case .hidden  : return 0.00
        case .showing : return 1.00
        case .fadeOut : return 0.05
        }
    }

    let autoFadeInterval: TimeInterval = 4.0
    let fadeOutInterval: TimeInterval = 8.0
    let animInterval: TimeInterval = 0.25
    let tapInterval: TimeInterval = 0.5

    var animation: Animation {
        switch state {
        case .hidden  : return Animate(animInterval)
        case .showing : return Animate(animInterval)
        case .fadeOut : return Animate(fadeOutInterval)
        }
    }

    var autoFadeTimer: Timer?
    var fadeOutTimer: Timer?
    var fadeInTimer: Timer?
    var showStartTime: TimeInterval = 0.0

    func clearTimers() {
        autoFadeTimer?.invalidate()
        fadeInTimer?.invalidate()
        fadeOutTimer?.invalidate()
    }

    public func startAutoFade() {

        clearTimers()
        if state == .hidden {
            print("??")
        }

        autoFadeTimer = Timer.scheduledTimer(
            withTimeInterval: autoFadeInterval,
            repeats: false) { _ in

                self.fadeOut()
            }
    }
    func fadeOut() {
        clearTimers()
        state = .fadeOut

        fadeOutTimer = Timer.scheduledTimer(
            withTimeInterval: fadeOutInterval,
            repeats: false) {_ in

                self.hideTree()
            }
    }
    func hideTree() {
        clearTimers()
        state = .hidden
    }

    func showTree() {
        clearTimers()
        if state == .hidden {
            showStartTime = Date().timeIntervalSince1970
        }
        state = .showing
        startAutoFade()
    }

    func toggleTree() {
        let timeNow = Date().timeIntervalSince1970
        let timeElapsed: TimeInterval = timeNow - showStartTime
        if timeElapsed < tapInterval { return }

        switch state {
        case .showing, .fadeOut : hideTree()
        case .hidden            : showTree()
        }
    }
}
