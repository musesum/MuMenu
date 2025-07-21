// created by musesum on 6/13/25
import MuFlo

extension RootVm { // touch

    internal func touchBegin(_ touchState: TouchState, _ fromRemote: Bool) {

        self.touchState = touchState
        beginViewOps = viewOps
        NoDebugLog { P("beginViewOps: \(self.beginViewOps.description)") }
        updateRoot(fromRemote)
        updateSpot(nodeSpotVm, fromRemote)
        touchTypeBegin = touchType
        showTrees(fromRemote)
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

        if !fromRemote, let nodeSpotVm {
            let nodeItem = MenuNodeItem(nodeSpotVm)
            let menuItem = MenuItem(node: nodeItem, touchState.phase)
            sendItemToPeers(menuItem)
        }

    }
    
}
