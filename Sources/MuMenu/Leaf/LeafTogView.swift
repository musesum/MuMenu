//  created by musesum on 5/10/22.

import SwiftUI

/// Toggle 0/1 (off/on)
struct LeafTogView: View {
    
    @ObservedObject var leafVm: LeafTogVm

    let runwayType = LeafRunwayType.none

    var togColor: Color {
        if let thumb = leafVm.runways.thumb() {
            return Menu.togColor(thumb.value.x > 0)
        } else {
            return Menu.togColor(false)
        }
    }
    var togOffset: CGSize { CGSize(width:  Menu.radius-6,
                                   height: Menu.radius-6)}
    var body: some View {

        GeometryReader { geo in

            ZStack {

                IconView(leafVm, leafVm.menuTree.icon, runwayType)

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

    var tapColor: Color {
        if let thumb = leafVm.runways.thumb() {
            return Menu.tapColor(thumb.value.x > 0)
        } else {
            return Menu.tapColor(false)
        }
    }
    var tapOffset: CGSize { CGSize(width:  Menu.radius-6,
                                   height: Menu.radius-6)}
    var body: some View {

        GeometryReader { geo in

            ZStack {

                IconView(leafVm, leafVm.menuTree.icon, runwayType)

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
