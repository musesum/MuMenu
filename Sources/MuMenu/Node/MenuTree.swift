// created by musesum on 10/17/21.

import SwiftUI
import MuFlo
import MuVision

open class MenuTree: Identifiable, Equatable {
    public var id = Visitor.nextId()
    public var flo: Flo
    public var icon: Icon!
    public var parentTree: MenuTree?
    public var children = [MenuTree]()
    public var nodeType = NodeType.node
    public var chiralSpot: [MenuType: Flo] = [:]

    var axis: Axis = .vertical
    /// path and hash get updated through MuNodeDispatch::bindDispatch
    public lazy var path: String = {
        if let parentTree {
           let parentPath = parentTree.path
            return parentPath + "." + flo.name
        } else {
            return flo.name
        }
    }()

    public lazy var hash: Int = {
        if nodeType.isControl {
            return Int(path.strHash()) + 1
        } else {
            return Int(path.strHash())
        }
    }()

    public lazy var wordPath: [String] = {
        var _wordPath = parentTree?.wordPath ?? []
        _wordPath.append(flo.name)
        return _wordPath
    }()

    public static func == (lhs: MenuTree, rhs: MenuTree) -> Bool {
        return lhs.hash == rhs.hash
    }

    public init(_ flo: Flo,
                parentTree: MenuTree? = nil) {

        self.flo = flo
        self.parentTree = parentTree
        self.icon = makeFloIcon(flo)
        parentTree?.children.append(self)
        makeOptionalControl()
    }

    /// this is a leaf node
    init(_ flo: Flo,
         _ nodeType: NodeType,
         _ icon: Icon,
         parentTree: MenuTree? = nil) {

        self.flo = flo
        self.icon = icon
        self.parentTree = parentTree
        self.nodeType = nodeType
        parentTree?.children.append(self)
    }

    /// optional leaf node for changing values
    func makeOptionalControl() {

        if children.count > 0 { return }
        let nodeType = getNodeType()
        if nodeType.isControl {

            _ = MenuTree(flo, nodeType, icon, parentTree: self)
        } else {
            self.nodeType = nodeType
        }
    }

    /// expression parameters: val vxy tog seg tap x,y indicates a leaf node
    public func getNodeType() -> NodeType {

        if let comp = flo.exprs?.flo.components() {
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

