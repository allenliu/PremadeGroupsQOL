# PremadeGroupsQOL

Quality-of-life fixes for the World of Warcraft Group Finder's "List a Group" panel. Targets Mythic+ pugging on retail (interface 120005, TWW 11.x).

## Install

### CurseForge

*Not yet published — coming later.*

### From GitHub

**Option A — download a release**

1. Grab the latest zip from the [Releases](https://github.com/allenliu/PremadeGroupsQOL/releases) page (or use **Code → Download ZIP** on the repo for the tip of `main`).
2. Extract it. You'll get a folder named something like `PremadeGroupsQOL-main` or `PremadeGroupsQOL-1.0.0`; rename it to `PremadeGroupsQOL`.
3. Move `PremadeGroupsQOL/` into `World of Warcraft/_retail_/Interface/AddOns/`.

**Option B — git clone**

```sh
cd "World of Warcraft/_retail_/Interface/AddOns"
git clone https://github.com/allenliu/PremadeGroupsQOL.git
```

Then enable **Premade Groups QOL** in the AddOns list at character select. `/reload` in-game if it doesn't pick up automatically.

## Improvements

### 1. Party Keys in the dungeon dropdown

The dungeon dropdown shows a "Party Keys" section at the top listing keystones held by you and your party members. Clicking one populates the dungeon, difficulty, and title in one shot. Uses [LibKeystone](https://github.com/BigWigsMods/LibKeystone) for party broadcasts (also embedded by BigWigs, DBM, Details!, and most keystone addons — so any party member running one of those will appear here automatically).

### 2. Dungeon list filtered to M+ keystone dungeons

Below the Party Keys section, the dungeon radios are filtered to M+-capable entries only (the default lists every dungeon in the category plus assorted standalone entries). **More** stays available at the bottom for the full unfiltered list (Heroic dungeons, etc.) via the ActivityFinder. Applied to the Dungeons category only — Raids and other categories are untouched.

### 3. Applicants sorted by Mythic+ score

Once you've listed a group, the ApplicationViewer sorts incoming applicants by primary member's Mythic+ score, descending. Multi-applicant groups (duos, trios) sort by the primary applier's score. Applies to all party members, not just the leader — non-leaders see the dimmed view with the same sorted order.

### 4. Title persists when you change dropdowns

Blizzard's default wipes the Title field on every dungeon or difficulty change. Both typed titles and auto-fills now stick. The field is re-auto-filled only when it's empty, so clearing it manually still lets the keystone-aware default come back.

### 5. Difficulty stays put when you switch dungeons

Blizzard's "best activity" picker means changing dungeon can flip Mythic+ → Mythic 0 (or worse, depending on your gear). Your difficulty selection now follows you to the next dungeon. Falls back to the default if the new dungeon doesn't offer the same difficulty. Re-clicking the same dungeon also no longer drifts.

### 6. Dungeon persists after delisting

After listing a group, delisting, then reopening the panel, Blizzard snaps the dungeon back to whatever keystone is in your bag — usually not the one you were just listing. Your dungeon pick is now preserved across the delist-reopen cycle. Only kicks in once you've explicitly chosen a dungeon this session; first-ever open still respects the keystone default.

### 7. Playstyle defaults to Competitive

Saves a click every time you open the panel to list a new group. Edit-mode (reopening to edit an active listing) still uses the listing's real playstyle.

## Development

The addon hooks `LFGListEntryCreation_*` global functions. The Name EditBox has `securityDisableSetText`, so the title strategy is "prevent, don't restore." Anything touching the secure listing path (apply, invite, create) is left alone to avoid tainting the **List Group** button.

Blizzard's UI source — invaluable when reading hook targets — lives at [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_GroupFinder/Mainline).
