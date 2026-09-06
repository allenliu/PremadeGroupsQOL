# Changelog

## v0.3.3

- Update for patch 12.1.0 (interface 120100). No code changes needed — 12.1 only added new `C_LFGList` APIs; nothing the addon uses was changed or removed.

## v0.2.5

- Fix: `[OCE]` tag was missing on some OCE-realm applicants when the realm suffix arrived asynchronously. The decision is now cached per applicant so the tag survives Blizzard's later text refreshes.

## v0.2.4

- First release on CurseForge.

## v0.2.3

- **[OCE] badge** on applicant member names in the ApplicationViewer. Tags every member of a multi-applicant individually based on their realm.

## v0.2.2

- Fix: delist-then-relist no longer restores a stale dungeon (a prior regular-dropdown pick) over the party-key dungeon you actually listed. Party-key picks now correctly stamp the dungeon/activity trackers.

## v0.2.1

- Party Keys: picking a party member's key now focuses the title field and selects existing text so you can type their level in a few keystrokes. A green `+N` hint next to the "Title" label shows what to type.
- The hint is skipped when the title's leading number already matches the picked key's level (`+10` title + pick `+10` key = silent).
- The hint clears automatically when you pick a regular dungeon or activity, or start typing.
- Fix: title auto-fill no longer wrongly fires for party members' keys (it was using your own keystone level, producing empty or wrong values).

## v0.2.0

- **Party Keys section** at the top of the dungeon dropdown. Lists keystones held by you and your party members; clicking one populates the dungeon, difficulty, and title. Uses LibKeystone — interoperable with BigWigs, DBM, Details!, and other addons that embed it.
- **Applicant sort by Mythic+ score (descending)** in the ApplicationViewer. Multi-applicant groups sort by the primary applier's score. Applies to all party members, not just the leader.

## v0.1.0

Initial release.

- **Dungeon dropdown filtered to M+ keystone dungeons** in the "List a Group" panel. "More" still exposes the full list via the ActivityFinder.
- **Title field persists** across dungeon and difficulty changes (typed titles and auto-fills both). Re-auto-fills only when empty.
- **Difficulty stays put** when switching dungeons. Falls back to Blizzard's default if the new dungeon doesn't offer the same difficulty.
- **Dungeon persists across the list/delist cycle.** Only after you've explicitly picked a dungeon this session; first-ever opens still respect the keystone default.
- **Playstyle defaults to "Competitive"** on fresh panel opens. Edit-mode preserves the listing's actual playstyle.
