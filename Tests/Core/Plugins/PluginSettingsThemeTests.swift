import XCTest
@testable import MacToolsPluginKit

final class PluginSettingsThemeTests: XCTestCase {
    func testRadiusScaleStepsUpByRole() {
        let scale = [
            PluginSettingsTheme.Radius.chip,
            PluginSettingsTheme.Radius.field,
            PluginSettingsTheme.Radius.control,
            PluginSettingsTheme.Radius.card,
            PluginSettingsTheme.Radius.hostCard,
            PluginSettingsTheme.Radius.overlay,
        ]
        XCTAssertEqual(scale, scale.sorted())
        XCTAssertEqual(Set(scale).count, scale.count)
        // Shared surfaces read from the same scale instead of restating a number.
        XCTAssertEqual(PluginPanelWidgetLayoutMetrics.cardCornerRadius, PluginSettingsTheme.Radius.hostCard)
        XCTAssertEqual(PluginPaletteMetrics.surfaceCornerRadius, PluginSettingsTheme.Radius.overlay)
        XCTAssertEqual(PluginPaletteMetrics.rowCornerRadius, PluginSettingsTheme.Radius.control)
    }

    func testNestedCornersStayConcentricAndNeverCollapse() {
        XCTAssertEqual(PluginSettingsTheme.Radius.nested(PluginSettingsTheme.Radius.overlay, inset: 4), 12)
        XCTAssertEqual(PluginSettingsTheme.Radius.nested(PluginSettingsTheme.Radius.hostCard, inset: 4), 8)
        XCTAssertEqual(PluginSettingsTheme.Radius.nested(PluginSettingsTheme.Radius.field, inset: 10),
                       PluginSettingsTheme.Radius.chip)
    }

    func testAppIconCornerFollowsTheIconSize() {
        XCTAssertEqual(PluginSettingsTheme.Radius.appIcon(for: 76), 17)
        XCTAssertEqual(PluginSettingsTheme.Radius.appIcon(for: 1024), 229)
    }
}
