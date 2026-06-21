# Discoveries

Running notes from investigation spikes. Each entry summarises what was learned, what worked, and what to watch out for. Full architectural decisions are in `Docs/ADR/`.

---

## Foreground Application Detection

**Spike date:** 2026-06-21
**ADR:** [ADR-002](ADR/ADR-002-foreground-application-detection-strategy.md)

### What works

`NSWorkspace.shared.frontmostApplication` returns the active app as `NSRunningApplication`, giving:

- `localizedName` — display name (e.g. "Xcode")
- `bundleIdentifier` — reverse-DNS ID (e.g. "com.apple.dt.Xcode")
- `processIdentifier` — Unix PID
- `icon` — `NSImage` of the app icon
- `executableURL` — path to the binary

Subscribing to `NSWorkspace.didActivateApplicationNotification` on `NSWorkspace.shared.notificationCenter` delivers an event every time the active app changes. No polling required.

### Permissions

None. Works inside App Sandbox without any additional entitlements.

### Watch out for

- **Chronicle reports itself.** When Chronicle is the frontmost app, `frontmostApplication` returns Chronicle. Production code will need to decide whether to record or suppress this.
- **No window titles.** `NSWorkspace` cannot see window titles. That requires the Accessibility API and a user permission prompt — addressed separately when window tracking is prioritised.
- **One app at a time.** Multiple windows of the same app are indistinguishable without Accessibility.
- **System UI is invisible.** Spotlight, the Dock, and menu bar interactions do not appear as running applications.

---

## Idle Detection

**Spike date:** 2026-06-21
**ADR:** [ADR-003](ADR/ADR-003-idle-detection-strategy.md)

### What works

`CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~UInt32(0))!)` returns the number of seconds since any HID input event (keyboard, mouse, trackpad, scroll, stylus). Polled every second with a `Timer`.

The special event type value `~UInt32(0)` is equivalent to `kCGAnyInputEventType` and covers all input categories in a single call.

### Permissions

None. Works inside App Sandbox without any additional entitlements.

### Watch out for

- **Poll-based, not event-driven.** There is no callback when the user goes idle. A 1-second poll is sufficient for timeline purposes.
- **Accessibility input resets the timer.** Synthetic events from screen readers or remote control software count as activity. This is correct behaviour.
- **Screen lock accumulates idle time.** When the display sleeps or the screen locks, idle time continues to grow. This is the desired behaviour — lock events should appear as idle periods in the timeline.
- **Threshold choice matters.** For the spike the threshold was set to 30 seconds for easy observation. Production default should be 5 minutes (300 seconds), configurable by the user.

### Alternatives considered

| API | Verdict |
|-----|---------|
| `IOKit IOHIDGetIdleTime` | Same data source, more complex Swift bridging, no benefit |
| `NSEvent.addGlobalMonitorForEvents` | Event-driven but requires Accessibility permission — not suitable |

---

## Open Questions

- **Idle threshold:** Should the user be able to configure the idle threshold? The recommended default is 5 minutes.
- **Self-recording:** Should Chronicle record its own window as an activity entry? Probably not by default.
- **Window title tracking:** Requires Accessibility permission. Worth exploring as a separate spike when window-level detail becomes a priority.
- **Screen lock events:** Can Chronicle detect screen lock/unlock transitions explicitly, or should it infer them from idle duration? (`NSWorkspace` posts `NSWorkspace.screensDidSleepNotification` and `NSWorkspace.screensDidWakeNotification` — worth investigating.)
