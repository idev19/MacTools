import AppKit
import QuartzCore
import SwiftUI

/// Shared motion vocabulary for host and plugin interfaces.
///
/// One decision order picks the curve: entrances and exits ease out so the
/// response is visible immediately, elements that move or morph while on
/// screen ease in and out, hover and color changes use a gentle ease, and
/// constant motion stays linear. Every interface animation stays under
/// 300 ms. Keyboard-driven and high-frequency actions, such as command
/// palette selection, should not animate at all.
public enum PluginMotion {
    public enum Duration {
        /// Press feedback on any pressable control.
        public static let press: TimeInterval = 0.12
        /// Hover and other color-only changes.
        public static let hover: TimeInterval = 0.10
        /// Disclosures, inline panels, tooltips, and other small reveals.
        public static let reveal: TimeInterval = 0.18
        /// Reordering and other on-screen movement.
        public static let move: TimeInterval = 0.20
        /// Programmatic scrolling to reveal a target.
        public static let scroll: TimeInterval = 0.20
        /// Sheets and overlays.
        public static let sheet: TimeInterval = 0.24
    }

    /// A named role, so call sites say what the motion is for rather than how long it lasts.
    public enum Token: CaseIterable, Sendable {
        case press
        case hover
        case reveal
        case move
        case scroll
        case sheet
        case spring
        case momentum

        public var animation: Animation {
            switch self {
            case .press: return PluginMotion.press
            case .hover: return PluginMotion.hover
            case .reveal: return PluginMotion.reveal
            case .move: return PluginMotion.move
            case .scroll: return PluginMotion.scroll
            case .sheet: return PluginMotion.sheet
            case .spring: return PluginMotion.spring
            case .momentum: return PluginMotion.momentum
            }
        }
    }

    /// Strong ease-out: starts fast, so the interface reacts the moment the user acts.
    public static func easeOut(duration: TimeInterval = Duration.reveal) -> Animation {
        .timingCurve(0.23, 1, 0.32, 1, duration: duration)
    }

    /// Strong ease-in-out for elements that move or morph while they stay on screen.
    public static func easeInOut(duration: TimeInterval = Duration.move) -> Animation {
        .timingCurve(0.77, 0, 0.175, 1, duration: duration)
    }

    /// Gentle ease for hover and color changes.
    public static func ease(duration: TimeInterval = Duration.hover) -> Animation {
        .timingCurve(0.25, 0.1, 0.25, 1, duration: duration)
    }

    public static var press: Animation { easeOut(duration: Duration.press) }
    public static var hover: Animation { ease(duration: Duration.hover) }
    public static var reveal: Animation { easeOut(duration: Duration.reveal) }
    public static var move: Animation { easeInOut(duration: Duration.move) }
    public static var scroll: Animation { easeOut(duration: Duration.scroll) }
    public static var sheet: Animation { easeOut(duration: Duration.sheet) }

    /// Critically damped: settles without overshoot. The default for anything the user can grab.
    public static var spring: Animation { .spring(response: 0.35, dampingFraction: 1) }

    /// A little bounce, only where the gesture itself carried momentum.
    public static var momentum: Animation { .spring(response: 0.35, dampingFraction: 0.8) }

    /// `nil` under Reduce Motion, ready for `withAnimation` and `.animation(_:value:)`.
    public static func animation(_ token: Token, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : token.animation
    }

    /// Reduce Motion keeps the cross-fade and drops the movement.
    public static func revealTransition(edge: Edge = .top, reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: edge))
    }

    /// Popovers grow from their trigger; nothing appears from nothing, so the scale starts near 1.
    public static func popoverTransition(anchor: UnitPoint = .top, reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96, anchor: anchor))
    }

    /// AppKit counterparts for `NSAnimationContext` and Core Animation code paths.
    public enum CoreAnimation {
        public static var easeOut: CAMediaTimingFunction {
            CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)
        }

        public static var easeInOut: CAMediaTimingFunction {
            CAMediaTimingFunction(controlPoints: 0.77, 0, 0.175, 1)
        }

        /// The system preference for code without a SwiftUI environment.
        @MainActor public static var reduceMotion: Bool {
            NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }

        /// A zero duration under Reduce Motion, so the change still applies without moving.
        @MainActor public static func duration(_ duration: TimeInterval) -> TimeInterval {
            reduceMotion ? 0 : duration
        }
    }
}
