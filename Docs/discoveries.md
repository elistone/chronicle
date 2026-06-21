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

## Window Title Detection

**Spike date:** 2026-06-21

### What works

`AXUIElementCreateApplication(pid)` creates an Accessibility element for any running app given its PID (available from `NSRunningApplication.processIdentifier`).

From there, two attribute reads yield the focused window title:

```swift
// 1. Get the focused window element
var windowRef: CFTypeRef?
AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &windowRef)

// 2. Read its title
var titleRef: CFTypeRef?
AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)
let title = titleRef as? String
```

The approach is polled (1-second `Timer`) and also responds instantly to `NSWorkspace.didActivateApplicationNotification` for app switches.

### Permissions

**Accessibility permission is required.** The user must grant access under System Settings → Privacy & Security → Accessibility.

- `AXIsProcessTrusted()` — checks current permission state (no prompt)
- `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])` — checks and opens System Settings if not granted

No special entitlements are needed in the app sandbox; user consent via System Settings is sufficient on modern macOS.

### What titles look like in practice

Results vary considerably by application:

| App | Window title returned |
|-----|-----------------------|
| Safari | Page title (e.g. "GitHub - Chronicle") |
| Chrome | Page title + " - Google Chrome" |
| Xcode | Filename + project (e.g. "ContentView.swift — Chronicle") |
| Terminal | Current directory or running command |
| VS Code | Filename + folder (e.g. "ContentView.swift — Chronicle") |
| Finder | Folder name (e.g. "Documents") |
| System Settings | Current pane name (e.g. "Privacy & Security") |

### Watch out for

- **Permission required — and it must be granted before use.** Unlike app detection, this cannot work silently. The user has to make an explicit choice.
- **Titles are not consistent across apps.** Some apps append their own name; some return an empty string for untitled windows. Production code will need normalisation.
- **No title for some windows.** Modal dialogs and panels sometimes return an empty string or `kAXTitleAttribute` returns `AXError.noValue`.
- **Accessibility permission can be revoked.** The app should check `AXIsProcessTrusted()` on each poll rather than caching the result.
- **`kAXFocusedWindowAttribute` vs `kAXMainWindowAttribute`.** `kAXFocusedWindow` is the window with keyboard focus; `kAXMainWindow` is the app's main (frontmost) window. They differ when, e.g., a find bar or panel has focus. `kAXFocusedWindow` is the more useful signal for Chronicle.
- **AXError.cannotComplete.** This error appears transiently during app launch or when the target process is unresponsive. Graceful handling (skip and retry next poll) is sufficient.

### Sandbox and Accessibility — key finding

`AXIsProcessTrustedWithOptions` with the prompt flag is **suppressed by the App Sandbox** — it does not show a system dialog or open System Settings. The app must open System Settings directly via `NSWorkspace.shared.open()` with the `x-apple.systempreferences:` URL scheme instead.

`AXIsProcessTrustedWithOptions` should still be called (without relying on the prompt) because it **registers the app** with macOS so it appears in the System Settings Accessibility list. Without this call, Chronicle will not show up in the list at all.

**App Sandbox + Accessibility works technically** — once the user grants permission in System Settings, `AXIsProcessTrusted()` returns `true` and AX attribute reads succeed. The sandbox does not block the API calls after consent is granted.

**App Sandbox + App Store distribution does not work** — Apple's App Store review policy prohibits Accessibility API use in sandboxed apps. This is a policy restriction, not a technical one.

**Implication for Chronicle:** If Chronicle targets the Mac App Store, window title detection via Accessibility is not an option. Direct distribution (outside the App Store) is required to use this feature.

**Spike validation approach:** The App Sandbox is disabled in the Debug build configuration (`ENABLE_APP_SANDBOX = NO`) to allow the spike to be validated cleanly. The sandbox remains enabled in Release builds. This is a spike-only change — if window title tracking is productionised, the sandbox situation must be resolved before shipping.

### Alternatives considered

| API | Verdict |
|-----|---------|
| `CGWindowListCopyWindowInfo` | Returns all window titles without Accessibility permission, but is deprecated in macOS 14+ and returns titles for all windows, not just the focused one |
| `NSAccessibility` Swift overlay | Thin wrapper over the same `AXUIElement` C API — no practical advantage for this use case |

### CGWindowListCopyWindowInfo note

`CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)` can return window titles without Accessibility permission, but:
- It was deprecated in macOS 14 (Sonoma) with no direct replacement
- It returns all visible windows, requiring filtering to find the focused one
- The focused window cannot be reliably identified without either Accessibility or cross-referencing with `NSWorkspace.frontmostApplication` PID
- Its future availability is uncertain — not safe to rely on

---

## Open Questions

- **Idle threshold:** Should the user be able to configure the idle threshold? The recommended default is 5 minutes.
- **Self-recording:** Should Chronicle record its own window as an activity entry? Probably not by default.
- **Screen lock events:** Can Chronicle detect screen lock/unlock transitions explicitly, or should it infer them from idle duration? (`NSWorkspace` posts `NSWorkspace.screensDidSleepNotification` and `NSWorkspace.screensDidWakeNotification` — worth investigating.)
- **Accessibility permission UX:** How and when should Chronicle ask for Accessibility permission? On first launch, on first use of window tracking, or as an optional feature the user explicitly enables? Given Chronicle's privacy principles, explicit opt-in is likely the right default.
- **Window title normalisation:** Apps format titles inconsistently (e.g. some append " — AppName", some don't). Should Chronicle strip app names from titles? A normalisation pass would improve data quality.
- **`CGWindowListCopyWindowInfo` deprecation:** Now that it is deprecated in macOS 14+, there is no permission-free path to window titles. Accessibility is the only viable route going forward.
