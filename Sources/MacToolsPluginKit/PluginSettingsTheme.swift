import AppKit
import SwiftUI

public enum PluginSettingsTheme {
    public enum Typography {
        public static var pageTitle: Font {
            .title2.weight(.semibold)
        }

        public static var pageDescription: Font {
            .subheadline
        }

        public static var sectionTitle: Font {
            .body.weight(.semibold)
        }

        public static var rowTitle: Font {
            .body.weight(.medium)
        }

        public static var emphasizedRowTitle: Font {
            .body.weight(.semibold)
        }

        public static var rowDescription: Font {
            .subheadline
        }

        public static var secondaryLabel: Font {
            .subheadline.weight(.medium)
        }

        public static var statusBadge: Font {
            .caption2.weight(.medium)
        }

        public static var rowIcon: Font {
            .caption.weight(.semibold)
        }

        public static var controlLabel: Font {
            .callout
        }

        public static var monospacedValue: Font {
            .callout.monospaced()
        }

        public static var compactMonospacedValue: Font {
            .subheadline.monospaced()
        }

        /// Card titles in galleries and pickers.
        public static var cardTitle: Font {
            .callout.weight(.semibold)
        }

        public static var cardSubtitle: Font {
            .caption2
        }

        /// Large empty-state and overlay glyphs.
        public static var heroSymbol: Font {
            .largeTitle.weight(.medium)
        }

        /// Glyphs that lead a page-level card.
        public static var pageSymbol: Font {
            .title.weight(.semibold)
        }

        /// Glyphs that lead a card row, and close buttons on floating cards.
        public static var cardSymbol: Font {
            .title2
        }
    }

    public enum Spacing {
        public static let pagePadding: CGFloat = 24
        public static let section: CGFloat = 18
        public static let sectionHeaderContent: CGFloat = 10
        public static let cardContent: CGFloat = 16
        public static let rowHorizontal: CGFloat = 16
        public static let rowVertical: CGFloat = 10
        public static let interactiveRowVertical: CGFloat = 12
        public static let rowTitleDescription: CGFloat = 3
        public static let rowContentControl: CGFloat = 12
        public static let controlCluster: CGFloat = 8
    }

    /// One radius scale for every surface: each step is a role, not a number to tune per view.
    public enum Radius {
        /// Tags, keycaps, and other tiny chips.
        public static let chip: CGFloat = 4
        /// Text fields, keyboard candidates, and small icon-button hover backgrounds.
        public static let field: CGFloat = 6
        /// Controls, list rows, hover backgrounds, and inline icon tiles.
        public static let control: CGFloat = 8
        /// Standalone settings cards, search fields, and gallery previews.
        public static let card: CGFloat = 10
        /// Host cards, the menu bar panel, widget cards, and tiles inside overlays.
        public static let hostCard: CGFloat = 12
        /// Floating overlays such as palettes, the action grid, and run-link feedback.
        public static let overlay: CGFloat = 16

        /// Concentric corners: a shape inset from a rounded parent keeps the parent's
        /// corner center by subtracting the inset, never falling below `chip`.
        public static func nested(_ outer: CGFloat, inset: CGFloat) -> CGFloat {
            max(outer - inset, chip)
        }

        /// The macOS app icon corner, 22.37% of the icon size.
        public static func appIcon(for size: CGFloat) -> CGFloat {
            (size * 0.2237).rounded()
        }
    }

    public enum Stroke {
        public static let hairline: CGFloat = 0.5
        public static let standard: CGFloat = 1
    }

    public enum Size {
        public static let pageIcon: CGFloat = 42
        public static let rowIcon: CGFloat = 18
        public static let controlHeight: CGFloat = 30
        public static let shortcutRecorderWidth: CGFloat = 126
        public static let metricIcon: CGFloat = 36
        public static let emptyStateIcon: CGFloat = 28
    }

