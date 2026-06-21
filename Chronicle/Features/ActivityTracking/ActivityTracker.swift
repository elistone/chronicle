//
//  ActivityTracker.swift
//  Chronicle
//

import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

final class ActivityTracker {

    /// Called on the main thread each time a new ActivityEvent is produced.
    /// Assign before calling start().
    var onEvent: ((ActivityEvent) -> Void)?

    private let idleThreshold: TimeInterval
    private var timer: Timer?
    private var appSwitchObserver: Any?

    // Transition state — enough to detect changes, nothing more.
    private var currentBundleID: String?
    private var currentWindowTitle: String?
    private var isCurrentlyIdle = false

    init(idleThreshold: TimeInterval = 300) {
        self.idleThreshold = idleThreshold
    }

    // MARK: - Lifecycle

    func start() {
        captureInitialState()
        appSwitchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppSwitch()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let appSwitchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appSwitchObserver)
        }
        appSwitchObserver = nil
        currentBundleID = nil
        currentWindowTitle = nil
        isCurrentlyIdle = false
    }

    // MARK: - App switch

    private func handleAppSwitch() {
        guard let app = frontmostTrackedApp() else { return }

        let appName = app.localizedName ?? "Unknown"
        let bundleID = app.bundleIdentifier ?? ""
        let title = readWindowTitle(for: app)

        emit(.appActivated(appName: appName, bundleID: bundleID, windowTitle: title))

        currentBundleID = bundleID
        currentWindowTitle = title
    }

    // MARK: - Poll

    private func poll() {
        pollIdle()
        if !isCurrentlyIdle {
            pollWindowTitle()
        }
    }

    private func pollIdle() {
        let anyEvent = CGEventType(rawValue: ~UInt32(0))!
        let seconds = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)

        if seconds >= idleThreshold, !isCurrentlyIdle {
            isCurrentlyIdle = true
            emit(.idleStarted)
        } else if seconds < idleThreshold, isCurrentlyIdle {
            isCurrentlyIdle = false
            emit(.idleEnded)
        }
    }

    private func pollWindowTitle() {
        guard let app = frontmostTrackedApp() else { return }
        guard let title = readWindowTitle(for: app), title != currentWindowTitle else { return }

        emit(.windowTitleChanged(windowTitle: title))
        currentWindowTitle = title
    }

    // MARK: - Helpers

    /// Establishes baseline state on start so the first poll has accurate values to diff against.
    /// Does not emit any events — Chronicle may have been stopped and restarted mid-session.
    private func captureInitialState() {
        guard let app = frontmostTrackedApp() else { return }
        currentBundleID = app.bundleIdentifier
        currentWindowTitle = readWindowTitle(for: app)
    }

    private func frontmostTrackedApp() -> NSRunningApplication? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return nil
        }
        return app
    }

    private func readWindowTitle(for app: NSRunningApplication) -> String? {
        guard AXIsProcessTrusted() else { return nil }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var windowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
              let windowRef else { return nil }

        var titleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(windowRef as! AXUIElement, kAXTitleAttribute as CFString, &titleRef) == .success,
              let title = titleRef as? String, !title.isEmpty else { return nil }

        return title
    }

    private func emit(_ kind: ActivityEvent.Kind) {
        let event = ActivityEvent(id: UUID(), timestamp: Date(), kind: kind)
        onEvent?(event)
    }
}
