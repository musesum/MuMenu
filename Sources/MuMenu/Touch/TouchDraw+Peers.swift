//  Created by warren on 12/19/22.

import Foundation
import MuAudio
import MuPeer

extension TouchDraw: PeersControllerDelegate {

    public func didChange() {
    }

    public func received(data: Data,
                         viaStream: Bool) {

        let decoder = JSONDecoder()
        if let item = try? decoder.decode(TouchCanvasItem.self, from: data) {
            TouchCanvas.remoteItem(item)
            return
        }
        if let item = try? decoder.decode(MenuItem.self, from: data) {
            MenuTouch.remoteItem(item)
            return
        }
        if let item = try? decoder.decode(MidiItem.self, from: data) {
            TouchMidi.remoteItem(item)
            return
        }
    }


}
