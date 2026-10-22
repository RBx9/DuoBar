# DuoBar v2.7.2 Beta 1 — RootHide

This RootHide test build starts from the v2.7.1 release. It moves the native 5G/LTE carrier label into the DuoBar ring and keeps the regular Wi-Fi or Personal Hotspot mark visible inside the ring. The carrier label is handled in app status bars and Control Center. Existing battery percentage, cellular dots, size adjustment, Settings, hotspot handling, and Control Center positioning are retained.

## Device checks

- Confirm the compact `5G` or `LTE` label appears inside DuoBar in the Home Screen, in an app, and in Control Center; the original label should no longer sit outside the ring.
- Confirm the Wi-Fi mark and Personal Hotspot chain remain visible in the ring when their respective states are active.
- Move the size slider to 70%, 100%, and 140% and check the label remains centered and readable in each status-bar context.
- Switch between 5G, LTE, Wi-Fi, and Personal Hotspot states and make sure stale labels do not remain.
- Rapidly open and close Control Center, then open an app, to check DuoBar does not jump, disappear, or leave a native label hidden.
- Turn DuoBar off and confirm the normal iOS status bar returns; turn it back on and repeat the checks.

Compilation and package contents were checked locally. These runtime checks still need an iPhone running iOS 16 with Dopamine RootHide.
