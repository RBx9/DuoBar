DuoBar 2.7.3 beta 5 is a test build for iOS 16, for Dopamine RootHide and standard Rootless (Dopamine, palera1n). It is not on Sileo. Stable 2.7.2 is unchanged.

## Fix

- **Control Center ring on Home-button iPhones:** on the iPhone 8, 8 Plus and SE, Control Center drew a larger DuoBar about 45 pt left of the Home Screen's, so the ring slid sideways and resized as Control Center opened and closed. Beta 4 matched the size; beta 5 also moves it to the Home Screen's horizontal position (the simulator still showed a 29 pt gap on the 8 Plus after beta 4). Face ID iPhones were already identical and are unchanged.

## Not fixed

- The rotation-lock icon flicker in Control Center is still unexplained. The simulator could not show the icon.

## Install

Download the `.deb` for your jailbreak (`Rootless` for Dopamine Rootless or palera1n, `RootHide` for Dopamine RootHide), open it in your package manager and respring.
