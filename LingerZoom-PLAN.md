# LingerZoom — MuMenu LeafXY / LeafXYZ runway fine-adjust plan

Plan only. No code changes made. Implementer: future Opus session. All file:line references verified against sources on 2026-07-07.

Host app for verification: DeepMenu (`/Users/warren/Dev/Deep/Menu/DeepMenu.xcodeproj`), which consumes the local `MuMenu` package at `/Users/warren/Dev/Deep/Mu/MuMenu`.

---

## 1. Goal and UX spec

**Goal.** During a continuous drag on an XY/XYZ runway (strip or pad), a dwell (finger nearly stationary for a fixed interval) switches the touch→value mapping into a fine mode zoomed around a FIXED pivot. The same drag then continues with ~8× finer control. Release exits fine mode. Mirrors the Living Archive Trim linger-zoom (`/Users/warren/Dev/Deep/Living/Sources/ShareTabView.swift` `TrimTimeline`, 2266–2530).

**Reference mechanics (verified).**
- Trigger: wall-clock dwell Task sleeps 2.0 s (`ShareTabView.swift:2512-2521`); rescheduled whenever movement exceeds 2 pt against `lastDwellX` (2512-2513); fires once per drag (guarded by `zoomWin == nil` at 2512 and 2517); handle drags only — background scrub gesture (2420-2435) has no dwell.
- On fire: `zoomPivot` captured from the handle frac, never re-centered (2518, comment at 2288-2290); `withAnimation(.easeInOut(duration: 0.25)) { zoomWin = 0...1 }` (2519).
- Mapping: piecewise `fracFor`/`xFor` pair with `exp = 0.12` (2327, 2330-2349) — side toward the other handle compresses to 0.12 of frac-space (≈8.3× fine), other side 1:1; dragging chevron stays at its screen x; grab areas always rendered so the SAME `DragGesture` continues through the flip (2455-2466).
- Exit: `onEnded` → `zoomWin = nil` animated 0.2 s (2523-2528). No haptics anywhere.
- Vestigial count-based alternative: `/Users/warren/Dev/Deep/Living/Sources/CanvasScene.swift:1883-1893` `trackTrimDrag` — ≥6 near-stationary callbacks (frac epsilon 0.006) set `trimExpanded`; reset in `endTrimDrag` (1895-1897). Dead code; documents the alternative trigger.

**Trigger recommendation: wall-clock Task (Trim style), not callback count.**
Rationale: MuMenu touch callbacks arrive per touch event via `RootVm+State.swift:241` — delivery rate varies with device, hover, and coalescing; a count threshold makes dwell time hardware-dependent. A `Task.sleep` dwell is deterministic, cancels cleanly on movement/release, and matches the proven Trim implementation. Dwell = 2.0 s; movement re-arm threshold = 2 pt in global touch space (same constants as Trim).

**Mapping recommendation: symmetric affine fine map, exp-style ratio `fine = 0.12`.**
Trim's map is piecewise because trim handles sit at span edges and only one side needs magnification. A runway thumb is mid-runway: both directions need fine control equally, so use a single symmetric affine map around the pivot — value moves `fine ×` the normalized finger delta:

```
// captured at fire:
pivotValue : SIMD3<Double>   // thumb(runwayType).value at fire — FIXED
pivotNorm  : SIMD3<Double>   // normalizePoint(pointNow, ...) raw at fire — FIXED

// forward (touch → value), zoomed, per active axis:
value = pivotValue + (rawNorm - pivotNorm) * fine        // clamp 0...1

// inverse (value → screen-norm), zoomed, per active axis:
screenNorm = pivotNorm + (value - pivotValue) / fine     // clamp 0...1 for drawing
```

Properties: thumb stays exactly under the finger at fire (no jump — analogous to Trim's `xFor(pivot) == pivot·w` invariant, comment `ShareTabView.swift:2508-2511`); full runway travel now spans `fine = 0.12` of value space (≈8.3× fine, matching Trim's `exp`); monotone, trivially invertible; pivot never re-centers.
Edge behavior: pivot near 0 or 1 leaves part of the fine window unreachable past the clamp — accepted, Trim tolerates the analogous off-frame handle.

