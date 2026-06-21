//
//  ActivityLog.swift
//  Chronicle
//

import Foundation
import Combine

final class ActivityLog: ObservableObject {

    /// The in-memory event stream for the current session, in arrival order.
    /// Append-only. Never mutated except by the tracker callback.
    @Published private(set) var events: [ActivityEvent] = []

    private let tracker: ActivityTracker

    init(idleThreshold: TimeInterval = 300) {
        self.tracker = ActivityTracker(idleThreshold: idleThreshold)
    }

    func start() {
        tracker.onEvent = { [weak self] event in
            self?.events.append(event)
        }
        tracker.start()
    }

    func stop() {
        tracker.stop()
        tracker.onEvent = nil
    }
}
