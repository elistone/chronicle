//
//  IdleDetectorView.swift
//  Chronicle
//
//  Spike: validates idle detection via CGEventSourceSecondsSinceLastEventType.
//  Not intended for production use as-is.
//

import SwiftUI
import Combine
import CoreGraphics

// Threshold for the spike UI — low so behaviour is observable without waiting.
private let spikeIdleThreshold: TimeInterval = 30

final class IdleDetector: ObservableObject {
    @Published var idleSeconds: TimeInterval = 0
    @Published var isIdle: Bool = false

    private var timer: Timer?

    func start() {
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        // kCGAnyInputEventType (~0) returns seconds since any HID input event.
        let anyEvent = CGEventType(rawValue: ~UInt32(0))!
        let seconds = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)
        idleSeconds = seconds
        isIdle = seconds >= spikeIdleThreshold
    }
}

struct IdleDetectorView: View {
    @StateObject private var detector = IdleDetector()

    var body: some View {
        VStack(spacing: 12) {
            statusIndicator
            idleLabel
            secondsLabel
            thresholdNote
        }
        .padding(24)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .onAppear { detector.start() }
        .onDisappear { detector.stop() }
    }

    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(detector.isIdle ? Color.orange : Color.green)
                .frame(width: 10, height: 10)
            Text(detector.isIdle ? "Idle" : "Active")
                .font(.headline)
        }
    }

    private var idleLabel: some View {
        Text("Last input \(Int(detector.idleSeconds))s ago")
            .font(.title3)
            .monospacedDigit()
    }

    private var secondsLabel: some View {
        Text(formattedDuration)
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }

    private var thresholdNote: some View {
        Text("Idle threshold: \(Int(spikeIdleThreshold))s (spike only)")
            .font(.caption2)
            .foregroundStyle(.tertiary)
    }

    private var formattedDuration: String {
        let s = Int(detector.idleSeconds)
        let m = s / 60
        let rem = s % 60
        return m > 0 ? "\(m)m \(rem)s" : "\(rem)s"
    }
}

#Preview {
    IdleDetectorView()
        .padding()
}
