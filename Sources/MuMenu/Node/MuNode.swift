// Created by warren on 5/6/22.

import SwiftUI

open class MuNode: Identifiable, Equatable {
    public let id = MuNodeIdentity.getId()

    public var title: String
    public var icon: MuIcon
    public var children = [MuNode]()
    public var nodeProto: MuNodeProtocol?
    public var proxies = [MuLeafProtocol]()
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

    open func touch() {
        // when view is touched, may save 
    }

}
