# Device validation

Status: **not run on an iPhone**. These are the checks to complete on the intended iOS 16 device before treating the tweak as validated. Record the iPhone model, exact iOS version, jailbreak version, package variant and results.

## Installation and visibility

- [ ] Install the package variant matching the jailbreak: RootHide or standard Dopamine rootless. Confirm the package manager accepts its architecture and dependencies.
- [ ] Respring, then reopen apps that were already running.
- [ ] Confirm a single combined glyph appears on the Home Screen: battery percentage above open side arcs, Wi-Fi in the center and four cellular dots below. The native battery, Wi-Fi and cellular drawings should not remain underneath or beside it.
- [ ] Check status bars in several system and third-party apps, the Lock Screen and the app switcher. Confirm the native status-bar visibility rules still apply.
- [ ] Open Control Center and confirm its battery presentation has not been replaced by this status-bar tweak.
- [ ] Rotate in an app that supports landscape. Check that the combined glyph fits the available status-bar height, without clipping or overlap with the time, notch, privacy indicators or other items.

## Appearance and state changes

- [ ] Check both light and dark status-bar foregrounds, including a transition between apps with different status-bar styles. Battery digits, arcs, the charging bolt, active Wi-Fi segments and cellular dots should remain visible.
- [ ] Compare the percentage with the system's battery reading; it should update without reopening the app or respringing.
- [ ] Connect and disconnect a charger. Verify the bolt and fill color update; also observe the fully charged state.
- [ ] Toggle Low Power Mode. Verify the yellow state and its transition back to normal, including when the charger is connected.
- [ ] Observe a battery level at or below 20% and verify the short red arc while unplugged and outside Low Power Mode. Verify legibility at low percentages and at 100%. At 50%, the left battery arc should be filled and the right arc inactive.
- [ ] Observe Wi-Fi at different signal strengths. Verify that active segments follow the system reading.
- [ ] Disconnect Wi-Fi, reconnect, and toggle airplane mode. Confirm the center Wi-Fi symbol disappears when the native Wi-Fi indicator is absent and returns when connected; a stale connected symbol should not remain.
- [ ] Compare cellular reception with the system reading as it changes. Verify that 0 through 4 dots can be active, with inactive dots dimmed. Check no-service and airplane-mode states.
- [ ] If using dual SIM, compare both visible native line readings before enabling the tweak. Confirm the combined glyph uses the strongest visible line rather than combining or adding the two readings.
- [ ] Lock, unlock, sleep and wake the phone. Confirm the icons return and update correctly.
- [ ] If using VoiceOver, confirm the system battery, Wi-Fi and cellular announcements remain available without duplicate decorative elements.

## Compatibility and removal

- [ ] Open Settings → DuoBar after installation and confirm the page loads, the version is 0.2.0, the developer is RBx9, and the description appears.
- [ ] Tap Twitter / X and confirm the link opens @RedaBuali.
- [ ] Turn Enable DuoBar off and confirm stock battery, Wi-Fi and cellular icons return immediately on the Home Screen and in apps, without duplicate drawings.
- [ ] Turn the switch back on and confirm the circular design returns without a respring.
- [ ] Disable DuoBar, respring, and confirm it starts disabled and the switch stays off. Re-enable it and repeat with the switch on.
- [ ] Change the switch while an app is suspended, then reopen that app and confirm it adopts the new setting.

- [ ] First test with other battery and status-bar appearance tweaks disabled. Re-enable any desired tweaks individually and check for overlap or competing colors.
- [ ] Open and close apps repeatedly and observe for SpringBoard restarts, app crashes, persistent layout changes or unexpected resource use.
- [ ] If a crash occurs, capture the crash log, affected process and action that triggered it. Use the jailbreak's tweak-disable or Safe Mode recovery path to remove the package if needed.
- [ ] Remove DuoBar in the package manager, respring and reopen apps. Confirm the stock icons and their live updates return.

The SVG preview is an illustration of the drawing geometry. It does not validate private UIKit hooks, package installation or behavior on any particular iPhone.
