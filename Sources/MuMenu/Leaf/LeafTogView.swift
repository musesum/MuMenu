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

    #if os(watchOS)
    var togIndicatorOuter: CGFloat { max(3, Menu.diameter * 0.35) }
    var togIndicatorInner: CGFloat { max(2, togIndicatorOuter * 0.78) }
    var togOffset: CGSize {
        let off = Menu.radius * 0.65
        return CGSize(width: off, height: off)
    }
    #else
    var togIndicatorOuter: CGFloat { 9 }
    var togIndicatorInner: CGFloat { 7 }
    var togOffset: CGSize { CGSize(width:  Menu.radius-6,
                                   height: Menu.radius-6) }
    #endif

    var body: some View {

        GeometryReader { geo in

            ZStack {

                IconView(leafVm, icon, runwayType)
                    .id(leafVm.refresh)

                Capsule()
                    .fill(.black)
                    .frame(width: togIndicatorOuter, height: togIndicatorOuter)
                    .offset(togOffset)
                    .allowsHitTesting(false)

                Capsule()
                    .fill(togColor)
                    .frame(width: togIndicatorInner, height: togIndicatorInner)
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
    #if os(watchOS)
    var tapIndicatorOuter: CGFloat { max(3, Menu.diameter * 0.35) }
    var tapIndicatorInner: CGFloat { max(2, tapIndicatorOuter * 0.78) }
    var tapOffset: CGSize {
        let off = Menu.radius * 0.65
        return CGSize(width: off, height: off)
    }
    #else
    var tapIndicatorOuter: CGFloat { 9 }
    var tapIndicatorInner: CGFloat { 7 }
    var tapOffset: CGSize { CGSize(width:  Menu.radius-6,
                                   height: Menu.radius-6) }
    #endif

    var body: some View {

        GeometryReader { geo in

            ZStack {

                IconView(leafVm, icon, runwayType)
                    .id(leafVm.refresh)

                Capsule()
                    .fill(.black)
                    .frame(width: tapIndicatorOuter, height: tapIndicatorOuter)
                    .offset(tapOffset)
                    .allowsHitTesting(false)

                Capsule()
                    .fill(tapColor)
                    .frame(width: tapIndicatorInner, height: tapIndicatorInner)
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