    public enum Palette {
        public static var recessedControlBackground: Color {
            // Inset containers are neutral surfaces, not inactive selections.
            Color(nsColor: .underPageBackgroundColor)
        }

        public static var fieldBackground: Color {
            Color(nsColor: .textBackgroundColor)
        }

        public static var keycapBackground: Color {
            Color(nsColor: .controlBackgroundColor)
        }

        public static var separator: Color {
            Color(nsColor: .separatorColor)
        }

        public static var cardBorder: Color {
            Color(nsColor: .separatorColor)
        }

        // Washes: one short scale so every resting tile, hover, press, and
        // selection reads as the same material at a different weight. Resting,
        // hover, and press are three distinct steps (4%, 6%, 10%) so a chip
        // under the pointer visibly changes and a press is heavier still.

        /// A resting tile or chip on a solid surface.
        public static var chipBackground: Color {
            Color.primary.opacity(0.04)
        }

        /// Rows, cells, and cards under the pointer.
        public static var hoverBackground: Color {
            Color.primary.opacity(0.06)
        }

        /// Hover on translucent material, which needs a heavier wash to show.
        public static var materialHoverBackground: Color {
            Color.primary.opacity(0.10)
        }

        /// Pressed controls.
        public static var pressedBackground: Color {
            Color.primary.opacity(0.10)
        }

        /// The current selection and active controls.
        public static var selectionBackground: Color {
            Color.accentColor.opacity(0.12)
        }

        /// Callouts and selected tiles that should stay quieter than a selection.
        public static var emphasisBackground: Color {
            Color.accentColor.opacity(0.08)
        }

        /// The tile behind a tinted icon or a status badge; the tint comes from the icon.
        public static func tintBackground(_ color: Color) -> Color {
            color.opacity(0.12)
        }

        // Borders, from the quietest ring to the strongest.

        /// A hairline ring that separates a tile from its surface.
        public static var hairlineBorder: Color {
            Color.primary.opacity(0.10)
        }

        /// A softened separator for framed fields and floating surfaces.
        public static var subtleBorder: Color {
            separator.opacity(0.45)
        }

        /// Accent ring on hovered selectable cards.
        public static var hoverBorder: Color {
            Color.accentColor.opacity(0.3)
        }

        /// Accent ring on the selected card.
        public static var selectionBorder: Color {
            Color.accentColor.opacity(0.8)
        }

        /// Rings under Increase Contrast, which must stay visible on any surface.
        public static var contrastBorder: Color {
            Color.primary.opacity(0.6)
        }

        public static var focusRing: Color {
            Color(nsColor: .keyboardFocusIndicatorColor)
        }

        /// The backdrop behind a floating palette.
        public static var scrim: Color {
            Color.black.opacity(0.24)
        }

        public static var reducedTransparencyScrim: Color {
            Color.black.opacity(0.30)
        }

        public static var sidebarHoverBackground: Color {
            hoverBackground
        }

        public static var sidebarSelectionBackground: Color {
            selectionBackground
        }

        public static var activeControlBackground: Color {
            selectionBackground
        }

        public static var recordingBackground: Color {
            emphasisBackground
        }

    }

    public enum Surface {
        /// A raised control inside a recessed surface, such as the selected
        /// segment in a custom tab strip. Outer settings cards must use
        /// `pluginSettingsCardBackground(_:)` so their background and clipping
        /// stay consistent across appearances.
        public static var raisedControl: AnyShapeStyle {
            AnyShapeStyle(.background)
        }

        fileprivate static var standardCard: AnyShapeStyle {
            // Use the system's secondary content background for standalone
            // cards. Grouped Form continues to own its native section surface.
            AnyShapeStyle(.background.secondary)
        }
    }
}

/// Shared row content for native forms and custom settings sections.
/// The containing form or custom section owns row padding and separators.
public struct PluginSettingsItem<Control: View>: View {
    private let title: String
    private let description: String?
    private let systemImage: String?
    private let control: Control

