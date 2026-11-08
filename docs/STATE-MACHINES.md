# DuoBar's implicit state machines

DuoBar has no explicit state-machine type. The states below live in booleans, associated objects, weak tables and
guard clauses in `Sources/Tweak.xm`. This page names them, lists their states and transitions, and records the
invariants that must hold, so a change can be checked against them. It describes the code as of 2.7.3 beta 3 and
does not change behavior.

Line numbers are left out on purpose; search for the names in **bold**.

## 1. Load gate (`%ctor`) — decided once per process

`Inert` → `Core installed` → `Core + optional features`. Never goes back.

- Inert when iOS is outside 16…`DUO_MAX_IOS_MAJOR`, or a core class/selector is missing (battery, signal, Wi-Fi,
  cellular, `_UIStatusBar`).
- Optional groups (5G/LTE text, hotspot image, Control Center bar, foreground view) install only if their own
  selectors exist, so one renamed private API turns off one feature, not the tweak.
- **Invariant:** nothing is hooked until every check of its group has passed. `scripts/check-private-api.py` enforces
  that every hooked selector is probed here.

## 2. Preferences — `Enabled` × `SizeScale`

Read at load, on the Darwin notification `local.duobar/preferences.changed`, and when an app enters the foreground or
becomes active (**DuoReloadPreferences**). `Enabled` off restores every native view; a new size re-lays-out every
controller. `SizeScale` is clamped to 0.70–1.40 on every read.

## 3. Update scheduling — per controller

`Idle` → `Scheduled` (**updateScheduled**) → `Updating` (**updating**) → `Idle`.

- Many UIKit layout callbacks coalesce into one main-thread `update`. A re-entrant call while `Updating` is dropped.
- **Invariant:** every `return` inside `update` clears `updating`. A missed path would freeze DuoBar for that
  container.

## 4. Status-bar controller outcome — what one `update` decides

| Outcome | When | Effect |
|---|---|---|
| Disabled | `DuoEnabled` is off | glyph hidden, natives restored |
| Hidden | no valid data, or container shorter than 16 pt | glyph hidden, natives restored |
| Held | container height < 16 pt but a glyph is already shown (rotation, Control Center swap) | glyph stays, natives stay covered |
| Drawn | data valid | glyph placed, natives covered |

**Invariant:** the stock battery must never be uncovered between two Drawn passes. That is why Held exists.

## 5. Native cover (**DuoNativeState**) — per native view

`Native` ⇄ `Covered`. `cover` saves each sublayer's `hidden` flag and the view's `contents`, then hides them;
`restore` puts exactly those back. **Invariant:** `restore` only undoes what `cover` saved, and `cover` is
idempotent, so repeated passes never lose the original values.

## 6. Placement mode — Home/app vs Control Center

Chosen per pass by **DuoControlCenterVisible**. Two frame rules (`DuoComputeGlyphFrame`,
`DuoComputeControlCenterGlyphFrame`). **Invariant:** while Control Center closes, its rule must give the Home
Screen's frame, or the ring jumps. `tests/layout-test.c` checks this with measured cases.

## 7. Battery data source

`Native battery` ⇄ `Cached/fallback` (**DuoLastBattery…**, then `UIDevice`). Used when a container has no battery
view. **Hazard:** the cache is process-wide and survives containers; it is only a display fallback.

## 8. Battery position memory (beta 2) — per controller

`Live` → `Held` → `Reset`. The battery's last rectangle is kept while a pass lacks the battery, and dropped when the
container width changes (rotation) or the rectangle no longer fits.

## 9. Percentage text — Control Center only

`Native` ⇄ `Hidden` (**DuoSavedPercentageKey** holds the text). Matching is locale-aware (**DuoIsBatteryPercentage**:
"33%", "%33", "33 %", Arabic digits). **Invariant:** the saved text is put back when DuoBar is disabled or the view
leaves Control Center.

## 10. Rotation-lock icon — Control Center only

`Unmoved` → `Shifted` (original transform saved) → restored at the start of every pass → `Shifted` again. Since beta 3
the icon found last time is remembered (**rotationIndicator**). **Invariant:** the transform is always restored
before it is measured, so shifts never accumulate.

## 11. Centre mark

Derived each pass, in priority order: Personal Hotspot link, 5G/LTE label, Wi-Fi arcs, nothing.
Hotspot detection caches its image result per view (**DuoChainImageResultKey**).

## 12. Release pipeline (CI)

Version string → beta or stable → build → verify → publish. Publishing needs a dispatch input; stable also needs a
stable version string and `WANT_STABLE`. A release that already exists is never replaced.

## Rules when changing DuoBar

1. A new state must be written here first, with its invariant.
2. Never add a path out of `update` that skips `updating = NO`.
3. Anything that moves or hides a native view must have a restore on the Disabled and Hidden outcomes.
4. Hook a private selector only after probing it in `%ctor`; run `python3 scripts/check-private-api.py`.
5. Changing a frame rule needs a case in `tests/layout-test.c`.

## Why this is documentation, not a refactor

Turning these into one explicit state type would touch every hook in a tweak that runs inside SpringBoard, where a
mistake means Safe Mode, and none of it can be tested on a device from here. The invariants above are the part that
protects users, so they are written down and checked by CI where possible. An explicit state type for the update
outcome (section 4) is the best first step if you want one, once a device tester is available.
