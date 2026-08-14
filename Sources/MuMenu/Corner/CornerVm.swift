// created by musesum on 10/31/21.

import SwiftUI
import MuFlo

/// corner node which follows touch
@MainActor
@Observable public class CornerVm {

    var ringIconXY = CGPoint.zero /// current position
    public internal(set) var parkIconXY = CGPoint.zero /// fixed position of icon

    private var startupCenter: CGPoint? /// loading pin, global coords
    private var frameGlobal = CGRect.zero /// last known global frame
    internal private(set) var positioned = false /// true once frame has a size

    var centering: Bool { startupCenter != nil }

    public internal(set) var rootVm: RootVm?
    var logoNodeVm: NodeVm?  /// fixed root node in corner in which to drag from
    var ringNodeVm: NodeVm?  /// drag from root with duplicate node icon
    var touchState = TouchState() /// begin,moved,end state plus t count

    var rootNodeΔ = CGSize.zero /// offset between rootNode and touchNow
    private var spotNodeΔ = CGSize.zero /// offset between touch point and center in coord

    func dragNodeΔ() -> CGSize { /// kludge to compsate for small right offset
        if centering || ringIconXY == parkIconXY { return .zero }
        let deltaEast = rootVm?.cornerType.east ?? false ? -Menu.padding2 : 0
        let offset = Menu.offset(menuType.corner)
        return CGSize(width: deltaEast - offset.width, height: -offset.height)
    }

    public let menuType: MenuType
    let logoName: String

    init(_ menuType: MenuType,
         _ logoName: String) {
        self.menuType = menuType
        self.logoName = logoName
    }

    public func setRoot(_ rootVm: RootVm) {

        // choose an arbirary tree to allow for branc
        guard let treeVm = rootVm.treeVms.first else { return }
        self.rootVm = rootVm

        let branchVm = BranchVm.cached(treeVm: treeVm)
        let cornerFlo = Flo(rootVm.cornerType.key)

        if let cornerLogo = MenuTree(cornerFlo, .none,
                                     Icon(.symbol, logoName)) {
            logoNodeVm = NodeVm(cornerLogo, branchVm, nil)
            branchVm.addRootNodeVm(logoNodeVm)
        }
        if let cornerRing = MenuTree(cornerFlo, .none,
                                     Icon(.cursor, Menu.iconRing)) {

            ringNodeVm = NodeVm(cornerRing, branchVm, nil)
            branchVm.addRootNodeVm(ringNodeVm)
        }
    }
    
    public func updateDragXY(_ touchXY: CGPoint) {
        
        if !touchState.touching  { begin(touchXY, fromRemote: false) }
        else if touchXY == .zero { ended(touchXY, fromRemote: false) }
        else                     { moved(touchXY, fromRemote: false) }
        
        alignCursor(touchXY)
    }
    public func updateLongPressXY(_ touchXY: CGPoint) {

        touchState.longPoint(touchXY)
        alignCursor(touchXY)
    }
    public func updateTouchXY(_ touchXY: CGPoint,
                              _ phase: Int) {

        switch phase {
            case 0:  begin(touchXY, fromRemote: false)
            case 1, 2: moved(touchXY, fromRemote: false)
            default: ended(touchXY, fromRemote: false)
        }
        alignCursor(touchXY)
    }
    func begin(_ touchXY: CGPoint, fromRemote: Bool) {
        touchState.beginPoint(touchXY)
        rootVm?.touchBegin(touchState, fromRemote)
        // log("touch", [touchNow], terminator: " ")
    }
    
    func moved(_ touchXY: CGPoint, fromRemote: Bool)  {
        
        touchState.movedPoint(touchXY)
        
        if let rootVm {
            
            if touchState.isFast, //may child branch to skip
               rootVm.nodeSpotVm?.nextBranchVm?.nodeSpotVm != nil {
                log("🏁", terminator: " ")
            } else {
                rootVm.touchMoved(touchState, fromRemote)
            }
        }
    }
    
    func ended(_ touchXY: CGPoint, fromRemote: Bool) {
        touchState.ended()
        rootVm?.touchEnded(touchState, fromRemote)
        ringIconXY = parkIconXY
        spotNodeΔ = .zero // no spotNode to align with
        rootNodeΔ = .zero // go back to rootNode
    }
    /// loading: pin the ring to a global point; nil releases it home (animated by CornerView)
    public func setStartupCenter(_ globalXY: CGPoint?) {
        startupCenter = globalXY
        guard !touchState.touching else { return }
        if let globalXY, positioned {
            ringIconXY = localXY(globalXY)
        } else if globalXY == nil, positioned {
            ringIconXY = parkIconXY
        }
    }
    /// global point to CornerView local coord
    private func localXY(_ globalXY: CGPoint) -> CGPoint {
        CGPoint(x: globalXY.x - frameGlobal.minX,
                y: globalXY.y - frameGlobal.minY)
    }
    /// updated on startup or change in screen orientation
    func updateRootIcon(_ from: CGRect) {
        frameGlobal = from
        positioned = from.size != .zero
        parkRootIcon()
    }

    /// clamp the corner to the container: a panel wider than the screen swells
    /// this view's box past the edge, which would carry the parked icon along
    private func parkRootIcon() {
        guard let rootVm, positioned else { return } // never park from a zero frame
        let clamped = frameGlobal.intersection(bounds)
        let box = clamped.isEmpty ? frameGlobal : clamped
        parkIconXY = localXY(rootVm.cornerXY(in: box) + box.origin)

        guard !touchState.touching else { return } // alignCursor owns the ring
        if let startupCenter {
            ringIconXY = localXY(startupCenter) // the loading pin outranks a re-park
        } else {
            ringIconXY = parkIconXY
        }
    }

    /// either center dragNode icon on spotNode or track finger
    func alignCursor(_ touchXY: CGPoint) {
        
        #if os(visionOS)
        let origin = CGPoint.zero
        #else
        let origin = bounds.origin
        #endif

        guard let rootVm else {
            return ringIconXY = touchXY - origin
        }
        if !touchState.touching ||
            rootVm.touchType.isIn([.root, .canopy]) ||
            rootVm.nodeSpotVm?.nodeType.isControl ?? false {

            ringIconXY = parkIconXY  // park the dragIcon

        } else if let spotCenter = rootVm.nodeSpotVm?.center {

            ringIconXY = spotCenter - origin

        } else {

            ringIconXY = touchXY - origin
        }
    }
    var bounds = CGRect.zero
    func updateBounds(_ bounds: CGRect) {
        DebugLog { P("\(self.rootVm?.cornerType.icon ?? "??") CornerVm changed geometry ") }
        self.bounds = bounds
        guard !centering else { return } // loading pin owns the ring; updateRootIcon re-parks
        parkRootIcon() // the container corner moved
        //log("RootVm",[bounds])
    }

    func touchingRoot(_ touchNow: CGPoint) -> Bool {
        if let logoNodeVm,
           logoNodeVm.contains(touchNow) {
            return true
        }
        return false
    }
}