    public init(
        title: String,
        description: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.control = control()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: PluginSettingsTheme.Spacing.rowContentControl) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .pluginSettingsRowIconStyle()
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: PluginSettingsTheme.Spacing.rowTitleDescription) {
                    Text(title)
                        .font(PluginSettingsTheme.Typography.rowTitle)
                    if let description, !description.isEmpty {
                        Text(description)
                            .font(PluginSettingsTheme.Typography.rowDescription)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .layoutPriority(1)

            Spacer(minLength: PluginSettingsTheme.Spacing.rowContentControl)
            control
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public enum PluginSettingsCardBackgroundStyle {
    case standard
    case recessed
}

public enum PluginSettingsListDividerStyle {
    case horizontal
    case vertical
}

public struct PluginSettingsCardBackground: ViewModifier {
    private let style: PluginSettingsCardBackgroundStyle

    public init(_ style: PluginSettingsCardBackgroundStyle = .standard) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        content
            .background(
                shape.fill(backgroundStyle)
            )
            // A card owns its visible surface. Clipping prevents native list
            // or editor backgrounds from punching square corners through it.
            .clipShape(shape)
    }

    private var radius: CGFloat {
        switch style {
        case .standard:
            return PluginSettingsTheme.Radius.hostCard
        case .recessed:
            return PluginSettingsTheme.Radius.card
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch style {
        case .standard:
            return PluginSettingsTheme.Surface.standardCard
        case .recessed:
            return AnyShapeStyle(PluginSettingsTheme.Palette.recessedControlBackground)
        }
    }

}

public struct PluginSettingsListDivider: View {
    private let style: PluginSettingsListDividerStyle
    private let leadingInset: CGFloat
    private let trailingInset: CGFloat

    public init(
        _ style: PluginSettingsListDividerStyle = .horizontal,
        leadingInset: CGFloat = PluginSettingsTheme.Spacing.rowHorizontal,
        trailingInset: CGFloat = PluginSettingsTheme.Spacing.rowHorizontal
    ) {
        self.style = style
        self.leadingInset = leadingInset
        self.trailingInset = trailingInset
    }

    public var body: some View {
        switch style {
        case .horizontal:
            Rectangle()
                .fill(PluginSettingsTheme.Palette.separator)
                .frame(height: PluginSettingsTheme.Stroke.standard)
                .padding(.leading, leadingInset)
                .padding(.trailing, trailingInset)
        case .vertical:
            Rectangle()
                .fill(PluginSettingsTheme.Palette.separator)
                .frame(width: PluginSettingsTheme.Stroke.standard)
        }
    }
}

/// Keeps a shortcut's icon/title and recorder in one compact line. The first
/// child is the only compressible label; recorder fields and trailing actions
/// retain their intrinsic sizes as the settings window narrows.
public struct PluginSettingsShortcutControlLayout: Layout {
    private let spacing: CGFloat
    private let maximumLabelWidth: CGFloat

    public init(
        spacing: CGFloat = PluginSettingsTheme.Spacing.controlCluster,
        maximumLabelWidth: CGFloat = 160
    ) {
        self.spacing = max(spacing, 0)
        self.maximumLabelWidth = max(maximumLabelWidth, 0)
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard let label = subviews.first else {
            return .zero
        }

        let trailingSizes = subviews.dropFirst().map {
            $0.sizeThatFits(.unspecified)
        }
        let totalSpacing = spacing * CGFloat(max(subviews.count - 1, 0))
        let trailingWidth = trailingSizes.reduce(0) { $0 + $1.width }
        let proposedLabelWidth = proposal.width.map {
            max($0 - trailingWidth - totalSpacing, 0)
        } ?? maximumLabelWidth
        let labelWidth = min(
            label.sizeThatFits(.unspecified).width,
            maximumLabelWidth,
            proposedLabelWidth
        )
        let labelSize = label.sizeThatFits(
            ProposedViewSize(width: labelWidth, height: proposal.height)
        )
        let measuredLabelWidth = min(labelSize.width, labelWidth)
        let height = ([labelSize] + trailingSizes).map(\.height).max() ?? 0

        return CGSize(
            width: measuredLabelWidth + trailingWidth + totalSpacing,
            height: height
        )
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard let label = subviews.first else {
            return
        }

        let trailingSizes = subviews.dropFirst().map {
            $0.sizeThatFits(.unspecified)
        }
        let totalSpacing = spacing * CGFloat(max(subviews.count - 1, 0))
        let trailingWidth = trailingSizes.reduce(0) { $0 + $1.width }
        let availableLabelWidth = max(bounds.width - trailingWidth - totalSpacing, 0)
        let labelWidth = min(
            label.sizeThatFits(.unspecified).width,
            maximumLabelWidth,
            availableLabelWidth
        )
        let labelProposal = ProposedViewSize(width: labelWidth, height: bounds.height)
        let labelSize = label.sizeThatFits(labelProposal)
        var x = bounds.minX

        label.place(
            at: CGPoint(x: x, y: bounds.midY),
            anchor: .leading,
            proposal: labelProposal
        )
        x += min(labelSize.width, labelWidth)

        for (subview, size) in zip(subviews.dropFirst(), trailingSizes) {
            x += spacing
            subview.place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .leading,
                proposal: ProposedViewSize(size)
            )
            x += size.width
        }
    }
}

/// A stepped settings slider without macOS's dense tick-mark presentation.
/// Values are snapped relative to the lower bound before being written back,
/// so declarative and custom plugin settings share the same interaction model.
public struct PluginSettingsSlider: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let onEditingChanged: (Bool) -> Void

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _value = value
        self.range = range
        self.step = step
        self.onEditingChanged = onEditingChanged
    }

    public var body: some View {
        Slider(
            value: Binding(
                get: { value },
                set: {
                    value = Self.snappedValue($0, in: range, step: step)
                }
            ),
            in: range,
            onEditingChanged: onEditingChanged
        )
    }

    public static func snappedValue(
        _ value: Double,
        in range: ClosedRange<Double>,
        step: Double?
    ) -> Double {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        guard let step, step.isFinite, step > 0 else {
            return clamped
        }

        let offset = ((clamped - range.lowerBound) / step).rounded()
        let snapped = range.lowerBound + offset * step
        return min(max(snapped, range.lowerBound), range.upperBound)
    }
}

