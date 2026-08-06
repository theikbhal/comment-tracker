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
  Models.swift                         # Platform, Comment, Session, Milestone
  DatabaseManager.swift                # SQLite3 wrapper + schema migration
  Store.swift                          # observable app state + business logic
  Views/                               # SwiftUI screens
```

## Roadmap

See [ROADMAP.md](ROADMAP.md).

## License

MIT — free to use, modify and share.
