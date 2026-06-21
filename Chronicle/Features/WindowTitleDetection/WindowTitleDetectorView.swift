//
//  WindowTitleDetectorView.swift
//  Chronicle
//
//  Spike: validates window title detection via AXUIElement (Accessibility API).
//  Not intended for production use as-is.
//

import SwiftUI
import Combine
import AppKit
import ApplicationServices

final class WindowTitleDetector: ObservableObject {
    @Published var windowTitle: String = "—"
    @Published var appName: String = "—"
    @Published var axError: String? = nil
    @Published var isPermissionGranted: Bool = false

    private var timer: Timer?
    private var appSwitchObserver: Any?

    func start() {
        checkPermission()
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.poll()
        }
        appSwitchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let appSwitchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appSwitchObserver)
        }
    }

    func openAccessibilitySettings() {
        // Register the app with macOS so it appears in the Accessibility list.
        // The prompt itself is suppressed when sandboxed, but the registration still happens.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        // Open System Settings directly — the reliable path in all configurations.
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkPermission() {
        isPermissionGranted = AXIsProcessTrusted()
    }

    private func poll() {
        checkPermission()

        guard isPermissionGranted else {
            windowTitle = "—"
            axError = nil
            return
        }

        guard let app = NSWorkspace.shared.frontmostApplication,
              app.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            windowTitle = "—"
            axError = nil
            return
        }

        appName = app.localizedName ?? "Unknown"

        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var windowRef: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &windowRef)

        guard windowResult == .success, let windowRef else {
            windowTitle = "—"
            axError = axErrorDescription(windowResult)
            return
        }

        let axWindow = windowRef as! AXUIElement

        var titleRef: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef)

        guard titleResult == .success, let title = titleRef as? String, !title.isEmpty else {
            windowTitle = "—"
            axError = titleResult == .success ? "Empty title" : axErrorDescription(titleResult)
            return
        }

        windowTitle = title
        axError = nil
    }

    private func axErrorDescription(_ error: AXError) -> String? {
        switch error {
        case .success: return nil
        case .actionUnsupported: return "AXError: actionUnsupported"
        case .attributeUnsupported: return "AXError: attributeUnsupported"
        case .cannotComplete: return "AXError: cannotComplete"
        case .failure: return "AXError: failure"
        case .illegalArgument: return "AXError: illegalArgument"
        case .invalidUIElement: return "AXError: invalidUIElement"
        case .invalidUIElementObserver: return "AXError: invalidUIElementObserver"
        case .noValue: return "AXError: noValue"
        case .notEnoughPrecision: return "AXError: notEnoughPrecision"
        case .notImplemented: return "AXError: notImplemented"
        case .notificationAlreadyRegistered: return "AXError: notificationAlreadyRegistered"
        case .notificationNotRegistered: return "AXError: notificationNotRegistered"
        case .notificationUnsupported: return "AXError: notificationUnsupported"
        default: return "AXError: \(error.rawValue)"
        }
    }
}

struct WindowTitleDetectorView: View {
    @StateObject private var detector = WindowTitleDetector()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            permissionRow
            Divider()
            infoRow("App", value: detector.appName)
            infoRow("Window title", value: detector.windowTitle)
            if let error = detector.axError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(24)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { detector.start() }
        .onDisappear { detector.stop() }
    }

    private var permissionRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(detector.isPermissionGranted ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(detector.isPermissionGranted ? "Accessibility: granted" : "Accessibility: not granted")
                .font(.caption)
            if !detector.isPermissionGranted {
                Spacer()
                Button("Open Settings") {
                    detector.openAccessibilitySettings()
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            Text(value)
                .font(.body)
                .lineLimit(3)
        }
    }
}

#Preview {
    WindowTitleDetectorView()
        .padding()
        .frame(width: 400)
}