public extension View {
    func pluginSettingsCardBackground(
        _ style: PluginSettingsCardBackgroundStyle = .standard
    ) -> some View {
        modifier(PluginSettingsCardBackground(style))
    }

    func pluginSettingsRowIconStyle(visualScale: CGFloat = 1) -> some View {
        pluginSettingsRowIconStyle(
            HierarchicalShapeStyle.secondary,
            visualScale: visualScale
        )
    }

    func pluginSettingsRowIconStyle<S: ShapeStyle>(
        _ foregroundStyle: S,
        visualScale: CGFloat = 1
    ) -> some View {
        self
            .font(PluginSettingsTheme.Typography.rowIcon)
            .foregroundStyle(foregroundStyle)
            .symbolRenderingMode(.monochrome)
            .scaleEffect(visualScale)
            .frame(
                width: PluginSettingsTheme.Size.rowIcon,
                height: PluginSettingsTheme.Size.rowIcon
            )
    }

    func pluginSettingsListRowPadding(interactive: Bool = false) -> some View {
        self
            .padding(.horizontal, PluginSettingsTheme.Spacing.rowHorizontal)
            .padding(
                .vertical,
                interactive
                    ? PluginSettingsTheme.Spacing.interactiveRowVertical
                    : PluginSettingsTheme.Spacing.rowVertical
            )
    }
}
