import AppKit

/// Collects pointer clicks inside the recorded region, timed against the moment recording started.
@MainActor
final class RecordingClickTracker {
    private let region: CGRect
    private let uptime: () -> TimeInterval
    private var monitor: Any?
    private var startedAt: TimeInterval?
    private(set) var clicks: [AutoZoomPlan.Click] = []
    private static let limit = 5_000

    /// `region` uses AppKit screen coordinates, matching `CaptureRegion.globalRect`.
    init(region: CGRect, uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.region = region
        self.uptime = uptime
    }

    func start() {
        guard startedAt == nil else { return }
        startedAt = uptime()
        // Global monitors skip this process, so the session's own controls never trigger a zoom.
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            let timestamp = event.timestamp
            let location = event.locationInWindow
            Task { @MainActor in self?.record(at: location, timestamp: timestamp) }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    /// `location` is a screen point; `timestamp` uses the system uptime clock like `NSEvent.timestamp`.
    func record(at location: CGPoint, timestamp: TimeInterval) {
        guard let startedAt, clicks.count < Self.limit, timestamp >= startedAt,
              let point = Self.normalizedPoint(location, in: region) else { return }
        clicks.append(AutoZoomPlan.Click(time: timestamp - startedAt, point: point))
    }

    /// Screen coordinates to a top-left-origin fraction of the region; clicks outside are ignored.
    nonisolated static func normalizedPoint(_ location: CGPoint, in region: CGRect) -> CGPoint? {
        guard region.width > 0, region.height > 0, region.contains(location) else { return nil }
        return CGPoint(x: (location.x - region.minX) / region.width,
                       y: (region.maxY - location.y) / region.height)
    }
}
