#if !os(watchOS)
//  created by musesum on 8/5/26

import SwiftUI

/// corner drag affordance which resizes a bound size, clamped to min…max
public struct GrabHandle: View {

    @Binding private var size: CGSize
    @Binding private var origin: CGSize
    private let sizeMin: CGSize
    private let sizeMax: CGSize
    private let corner: MenuCorner
    private let anchor: MenuCorner

    @State private var sizeBegin: CGSize?
    @State private var originBegin = CGSize.zero

    static let arcRadius = CGFloat(22)
    /// the arc used to sit 5pt inside the panel, sharing the corner with
    /// whatever control reached it; it now rides the border from outside.
    /// The outer panel's own ring is the whole budget: past it the arc is
    /// clipped and the affordance loses its far end
    static let outward = Menu.padding
    private static let band = CGFloat(16)   /// hit zone width, measured across the arc
    private static let dim = arcRadius
    /// the arc draws nothing at rest: the affordance is the band the finger
    /// gets, not a ring over the panel edge. A touch-down lifts it by one step,
    /// which is the only time the handle is drawn at all
    private static let dimRest = 0.0
    private static let dimHeld = 0.25

    public init(size    : Binding<CGSize>,
                sizeMin : CGSize,
                sizeMax : CGSize,
                corner  : MenuCorner = .SE,
                origin  : Binding<CGSize> = .constant(.zero),
                anchor  : MenuCorner = .none) {

        self._size = size
        self._origin = origin
        self.sizeMin = sizeMin
        self.sizeMax = sizeMax
        self.corner = corner
        self.anchor = anchor
    }

    private static func east (_ corner: MenuCorner) -> Bool { corner == .NE || corner == .SE }
    private static func north(_ corner: MenuCorner) -> Bool { corner == .NW || corner == .NE }

    /// which way a positive translation grows the bound size
    private var sign: CGSize {
        switch corner {
        case .NW   : return CGSize(width: -1, height: -1)
        case .NE   : return CGSize(width:  1, height: -1)
        case .SW   : return CGSize(width: -1, height:  1)
        default    : return CGSize(width:  1, height:  1)
        }
    }

    /// an axis whose handle side is the pinned side grows away from the finger,
    /// so the origin carries that growth back; the free axis needs none
    private var originSign: CGSize {
        guard anchor != .none else { return .zero }
        let east = Self.east(corner)
        let north = Self.north(corner)
        return CGSize(width:  east  == Self.east(anchor)  ? (east  ?  1 : -1) : 0,
                      height: north == Self.north(anchor) ? (north ? -1 :  1) : 0)
    }

    private func clamped(_ from: CGSize) -> CGSize {
        CGSize(width:  min(max(from.width,  sizeMin.width ), sizeMax.width ),
               height: min(max(from.height, sizeMin.height), sizeMax.height))
    }

    private func dragged(_ shift: CGSize) {
        let begin = sizeBegin ?? size
        if sizeBegin == nil {
            sizeBegin = begin
            originBegin = origin
        }
        let next = clamped(CGSize(width:  begin.width  + shift.width  * sign.width,
                                  height: begin.height + shift.height * sign.height))
        size = next
        // the clamped delta, not the finger delta: a size sitting on its limit
        // parks the origin too, so reversing re-engages the corner without a jump
        let sway = originSign
        origin = CGSize(width:  originBegin.width  + (next.width  - begin.width ) * sway.width,
                        height: originBegin.height + (next.height - begin.height) * sway.height)
    }

    /// the arc hugs `corner`, swept about the frame's opposite corner
    private var arc: GrabArc {
        switch corner {
        case .NW : return GrabArc(pivot: .bottomTrailing, begin: 180)
        case .NE : return GrabArc(pivot: .bottomLeading,  begin: 270)
        case .SW : return GrabArc(pivot: .topTrailing,    begin:  90)
        default  : return GrabArc(pivot: .topLeading,     begin:   0)
        }
    }

    public var body: some View {
        arc
            .stroke(Color.white.opacity(sizeBegin != nil ? Self.dimHeld : Self.dimRest),
                    style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
            .frame(width: Self.dim, height: Self.dim)
            // the band, not the corner square: the square reached 27pt inward
            // on both axes, over whatever the panel parked in that corner
            .contentShape(GrabBand(pivot: arc.pivot, begin: arc.begin,
                                   band: Self.band))
            // .global, not the local space: the handle rides the corner it is
            // resizing, so a local translation is measured against a frame the
            // drag itself is moving, and the corner tracks at half the finger
            .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { dragged($0.translation) }
                .onEnded { _ in sizeBegin = nil })
    }
}

/// the arc's own stroke, widened into the hit zone the finger gets
private struct GrabBand: Shape {

    let pivot: UnitPoint
    let begin: Double
    let band: CGFloat

    func path(in rect: CGRect) -> Path {
        GrabArc(pivot: pivot, begin: begin)
            .path(in: rect)
            .strokedPath(StrokeStyle(lineWidth: band, lineCap: .round))
    }
}

/// quarter arc swept about `pivot`, from `begin` degrees in a y-down space
private struct GrabArc: Shape {

    let pivot: UnitPoint
    let begin: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.minX + rect.width  * pivot.x,
                             y: rect.minY + rect.height * pivot.y)
        var path = Path()
        path.addArc(center: center,
                    radius: GrabHandle.arcRadius,
                    startAngle: .degrees(begin),
                    endAngle: .degrees(begin + 90),
                    clockwise: false)
        return path
    }
}

public extension View {

    /// overlay a corner grab handle which resizes `size`
    func grabHandle(size    : Binding<CGSize>,
                    sizeMin : CGSize,
                    sizeMax : CGSize,
                    corner  : MenuCorner = .SE,
                    origin  : Binding<CGSize> = .constant(.zero),
                    anchor  : MenuCorner = .none) -> some View {

        grabHandle(size: size, sizeMin: sizeMin, sizeMax: sizeMax,
                   corners: [corner], origin: origin, anchor: anchor)
    }

    /// overlay a grab handle on each of `corners`, all resizing `size`;
    /// `anchor` names the container corner the panel is pinned to, which is
    /// what makes `origin` shift the dragged corner instead of the far edge
    func grabHandle(size    : Binding<CGSize>,
                    sizeMin : CGSize,
                    sizeMax : CGSize,
                    corners : Set<MenuCorner>,
                    origin  : Binding<CGSize> = .constant(.zero),
                    anchor  : MenuCorner = .none) -> some View {

        overlay {
            ZStack {
                ForEach(Array(corners), id: \.self) { corner in
                    GrabHandle(size: size,
                               sizeMin: sizeMin,
                               sizeMax: sizeMax,
                               corner: corner,
                               origin: origin,
                               anchor: anchor)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: corner.alignment)
                }
            }
            // the negative pad is what carries every arc past the border
            .padding(-GrabHandle.outward)
        }
    }
}

extension MenuCorner {
    /// where the handle parks inside its container
    var alignment: Alignment {
        switch self {
        case .NW   : return .topLeading
        case .NE   : return .topTrailing
        case .SW   : return .bottomLeading
        default    : return .bottomTrailing
        }
    }
}
#endif
