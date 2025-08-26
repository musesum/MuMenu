// created by musesum on 6/13/25
import MuFlo


/// This is a set of touches reported by SwiftUI.
/// VisionOS uses handpose and eyegaze in immersive Mode, which may conflict state.
extension RootVm { // touch

    internal func touchBegin(_ touchState: TouchState,
                             _ fromRemote: Bool) {

        self.touchState = touchState
        beginViewOps = viewOps

        updateRoot(fromRemote)
        updateSpot(nodeSpotVm, fromRemote)
        touchTypeBegin = touchType
        showTrees(fromRemote)
        DebugLog { P("🔰 touchBegin \(self.cornerType.icon) \(self.touchType.symbol) \(self.touchType.description)") }
    }
    internal func touchMoved(_ touchState: TouchState, _ fromRemote: Bool) {

        self.touchState = touchState
        showTrees(fromRemote)
        updateRoot(fromRemote)
    }
    internal func touchEnded(_ touchState: TouchState, _ fromRemote: Bool) {

        self.touchState = touchState
        startAutoFades()
        updateRoot(fromRemote)

        /// turn off spotlight for leaf after edit
        /// keep on for .tog, .tap so that double tapping on root will repeat
        if let nodeSpotVm {
            if nodeSpotVm.nodeType.isControl {
                nodeSpotVm.spotlight = false
            }
        }
        treeSpotVm?.branchSpotVm = nil
        touchType = .none
        DebugLog { P("🛑 touchEnded \(self.cornerType.icon) \(self.touchType.symbol) \(self.touchType.description)") }

        if !fromRemote, let nodeSpotVm {
            let nodeItem = MenuNodeItem(nodeSpotVm)
            let menuItem = MenuItem(node: nodeItem, touchState.phase)
            shareItem(menuItem)
        }

    }
    
}
