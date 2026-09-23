import SwiftUI
import XCTest
@testable import MacToolsPluginKit

final class PluginMotionTests: XCTestCase {
    func testEveryRoleStaysWithinTheInterfaceBudget() {
        for duration in [
            PluginMotion.Duration.press,
            PluginMotion.Duration.hover,
            PluginMotion.Duration.reveal,
            PluginMotion.Duration.move,
            PluginMotion.Duration.scroll,
            PluginMotion.Duration.sheet,
        ] {
            XCTAssertGreaterThan(duration, 0)
            XCTAssertLessThan(duration, 0.3, "Interface animations stay under 300 ms")
        }
        // Press feedback is the quickest response; sheets are the slowest reveal.
        XCTAssertLessThanOrEqual(PluginMotion.Duration.hover, PluginMotion.Duration.press)
        XCTAssertLessThan(PluginMotion.Duration.press, PluginMotion.Duration.reveal)
        XCTAssertLessThanOrEqual(PluginMotion.Duration.reveal, PluginMotion.Duration.sheet)
    }

    func testReduceMotionDropsTheAnimationAndKeepsTheCrossFade() {
        for token in PluginMotion.Token.allCases {
            XCTAssertNil(PluginMotion.animation(token, reduceMotion: true), "\(token)")
            XCTAssertNotNil(PluginMotion.animation(token, reduceMotion: false), "\(token)")
        }
        // Transitions cannot be compared, but both branches must produce a usable value.
        _ = PluginMotion.revealTransition(reduceMotion: true)
        _ = PluginMotion.revealTransition(edge: .bottom, reduceMotion: false)
        _ = PluginMotion.popoverTransition(reduceMotion: true)
        _ = PluginMotion.popoverTransition(anchor: .topLeading, reduceMotion: false)
    }

    @MainActor
    func testCoreAnimationHelpersFollowTheSystemPreference() {
        let expected: TimeInterval = PluginMotion.CoreAnimation.reduceMotion ? 0 : 0.2
        XCTAssertEqual(PluginMotion.CoreAnimation.duration(0.2), expected)
        var controlPoints: [Float] = [0, 0]
        PluginMotion.CoreAnimation.easeOut.getControlPoint(at: 1, values: &controlPoints)
        XCTAssertEqual(controlPoints, [0.23, 1], "Strong ease-out starts fast")
        PluginMotion.CoreAnimation.easeInOut.getControlPoint(at: 1, values: &controlPoints)
        XCTAssertEqual(controlPoints, [0.77, 0], "Strong ease-in-out accelerates before settling")
    }
}
