// created by musesum on 10/17/21.

import SwiftUI
import MuFlo
import MuVision

open class MenuTree: Identifiable, Equatable {
    public let id = Visitor.nextId()

    public var title: String
    public var icon: Icon!
    public var parent: MenuTree?
    public var children = [MenuTree]()
    public var nodeType = NodeType.node
    public var model˚: Flo
    public var menu˚: Flo?
    public var chiralSpot: [Chiral: Flo] = [:]

    var axis: Axis = .vertical
    /// path and hash get updated through MuNodeDispatch::bindDispatch
    public lazy var path: String = {
        if let parent {
           let parentPath = parent.path
            return parentPath + "." + title
        } else {
            return title
        }
    }()

    public lazy var hash: Int = {
        if nodeType.isControl {
            return Int(path.strHash()) + 1
        } else {
            return Int(path.strHash())
        }
    }()

    public lazy var hashPath: [Int] = {
        var _hashPath = parent?.hashPath ?? []
        _hashPath.append(hash)
        return _hashPath
    }()

    public static func == (lhs: MenuTree, rhs: MenuTree) -> Bool {
        return lhs.hash == rhs.hash
    }

    public init(_ model˚: Flo,
                parent: MenuTree? = nil) {

        self.model˚ = model˚
        self.title =  model˚.name
        self.parent = parent
        parent?.children.append(self)
        icon = makeFloIcon(model˚)
        makeOptionalControl()
    }

    /// this is a leaf node
    init(_ model˚: Flo,
         _ nodeType: NodeType,
         _ icon: Icon,
         parent: MenuTree? = nil) {
        
        self.model˚ = model˚
        self.title = model˚.name
        self.icon = icon
        self.parent = parent
        self.nodeType = nodeType
        parent?.children.append(self)
    }

    public func touch() {
        menu˚?.updateTime()
    }

    /// optional leaf node for changing values
    func makeOptionalControl() { 
        if children.count > 0 { return }
        let nodeType = getNodeType()
        if nodeType.isControl {
            _ = MenuTree(model˚, nodeType, icon, parent: self)
        } else {
            self.nodeType = nodeType
        }
    }

    /// expression parameters: val vxy tog seg tap x,y indicates a leaf node
    public func getNodeType() -> NodeType {

        if let comp = model˚.exprs?.flo.components() {
            for key in comp.keys {
                if let type = NodeType(rawValue: key) {
                    return type
                }
            }
        }
        return .node
    }

    public func makeFloIcon(_ flo: Flo) -> Icon {
        if let nameAny = flo.exprs?.nameAny {
            for (key,name) in nameAny {
                if let name = name as? String {
                    switch key {
                    case "sym"    : return Icon(.symbol, name, nodeType)
                    case "img"    : return Icon(.image,  name, nodeType)
                    case "svg"    : return Icon(.svg,    name, nodeType)
                    case "text"   : return Icon(.text,   name, nodeType)
                    case "cursor" : return Icon(.cursor, name, nodeType)
                    default       : continue
                    }
                }
            }
        }
        return Icon(.none, "??")
    }
}


