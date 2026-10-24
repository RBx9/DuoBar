Beta 3 is superseded by [DuoBar v2.7.2 Beta 4](https://github.com/RBx9/DuoBar/releases/tag/v2.7.2-beta.4).

The Beta 3 Rootless package included only an arm64 slice in its Settings executable. On arm64e devices, this can make Settings report that `DuoBarPrefs.bundle` has an incompatible architecture. Install the Beta 4 Rootless package instead; its Settings executable and tweak library include both arm64 and arm64e slices.

The Beta 3 RootHide package is unaffected. Stable v2.7.1 and the Sileo source are unchanged.
