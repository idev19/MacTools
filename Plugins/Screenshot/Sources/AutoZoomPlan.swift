import CoreGraphics
import Foundation

/// Click-driven zoom targets for a finished recording, evaluated on the output frame cadence.
struct AutoZoomPlan: Sendable, Equatable {
    /// One pointer click on the recording timeline; `point` is a top-left-origin fraction of the region.
    struct Click: Sendable, Equatable {
        let time: TimeInterval
        let point: CGPoint

        init(time: TimeInterval, point: CGPoint) {
            self.time = time
            self.point = point
        }
    }

    struct Settings: Sendable, Equatable {
        var scale: CGFloat = 2
        /// Zooming starts ahead of the click so the target is already framed when it happens.
        var leadIn: TimeInterval = 0.4
        /// The zoom stays this long after the latest click before easing back to the full frame.
        var hold: TimeInterval = 1.6
        var scaleSmoothing: TimeInterval = 0.3
        var panSmoothing: TimeInterval = 0.25

        init() {}
    }

    let clicks: [Click]
    let settings: Settings

    init(clicks: [Click], settings: Settings = Settings()) {
        self.clicks = clicks
            .filter { click in
                click.time.isFinite && click.time >= 0
                    && (0...1).contains(click.point.x) && (0...1).contains(click.point.y)
            }
            .sorted { $0.time < $1.time }
        self.settings = settings
    }

    var isEmpty: Bool { clicks.isEmpty }

    /// Where the motion should be heading at `time`: zoomed on the latest click while its window is open.
    func target(at time: TimeInterval) -> AutoZoomState {
        var focus = AutoZoomState.identity.center
        var zoomed = false
        for click in clicks where click.time - settings.leadIn <= time {
            focus = click.point
            if time <= click.time + settings.hold { zoomed = true }
        }
        return AutoZoomState(scale: zoomed ? settings.scale : 1, center: focus)
    }
}

struct AutoZoomState: Sendable, Equatable {
    var scale: CGFloat
    /// Normalized focus with a top-left origin, before viewport clamping.
    var center: CGPoint

    static let identity = AutoZoomState(scale: 1, center: CGPoint(x: 0.5, y: 0.5))

    var isIdentity: Bool { abs(scale - 1) < 0.001 }

    /// The visible source area in pixels with a bottom-left origin, kept inside the frame.
    func cropRect(in size: CGSize) -> CGRect {
        let scale = max(1, self.scale)
        let width = size.width / scale
        let height = size.height / scale
        let half = 0.5 / scale
        let x = min(max(center.x, half), 1 - half) * size.width
        let yFromTop = min(max(center.y, half), 1 - half) * size.height
        return CGRect(x: x - width / 2, y: size.height - yFromTop - height / 2, width: width, height: height)
    }
}

/// Critically damped motion toward the plan's targets, stepped at whatever cadence the caller uses.
struct AutoZoomSimulator {
    private let plan: AutoZoomPlan
    private var time: TimeInterval = 0
    private var scale = SmoothedValue(value: AutoZoomState.identity.scale)
    private var x = SmoothedValue(value: AutoZoomState.identity.center.x)
    private var y = SmoothedValue(value: AutoZoomState.identity.center.y)
    private(set) var state = AutoZoomState.identity

    init(plan: AutoZoomPlan) {
        self.plan = plan
    }

    mutating func advance(to newTime: TimeInterval) -> AutoZoomState {
        let step = max(0, newTime - time)
        time = max(time, newTime)
        let target = plan.target(at: time)
        scale.move(toward: target.scale, smoothing: plan.settings.scaleSmoothing, step: step)
        x.move(toward: target.center.x, smoothing: plan.settings.panSmoothing, step: step)
        y.move(toward: target.center.y, smoothing: plan.settings.panSmoothing, step: step)
        state = AutoZoomState(scale: scale.value, center: CGPoint(x: x.value, y: y.value))
        return state
    }
}

/// Spring-like approach without overshoot, stable for any step size.
private struct SmoothedValue {
    private(set) var value: CGFloat
    private var velocity: CGFloat = 0

    init(value: CGFloat) {
        self.value = value
    }

    mutating func move(toward target: CGFloat, smoothing: TimeInterval, step: TimeInterval) {
        guard step > 0 else { return }
        guard smoothing > 0 else {
            value = target
            velocity = 0
            return
        }
        let omega = 2 / CGFloat(smoothing)
        let x = omega * CGFloat(step)
        let decay = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
        let change = value - target
        let temp = (velocity + omega * change) * CGFloat(step)
        velocity = (velocity - omega * temp) * decay
        value = target + (change + temp) * decay
        // Settle exactly so steady frames compare equal and pass through untouched.
        if abs(value - target) < 0.0005, abs(velocity) < 0.005 {
            value = target
            velocity = 0
        }
    }
}
