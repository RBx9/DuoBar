# DuoBar v0.2.6 — Settings icon and optional support (development)

This change is being prepared on a separate branch. It is **not** a stable release.

- Removes the white square around the existing rounded Settings icon using a background-only transparency mask.
- Adds an optional support section in Settings with a donation explanation.
- The **Support via PayPal** button becomes visible only after the developer provides their own PayPal.Me URL.
- Does not change the status-bar tweak logic, Control Center or existing v0.2.5 stable package.

## Developer action required

Set `DuoPayPalURL` in `duobarprefs/DuoRootListController.m` to the developer's verified PayPal.Me URL, then build a RootHide beta for device testing before publishing.
