# Proposal: ActivityEvent Model

Status: Approved

---

## Context

Chronicle needs a domain model to represent the activity information it can collect. Three investigation spikes have been completed and validated:

- Active application detection — no permission required
- Window title detection — Accessibility permission required
- Idle detection — no permission required

This proposal defines the domain model for representing that information before persistence is designed.

---

## What has been validated

The following information can be collected reliably on macOS.

**From active application detection:**

- App display name (`NSRunningApplication.localizedName`)
- Bundle identifier (`NSRunningApplication.bundleIdentifier`)
- App switches are event-driven via `NSWorkspace.didActivateApplicationNotification`

**From window title detection:**

- The title of the focused window, read via `kAXTitleAttribute` on `AXUIElement`
- Present only when Accessibility permission is granted
- Within-app title changes (e.g. switching files in Xcode, tabs in Safari) are detectable by polling

**From idle detection:**

- The moment the idle threshold is crossed (active → idle)
- The moment activity resumes (idle → active)
- Detected by polling `CGEventSource.secondsSinceLastEventType` every second

**What has not been validated and is excluded from this model:**

| Information | Reason |
|---|---|
| `processIdentifier` | Changes on every app launch; meaningless for persistence |
| `executableURL`, `icon` | UI concerns, not domain data |
| Git repository / branch | Not yet investigated |
| Jira / ticket references | Not yet investigated |
| Screen lock / wake transitions | Identified as an open question; not yet validated |
| AI metadata | Not yet investigated |

---

## Approaches considered

### Approach 1 — Event-based

Each record describes a transition that occurred at a specific moment in time.

```
appActivated       { timestamp, appName, bundleID, windowTitle? }
windowTitleChanged { timestamp, windowTitle }
idleStarted        { timestamp }
idleEnded          { timestamp }
```

Each event is written once, is immutable, and describes exactly one thing that happened.

**Strengths**

- Faithful to the underlying APIs. `NSWorkspace.didActivateApplicationNotification` is natively a notification. Idle threshold crossing is a transition. The model reflects what the system actually delivers.
- Append-only. Nothing is ever updated. Simple to persist and simple to reason about.
- Resilient to crashes. The last event before an unexpected quit is still a valid, complete record. The end time of the current period is unknown, but no data is corrupted.
- Handles gaps honestly. If Chronicle was not running between two timestamps, there are simply no events for that window. No placeholder or sentinel value is needed.
- Efficient storage. Only changes are written. An uninterrupted hour of Xcode work produces two records: one `appActivated` at the start and one event (an `idleStarted` or another `appActivated`) when something changes.

**Weaknesses**

- Answering "how long was I in Xcode?" requires scanning adjacent events and computing time differences. It is not a direct lookup.
- "What was I doing at time T?" requires finding the most recent event before T — a range query rather than a point lookup.
- Two event kinds relate to application context (`appActivated` and `windowTitleChanged`). A consumer reading the stream must maintain a cursor tracking the current app.

---

### Approach 2 — Snapshot-based

Each record describes the complete observable state at a point in time.

```
snapshot { timestamp, appName, bundleID, windowTitle?, isIdle }
```

Written whenever anything changes, or on a fixed polling interval.

**Strengths**

- "What was I doing at time T?" is a direct lookup.
- Each record is self-contained with no dependency on adjacent records.

**Weaknesses**

- Fights the underlying APIs. `NSWorkspace.didActivateApplicationNotification` delivers transitions, not states. Producing snapshots from it means converting events into state so they can be converted back into transitions when queried — an unnecessary round-trip.
- Creates redundancy. An hour of uninterrupted Xcode work with 1-second snapshots produces 3,600 nearly identical records. Even writing only on change, two interleaved signals (app changes and title changes) produce snapshots at different rates.
- Transition timing is imprecise for polled signals. Idle start is known to within one second. An event model has the same resolution but is explicit about it; the snapshot model makes the imprecision inherent.
- Does not represent gaps cleanly. An absence of snapshots is ambiguous — Chronicle may have been stopped, or the machine may have been idle.
- `isIdle` as a boolean field cannot express when an idle period began without scanning backwards. Idle is a transition, not a persistent state.

---

## Recommendation

**Use the event-based model.**

The primary reason is faithfulness to the sources. App changes arrive as notifications. Idle transitions are detected as threshold crossings. These are events. The event model records them directly, without the intermediate step of converting transitions into state and then back into transitions to answer Chronicle's questions.

