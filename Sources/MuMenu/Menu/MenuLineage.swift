// created by musesum on 8/6/26

import Combine

/// the navigated menu path, offered to readers outside the menu.
/// The menu only writes here; nothing in the menu reads it back
@MainActor
final class MenuLineage {

    static let shared = MenuLineage()

    /// root first, deepest branch reached last; empty once the menu closes
    let lineage = PassthroughSubject<[MenuTree], Never>()

    private var lastIds = [Int]()   /// path already sent, so a hover repeat is free

    private init() {}

    /// the new spot node and its menu ancestors
    func post(_ nodeVm: NodeVm?) {
        var trees = [MenuTree]()
        var walk = nodeVm?.menuTree
        while let tree = walk {
            trees.insert(tree, at: 0)
            walk = tree.parentTree
        }
        let ids = trees.map { $0.id }
        if ids == lastIds { return }
        lastIds = ids
        lineage.send(trees)
    }
}
