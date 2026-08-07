# Changelog

All notable changes to Comment Tracker, newest first.

## [v1.23.0]

### Added
- **Diet tab**: log food by meal (Breakfast, Lunch, Dinner, Snacks) with optional notes, flip through days, search, and per-meal counts.
- **Family tab**: family members with relation, optional birthday countdown (orange in the last week, pink today), markdown notes, reorderable.
- **Follow-ups tab**: things to come back to, with optional dates. Today/Tomorrow chips, overdue glows red, check off when handled.
- **Inspire tab**: quotes and lines that lift you — the words, a source, optional link, markdown note, and bookmarking. Filter to bookmarked anytime.

## [v1.22.0]

### Added
- **Table Tracker tab**: spreadsheet-style habit tracking. Create multiple tables; your habits run down the rows, the last 14 days run across the columns. Click any cell to check the day off, arrow through time, jump to today, and rename/delete rows from the row menu. Each row shows its hit count for the window.
- **Pending tab**: a simple pending list. Add items, check them done, edit markdown notes, reorder the open ones, search, and toggle the Done filter.

## [v1.21.0]

### Added
- **Notes upgraded to a Wins-style feed**: every check-in is now a card with a bookmark (filter to bookmarked anytime), edit, delete, and move-to-top. Same look as Wins, including the yellow bookmark ring and "show older" paging.
- **Feature Requests tab**: a board (Ideas → Planned → In Progress → Done) for the features you want to build across your apps. Each request holds an app tag, title, markdown note, link, and a comments feed. Status is changed from the card or the detail sheet.

## [v1.20.0]

### Added
- **Tools tab**: a reorderable toolkit. Each tool has a name, a markdown note (self-notes with clickable links), and an optional link that opens in your browser. Reorder with the up/down arrows.
- **Old Dreams tab**: keep the hopes and ambitions you don't want to lose. Each dream holds a title, a markdown note, and an optional link; reorder to reflect what matters now. Double-click to edit.

## [v1.19.0]

### Added
- **Alarms tab**: set reminders in plain English — `15 minutes`, `1 hour`, `2pm`, `8.30pm`, `9:45 am`, `noon`, `midnight`. Live preview shows what was understood. Quick presets for 15/30/50 min and 1 hour. Alarms fire as local notifications in the background — even on another tab or with the app closed. View active alarms with live countdowns, edit time/label, snooze by 5 minutes, or stop & delete. Fired alarms are kept for reference.

## [v1.18.0]

### Fixed
- **Pomodoro & Deep Work now survive tab switches**: the timers live in the shared app state, so starting a session and navigating anywhere keeps counting.
- **Floating timer**: "Floating timer" button (Pomodoro + Deep Work headers) opens a small always-on-top window showing whichever timer is active, with Start/Pause/Reset. It stays above other windows and on every Space.
- **Completion notifications**: a local notification (plus sound) fires when a Pomodoro session or Deep Work block ends — even if you're on another tab or the app isn't focused.

## [v1.16.2]

### Added
- **Challenge prerequisites**: link any challenge to prerequisite challenges it depends on. Cards show a lock when waiting on incomplete prerequisites (green "Prerequisites met" once they're done). Add/remove prerequisites from the challenge detail sheet.

## [v1.16.1]

### Added
- **Challenge comments**: open a challenge to see a comment feed — add and delete comments, with a comment count on each card. Delete a challenge now removes its comments too.
- **Start / end dates**: set them with real date pickers instead of free text.

## [v1.17.0]

### Added
- **Roadmap** tab: plan big work in Planned / In Progress / Done / Deferred columns. Each item has a quarter label, a priority (high/medium/low), and a markdown note with clickable links. Move items between columns via the arrows menu. Search via ⌘K.

## [v1.16.0]

### Added
- **Challenges** tab: personal quests across Active / Completed / Archived columns. Each challenge has optional start/end dates and a markdown note with clickable links. Move between columns via the arrows menu. Search via ⌘K.

## [v1.15.0]

### Added
- **52 Weeks** tab: one card per week of the year. Each shows the week number, month, and start/end dates. Click a card to add a title plus a **markdown note** — bold, lists and links work, so paste a YouTube or any URL and click it straight from the note or the card preview. Search via ⌘K, export/import all 52 as JSON, or reset.

## [v1.14.0]

### Added
- **Year** tab: 12 cards, one per month. Click a card and type the word/phrase you want to focus on for that month; a count shows how many of the 12 are filled. Searchable via ⌘K, resettable in one click.

## [v1.13.1]

### Added
- **Calendar reminders**: set a reminder (5 min to 1 day before) on any event and a local notification fires at the right time — even when the app is closed or you're on another tab. Add a bell in the calendar header to send a test notification.

## [v1.13.0]

### Added
- New **Calendar** tab: a month grid of events with optional times and colors. Click a day to see its events in a side panel, add events per day, edit or delete from the panel, navigate months, and jump to Today.

## [v1.12.2]

### Added
- **Blog**: full read view for each post (click a card or hit View). The view sheet shows the whole body, tags, status, and dates, with Publish/Unpublish, Edit, and Delete actions.
- **Blog** cards now show explicit View / Edit / Publish / Delete buttons; pagination shows how many posts remain.

## [v1.12.1]

### Changed
- **Mind Map**: node text now edits in place at the node (Enter saves, Esc cancels) instead of a popover. Double-click a map chip to rename it.

## [v1.12.0]

### Added
- New **Slack** tab: a mini in-app Slack. Channels with names and colors (a #general channel is created for you), messages posted with Return, auto-scroll, rename/delete channels and delete messages from right-click.

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