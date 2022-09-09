// Created by warren on 5/6/22.

import SwiftUI

open class MuNode: Identifiable, Equatable {
    public let id = MuIdentity.getId()

    public var title: String
    public var icon: MuIcon
    public var children = [MuNode]()
    public var proto: MuNodeProtocol?
    public var proxies = [MuLeafProxy]()
    public var nodeType = MuNodeType.node

    public static func == (lhs: MuNode, rhs: MuNode) -> Bool {
        return lhs.id == rhs.id
    }

    public init(name: String,
                icon: MuIcon,
                parent: MuNode? = nil) {

        self.title = name
        self.icon = icon
        parent?.children.append(self)
    }

    /// overrides this to add controls to the Menu
    open func getNodeType() -> MuNodeType {
        return nodeType
    }


}
