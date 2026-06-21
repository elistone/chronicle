//
//  ActivityEventTests.swift
//  ChronicleTests
//

import Testing
import Foundation
@testable import Chronicle

@Suite("ActivityEvent")
struct ActivityEventTests {

    @Test("stores id and timestamp")
    func storesIdentity() {
        let id = UUID()
        let timestamp = Date()
        let event = ActivityEvent(id: id, timestamp: timestamp, kind: .idleStarted)

        #expect(event.id == id)
        #expect(event.timestamp == timestamp)
    }

    @Test("appActivated stores app name, bundle ID, and window title")
    func appActivatedWithTitle() {
        let event = ActivityEvent(
            id: UUID(),
            timestamp: Date(),
            kind: .appActivated(
                appName: "Xcode",
                bundleID: "com.apple.dt.Xcode",
                windowTitle: "ContentView.swift — Chronicle"
            )
        )

        guard case .appActivated(let appName, let bundleID, let windowTitle) = event.kind else {
            Issue.record("Expected appActivated kind")
            return
        }

        #expect(appName == "Xcode")
        #expect(bundleID == "com.apple.dt.Xcode")
        #expect(windowTitle == "ContentView.swift — Chronicle")
    }

    @Test("appActivated allows nil window title when Accessibility is unavailable")
    func appActivatedWithoutTitle() {
        let event = ActivityEvent(
            id: UUID(),
            timestamp: Date(),
            kind: .appActivated(
                appName: "Xcode",
                bundleID: "com.apple.dt.Xcode",
                windowTitle: nil
            )
        )

        guard case .appActivated(_, _, let windowTitle) = event.kind else {
            Issue.record("Expected appActivated kind")
            return
        }

        #expect(windowTitle == nil)
    }

    @Test("windowTitleChanged stores the new title")
    func windowTitleChanged() {
        let event = ActivityEvent(
            id: UUID(),
            timestamp: Date(),
            kind: .windowTitleChanged(windowTitle: "ActivityEvent.swift — Chronicle")
        )

        guard case .windowTitleChanged(let title) = event.kind else {
            Issue.record("Expected windowTitleChanged kind")
            return
        }

        #expect(title == "ActivityEvent.swift — Chronicle")
    }

    @Test("idleStarted carries no additional data")
    func idleStarted() {
        let event = ActivityEvent(id: UUID(), timestamp: Date(), kind: .idleStarted)
        #expect(event.kind == .idleStarted)
    }

    @Test("idleEnded carries no additional data")
    func idleEnded() {
        let event = ActivityEvent(id: UUID(), timestamp: Date(), kind: .idleEnded)
        #expect(event.kind == .idleEnded)
    }

    @Test("events with the same id, timestamp, and kind are equal")
    func equalityMatch() {
        let id = UUID()
        let timestamp = Date()
        let a = ActivityEvent(id: id, timestamp: timestamp, kind: .idleStarted)
        let b = ActivityEvent(id: id, timestamp: timestamp, kind: .idleStarted)

        #expect(a == b)
    }

    @Test("events with different ids are not equal")
    func equalityMismatchedId() {
        let timestamp = Date()
        let a = ActivityEvent(id: UUID(), timestamp: timestamp, kind: .idleStarted)
        let b = ActivityEvent(id: UUID(), timestamp: timestamp, kind: .idleStarted)

        #expect(a != b)
    }

    @Test("idle duration is derivable from a pair of events")
    func idleDuration() {
        let start = Date()
        let end = start.addingTimeInterval(300)

        let started = ActivityEvent(id: UUID(), timestamp: start, kind: .idleStarted)
        let ended = ActivityEvent(id: UUID(), timestamp: end, kind: .idleEnded)

        let duration = ended.timestamp.timeIntervalSince(started.timestamp)

        #expect(duration == 300)
    }
}
