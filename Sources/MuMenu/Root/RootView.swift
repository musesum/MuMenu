import SwiftUI

public struct MainContentKey: EnvironmentKey {
    public static let defaultValue: AnyView = AnyView(EmptyView())
}

extension EnvironmentValues {
    public var mainContent: AnyView {
        get { self[MainContentKey.self] }
        set { self[MainContentKey.self] = newValue }
    }
}

/// four posible corners
public struct RootView: View {
    @EnvironmentObject var rootVm: RootVm
    public var body: some View {
        switch rootVm.cornerType.corner {
        case .SE : SoutEastView()
        case .SW : SouthWestView()
        case .NE : NorthEastView()
        case .NW : NorthWestView()
        default  : SouthWestView()
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
private struct SoutEastView: View {
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
private struct NorthEastView: View {
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
private struct SouthWestView: View {
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
private struct NorthWestView: View {
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
