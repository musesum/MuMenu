// Created by warren on 10/17/21.

import SwiftUI
import MuFlo

open class MuFloNode: MuNode {

    public var modelFlo: Flo
    public var viewFlo: Flo?
    var axis: Axis = .vertical

    public init(_ modelFlo: Flo,
                parent: MuNode? = nil) {

        self.modelFlo = modelFlo
        
        super.init(name: modelFlo.name,
                   parent: parent)
        icon = makeFloIcon(modelFlo)

        menuSync = self
        makeOptionalControl()
    }

    /// this is a leaf node
    init(_ modelFlo: Flo,
         _ nodeType: MuNodeType,
         _ icon: MuIcon,
         parent: MuFloNode? = nil) {

        self.modelFlo = modelFlo

        super.init(name: modelFlo.name, icon: icon, parent: parent)
        self.nodeType = nodeType

        modelFlo.addClosure(syncMenuModel) // update node value closure
        
        menuSync = self // setup delegate for MuValue protocol
    }

    override public func touch() {
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
        
        if let name = modelFlo.getName(in: MuNodeLeaves) {
            return  MuNodeType(rawValue: name) ?? .node
        } else if modelFlo.contains(names: ["x","y"]) {
            return MuNodeType.vxy
        }
        return .node
    }

    public func makeFloIcon(_ flo: Flo) -> MuIcon {
        let components = flo.components(named: ["sym", "img", "svg", "text","off", "cursor"])
        for (key,name) in components {
            if let name = name as? String {
                switch key {
                    case "sym"   : return MuIcon(.symbol, name, nodeType)
                    case "img"   : return MuIcon(.image , name, nodeType)
                    case "svg"   : return MuIcon(.svg   , name, nodeType)
                    case "text"  : return MuIcon(.text  , name, nodeType)
                    case "cursor": return MuIcon(.cursor, name, nodeType)
                    default: continue
                }
            }
        }
        return MuIcon(.none, "??")
    }
}


