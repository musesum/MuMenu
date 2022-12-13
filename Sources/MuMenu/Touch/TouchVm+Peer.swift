//
//  File.swift
//  
//
//  Created by warren on 12/13/22.
//

import Foundation
extension MuTouchVm {

    /// called by UIKit to see if UITouchBegin hits a menu.
    /// If not, it will not call touch
    public func hitTest(_ touchNow: CGPoint) -> (MuCorner, MuNodeVm)? {
        guard let corner = rootVm?.corner else {
            print("⁉️ hitTest rootVm?.corner == nil")
            return nil
        }
        if let rootNodeVm, rootNodeVm.contains(touchNow) {
            return (corner,rootNodeVm) // hits the root (home) node icon
        } else if let rootVm, let nodeVm = rootVm.hitTest(touchNow) {
            return (corner,nodeVm) // hits one of the shown branches
        }
        return nil // does NOT hit menu
    }

    public func gotoHashPath(_ hashPath: [Int]) {
        if let lastHash = hashPath.last,
           rootVm?.nodeSpotVm?.hash == lastHash {
            print("*** gotoHashPath nodeSpotVm?.hash == lastHash")
        }
        else if let firstHash = hashPath.first,
                let rootNodeVm,
                let rootVm,
                let nodeSpotVm = rootVm.nodeSpotVm {

            let rootPath = rootNodeVm.node.hashPath
            let rootHash = rootPath.first ?? -1

                log("hashPath", [hashPath])
                log("rootPath", [rootPath])
                log("nodeSpotVm", [nodeSpotVm.node.hashPath])

        } else {
            print("*** not yet")
        }

    }
}
