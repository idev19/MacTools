import SwiftUI

/// Type tokens for the compact menu bar panel and its widgets.
///
/// Panel rows read like a menu, so this scale uses fixed point sizes that keep
/// rows stable instead of the semantic, user-scalable settings scale in
/// `PluginSettingsTheme.Typography`. The scale is whole points only, 13 / 12 /
/// 11 / 10 / 9 under a 14 pt heading, so every step is visibly different from
/// its neighbors. Hierarchy comes from weight and size as a set: one semibold
/// row title, a medium description a step below, and small semibold badges.
/// Symbols share the same steps so an icon never outweighs the text beside it.
public enum PluginPanelTheme {
    public enum Typography {
        /// The row's name; the only semibold 13 pt text in a row.
        public static var rowTitle: Font { .system(size: 13, weight: .semibold) }
        /// Descriptions, section titles, and subtitles under a row title.
        public static var rowDescription: Font { .system(size: 11, weight: .medium) }
        /// Emphasized control or section titles inside a row.
        public static var controlTitle: Font { .system(size: 12, weight: .semibold) }
        /// Button and control labels.
        public static var controlLabel: Font { .system(size: 12, weight: .medium) }
        /// Options in a select list.
        public static var optionLabel: Font { .system(size: 11) }
        /// Secondary single-line notes.
        public static var caption: Font { .system(size: 11) }
        /// Titles under icon widgets.
        public static var widgetTitle: Font { .system(size: 10, weight: .medium) }
        /// Keycap glyphs in palettes.
        public static var keycap: Font { .system(size: 10, weight: .semibold, design: .rounded) }
        /// Inline indicators and counters.
        public static var badge: Font { .system(size: 9, weight: .semibold) }
        /// Fixed-width readings beside a row.
        public static var monospacedValue: Font { .system(size: 10, weight: .medium, design: .monospaced) }
        /// Empty-state headings inside the panel.
        public static var emptyStateTitle: Font { .system(size: 14, weight: .semibold) }
    }

    /// SF Symbol sizes, stepped with the text they sit beside.
    public enum Symbol {
        /// Large empty-state and overlay glyphs.
        public static var hero: Font { .system(size: 26, weight: .medium) }
        /// Icon widget glyphs.
        public static var widget: Font { .system(size: 20, weight: .medium) }
        /// Leading icons beside a row title.
        public static var row: Font { .system(size: 13, weight: .semibold) }
        /// Icons inside controls and icon buttons.
        public static var control: Font { .system(size: 12, weight: .semibold) }
        /// Small inline glyphs such as dismiss and link icons.
        public static var caption: Font { .system(size: 11, weight: .semibold) }
        /// Disclosure chevrons and checkmarks.
        public static var chevron: Font { .system(size: 10, weight: .semibold) }
    }
}