**Per-axis behavior.**
- `.runX` strip: fine map on x only.
- `.runY` strip: fine map on y only.
- `.runZ` strip (XYZ only): fine map on z only.
- `.runXY` pad: fine map on x AND y simultaneously, shared 2-axis pivot (one dwell, one zoom, both axes fine).
- `.runVal` and watch-only paths: out of scope (§7 non-goals).
- Cross-thumb dispatch is unchanged: `setThumbPoint` (`LeafRunways.swift:105-142`) already fans the mapped value out to every runway thumb (`LeafRunways.swift:130-141`), so zooming on the x strip still moves the XY pad thumb — the pad simply moves slowly (true value space), which is correct.

---

## 2. State additions to LeafRunways

File: `/Users/warren/Dev/Deep/Mu/MuMenu/Sources/MuMenu/Leaf/LeafRunways.swift` (`@MainActor` class, not a view, no `@Published` — lines 18-19; refresh flows through `leafVm.refreshView()`, `NodeVm.swift:138-140`).

Add stored state (near `touchState`, line 27):

```swift
/// linger-zoom (fine-adjust) state — mirrors Living TrimTimeline dwell/zoom
private(set) var zoomType: LeafRunwayType? = nil   // nil = not zoomed; set = active fine runway
private var zoomPivotValue: SIMD3<Double> = .zero  // thumb value at fire — FIXED
private var zoomPivotNorm: SIMD3<Double> = .zero   // raw touch norm at fire — FIXED
private var dwellTask: Task<Void, Never>? = nil
private var lastDwellPoint: CGPoint = .zero
private let dwellSeconds: UInt64 = 2_000_000_000
private let dwellMoveThreshold: CGFloat = 2
private let fine: Double = 0.12
var zoomed: Bool { zoomType != nil }
```

**Trigger logic in `touchLeaf` (`LeafRunways.swift:230-259`).**
- `beginRunway()` (243-252): after locking `runwayType`, reset — `dwellTask?.cancel(); dwellTask = nil; zoomType = nil; lastDwellPoint = point` — then schedule the first dwell.
- `nextRunway()` (254-258): before `setThumbPoint`, run dwell bookkeeping (fire-once guard first, Trim `ShareTabView.swift:2512` pattern):

```swift
if zoomType == nil, point.distance(lastDwellPoint) > dwellMoveThreshold {
    lastDwellPoint = point
    dwellTask?.cancel()
    dwellTask = Task { @MainActor [weak self] in
        try? await Task.sleep(nanoseconds: self?.dwellSeconds ?? 0)
        guard let self, !Task.isCancelled, self.zoomType == nil,
              self.touching else { return }
        self.fireZoom(nodeVm)     // captures pivots, sets zoomType, refresh
    }
}
```

- `fireZoom`: capture `zoomPivotValue = thumb(runwayType)!.value`; capture `zoomPivotNorm = normalizePoint(touchState!.pointNow, runwayType, bounds(runwayType)!)` (raw, pre-fine); zero `thumb(runwayType)!.offset` (kills residual offset-decay drift, `LeafThumb.swift:83`); set `zoomType = runwayType`; `withAnimation(.easeInOut(duration: 0.25)) { nodeVm.refreshView() }` (see §4 for what animates).

**Explicit `.ended` cleanup.** `touchLeaf` currently switches only `.began` vs `default` (238-241) — drag end is not observed. Add a done branch:

```swift
switch touchState.phase {
case .began:              beginRunway()
default:
    nextRunway()          // final point still maps through the zoomed space
    if touchState.phase.done { endZoom(nodeVm) }   // .ended or .cancelled
}
```

`endZoom`: `dwellTask?.cancel(); dwellTask = nil; zoomType = nil; withAnimation(.easeInOut(duration: 0.2)) { nodeVm.refreshView() }`. `phase.done` covers `.ended` and `.cancelled` (`TouchState.swift` / `MenuTouchPhase`, watch enum at `TouchState.swift:10`; UIKit `UITouch.Phase` on iOS).
`touchLeaf` needs no signature change — `nodeVm` is already a parameter (230).

---

## 3. Mapping changes — normalizePoint forward, expandItem inverse

**Forward: `normalizePoint` (`LeafRunways.swift:176-196`).** After computing the raw `norm` (existing radius-inset math, 177-193), apply the fine map when `zoomType == runwayType` for the axes active on that type:

```swift
if zoomType == type {
    switch type {
    case .runX : norm.x = (zoomPivotValue.x + (norm.x - zoomPivotNorm.x) * fine)
    case .runY : norm.y = (zoomPivotValue.y + (norm.y - zoomPivotNorm.y) * fine)
    case .runZ : norm.z = (zoomPivotValue.z + (norm.z - zoomPivotNorm.z) * fine)
    case .runXY: norm.x = ... ; norm.y = ...   // both axes
    default: break
    }
}
```

