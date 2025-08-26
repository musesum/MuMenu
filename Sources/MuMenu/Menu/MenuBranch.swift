// created by musesum on 8/23/25

import Foundation

public class MenuBranch {
    let type: MenuType
    let names: [String]
    init(_ type: MenuType,_  names: [String]) {
        self.type = type
        self.names = names
    }
}
