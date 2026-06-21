//
//  ContentView.swift
//  Chronicle
//
//  Created by Eli Stone on 21/06/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var activityLog: ActivityLog

    var body: some View {
        Group {
            if activityLog.events.isEmpty {
                ContentUnavailableView(
                    "No Activity",
                    systemImage: "clock",
                    description: Text("Events will appear here as you work.")
                )
            } else {
                List(activityLog.events.reversed()) { event in
                    ActivityEventRow(event: event)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 400)
    }
}

private struct ActivityEventRow: View {
    let event: ActivityEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var title: String {
        switch event.kind {
        case .appActivated(let appName, _, _):
            return appName
        case .windowTitleChanged(let windowTitle):
            return windowTitle
        case .idleStarted:
            return "Idle started"
        case .idleEnded:
            return "Idle ended"
        }
    }

    private var detail: String? {
        switch event.kind {
        case .appActivated(_, let bundleID, let windowTitle):
            if let windowTitle {
                return "\(bundleID) · \(windowTitle)"
            }
            return bundleID
        case .windowTitleChanged:
            return "Window title changed"
        case .idleStarted, .idleEnded:
            return nil
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ActivityLog())
}
