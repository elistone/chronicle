//
//  ActivityEvent.swift
//  Chronicle
//

import Foundation

struct ActivityEvent: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let kind: Kind

    enum Kind {
        case appActivated(appName: String, bundleID: String, windowTitle: String?)
        case windowTitleChanged(windowTitle: String)
        case idleStarted
        case idleEnded
    }
}

// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor causes synthesised Equatable
// conformances to be implicitly @MainActor, making them unusable in nonisolated
// contexts (an error in Swift 6). Implementing == manually with nonisolated
// keeps the same behaviour without the isolation constraint.
extension ActivityEvent.Kind: Equatable {
    nonisolated static func == (lhs: ActivityEvent.Kind, rhs: ActivityEvent.Kind) -> Bool {
        switch (lhs, rhs) {
        case let (.appActivated(n1, b1, w1), .appActivated(n2, b2, w2)):
            return n1 == n2 && b1 == b2 && w1 == w2
        case let (.windowTitleChanged(t1), .windowTitleChanged(t2)):
            return t1 == t2
        case (.idleStarted, .idleStarted), (.idleEnded, .idleEnded):
            return true
        default:
            return false
        }
    }
}

extension ActivityEvent {
    nonisolated static func == (lhs: ActivityEvent, rhs: ActivityEvent) -> Bool {
        lhs.id == rhs.id && lhs.timestamp == rhs.timestamp && lhs.kind == rhs.kind
    }
}