The snapshot model's main advantage — direct point-in-time lookup — is not a requirement Chronicle has today. Chronicle's primary output is a timeline of spans ("I was in Xcode from 10:05 to 10:47"). Spans are computed from pairs of adjacent events, not from a scan of snapshots. The event model is the correct primitive for that output.

The event model is also simpler to implement correctly: write a record when something changes, never update it, never delete it.

---

## Proposed model

```
ActivityEvent
  id          UUID
  timestamp   Date
  kind        one of:
                appActivated(appName, bundleID, windowTitle?)
                windowTitleChanged(windowTitle)
                idleStarted
                idleEnded
```

### `appActivated(appName, bundleID, windowTitle?)`

Fires when `NSWorkspace.didActivateApplicationNotification` delivers a new application.

- `appName: String` — display name from `NSRunningApplication.localizedName`. Stored for human-readable display without requiring a lookup at read time.
- `bundleID: String` — reverse-DNS identifier from `NSRunningApplication.bundleIdentifier`. Stable across launches. The reliable key for grouping and querying by application.
- `windowTitle: String?` — the title of the focused window at the moment of the app switch, read from `kAXTitleAttribute`. Optional because Accessibility permission may not be granted, or the app may expose no title.

### `windowTitleChanged(windowTitle)`

Fires when the window title changes within the currently active application — switching files in Xcode, switching tabs in Safari — without the application itself changing.

- `windowTitle: String` — the new title. Non-optional because this event only fires when a concrete, non-empty title has been detected.

This event only occurs when Accessibility permission is granted. When permission is absent, `appActivated` alone captures the title at the moment of each app switch; within-app changes are not recorded.

### `idleStarted`

Fires when `CGEventSource.secondsSinceLastEventType` crosses the configured idle threshold. No payload beyond the timestamp. The application that was active when the user went idle is derivable from the most recent preceding `appActivated` event.

### `idleEnded`

Fires when input resumes after an idle period. No payload beyond the timestamp. Idle duration is derivable from the `idleStarted` timestamp immediately preceding it in the sequence.

---

## Trade-offs in this design

**`windowTitle` on `appActivated` and as a separate `windowTitleChanged`**

`windowTitle` appears on `appActivated` because switching to an app and reading its title are simultaneous. Capturing it at the moment of switch means the model has title context from the start of each app session, even if within-app tracking is disabled or unavailable. Omitting it from `appActivated` and relying solely on `windowTitleChanged` would mean no title is recorded for apps where the title never changes after the initial switch.

`windowTitleChanged` is kept as a separate event kind because within-app title changes are real, distinct transitions — "the user switched from ContentView.swift to ActivityEvent.swift" is meaningfully different from "the user switched from Xcode to Safari". Keeping them separate allows a timeline to represent both.

**`appName` is redundant given `bundleID`**

Strictly, `appName` can be resolved from `bundleID` at display time. It is included because it makes records self-describing — useful for debugging, human-readable exports, and future integrations. The storage cost is negligible.

**`idleDuration` is omitted from `idleEnded`**

Duration is derivable from `idleStarted` and `idleEnded` timestamps. Storing it would be a persistence convenience, not a modelling requirement. That decision belongs with the persistence layer when it is designed.

**An unclosed `idleStarted` at end of session is a valid terminal state**

If Chronicle stops while the user is idle — app quit, machine shut down, end of day — the last event in the stream is an `idleStarted` with no following `idleEnded`. This is correct: the end of the idle period is unknown, and the model should not fabricate it. Consumers treat an unclosed idle as "idle from T until Chronicle next ran".

---

## Example event stream

The following represents a realistic developer workday. Accessibility permission is granted throughout.

