# DuoBar v0.2.6 Beta 2 — Settings Feedback & Icon Polish

**RootHide test build for iOS 16.x. Not available in Sileo.**

## What's new

- The blue DuoBar Settings icon no longer has white square corners.
- New **Report a Bug** button opens a prefilled email report, with a prompt suggesting a screenshot or short video.
- New **Help Test Other iOS Versions** button lets volunteers email device, iOS and jailbreak details to help improve compatibility.
- No changes to the working Personal Hotspot, rotation-lock, Control Center, or size-slider code.

## Install and verify

Install `DuoBar_0.2.6-beta2_RootHide.deb` using your RootHide-compatible package manager and respring. Close and reopen Settings.

In **Settings → DuoBar → Feedback & iOS Testing**, tap **Report a Bug**. Confirm a screenshot reminder appears and **Compose Email** opens an editable draft addressed to the developer. Cancel the draft rather than sending a test report. Then check **Help Test Other iOS Versions** opens a prefilled draft with your iOS version, and confirm the transparent icon looks correct in the main Settings list.

The email buttons only open drafts; users must review and send them. Screenshots are added manually in the email application. No reports are transmitted automatically.

**Rollback:** [v0.2.5 stable](https://github.com/RBx9/DuoBar/releases/tag/v0.2.5).

Package: `local.duobar` · Version: `0.2.6~beta2` · Architecture: `iphoneos-arm64e`.
