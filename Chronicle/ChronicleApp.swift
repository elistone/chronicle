//
//  ChronicleApp.swift
//  Chronicle
//
//  Created by Eli Stone on 21/06/2026.
//

import SwiftUI

@main
struct ChronicleApp: App {
    private let activityLog = ActivityLog()

    init() {
        activityLog.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(activityLog)
        }
    }
}