```
TIME      KIND                  APP         BUNDLE ID                    WINDOW TITLE
────────  ────────────────────  ──────────  ───────────────────────────  ────────────────────────────────────────────────
09:02:14  appActivated          Mail        com.apple.mail               Inbox (3) — hi@eli.dev
09:06:33  appActivated          Slack       com.tinyspeck.slackmacgap    Slack | #general
09:08:47  windowTitleChanged    –           –                            Slack | #dev-chronicle
09:11:02  appActivated          Xcode       com.apple.dt.Xcode           ContentView.swift — Chronicle
09:18:29  windowTitleChanged    –           –                            IdleDetectorView.swift — Chronicle
09:26:54  windowTitleChanged    –           –                            WindowTitleDetectorView.swift — Chronicle
09:41:07  appActivated          Safari      com.apple.Safari             AXUIElement - Apple Developer Documentation
09:44:22  windowTitleChanged    –           –                            kAXFocusedWindowAttribute - Apple Developer Documentation
09:47:38  appActivated          Xcode       com.apple.dt.Xcode           WindowTitleDetectorView.swift — Chronicle
09:48:12  windowTitleChanged    –           –                            ContentView.swift — Chronicle
10:03:41  appActivated          Terminal    com.apple.Terminal           zsh — chronicle — 120×40
10:04:09  windowTitleChanged    –           –                            git diff — chronicle — 120×40
10:06:22  appActivated          Xcode       com.apple.dt.Xcode           ContentView.swift — Chronicle
10:31:05  idleStarted           –           –                            –
10:36:48  idleEnded             –           –                            –
10:36:51  appActivated          Xcode       com.apple.dt.Xcode           ContentView.swift — Chronicle
10:52:17  windowTitleChanged    –           –                            ActivityEvent.swift — Chronicle
11:04:33  windowTitleChanged    –           –                            ContentView.swift — Chronicle
11:19:44  appActivated          Safari      com.apple.Safari             GitHub — elistone/chronicle
11:21:09  windowTitleChanged    –           –                            Spike: window title detection · Pull Request
11:23:55  appActivated          Xcode       com.apple.dt.Xcode           ActivityEvent.swift — Chronicle
12:00:02  idleStarted           –           –                            –
13:00:17  idleEnded             –           –                            –
13:00:19  appActivated          Xcode       com.apple.dt.Xcode           ActivityEvent.swift — Chronicle
13:08:44  windowTitleChanged    –           –                            ActivityEventTests.swift — Chronicle
13:41:22  appActivated          Safari      com.apple.Safari             SQLite - Apple Developer Documentation
13:45:01  appActivated          Xcode       com.apple.dt.Xcode           ActivityEvent.swift — Chronicle
14:00:08  appActivated          Zoom        us.zoom.xos                  Sprint Planning — Zoom
14:32:19  idleStarted           –           –                            –
14:33:41  idleEnded             –           –                            –
14:33:42  appActivated          Zoom        us.zoom.xos                  Sprint Planning — Zoom
15:01:17  appActivated          Xcode       com.apple.dt.Xcode           ActivityEvent.swift — Chronicle
15:14:09  windowTitleChanged    –           –                            ContentView.swift — Chronicle
15:44:03  windowTitleChanged    –           –                            ActivityEvent.swift — Chronicle
16:22:38  appActivated          Safari      com.apple.Safari             GitHub — elistone/chronicle
16:24:55  appActivated          Xcode       com.apple.dt.Xcode           ActivityEvent.swift — Chronicle
17:03:14  idleStarted           –           –                            –
```

### Reading the stream

`windowTitleChanged` events carry no app name or bundle ID. The current application is established by the most recent `appActivated` event. A consumer maintains a cursor: current app = last `appActivated`. This is efficient and non-redundant.

`idleStarted` and `idleEnded` carry no app context. The app that was active when the user went idle is the app from the most recent `appActivated` before the `idleStarted`.

The final event is an unclosed `idleStarted` at 17:03. The developer left their desk. This is a valid terminal state requiring no special handling.

### Derived time-in-app (not stored — computed on read)

```
APPLICATION    ACTIVE TIME
─────────────  ───────────
Xcode          ~5h 14m
Zoom           ~59m
Safari         ~24m
Mail           ~4m
Slack          ~4m
Terminal       ~2m

Idle           ~1h 07m  (coffee 5m, lunch 1h, Zoom-listener 1m)
```

### Supporting Jira worklog generation

The window titles provide the context needed to generate a meaningful worklog entry:

```
Chronicle — 5h 14m
  ActivityEvent.swift     primary focus, afternoon
  ContentView.swift       morning and afternoon
  ActivityEventTests.swift  13:08–13:41
Sprint Planning — 59m
```

This is richer than "I was in Xcode for 5 hours" and is derived entirely from the event stream with no additional data collection.

---

## Final recommendation

Adopt the event-based `ActivityEvent` model with four event kinds: `appActivated`, `windowTitleChanged`, `idleStarted`, and `idleEnded`.

The model is grounded in what has been validated through investigation spikes. It contains no speculative fields. It represents the full information Chronicle can currently collect, handles optional Accessibility permission gracefully, and produces an event stream from which time-per-app, timeline spans, and Jira worklog entries can all be derived.

The persistence schema — how these events are stored in SQLite — is a separate decision and should be designed after this model is approved.
