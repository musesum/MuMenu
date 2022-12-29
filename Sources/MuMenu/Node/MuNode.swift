// Created by warren on 5/6/22.

import SwiftUI

open class MuNode: Identifiable, Equatable {
    public let id = MuNodeIdentity.getId()

    public var title: String
    public var icon: MuIcon
    public var parent: MuNode?
    public var children = [MuNode]()
    public var menuSync: MuMenuSync?
    public var leafProtos = [MuLeafProtocol]()
    public var nodeType = MuNodeType.node

    /// path and hash get updated through MuNodeDispatch::bindDispatch
    public lazy var path: String? = {
        if let parent,
           let parentPath = parent.path {
            return parentPath + "." + title
        } else {
            return title
        }
    }()

    public lazy var hash: Int = {
        if let path {
            if nodeType.isLeaf {
                return Int(title.strHash()) + 1
            } else {
                return Int(title.strHash())
            }
        } else {
            print("⁉️ MuNode path==nil")
            return -1
        }
    }()

    public lazy var hashPath: [Int] = {
        var _hashPath = parent?.hashPath ?? []
        _hashPath.append(hash)
        return _hashPath
    }()

    public static func == (lhs: MuNode, rhs: MuNode) -> Bool {
        return lhs.hash == rhs.hash
    }

    public init(name: String,
                icon: MuIcon,
                parent: MuNode? = nil) {

        self.title = name
        self.icon = icon
        self.parent = parent
        parent?.children.append(self)
    }

    open func touch() {
        // when view is touched, may save 
    }

}
