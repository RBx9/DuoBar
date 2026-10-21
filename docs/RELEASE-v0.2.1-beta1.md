# DuoBar 0.2.1 beta 1 — Control Center layout fix

**TEST BUILD — iOS 16 Dopamine RootHide only.** The RootHide package has been compiled by GitHub Actions, but these layout fixes have not yet been confirmed on a real iPhone.

## What changed
- Suppress the duplicate system battery percentage in Control Center while DuoBar is enabled.
- Shift an overlapping Control Center orientation-lock indicator left, when identifiable.
- If the indicator can't be identified safely, reserve space by shifting the DuoBar glyph slightly right.
- Keep stock indicators intact when DuoBar is disabled; preserve regular status-bar behavior.

## How to test
1. Download and install the attached **DuoBar_0.2.1-beta1_RootHide.deb** (it upgrades your existing `local.duobar` package).
2. Respring.
3. Open Control Center and check that there is just one battery percentage inside DuoBar, with no rotation-lock overlap.
4. Close Control Center and inspect the normal status bar; toggle the lock and repeat.
5. Try Settings → DuoBar → Enable DuoBar off/on to ensure the stock layout returns.

**If SpringBoard behaves incorrectly:** disable tweak injection for DuoBar or use your jailbreak recovery/safe mode to remove the beta package, then reinstall [v0.2.0](https://github.com/RBx9/DuoBar/releases/tag/v0.2.0).

Please report whether the stock "86%" text disappeared and whether the rotation icon now sits to the left.
