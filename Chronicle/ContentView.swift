//
//  ContentView.swift
//  Chronicle
//
//  Created by Eli Stone on 21/06/2026.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var appName = "—"
    @State private var bundleID = "—"
    @State private var appIcon: NSImage? = nil

    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top, spacing: 24) {
                activeAppPanel
                Divider()
                IdleDetectorView()
            }
            Divider()
            WindowTitleDetectorView()
        }
        .padding(32)
        .frame(minWidth: 560, minHeight: 400)
        .onAppear(perform: refresh)
        .onReceive(
            NotificationCenter.Publisher(
                center: NSWorkspace.shared.notificationCenter,
                name: NSWorkspace.didActivateApplicationNotification
            )
        ) { _ in
            refresh()
        }
    }

    private var activeAppPanel: some View {
        VStack(spacing: 16) {
            Group {
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 64, height: 64)
                } else {
                    Image(systemName: "app.dashed")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.secondary)
                }
            }

            Text(appName)
                .font(.title2)
                .fontWeight(.semibold)

            Text(bundleID)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 200)
    }

    private func refresh() {
        let app = NSWorkspace.shared.frontmostApplication
        appName = app?.localizedName ?? "Unknown"
        bundleID = app?.bundleIdentifier ?? ""
        appIcon = app?.icon
    }
}

#Preview {
    ContentView()
}
