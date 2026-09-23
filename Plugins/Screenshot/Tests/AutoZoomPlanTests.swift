import CoreGraphics
import XCTest
@testable import ScreenshotPlugin

final class AutoZoomPlanTests: XCTestCase {
    func testClicksAreSortedAndInvalidClicksAreDropped() {
        let plan = AutoZoomPlan(clicks: [
            .init(time: 2, point: CGPoint(x: 0.2, y: 0.2)),
            .init(time: 1, point: CGPoint(x: 0.8, y: 0.8)),
            .init(time: -1, point: CGPoint(x: 0.5, y: 0.5)),
            .init(time: 3, point: CGPoint(x: 1.5, y: 0.5)),
            .init(time: .nan, point: CGPoint(x: 0.5, y: 0.5)),
        ])
        XCTAssertEqual(plan.clicks.map(\.time), [1, 2])
        XCTAssertFalse(plan.isEmpty)
        XCTAssertTrue(AutoZoomPlan(clicks: []).isEmpty)
    }

    func testTargetLeadsEachClickAndReleasesAfterTheHold() {
        var settings = AutoZoomPlan.Settings()
        settings.scale = 2
        settings.leadIn = 0.5
        settings.hold = 1
        let focus = CGPoint(x: 0.25, y: 0.75)
        let plan = AutoZoomPlan(clicks: [.init(time: 2, point: focus)], settings: settings)
        XCTAssertEqual(plan.target(at: 1.4), .identity)
        XCTAssertEqual(plan.target(at: 1.5), AutoZoomState(scale: 2, center: focus))
        XCTAssertEqual(plan.target(at: 3), AutoZoomState(scale: 2, center: focus))
        // After the hold the frame relaxes but keeps its last focus, so the release does not pan.
        XCTAssertEqual(plan.target(at: 3.1), AutoZoomState(scale: 1, center: focus))
    }

    func testNearbyClicksExtendTheZoomAndMoveTheFocus() {
        let first = CGPoint(x: 0.2, y: 0.2)
        let second = CGPoint(x: 0.8, y: 0.8)
        let plan = AutoZoomPlan(clicks: [.init(time: 1, point: first), .init(time: 2, point: second)])
        XCTAssertEqual(plan.target(at: 1.5).center, first)
        XCTAssertEqual(plan.target(at: 1.9).center, second)
        XCTAssertEqual(plan.target(at: 3.5).scale, plan.settings.scale)
        XCTAssertEqual(plan.target(at: 3.7).scale, 1)
    }

    func testSimulatorZoomsInWithoutOvershootAndSettlesBackToIdentity() {
        let focus = CGPoint(x: 0.75, y: 0.5)
        let plan = AutoZoomPlan(clicks: [.init(time: 1, point: focus)])
        var simulator = AutoZoomSimulator(plan: plan)
        var samples: [(time: TimeInterval, state: AutoZoomState)] = []
        for frame in 0...150 {
            let time = TimeInterval(frame) / 30
            samples.append((time, simulator.advance(to: time)))
        }
        func state(at time: TimeInterval) -> AutoZoomState {
            samples.min { abs($0.time - time) < abs($1.time - time) }!.state
        }
        XCTAssertEqual(state(at: 0.5), .identity)
        XCTAssertGreaterThan(state(at: 1.0).scale, 1.3)
        XCTAssertGreaterThan(state(at: 2.0).scale, 1.95)
        XCTAssertTrue(samples.allSatisfy { $0.state.scale <= plan.settings.scale + 0.0001 && $0.state.scale >= 0.9999 })
        let zoomingIn = samples.filter { $0.time >= 0.6 && $0.time <= 1.6 }.map(\.state.scale)
        XCTAssertEqual(zoomingIn, zoomingIn.sorted())
        // Motion settles exactly, so later frames compare equal and can pass through untouched.
        XCTAssertEqual(state(at: 4.9), AutoZoomState(scale: 1, center: focus))
    }

    func testCropRectStaysInsideTheFrameAndUsesBottomLeftPixels() {
        let size = CGSize(width: 200, height: 100)
        XCTAssertEqual(AutoZoomState.identity.cropRect(in: size), CGRect(origin: .zero, size: size))
        // A focus near the top-left corner clamps to the top-left quadrant.
        let corner = AutoZoomState(scale: 2, center: CGPoint(x: 0.05, y: 0.05)).cropRect(in: size)
        XCTAssertEqual(corner, CGRect(x: 0, y: 50, width: 100, height: 50))
        let centered = AutoZoomState(scale: 2, center: CGPoint(x: 0.5, y: 0.5)).cropRect(in: size)
        XCTAssertEqual(centered, CGRect(x: 50, y: 25, width: 100, height: 50))
        let bottomRight = AutoZoomState(scale: 4, center: CGPoint(x: 1, y: 1)).cropRect(in: size)
        XCTAssertEqual(bottomRight, CGRect(x: 150, y: 0, width: 50, height: 25))
    }

    func testClickTrackerNormalizesScreenPointsInsideTheRegionOnly() {
        let region = CGRect(x: 100, y: 200, width: 200, height: 100)
        XCTAssertEqual(RecordingClickTracker.normalizedPoint(CGPoint(x: 150, y: 250), in: region),
                       CGPoint(x: 0.25, y: 0.5))
        // AppKit's y axis points up, so the region's bottom edge maps to y = 1.
        XCTAssertEqual(RecordingClickTracker.normalizedPoint(CGPoint(x: 100, y: 200), in: region),
                       CGPoint(x: 0, y: 1))
        XCTAssertNil(RecordingClickTracker.normalizedPoint(CGPoint(x: 99, y: 250), in: region))
        XCTAssertNil(RecordingClickTracker.normalizedPoint(CGPoint(x: 150, y: 301), in: region))
        XCTAssertNil(RecordingClickTracker.normalizedPoint(.zero, in: .zero))
    }

    @MainActor
    func testClickTrackerTimesClicksFromRecordingStartAndIgnoresEarlierEvents() {
        let tracker = RecordingClickTracker(region: CGRect(x: 0, y: 0, width: 100, height: 100), uptime: { 100 })
        tracker.record(at: CGPoint(x: 50, y: 50), timestamp: 101)
        XCTAssertTrue(tracker.clicks.isEmpty)
        tracker.start()
        defer { tracker.stop() }
        tracker.record(at: CGPoint(x: 50, y: 50), timestamp: 99.5)
        tracker.record(at: CGPoint(x: 25, y: 75), timestamp: 101.5)
        tracker.record(at: CGPoint(x: 150, y: 50), timestamp: 102)
        XCTAssertEqual(tracker.clicks, [AutoZoomPlan.Click(time: 1.5, point: CGPoint(x: 0.25, y: 0.25))])
    }
}