Caller `setThumbPoint` (105-142) already clamps (`.clamped(to: 0...1)`, 111) and quantizes AFTER this (112) — order preserved: raw → fine map → clamp → quantize.

**Inverse: `expandItem` (`LeafRunways.swift:205-227`)**, the single value→pixel map behind both `valueOffset` (197-200, thumb) and `tweenOffset` (201-204, plugin tween capsule). Before the existing pixel math, remap the item through the inverse when `zoomType == type`:

```swift
var item = item
if zoomType == type {
    // inverse of the normalizePoint fine map, per active axis:
    item.x = zoomPivotNorm.x + (item.x - zoomPivotValue.x) / fine   // .runX / .runXY
    // ... y, z analogous; then clamp each remapped axis to 0...1
}
```

One caveat: `expandItem` uses `panelVm.innerPanel(type)` natural dimensions while `normalizePoint` uses stored global bounds with `thumbRadius(type)` insets (177-186 vs 208-211). The screen-norm spaces differ by the radius inset. Exact under-finger fidelity requires the inverse to be expressed in the SAME normalized space the forward map uses — since both fine maps are affine in the same 0…1 value/norm coordinates, applying the inverse to `item` before the existing pixel math is consistent; verify visually that the thumb does not creep at fire (checklist §7 step V3).

Agreement obligations:
- **Thumb**: `LeafThumbSlideView` draws at `runways.valueOffset(type)` (`Thumb/LeafThumbSlideView.swift:33`) — inherits the inverse automatically.
- **Tween**: plugin tween capsule draws at `tweenOffset` (`LeafThumbSlideView.swift:28`) — inherits automatically; during zoom the tween chases `value` in true value space and renders magnified, correct.
- **Ticks**: `LeafXyVm.ticks()` (`Leaf/LeafXyVm.swift:11-25`; identical duplicate in `LeafXyzVm.swift:11-25`) computes static quarter-grid `CGSize`s from `panelVm.runwayXY` (`Panel/PanelVm.swift:123`). Zoomed, ticks must ride the same inverse: add a `LeafRunways.tickOffsets(_ type:) -> [CGSize]` (or have `ticks()` route each grid fraction through `expandItem(type, SIMD3(w, 1-h, 0))`) so tick positions magnify around the pivot; ticks mapping outside 0…1 are dropped (not clamped — clamped ticks would pile up on the border). Ticks exist only on `.runXY` (`LeafXyView.swift:40`, `LeafXyzView.swift:41`; watch omits them).
- `thumb(_:contains:)` (166-175) uses raw geometry for the offset-`.begin` decision at touch start only — zoom never active at `.began`, no change needed.

---

## 4. Visual cue and refresh path

Views stay gesture-free (`Leaf/LeafXyView.swift:25-42`, `Leaf/LeafXyzView.swift:26-46` compose `LeafBezelView` + `LeafThumbSlideView`; bounds registration at `Leaf/LeafBezelView.swift:32-36`). Cue is state-driven:

1. **Magnified ticks** (primary cue, `.runXY` only): tick grid spreads ≈8× around the pivot the instant zoom fires — the direct analog of Trim's magnified filmstrip cells (`ShareTabView.swift:2398-2415`).
2. **Bezel stroke spotlight** (all runways): `LeafBezelView` currently strokes `Menu.strokeColor(leafVm.spotlight)` / `Menu.strokeWidth(leafVm.spotlight)` (`LeafBezelView.swift:12-13`; `Global/Menu.swift:73,84`). Change to per-runway: `leafVm.spotlight || leafVm.runways.zoomType == runwayType` for the ACTIVE zoomed runway — the zoomed strip/pad gets the hot stroke; note during a leaf drag `spotlight` is already on for the whole leaf (`RootVm+State.swift:245`), so prefer a distinct treatment for the zoomed runway: `Menu.strokeWidth(true) + 1` or `Menu.tweenColor(true)` (`Menu.swift:100`) stroke to differentiate from plain spotlight.
3. Optionally dim the non-zoomed sibling bezels (Trim pushes the other handle off-frame; the analog is de-emphasis, not removal).

