# Changelog

## v0.1.0

Initial release.

- **Dungeon dropdown filtered to M+ keystone dungeons** in the "List a Group" panel. "More" still exposes the full list via the ActivityFinder.
- **Title field persists** across dungeon and difficulty changes (typed titles and auto-fills both). Re-auto-fills only when empty.
- **Difficulty stays put** when switching dungeons. Falls back to Blizzard's default if the new dungeon doesn't offer the same difficulty.
- **Dungeon persists across the list/delist cycle.** Only after you've explicitly picked a dungeon this session; first-ever opens still respect the keystone default.
- **Playstyle defaults to "Competitive"** on fresh panel opens. Edit-mode preserves the listing's actual playstyle.
