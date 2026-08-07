# Comment Tracker

A native macOS app to **push your daily commenting goal** — track comments posted on **x.com** (primary), **yt.com** and **ig.com**, time your sessions, and see how much you can do.

Built with **Swift + SwiftUI + SQLite**. No network calls. Your data stays on your Mac.

---

## Features

- **Daily goal** (default 313) with a **sub-goal system** (default 30) — pick any level you're comfortable with so the big number doesn't feel overwhelming
- **Sub-goals are configurable anytime** — presets (5, 10, 20, 30, 50, 75, 100) or custom
- **Per-platform counters** — x.com is the focus; yt.com and ig.com available too
- **Session timer** — start/end sessions and track how much you can push and how long it takes
- **Pace** — comments per hour and live progress
- **Milestones** — hit 1% of your sub-goal and you've already won; keep going through 5%, 10%, 25%, 50%, 75%, 100%
- **History** — last-7-days chart + all past sessions
- **People board (Trello-style)** — track up to 313 people across a **Holding** list and **Check** lists (Daily / Weekly / Monthly / Quarterly / Yearly), drag cards between lists and reorder
- **Person cards with details** — double-click a card for description, activity comments, and openable links (X, YouTube, Instagram, videos, websites, anything)
- **Videos board (Trello-style)** — save YouTube, X and Instagram-reel videos across Holding / Urgent / Important / Daily / Weekly / Monthly watch lists, drag & drop, search
- **Video cards with details** — double-click to edit notes, add comments, or open the video in your browser
- **Tracker (daily routines)** — checkboxes and counters with monthly calendar views and notes: **Namaz (5)**, **Quran (1 para)**, **Zikr** (morning/evening, 1000 darood, 1000 astaghfar), **Dua**, **Fasting** (Ramadan + Thursdays), **Jamaat** (3/month · 40/year · Sunday night), **Masjid**, **Family/Wife**, **Parents**, **Relatives**, **Parenting**, **Friends**, **Health** (steps, diet), **Business** (app build, content, sales, automation)
- **Enable/disable any tracker** in Manage; add custom trackers with your own icon, color and target
- **Global search (⌘K)** — search across tabs, trackers, people and videos
- **Thoughts board (Trello-style)** — Long-term / This week / Doing lists; add one or a whole batch (one per line), drag to reorder, and hit **"Pick for me"** to let the dice choose when you can't decide
- **Wins feed (Twitter-style)** — celebrate small wins as they happen (newest on top), bookmark the ones that matter and filter to them; "Show older" paginates the timeline
- **Backup & Restore** — export the whole database to a file anytime, restore from any previous backup (Help → Backup & Restore)
- **Local SQLite storage** — nothing leaves the machine
- **First-run onboarding**, Help screen with settings, and keyboard shortcuts
- Custom app icon

## Platforms

| Platform | Handle | Tier | Focus |
|----------|--------|------|-------|
| X        | x.com  | Primary   | ✅ |
| YouTube  | yt.com  | Other     | — |
| Instagram| ig.com  | Secondary | — |

## Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘ N` | Add comment |
| `⇧ ⌘ S` | Start / End session |
| `⌘ K` | Search everything |

## Build & run

Requires macOS 14+ and Xcode command line tools (Swift 6+).

```bash
make bundle      # build release + generate icon + assemble .app
make run         # build and open dist/CommentTracker.app
```

The app lands at `dist/CommentTracker.app`.

## Data

Everything is stored in a local SQLite database:

```
~/Library/Application Support/CommentTracker/comments.sqlite
```

Tables: `settings`, `comments`, `sessions`.

## Project structure

```
Package.swift                          # SwiftPM executable target
Makefile                               # build / bundle / icon / run
scripts/make_icon.swift                # renders the app icon
Resources/Info.plist                   # app bundle metadata
Sources/CommentTracker/
  CommentTrackerApp.swift              # @main entry + menu commands
  Models.swift                         # Platform, Comment, Session, Milestone, Person…
  DatabaseManager.swift                # SQLite3 wrapper + schema migration
  Store.swift                          # observable app state + business logic
  Views/                               # SwiftUI screens
```

## Roadmap

See [ROADMAP.md](ROADMAP.md).

## License

MIT — free to use, modify and share.
