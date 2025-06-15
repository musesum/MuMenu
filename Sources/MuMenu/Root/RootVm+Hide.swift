// created by musesum on 6/13/25

import Foundation

extension RootVm {
    
    public func startAutoHide(_ fromRemote: Bool = false) {
        #if os(visionOS)
        #else
        if autoHideMenu {
            autoHideTimer = Timer.scheduledTimer(withTimeInterval: autoHideInterval, repeats: false) { timer in
                self.hideBranches(.none, fromRemote)
            }
        }
        #endif
    }
    public func endAutoHide(_ fromRemote: Bool) {
        autoHideTimer?.invalidate()
        reshowTree(fromRemote)
    }
}
