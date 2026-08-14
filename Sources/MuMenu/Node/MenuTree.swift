// created by musesum on 10/17/21.

import SwiftUI
import MuFlo
#if !os(watchOS)
import MuVision
#endif

open class MenuTree: Identifiable, Equatable {
    public var id = Visitor.nextId()
    public var flo: Flo
    public var icon: Icon!
    public var parentTree: MenuTree?
    public var children = [MenuTree]()
    public var nodeType = NodeType.node
    /// `{}` row riding under a value control, not a chooser sibling
    public internal(set) var isCodeRow = false
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

    public init?(_ flo: Flo,
                parentTree: MenuTree? = nil) {

        guard flo.policy.contains(.menu) else { return nil }
        self.flo = flo
        self.parentTree = parentTree
        self.icon = makeFloIcon(flo)
        parentTree?.children.append(self)
        makeOptionalControl()
    }

    /// this is a leaf node
    init?(_ flo: Flo,
         _ nodeType: NodeType,
         _ icon: Icon,
         parentTree: MenuTree? = nil) {
        guard flo.policy.contains(.menu) else { return nil }
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
        if nodeType == .graph {
            // one leaf, so the chooser row a multi-leaf branch needs would be an
            // empty step: the graph opens from the node it was declared on, the
            // way .tog and .tap do
            self.nodeType = nodeType
        } else if nodeType.isControl {
            // .code included: a multi-leaf branch needs the chooser row, and the
            // leaf opens full-size from its own child branch
            _ = MenuTree(flo, nodeType, icon, parentTree: self)
            makeOptionalCode(nodeType)
        } else {
            self.nodeType = nodeType
        }
    }

    /// `{{ @<file> }}` on the flo hangs a `{}` row under its value control;
    /// the row's own child is the editor, so it opens to the right
    func makeOptionalCode(_ nodeType: NodeType) {
        #if !os(watchOS)
        guard nodeType != .code, flo.embed != nil else { return }
        let curly: IconTypeName = (.symbol, "curlybraces")
        if let codeRow = MenuTree(flo, .node, Icon(curly, curly, .node), parentTree: self) {
            codeRow.isCodeRow = true
            _ = MenuTree(flo, .code, Icon(curly, curly, .code), parentTree: codeRow)
        }
        #endif
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
        var on: IconTypeName?
        var off: IconTypeName?

        if let on = iconTypeName(flo) {
            return Icon(on,off,nodeType)
        } else {
            for child in flo.children {
                switch child.name {
                case "_on" , "on"  : on  = iconTypeName(child);
                case "_off", "off" : off = iconTypeName(child);
                default: continue
                }
            }
            if let on, let off {
                return Icon(on, off, nodeType)
            }
        }
        let none: IconTypeName = (.none,"")
        return Icon(none,none, nodeType)


        func iconTypeName(_ flo: Flo) -> IconTypeName? {
            if let nameAny = flo.exprs?.nameAny {
                for (key,name) in nameAny {
                    if let name = name as? String {
                        switch key {
                        case "sym"    : return (.symbol , name)
                        case "img"    : return (.image  , name)
                        case "svg"    : return (.svg    , name)
                        case "text"   : return (.text   , name)
                        case "cursor" : return (.cursor , name)
                        default       : continue
                        }
                    }
                }
            }
            return nil
        }
    }
}

