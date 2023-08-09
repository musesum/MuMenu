// Created by warren on 10/17/21.

import SwiftUI
import MuFlo
import MuVisit

open class MuFloNode: Identifiable, Equatable {
    public let id = Visitor.nextId()

    public var title: String
    public var icon: MuIcon!
    public var parent: MuFloNode?
    public var children = [MuFloNode]()
    public var leafProtos = [MuLeafProtocol]()
    public var nodeType = MuNodeType.node

    public var modelFlo: Flo
    public var viewFlo: Flo?
    var axis: Axis = .vertical
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
            if nodeType.isControl {
                return Int(title.strHash()) + 1
            } else {
                return Int(title.strHash())
            }
        } else {
            print("⁉️ MuFloNode path==nil")
            return -1
        }
    }()

    public lazy var hashPath: [Int] = {
        var _hashPath = parent?.hashPath ?? []
        _hashPath.append(hash)
        return _hashPath
    }()

    public static func == (lhs: MuFloNode, rhs: MuFloNode) -> Bool {
        return lhs.hash == rhs.hash
    }

    public init(_ modelFlo: Flo,
                parent: MuFloNode? = nil) {

        self.modelFlo = modelFlo
        self.title =  modelFlo.name
        self.parent = parent
        parent?.children.append(self)

        icon = makeFloIcon(modelFlo)

        makeOptionalControl()
    }

    /// this is a leaf node
    init(_ modelFlo: Flo,
         _ nodeType: MuNodeType,
         _ icon: MuIcon,
         parent: MuFloNode? = nil) {
        
        self.modelFlo = modelFlo
        self.title = modelFlo.name
        self.icon = icon
        self.parent = parent
        self.nodeType = nodeType
        parent?.children.append(self)
        
        modelFlo.addClosure { flo, visit in
            for leaf in self.leafProtos {
                DispatchQueue.main.async {
                    leaf.updateFromModel(flo, visit)
                }
            }
        }
    }

    public func touch() {
        viewFlo?.updateTime()
    }
    /// optional leaf node for changing values
    func makeOptionalControl() { 
        if children.count > 0 { return }
        let nodeType = getNodeType()
        if nodeType.isControl {
            _ = MuFloNode(modelFlo, nodeType, icon, parent: self)
        } else {
            self.nodeType = nodeType
        }
    }

    /// expression parameters: val vxy tog seg tap x,y indicates a leaf node
    public func getNodeType() -> MuNodeType {

        guard let comp = modelFlo.exprs?.flo.components() else { return .node}
        switch comp.keys.intersection(["x","y","z"]).count {
        case 3: return .vxy // later vxyz
        case 2: return .vxy
        case 1:
            for key in ["x","y","z"] {
                if let type = scalarType(comp[key]) {
                    return type
                }
            }
        default:
            for value in comp.values {
                if let type = scalarType(value) {
                    return type
                }
            }
        }
        return .node

        func scalarType(_ value: Any?) -> MuNodeType? {
            if let scalar = value as? FloValScalar {
                if scalar.valOps.modu {
                    if scalar.max == 2 {
                        return .tog
                    } else {
                        return .tap
                    }
                } else if scalar.valOps.thri {
                    // integers are segmented
                    return .seg
                } else {
                    // otherwise continuous
                    return .val
                }
            }
            return nil
        }
    }

    public func makeFloIcon(_ flo: Flo) -> MuIcon {
        let components = flo.components(named: ["sym", "img", "svg", "text","off", "cursor"])
        for (key,name) in components {
            if let name = name as? String {
                switch key {
                    case "sym"    : return MuIcon(.symbol, name, nodeType)
                    case "img"    : return MuIcon(.image , name, nodeType)
                    case "svg"    : return MuIcon(.svg   , name, nodeType)
                    case "text"   : return MuIcon(.text  , name, nodeType)
                    case "cursor" : return MuIcon(.cursor, name, nodeType)
                    default       : continue
                }
            }
        }
        return MuIcon(.none, "??")
    }
}


