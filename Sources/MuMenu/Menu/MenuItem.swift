//  created by musesum on 1/8/23.

import SwiftUI
import MuFlo

nonisolated(unsafe) public var CornerOpVm = [Int: CornerVm]()

public enum MenuType: String, Codable, Sendable {
    case root, node, leaf, touch }

public enum MenuItemContent: Codable, Sendable {
    case root(MenuRootItem)
    case node(MenuNodeItem)
    case leaf(MenuLeafItem)
    case touch(MenuTouchItem)
}
public struct MenuItem: Codable, Sendable {

    public let type     : MenuType
    public let time     : TimeInterval
    public let cornerOp : Int
    public let phase    : Int // UITouch.Phase.rawValue
    public let item     : MenuItemContent

    public init(root: MenuRootItem) {

        self.type   = .root
        self.item   = .root(root)
        self.time   = Date().timeIntervalSince1970
        self.cornerOp = root.cornerOp
        self.phase  = root.phase

        // log("MenuItem", [self.phase])
    }

    public init(node: MenuNodeItem,
                _ cornerOp: CornerOp,
                _ phase : Int) {

        self.type   = .node
        self.item   = .node(node)
        self.time   = Date().timeIntervalSince1970
        self.cornerOp = cornerOp.rawValue
        self.phase  = phase

        // log("MenuNodeItem", [self.phase])
    }

    public init(leaf: MenuLeafItem,
                _ corner: CornerOp,
                _ phase : Int) {

        self.type   = .leaf
        self.item   = .leaf(leaf)
        self.time   = Date().timeIntervalSince1970
        self.cornerOp = corner.rawValue
        self.phase  = phase

        // log("MenuNodeItem", [self.phase])
    }

    public init(_ touch: SendTouch,
                _ corner: CornerOp) {

        self.type   = .touch
        self.item   = .touch(MenuTouchItem(touch))
        self.time   = Date().timeIntervalSince1970
        self.cornerOp = corner.rawValue
        self.phase  = touch.phase.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case type, time, cornerOp, phase, item }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(time, forKey: .time)
        try container.encode(cornerOp, forKey: .cornerOp)
        try container.encode(phase, forKey: .phase)
        try container.encode(item, forKey: .item)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(MenuType.self, forKey: .type)
        time = try container.decode(TimeInterval.self, forKey: .time)
        cornerOp = try container.decode(Int.self, forKey: .cornerOp)
        phase = try container.decode(Int.self, forKey: .phase)
        item = try container.decode(MenuItemContent.self, forKey: .item)
    }

    var key: Int {
        switch item {
        case .touch(let touchItem):
            return touchItem.finger
        default:
            return type.rawValue.hash
        }
    }
    var isDone: Bool {
        (phase == UITouch.Phase.ended.rawValue ||
         phase == UITouch.Phase.cancelled.rawValue)
    }
    var cornerVm: CornerVm? {
        if let vm = CornerOpVm[cornerOp] ?? CornerOpVm[CornerOp.flipUpperLower(cornerOp)] {
            return vm
        }
        return nil
    }

}
