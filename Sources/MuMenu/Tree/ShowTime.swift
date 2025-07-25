// created by musesum on 7/16/25

import SwiftUI

public class ShowTime: ObservableObject, Codable, @unchecked Sendable {

    @Published public private(set) var state: State

    public enum State: String, Codable {
        case hidden, fadeOut, showing
    }

    public init(_ state: State = .showing) {
        self.state = state
    }

    public var opacity: CGFloat {
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

    public var animation: Animation {
        switch state {
        case .hidden  : return Animate(animInterval)
        case .showing : return Animate(animInterval)
        case .fadeOut : return Animate(fadeOutInterval)
        }
    }

    private var autoFadeTimer: Timer?
    private var fadeOutTimer: Timer?
    private var fadeInTimer: Timer?
    private var showStartTime: TimeInterval = 0.0

    private func clearTimers() {
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
                self.hideNow()
            }
    }
    public func hideNow() {
        clearTimers()
        state = .hidden
    }

    public func showNow() {
        clearTimers()
        if state == .hidden {
            showStartTime = Date().timeIntervalSince1970
        }
        state = .showing
        startAutoFade()
    }

    func setState(_ state: State) {

        switch state {
        case .showing : showNow()
        case .hidden  : hideNow()
        default       : break
        }
    }

    func toggleTree() {
        let timeNow = Date().timeIntervalSince1970
        let timeElapsed: TimeInterval = timeNow - showStartTime
        if timeElapsed < tapInterval { return }

        switch state {
        case .showing, .fadeOut : hideNow()
        case .hidden            : showNow()
        }
    }

    enum CodingKeys: String, CodingKey {
        case state
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.state = try container.decode(State.self, forKey: .state)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
    }
}

