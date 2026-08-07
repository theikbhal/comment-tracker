# Changelog

All notable changes to Comment Tracker, newest first.

## [v1.11.0]

### Added
- New **Blog** tab: write and manage posts. Title, body, and comma-separated tags; Draft/Published status with a stamped publish date; filter by status, search across title/body/tags.

## [v1.10.0]

### Added
- New **Mini Mind Map** tab: visual idea webs with multiple maps. Add child nodes to any node (right-click or double-click), drag to rearrange with live connector lines, rename and recolor nodes, delete whole branches.

## [v1.9.0]

### Added
- New **Urgent** tab: four urgency lists (Now / Today / Soon / Whenever) side by side, wins-style cards. Add from any lane's + or the header button — the popup lets you pick the section. Drag cards to reorder within a lane or move between lanes; right-click to edit, move, or delete.

## [v1.8.0]

### Added
- New **Holding Hand** tab: a Wins-style parking lot for things you don't want to lose but aren't ready to organize. Compose, hold, timestamped feed, Open/Bookmarked filters, release items when handled, delete via right-click. Searchable via ⌘K.

## [v1.7.1]

### Added
- New **Schedule** tab: a weekly grid (7 days × Morning/Noon/Afternoon/Evening) to plan when to work and what to work on. Click a cell to set or clear it; today's column is highlighted.

## [v1.7.0]

### Added
- New **Deep Work** tab: a single focus timer for 15–120 min blocks with a live progress ring, pause/reset, sound on completion, daily minutes + history. Completing a block automatically logs a Win.

## [v1.6.3]

### Added
- New **Projects** tab: track what you're working on. Each project is Working (the single current project), In Progress, or Completed. One-click Start/Stop, reopen, and per-project "how to start" / "how to stop" notes so switching in and out is easy.

## [v1.6.2]

### Added
- New **Parallel** tab: 3 parallel threads (Thing 1 / 2 / 3) plus an Unorganized catch-all bucket. Add items in any lane, drag between lanes or move from right-click, attach notes.

## [v1.6.1]

### Added
- New **Focus** tab: a single "current focus" anchor. Start a session on one thing, watch a live timer while you focus, add a note, and end it when done. Every session is saved to history with duration so you can see where attention actually went.

## [v1.6.0]

### Added
- New **Buck Track** tab (pinned near the top): a three-column board — In Flight / On Hold / Done — that shows everything we're working on. Add a bucket at the top, drag cards between columns or move them from the right-click menu, and attach/edit notes on each. Search finds buckets anywhere.

## [v1.5.1]

### Added
- New **Notes** tab: Interstitial Notes — a notebook-paper capture log. Between tasks, jot what you're working on right now; every line is timestamped and grouped by day (Today / Yesterday / date), styled like ruled notebook paper. Searchable, delete per line, ⌘⏎ to log.

## [v1.5.0]

### Added
- New **Fails** tab: a Twitter/X-style timeline of things that didn't work, mirroring Wins. Compose at the top, newest first, bookmark + filter, search, paginated "Show older fails", delete via right-click. Surfacing what missed makes the pattern visible instead of eating you quietly.

## [v1.4.3]

### Fixed
- 313 Cards grid now scrolls both vertically and horizontally with visible scrollbars, so every card in the deck is reachable.

## [v1.4.2]

### Changed
- 313 Cards: every card now has a fixed slot number (1–313) with a grid reference (r,c) in the corner.
- 313 Cards: words are edited in place directly on the card (Enter or click away to save); right-click opens the full dialog for 5 words + link.
- Existing cards were auto-numbered in place (no data loss); export/import now preserves slot positions.

## [v1.4.1]

### Added
- 313 Cards: "Add 313 empty", "Reset deck" (with confirmation), "Hide empty" toggle.
- Close button on the sprint dialog.

## [v1.4.0]

### Added
- Links — a simple reorderable list (drag to reorder, add, edit, delete; click to open).
- 313 Cards — a one-word card deck; tap a card for a dialog with up to 5 words and a link; group by a searchable name; export/import the whole deck as JSON.
- Pomodoro — focus (25) / short break (5) / long break (15) timer that counts your sessions.
- Sprints — time-boxed (30 min / 1 hr / 2 hrs) sprints with stories broken into tasks; edit/delete/move stories between sprints; marking a task or a sprint done automatically adds a Win.
- All new sections searchable from ⌘K.

## [v1.3.0]

### Added
- Wins feed — Twitter/X-style timeline (newest at top, oldest below) to celebrate wins, with compose box, bookmark (star) filter, and pagination ("Show older").
- Backup & Restore — export the whole database any time; restore from any previous backup file. Located in Help → Backup & Restore.

## [v1.2.0] - Recent

### Added
- Thoughts board (Trello-style) — Long-term / This week / Doing lists.
- Add thoughts one at a time or paste a batch (one per line).
- Drag to reorder or move between lists.
- "Pick for me" (🎲) — chooses a random thought when you can't decide, with Shuffle again + Do it now.
- Thoughts searchable from ⌘K.

## [v1.1.0]

### Added
- Daily routines Tracker — checkboxes and counters with monthly calendar views and notes.
- 32 presets: Namaz (5), Quran, Zikr (darood/astaghfar 1000 counters), Dua, Fasting, Jamaat, Masjid, Family, Parents, Relatives, Parenting, Friends, Health, Business.
- Manage trackers: enable/disable any preset, add custom trackers.
- Global search (⌘K) across tabs, trackers, people and videos.

## [v1.0.0]

### Added

- Daily comment goal (313 default) with sub-goals (default 30).
- Sessions with a live timer and per-hour pace; milestones at 1–100%.
- Platform tracking: x.com (primary/focus), yt.com, ig.com.
- History: last 7 days + full session log.
- People board (Trello-style) — Holding + Daily / Weekly / Monthly / Quarterly / Yearly with drag & drop and person details (links + comments).
- Videos board — Holding / Urgent / Important / Daily / Weekly / Monthly, open in browser, comments.
- Onboarding + Help, local SQLite storage.