**Refresh path.** `LeafRunways` publishes nothing; all redraw flows through `leafVm.refreshView()` (`Node/NodeVm.swift:138-140` bumps `@Published refresh`), and every touch already ends in `syncVal → refreshView` (`LeafXyVm.swift:64-66`, `LeafXyzVm.swift:82`). Zoom fire/exit calls `refreshView()` directly inside `withAnimation(.easeInOut(duration: 0.25))` / `(0.2)`.
Constraint: `LeafThumbSlideView` pins the icon with `.id(leafVm.refresh)` (`LeafThumbSlideView.swift:34`) — `.id` change resets identity, so the thumb itself does not tween — acceptable: the thumb stays under the finger at fire by construction (zero visual jump). Ticks and bezel stroke are not behind `.id`, so they animate with the `withAnimation` transaction. If tick animation fails to interpolate (positions computed in model code), fall back to a snap — Trim's cells also snap through the piecewise map; the 0.25 s animation there covers stroke/window only.

---

## 5. Precedent constraints (carried from Trim, binding)

| Constraint | Trim source | MuMenu obligation |
|---|---|---|
| Fire once per drag | `zoomWin == nil` guards, `ShareTabView.swift:2512,2517` | `zoomType == nil` guard on scheduling AND on fire |
| Fixed pivot, never re-centered | 2288-2290, 2518 | `zoomPivotValue`/`zoomPivotNorm` written only in `fireZoom` |
| Same touch continues through the flip | always-rendered grab areas, 2455-2466 | free — touch routed globally via `RootVm+State.swift:238-248`, no gesture re-grab exists |
| Thumb stays at its screen position at fire | `xFor(cur) == cur·w`, 2508-2511 | affine map anchored at `pivotNorm` (§1) |
| No haptics | none in TrimTimeline | none added |
| Animate in 0.25 s / out 0.2 s | 2519 / 2527 | `withAnimation` around fire/exit `refreshView()` |
| Dwell 2.0 s, re-arm at >2 pt | 2512-2516 | same constants |
| Exit on release only | 2523-2528 | `endZoom` on `phase.done` only — no timeout exit |

---

## 6. Edge cases

- **Quantized leaves.** `touchLeaf` accepts `quantize:` (`LeafRunways.swift:232`; call site passes nil, commented `quantize: 4` at `LeafVm.swift:48`). Quantize snaps AFTER the fine map (`setThumbPoint` order, 111-112) — zoom remains coherent but useless within one quantum. Guard: skip dwell scheduling when `quantize != nil`.
- **Plugins / tween thumb.** `hasPlugin` leaves draw a tween capsule at `tweenOffset` (`LeafThumbSlideView.swift:24-30`). §3 routes it through the same inverse. Tween updates arrive via `updateFromFlo` with `.tween` visits which `syncVal` ignores for value writes (`LeafXyVm.swift:41-42`) but still refresh — no zoom interaction beyond the inverse map.
- **watchOS thumbRadius scale.** `LeafRunwayType.thumbRadius` is 7/12 on watch vs 20/40 on iOS (`Leaf/LeafRunwayType.swift:24-38`); `LeafRunways.thumbRadius(_:)` (160-165) is a SEPARATE `Menu.radius`-based function used by `normalizePoint` — the fine map sits after the inset math and uses whatever insets the forward map used, so it is scale-neutral. Watch touch enters via `setNormalized` (`LeafVm.swift:108-136`) bypassing `touchLeaf` entirely — zoom never triggers on watch. Confirm no `#if os(watchOS)` guard needed beyond that.
- **Peer-mirrored values during zoom.** `updateLeafPeers` ships `thumb.value` (true value space) via `MenuLeafItem` (`LeafVm.swift:86-94`); remotes see slow fine motion — no protocol change. Inbound `remoteThumb` (`LeafVm.swift:65-75`) writes `thumb.value` directly; if a remote write lands mid-zoom the local thumb jumps within the magnified view and the pivot goes stale. Accept last-writer-wins (matches existing non-zoom behavior); do NOT re-capture the pivot.
- **XYZ z-strip interaction.** Zoom locks to the runway hit at `.began` (`runwayType` lock, 243-252); a z-strip dwell zooms z only. `setThumbPoint` fans z to the z thumb only (134) — XY pad untouched. Exiting the z bounds mid-drag is already handled: `nextRunway` keeps mapping against the LOCKED bounds (254-258); the fine map keys off `zoomType == runwayType`, unaffected.
- **Taps must not zoom.** `tapThreshold = 0.5 s` (`Touch/TouchState.swift:28`); dwell is 2.0 s and the `.ended` branch cancels `dwellTask` — a tap can never fire the zoom. The dwell Task also re-checks `touching` and `zoomType == nil` after sleeping (§2) against stale fires from an already-ended drag.
- **Offset-decay residue.** `LeafThumb.setValue` `.move` decays a touch-begin offset by 0.88/callback (`Leaf/LeafThumb.swift:79-84`). At fire (≥2 s in), the offset is ≈0 but not exactly; `fireZoom` zeroes it (§2) so the fine map is exact from the first zoomed callback.
- **Bounds re-layout mid-zoom.** `LeafBezelView.onChange` re-registers bounds (32-36). A rotation mid-drag would shift `zoomPivotNorm`'s meaning; ignore — drags do not survive rotation.

