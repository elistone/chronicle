# ADR-002: Foreground Application Detection Strategy

Status: Accepted

## Context

Chronicle needs to detect which application the user is currently working in.

This ADR documents findings from a proof-of-concept that validates active application detection on macOS before committing to a production implementation.

## Decision

Use `NSWorkspace.shared.frontmostApplication` combined with `NSWorkspace.didActivateApplicationNotification` for event-driven detection of the currently active application.

## Approach

`NSWorkspace` (AppKit) exposes the frontmost application as an `NSRunningApplication` instance, which provides:

- `localizedName` — display name (e.g. "Safari")
- `bundleIdentifier` — reverse-DNS identifier (e.g. "com.apple.Safari")
- `processIdentifier` — Unix PID
- `icon` — the application's icon as `NSImage`
- `executableURL` — path to the binary

Subscribing to `NSWorkspace.didActivateApplicationNotification` (on `NSWorkspace.shared.notificationCenter`) delivers a notification each time the active application changes. This is event-driven and requires no polling.

## Permissions

No special entitlements or user-facing permission prompts are required for basic active application detection. The App Sandbox does not block `NSWorkspace.shared.frontmostApplication`.

## Limitations

### Window titles require Accessibility

`NSWorkspace` provides no access to window titles. Detecting the active window title (e.g. the open file in Xcode or the tab in Safari) requires the Accessibility API (`AXUIElement`), which requires:

1. The user grants Chronicle access under System Settings → Privacy & Security → Accessibility.
2. The app must request this at runtime via `AXIsProcessTrustedWithOptions`.

This is a significant UX consideration and must be handled carefully given Chronicle's privacy principles.

### Self-reporting when Chronicle is active

When Chronicle is the frontmost application, `frontmostApplication` returns Chronicle itself. Production code should decide whether to record Chronicle activity or suppress it.

### App Sandbox is compatible

`ENABLE_APP_SANDBOX = YES` is compatible with `NSWorkspace` frontmost app detection. No additional entitlements are needed.

### No window-level detail without Accessibility

The API reports one application at a time. Multiple windows of the same application are indistinguishable without Accessibility.

### System UI elements not reported

Spotlight, menu bar interactions, and the Dock do not appear as running applications and will not be captured.

## Consequences

- Active application name and bundle ID can be captured without any user permission prompt.
- Window title tracking requires Accessibility permission — this should be addressed in a separate ADR when that feature is prioritised.
- The notification-based approach is efficient; no timer or polling is needed.
- A future production implementation should filter Chronicle itself from its own activity log.
