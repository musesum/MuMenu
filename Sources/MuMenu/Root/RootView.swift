import SwiftUI

/// four posible corners
public struct RootView: View {
    @EnvironmentObject var rootVm: RootVm
    public var body: some View {
        
        switch rootVm.cornerOp {
            case [.lower, .right]: LowerRightView()
            case [.lower, .left ]: LowerLeftView()
            case [.upper, .right]: UpperRightView()
            case [.upper, .left ]: UpperLeftView()
            default:               LowerRightView()
        }
    }
}

/// space with: vert, hori, and pilot views
private struct ForestView: View {
    @EnvironmentObject var rootVm: RootVm
    var body: some View {
        ForEach(rootVm.treeVms, id: \.id) {
            TreeView(treeVm: $0)
        }
        CornerView(cornerVm: rootVm.cornerVm)
    }
}

/// lower right corner of space
private struct LowerRightView: View {
    @EnvironmentObject var rootVm: RootVm
    var body: some View {
        HStack(alignment: .bottom) {
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                ForestView()
            }
        }
    }
}

/// upper right corner of space
private struct UpperRightView: View {
    var body: some View {
        VStack(alignment: .trailing) {
            HStack(alignment: .top) {
                Spacer()
                ZStack(alignment: .topTrailing) {
                    ForestView()
                    Spacer()
                }
            }
            Spacer()
        }
    }
}

/// lower left corner of space
private struct LowerLeftView: View {
    var body: some View {
        HStack(alignment: .bottom) {
            ZStack(alignment: .bottomLeading) {
                ForestView()
            }
            Spacer()
        }
    }
}

/// upper left corner of space
private struct UpperLeftView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                ZStack(alignment: .topLeading) {
                    ForestView()
                }
                Spacer()
            }
            Spacer()
        }
    }
}
