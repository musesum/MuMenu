// created by musesum on 6/13/25

extension RootVm { // touch
    internal func touchBegin(_ touchState: TouchState, _ fromRemote: Bool) {

        self.touchState = touchState
        beginViewOps = viewOps
        updateRoot(fromRemote)
        if let nodeSpotVm {
            updateSpot(nodeSpotVm, fromRemote)
        }
        touchTypeBegin = touchType
        endAutoHide(fromRemote)
    }
    internal func touchMoved(_ touchState: TouchState, _ fromRemote: Bool) {

        self.touchState = touchState
        updateRoot(fromRemote)
    }
    internal func touchEnded(_ touchState: TouchState, _ fromRemote: Bool) {

        self.touchState = touchState
        startAutoHide(fromRemote)
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
            let menuItem = MenuItem(node: nodeItem, menuOp, touchState.phase)
            sendItemToPeers(menuItem)
        }

    }
    
}
