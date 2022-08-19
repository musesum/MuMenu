//
//  File.swift
//  MuseSky2
//
//  Created by warren on 8/18/22.
//  Copyright © 2022 Muse. All rights reserved.
//

import SwiftUI

struct MuLeafThumbTapView: View {

    @ObservedObject var leafVm: MuLeafVm
    var panelVm: MuPanelVm { leafVm.panelVm }
    var value: CGFloat
    var color: Color { Layout.thumbColor(value) }
    var blend: BlendMode { value == 1 ? .exclusion : .colorDodge }

    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(width:  panelVm.thumbDiameter,
                       height: panelVm.thumbDiameter)
                .offset(leafVm.thumbOffset())
                .allowsHitTesting(false)

            MuIconView(nodeVm: leafVm, icon: leafVm.node.icon)
                .frame(width:  panelVm.thumbDiameter,
                       height: panelVm.thumbDiameter)
                .offset(leafVm.thumbOffset())
                .blendMode(blend)
        }
    }
}