---

## 7. Implementation checklist, verification, non-goals

### Checklist (ordered)

1. `Leaf/LeafRunways.swift` (~line 27): add zoom state block, constants, `zoomed`/`zoomType` accessors (§2).
2. `Leaf/LeafRunways.swift` `touchLeaf` (~230-259): `.began` reset + schedule; `nextRunway` dwell re-arm; `phase.done` → `endZoom` branch; private `fireZoom(_:)`/`endZoom(_:)` (§2). `Task { @MainActor [weak self] ... }` — class is `@MainActor`.
3. `Leaf/LeafRunways.swift` `normalizePoint` (~176-196): apply forward fine map per §3 (after raw norm, before return; log line 194 unchanged).
4. `Leaf/LeafRunways.swift` `expandItem` (~205-227): apply inverse per §3 ahead of existing pixel math.
5. `Leaf/LeafRunways.swift`: add `tickOffsets(_ type:_ ticks:)` (or equivalent) routing tick grid fractions through the inverse; drop off-range ticks (§3).
6. `Leaf/LeafXyVm.swift:11-25` + `Leaf/LeafXyzVm.swift:11-25` `ticks()`: route through step 5 when `runways.zoomType == .runXY` (or make `LeafThumbSlideView` remap — pick ONE site; recommend the Vm so `LeafTicksView` stays dumb).
7. `Leaf/LeafBezelView.swift:12-13`: zoomed-runway stroke treatment (§4). Scope: this file only — no other stroke sites (Precise Scope).
8. Guard: skip dwell when `quantize != nil` (§6) — one condition in step 2's scheduling.
9. Build check: `cd /Users/warren/Dev/Deep/Mu/MuMenu && swift build` (macOS destination may not compile UIKit paths — if so build via DeepMenu scheme instead); watch target must still compile (`setNormalized` path untouched).

### Verify

Run DeepMenu (`/Users/warren/Dev/Deep/Menu/DeepMenu.xcodeproj`, iPad simulator or device). Open a branch with an XY leaf (any `x/y` scalar pair) and an XYZ leaf.

- V1 dwell: drag the XY pad thumb, hold still 2 s → ticks spread + bezel stroke change; moving before 2 s keeps rescheduling (no fire).
- V2 fine ratio: after fire, a full-width finger sweep changes the tree title value (`treeTitle`, `LeafXyVm.swift:27-33`) by ≈0.12 of the range.
- V3 no jump: at fire, thumb pixel position unchanged (fixed pivot, offset zeroed); thumb tracks finger 1:1 on screen while zoomed.
- V4 fire-once: after release+re-grab, dwell can fire again; within one drag it fires at most once.
- V5 exit: release → ticks/stroke restore (0.2 s); values persist; `Flo` value correct (check title / downstream render).
- V6 strips: repeat V1-V5 on x strip, y strip, z strip (XYZ leaf); zoom on a strip moves the pad thumb slowly, pad NOT visually zoomed.
- V7 taps: quick taps on the pad never zoom.
- V8 plugin leaf: leaf with plugins — tween capsule renders magnified during zoom, no divergence from thumb after release.
- V9 peers: second device/peer session — remote thumb moves smoothly (true values) during local zoom.
- V10 watch: DeepWatch build unaffected; watch leaf interaction unchanged.

### Non-goals

- No changes to Living (`ShareTabView.swift`, `CanvasScene.swift`) — reference only.
- No zoom for `.runVal`, `LeafSegView`, toggles, or watch gesture surfaces (`setNormalized` path).
- No haptics, no long-press gestures in views (views stay gesture-free), no new `@Published` on `LeafRunways`, no protocol/`MenuLeafItem` changes, no persistence of zoom state.
- No re-centering, no multi-fire per drag, no pinch-style zoom levels — single fixed fine ratio 0.12.
