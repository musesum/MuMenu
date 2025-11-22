//  created by musesum on 5/10/22.

import SwiftUI

/// Toggle 0/1 (off/on)
struct LeafTogView: View {
    
    @ObservedObject var leafVm: LeafTogVm

    let runwayType = LeafRunwayType.none
    var icon: Icon { leafVm.menuTree.icon }
    var isOn: Bool {
        if let thumb = leafVm.runways.thumb() {
            return thumb.value.x > 0
        } else {
            return false
        }
    }
    var togColor: Color {
       Menu.togColor(isOn)
    }

    var togOffset: CGSize { CGSize(width:  Menu.radius-6,
                                   height: Menu.radius-6)}
    var body: some View {

        GeometryReader { geo in

            ZStack {

                IconView(leafVm, icon, runwayType)
                    .id(leafVm.refresh)

                Capsule()
                    .fill(.black)
                    .frame(width: 9, height: 9)
                    .offset(togOffset)
                    .allowsHitTesting(false)

                Capsule()
                    .fill(togColor)
                    .frame(width: 7, height: 7)
                    .offset(togOffset)
                    .allowsHitTesting(false)
            }
            .onAppear {
                let now = geo.frame(in: .global)
                leafVm.runways.updateBounds(runwayType, now) }
            .onChange(of: geo.frame(in: .global)) {
                leafVm.runways.updateBounds(runwayType, $1) }
        }
    }
}

/// Tap 0/1 (off/on)
struct LeafTapView: View {

    @ObservedObject var leafVm: LeafTapVm

    let runwayType = LeafRunwayType.none
    var icon: Icon { leafVm.menuTree.icon }
    var isOn: Bool {
        if let thumb = leafVm.runways.thumb() {
            return thumb.value.x > 0
        } else {
            return false
        }
    }
    var tapColor: Color {
        return Menu.tapColor(isOn)
    }
    var tapOffset: CGSize { CGSize(width:  Menu.radius-6,
                                   height: Menu.radius-6)}
    var body: some View {

        GeometryReader { geo in

            ZStack {

                IconView(leafVm, icon, runwayType)
                    .id(leafVm.refresh)

                Capsule()
                    .fill(.black)
                    .frame(width: 9, height: 9)
                    .offset(tapOffset)
                    .allowsHitTesting(false)

                Capsule()
                    .fill(tapColor)
                    .frame(width: 7, height: 7)
                    .offset(tapOffset)
                    .allowsHitTesting(false)
            }
            .onAppear {
                let now = geo.frame(in: .global)
                leafVm.runways.updateBounds(runwayType, now) }
            .onChange(of: geo.frame(in: .global)) {
                leafVm.runways.updateBounds(runwayType, $1) }
        }
    }
}
