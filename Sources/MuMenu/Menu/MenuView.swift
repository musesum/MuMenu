//  Created by warren on 12/1/22.

import SwiftUI
import MuFlo
#if os(xrOS)
import _CompositorServices_SwiftUI
#endif
public protocol MenuDelegate {
    func window(bounds: CGRect, insets: EdgeInsets)
}

public struct MenuView: View {
    #if os(xrOS)
    @State private var enlarge = false //...
    @State private var showImmersiveSpace = false //...
    @State private var immersiveSpaceIsShown = false //...

    @Environment(\.openImmersiveSpace) var openImmersiveSpace //...
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace //...
    #endif

    var menuVms: [MenuVm]
    var touchVms: [MuTouchVm] { menuVms.map { $0.rootVm.touchVm } }
    var touchView: TouchView
    var delegate: MenuDelegate

    public init(_ root: Flo,
                _ touchView: TouchView,
                _ delegate: MenuDelegate) {

        self.menuVms = MenuVms(root).menuVms
        self.touchView = touchView
        self.delegate = delegate
    }
    public init(_ touchView: TouchView,
                _ menuVms: [MenuVm],
                _ delegate: MenuDelegate) {
        self.menuVms = menuVms
        self.touchView = touchView
        self.delegate = delegate
    }

    public var body: some View {

        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {

                TouchViewRepresentable(touchVms, touchView)
                ForEach(menuVms, id: \.self) { menuVm in
                    MenuTouchView(menuVm: menuVm)
                }
            }
            .onAppear { delegate.window(bounds: geo.frame(in: .global), insets: geo.safeAreaInsets) }
            #if os(xrOS)
            .onChange(of: geo.frame(in: .global)) { old, now in delegate.window(bounds: now, insets: geo.safeAreaInsets) }
            #else
            .onChange(of: geo.frame(in: .global)) { delegate.window(bounds: $0, insets: geo.safeAreaInsets) }
            #endif
            .statusBar(hidden: true)

        }
        #if os(xrOS)
        ImmersiveSpace(id: "ImmersiveSpace") {
            CompositorLayer(configuration: ContentStageConfiguration()) { layerRenderer in
                let renderer = Renderer(layerRenderer)
                renderer.startRenderLoop()
            }
        }.immersionStyle(selection: .constant(.full), in: .full)
        #endif
    }
}
#if os(xrOS)
struct ContentStageConfiguration: CompositorLayerConfiguration {
    func makeConfiguration(capabilities: LayerRenderer.Capabilities, configuration: inout LayerRenderer.Configuration) {
        configuration.depthFormat = .depth32Float
        configuration.colorFormat = .bgra8Unorm_srgb

        let foveationEnabled = capabilities.supportsFoveation
        configuration.isFoveationEnabled = foveationEnabled

        let options: LayerRenderer.Capabilities.SupportedLayoutsOptions = foveationEnabled ? [.foveationEnabled] : []
        let supportedLayouts = capabilities.supportedLayouts(options: options)

        configuration.layout = supportedLayouts.contains(.layered) ? .layered : .dedicated
    }
}
#endif
