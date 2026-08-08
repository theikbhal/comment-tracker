import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct HelpView: View {
    @EnvironmentObject var store: Store
    @State private var goalText: String = ""
    @State private var subGoalText: String = ""
    @State private var peopleGoalText: String = ""
    @State private var showDataPath = false
    @State private var backupMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Help")
                        .font(.title.bold())
                    Text("How to use Comment Tracker.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                goalCard
                subGoalCard
                peopleGoalCard
                buckCard
                focusCard
                parallelCard
                urgentCard
                holdingCard
                projectCard
                deepWorkCard
                scheduleCard
                mindMapCard
                blogCard
                slackCard
                calendarCard
                yearCard
                weekCard
                challengeCard
                roadmapFeatureCard
                alarmsCard
                toolsCard
                dreamsCard
                featuresCard
                tableTrackerCard
                airtableCard
                miniVideosCard
                redditCard
                eventsCard
                treeCard
                faqCard
                celebrationsCard
                longTermCard
                pendingCard
                dietCard
                familyCard
                followUpCard
                inspireCard
                howToCard
                trackerCard
                thoughtsCard
                winsCard
                failsCard
                notesCard
                linksCard
                cardsCard
                stacksCard
                pomodoroCard
                sprintsCard
                videosCard
                searchCard
                shortcutsCard
                dataCard
                backupCard
                roadmapCard
                aboutCard
            }
            .padding(22)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            goalText = "\(store.goal)"
            subGoalText = "\(store.subGoal)"
            peopleGoalText = "\(store.peopleGoal)"
        }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Daily Goal", systemImage: "target")
                .font(.headline)
            HStack {
                TextField("Daily goal", text: $goalText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                Button("Save") {
                    store.updateGoal(Int(goalText) ?? 313)
                }
                .buttonStyle(.borderedProminent)
                Text("Default 313 · minimum pass 3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private var subGoalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sub-goal — today's comfortable push", systemImage: "flag.checkered")
                .font(.headline)
            Text("Smaller target so the big daily number doesn't feel overwhelming. Change it to any level you like.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(SubGoalPreset.allCases) { preset in
                    Button {
                        subGoalText = "\(preset.rawValue)"
                        store.updateSubGoal(preset.rawValue)
                    } label: {
                        Text(preset.label)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .frame(width: 48)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(store.subGoal == preset.rawValue ? Color.blue.opacity(0.2) : Color.gray.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                TextField("Custom", text: $subGoalText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .onSubmit {
                        store.updateSubGoal(Int(subGoalText) ?? 30)
                    }
                Button("Set") {
                    store.updateSubGoal(Int(subGoalText) ?? 30)
                }
                .buttonStyle(.bordered)
            }
            Text("Current sub-goal: \(store.subGoal) comments")
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .card()
    }

    private var peopleGoalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("People Goal", systemImage: "person.2")
                .font(.headline)
            Text("How many people you're tracking on the People board. Default 313.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                TextField("People goal", text: $peopleGoalText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                Button("Save") {
                    store.updatePeopleGoal(Int(peopleGoalText) ?? 313)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Text("Tracking \(store.totalPeople)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private var buckCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Buck Track — what we're working on", systemImage: "hammer.fill")
                .font(.headline)
            Text("A three-column board: In Flight, On Hold, Done. Everything you're working on lives here. Add it at the top, drag cards between columns (or use right-click), and keep notes on each bucket.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var focusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Focus — one thing at a time", systemImage: "scope")
                .font(.headline)
            Text("Pick a single current focus and the app holds the timer while you work. End it when done; every session is saved to your history with a duration and optional note, so you can look back at where attention actually went.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var parallelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Parallel — 3 threads + a catch-all", systemImage: "square.split.3x1")
                .font(.headline)
            Text("Keep three things running side by side (Thing 1 / 2 / 3) plus an Unorganized bucket for everything that doesn't fit yet. Drag items between lanes or use right-click to move them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var urgentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Urgent — four urgency lists side by side", systemImage: "flame.fill")
                .font(.headline)
            Text("Now / Today / Soon / Whenever, in parallel lanes. Use the + on any lane or Add urgent to open the popup, where you pick the section from a menu. Drag cards to reorder within a lane or move them between lanes; right-click to edit, move, or delete.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var holdingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Holding Hand — a parking lot", systemImage: "hand.raised.fill")
                .font(.headline)
            Text("A Wins-style feed for things you don't want to lose but aren't ready to organize. Type it and hit Hold it; each item is timestamped. Filter by Open or Bookmarked, release an item when it's handled, delete from right-click.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var projectCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Projects — track what you're working on", systemImage: "shippingbox.fill")
                .font(.headline)
            Text("Each project has a status: Working (the one, single current focus), In Progress, or Completed. Hit Start to make it the active project, Stop to drop it back. Store a \"how to start\" and a \"how to stop\" note on each project so switching in and out is easy.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var deepWorkCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Deep Work — a dedicated block", systemImage: "brain.head.profile")
                .font(.headline)
            Text("A single focus timer for longer blocks (15–120 min). Phones down, one thing. It keeps running while you switch tabs, and you can pin a floating always-on-top window. When a block completes, a Win is logged and a notification fires.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Schedule — when to work, what to work on", systemImage: "calendar.badge.clock")
                .font(.headline)
            Text("A weekly grid across 7 days and 4 time slots (Morning / Noon / Afternoon / Evening). Click a cell to plan what you'll work on then; today's column is highlighted.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var mindMapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mini Mind Map — visual idea webs", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.headline)
            Text("Create maps and add child nodes to any node (via + or right-click). Drag nodes to rearrange them; lines follow automatically. Double-click a node to rename or recolor it. Right-click to add a child, change color, or delete a whole branch.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var blogCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Blog — write and publish posts", systemImage: "newspaper.fill")
                .font(.headline)
            Text("Keep your writing here: title, body, and comma-separated tags. Draft or publish with one click (publishing stamps the date), filter by status, search by title/body/tags.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var slackCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Slack — mini channels", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.headline)
            Text("A tiny in-app Slack. Channels have names and colors; post messages with Return, rename or delete a channel from right-click, and delete any message from right-click. A #general channel is created for you.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Calendar — events by day", systemImage: "calendar")
                .font(.headline)
            Text("A month grid of events with times and colors. Click a day to see its events in the side panel; click the + to add, click an event to edit. Navigate months, jump to Today, search events via ⌘K. Set a reminder (5 min to 1 day before) and a local notification fires at the right time — even when the app isn't open.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var yearCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Year — 12 cards, one per month", systemImage: "calendar.circle")
                .font(.headline)
            Text("One card for each month of the year. Click a card and type a single word or phrase to set its focus for that month. A count at the top shows how many of the 12 are filled. Reset clears all 12 back to empty.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("52 Weeks — one card per week of the year", systemImage: "calendar.badge.plus")
                .font(.headline)
            Text("Each card shows its week number, month, and start/end dates. Click a card to add a title and a markdown note — bold, lists and links all work, so paste a YouTube URL or any link and click it straight from the note or the card preview. Search via ⌘K, export/import all 52 weeks as JSON, or reset them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var challengeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Challenges — personal quests", systemImage: "bolt.fill")
                .font(.headline)
            Text("Track any challenge (30-day streaks, no-sugar month, etc.) across Active / Completed / Archived columns. Each challenge has optional start/end dates and a markdown note with clickable links. Move a challenge between columns via the arrows menu.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var roadmapFeatureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Roadmap — plan across quarters", systemImage: "map.fill")
                .font(.headline)
            Text("Plan big work in Planned / In Progress / Done / Deferred columns. Each item has a quarter label, a priority (high/medium/low), and a markdown note with clickable links. Move items between columns via the arrows menu.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var alarmsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Alarms — plain-English reminders", systemImage: "alarm.fill")
                .font(.headline)
            Text("Just type it: \"15 minutes\", \"1 hour\", \"2pm\", \"8.30pm\". Alarms fire as notifications in the background — even on another tab or with the app closed. Quick presets for 15/30/50 min and 1 hour; snooze any alarm by 5 minutes.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var toolsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tools — your toolkit, in order", systemImage: "wrench.and.screwdriver.fill")
                .font(.headline)
            Text("A reorderable list of the tools you rely on. Each has a name, a markdown note (your own self-notes with clickable links), and an optional link that opens in your browser. Reorder with the up/down arrows.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var dreamsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Old Dreams — hopes you carry", systemImage: "moon.stars.fill")
                .font(.headline)
            Text("A place to keep the dreams you don't want to lose. Each dream can hold a title, a markdown note, and a link — reorder them to reflect how much they matter right now.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Feature Requests — for the apps you build", systemImage: "lightbulb.fill")
                .font(.headline)
            Text("Collect what you want to build next. Tag each request with an app, add a markdown note and a link, and move it through Ideas → Planned → In Progress → Done. Every request has a comments feed for thoughts.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var tableTrackerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Table Tracker — spreadsheet-style habits", systemImage: "tablecells")
                .font(.headline)
            Text("A grid tracker: your habits down the rows, the last 14 days across the columns. Click a cell to check the day off, use the arrows to page through time, and create multiple tables. Every row shows how many days it hit.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var airtableCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mini Airtable — your own little database", systemImage: "rectangle.3.group.fill")
                .font(.headline)
            Text("Create tables with typed columns — text, number, checkbox, date — then add rows and edit cells inline. Rename columns, change their type, reorder columns and rows, and delete what you don't need.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var miniVideosCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mini Videos — host your own", systemImage: "video.fill")
                .font(.headline)
            Text("Paste a YouTube link and it plays right in the app with a thumbnail. Each video has a title, a markdown description, and a comments feed with nested reply threads.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var redditCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Reddit — your own little community", systemImage: "bubble.left.and.bubble.right.fill")
                .font(.headline)
            Text("Post threads with a title, markdown body, and a sub tag. Upvote and downvote, and open any post for a comments feed with nested reply threads.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var eventsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Events — subscribe & listen", systemImage: "calendar.badge.clock")
                .font(.headline)
            Text("Follow shows, feeds, or series you care about. Each event holds audio episodes — pick an audio file, add a title and notes, then listen right in the app with play, pause, and a progress bar. Subscribe to keep favourites on top.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var treeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Mini Tree — grow your own branches", systemImage: "tree")
                .font(.headline)
            Text("A tree of ideas. Plant a root and add children to any branch — expand and collapse them, reorder siblings, and add a markdown note to each branch. Deleting a branch removes everything under it.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var faqCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("FAQ — question banks from videos", systemImage: "questionmark.circle.fill")
                .font(.headline)
            Text("Attach a YouTube link and paste the FAQ ChatGPT wrote from its transcript. Lines starting with Q1., Q2., … become questions with their answers. Reorder, edit, or add questions any time.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var celebrationsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Celebrations — collect the wins you replay", systemImage: "party.popper.fill")
                .font(.headline)
            Text("Collect videos worth remembering and replay them right in the app. Take markdown notes at the video level, keep an overview note for the whole collection, and comment on each video.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var longTermCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Long Term Projects — the work you keep coming back to", systemImage: "mountain.2.fill")
                .font(.headline)
            Text("Track big ongoing projects with a status (planning, active, paused, done), an overall progress bar, the next action to take, target dates, and a checkable milestone list. Edit, reorder, and delete projects anytime.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var pendingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Pending — the list that keeps your mind clear", systemImage: "hourglass")
                .font(.headline)
            Text("A simple pending list. Add items, check them done, edit the markdown note, reorder the open ones, and search. Toggle the Done filter to review what you've cleared.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var dietCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Diet — what you ate, day by day", systemImage: "fork.knife")
                .font(.headline)
            Text("Log food by meal — Breakfast, Lunch, Dinner, Snacks — with an optional note. Flip through days, search, and see per-meal counts at a glance.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var familyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Family — the people who matter", systemImage: "person.2.fill")
                .font(.headline)
            Text("Keep your family close: name, relation, an optional birthday (with a days-until countdown that turns orange in the last week), and a markdown note. Reorder as you like.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var followUpCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Follow-ups — don't let things slip", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
            Text("Track things you need to come back to. Set an optional date — Today/Tomorrow chips, overdue items glow red. Check them off when handled.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var inspireCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Inspire — quotes that lift you", systemImage: "sparkles")
                .font(.headline)
            Text("Collect quotes, verses, and lines that move you. Each piece has the words, a source, an optional link, and a markdown note. Bookmark the ones that matter and filter to them.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var howToCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How it works", systemImage: "questionmark.circle")
                .font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                row("1", "Set your daily goal + sub-goal", "Default daily goal is 313, sub-goal 30. Pick any level you're comfortable with.")
                row("2", "Start a session", "Hit Start Session, it times your push so you can see how much you can do.")
                row("3", "Add a comment per post", "Pick the platform (x.com is your focus), tap Add Comment. Optional note + link.")
                row("4", "Watch milestones", "Hit 1% of your sub-goal and you've already won — keep going through 5%, 10%, 25%, 50%, 75%, 100%.")
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .card()
    }

    private var trackerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tracker — daily routines", systemImage: "checklist")
                .font(.headline)
            Text("Track any daily habit with a checkbox or a counter. Included: Namaz (5), Quran (1 para), Zikr (morning/evening, 1000 darood, 1000 astaghfar), Dua, Fasting (Ramadan + Thursdays), Jamaat (3/month · 40/year · Sunday night), Masjid, Family, Parents, Relatives, Parenting, Friends, Health, Business.")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text("• Checkboxes mark done/not done; counters track up to a daily target")
                    .font(.caption)
                Text("• Every tracker has a monthly calendar — tap any day to set count + note")
                    .font(.caption)
                Text("• Manage (gear icon) turns any tracker on or off; add custom trackers with your own icon, color and target")
                    .font(.caption)
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .card()
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Search everything", systemImage: "magnifyingglass")
                .font(.headline)
            Text("Press ⌘K to search across tabs, trackers, people and videos. Type, then click (or Enter) to jump straight to the item.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var thoughtsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Thoughts — don't lose an idea", systemImage: "lightbulb")
                .font(.headline)
            Text("A Trello-style board with three lists — Long-term, This week, Doing. Add thoughts one at a time or paste a batch (one per line), drag them to reorder or move between lists.")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text("• “Pick for me” (🎲) chooses a random thought when you can’t decide")
                    .font(.caption)
                Text("• “Start doing” moves a thought to the Doing list")
                    .font(.caption)
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .card()
    }

    private var winsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Wins — celebrate the small stuff", systemImage: "party.popper")
                .font(.headline)
            Text("A Twitter/X-style timeline of your wins. Newest at the top, older below. Bookmark the ones that matter and filter to them anytime.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("• Just won something? Type it in the compose box and hit Celebrate.")
                    .font(.caption)
        }
        .card()
    }

    private var failsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Fails — lessons to learn from", systemImage: "xmark.seal")
                .font(.headline)
            Text("A Twitter/X-style timeline of things that didn't work. Same shape as wins, but for what missed — so the pattern becomes visible instead of eating you quietly.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("• Just stumbled? Type it in the compose box and hit Log the fail.")
                    .font(.caption)
        }
        .card()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Interstitial Notes — a notebook for 'what am I doing now'", systemImage: "note.text")
                .font(.headline)
            Text("A notebook-paper capture log. When you pause between tasks, jot down what you're working on right now. Each line is timestamped and grouped by day, so you can see the thread of your attention.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("• Quick check-in: type above and hit Log check-in (⌘⏎).")
                    .font(.caption)
        }
        .card()
    }

    private var linksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Links", systemImage: "link")
                .font(.headline)
            Text("A simple list of links. Add one, click to open in your browser, drag to reorder, edit or delete. Perfect for a quick set of bookmarks.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

private var cardsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("313 Cards — one word per card", systemImage: "square.grid.3x3")
                .font(.headline)
            Text("A deck of one-word cards. Every card has a fixed slot number (1–313) and a grid reference (r,c) in its corner. Type a word directly on the card to edit it in place; right-click for the full dialog with 5 related words and a link. Group cards under a name you can search by, and export/import the whole deck as JSON.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("“Add 313 empty” tops the deck up to 313 blank cards to fill in. “Reset” wipes the deck and gives you a fresh set of 313 empty cards. “Hide empty” keeps the grid clean.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var stacksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Stacks — push, pop, and organize", systemImage: "rectangle.stack.fill")
                .font(.headline)
            Text("Color-coded stacks you can push one-word items onto. Type up to 3 words and hit Enter to push to the top; Pop moves the top item to the built-in Uncategorized stack. Double-click any item to open its detail: description, links, and Trello-style comments with the newest at the top. Add and recolor as many stacks as you like.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var pomodoroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Pomodoro", systemImage: "timer")
                .font(.headline)
            Text("Classic focus timer — Focus 25 / Short break 5 / Long break 15. Start with Space. It keeps running while you switch tabs, and you can pin a floating always-on-top window. A notification + sound fires when a session ends, and it auto-switches to a break.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var sprintsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sprints — stories & tasks", systemImage: "flag")
                .font(.headline)
            Text("Time-boxed sprints (30 min / 1 hr / 2 hrs). Add stories, break each story into tasks, and move stories between sprints. Marking a task or an entire sprint done automatically adds a Win to your feed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var videosCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Videos board", systemImage: "play.rectangle")
                .font(.headline)
            Text("Save videos you want to watch on a Trello-style board. Add YouTube, X video or Instagram reel links.")
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text("Lists: Holding (queue) · Urgent · Important · Daily Watch · Weekly Watch · Monthly Watch")
                    .font(.caption)
                Text("• Search filters across title, notes, links and comments")
                    .font(.caption)
                Text("• Drag cards between lists and reorder them")
                    .font(.caption)
                Text("• Double-click a card to edit, add comments, or open the video in your browser")
                    .font(.caption)
            }
            .padding(10)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        }
        .card()
    }

    private var shortcutsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Keyboard shortcuts", systemImage: "keyboard")
                .font(.headline)
            HStack(spacing: 24) {
                shortcutRow("⌘ N", "Add Comment")
                shortcutRow("⇧ ⌘ S", "Start / End Session")
                shortcutRow("⌘ K", "Search Everything")
            }
        }
        .card()
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your data", systemImage: "internaldrive")
                .font(.headline)
            Text("Everything is stored locally in a SQLite database on this Mac — nothing leaves your machine.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(showDataPath ? DatabaseManager.shared.databaseURL.path : "Show database path") {
                showDataPath.toggle()
            }
            .buttonStyle(.link)
            .help("Local SQLite file")
        }
        .card()
    }

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Backup & Restore", systemImage: "externaldrive.badge.checkmark")
                .font(.headline)
            Text("Everything lives in one SQLite file. Back it up anytime, and restore from any previous backup to bring your data back — nothing is ever lost.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button {
                    exportBackup()
                } label: {
                    Label("Backup now…", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .help("Save a full copy of your data as a .sqlite file")
                Button {
                    importBackup()
                } label: {
                    Label("Restore…", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.bordered)
                .help("Replace your data from a previous backup .sqlite file")
                if !backupMessage.isEmpty {
                    Text(backupMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }

    private func exportBackup() {
        let panel = NSSavePanel()
        panel.title = "Back up Comment Tracker data"
        panel.nameFieldStringValue = "CommentTracker-backup-\(backupStamp()).sqlite"
        panel.allowedContentTypes = [.data]
        if panel.runModal() == .OK, let url = panel.url {
            backupMessage = store.backup(to: url) ? "Backup saved ✓" : "Backup failed"
        }
    }

    private func importBackup() {
        let panel = NSOpenPanel()
        panel.title = "Choose a backup to restore"
        panel.allowedContentTypes = [.data]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Restore this backup?"
        alert.informativeText = "Your current data will be replaced with the backup. Your current data is kept as a safety copy (comments-pre-restore.sqlite). This cannot be undone."
        alert.addButton(withTitle: "Restore")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        backupMessage = store.restore(from: url) ? "Restored ✓" : "Restore failed"
    }

    private func backupStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }

    private var roadmapCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Roadmap", systemImage: "map")
                .font(.headline)
            Text("v1.0 · tracking core — today, sub-goals, sessions, milestones, local SQLite. Next up: streaks, reminders, exports, menu-bar widget. See ROADMAP.md in the repo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About", systemImage: "info.circle")
                .font(.headline)
            Text("Comment Tracker v1.0.0 · Swift + SwiftUI + SQLite")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .card()
    }

    private func row(_ n: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.blue))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func shortcutRow(_ keys: String, _ label: String) -> some View {
        HStack(spacing: 8) {
            Text(keys)
                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 6))
            Text(label)
                .font(.subheadline)
        }
    }
}

private struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View {
        modifier(CardModifier())
    }
}
