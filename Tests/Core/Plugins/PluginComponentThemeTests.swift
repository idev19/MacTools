import AppKit
import SwiftUI
import XCTest
@testable import MacToolsPluginKit

final class PluginComponentThemeTests: XCTestCase {
    func testSystemDataSeriesHasEightDistinctSlotsAndFoldsExtrasIntoOther() {
        for scheme in [ColorScheme.light, .dark] {
            let palette = PluginComponentTheme.DataSeriesPalette.system(colorScheme: scheme)
            XCTAssertEqual(palette.slots.count, 8)
            XCTAssertEqual(Set(palette.slots).count, 8, "\(scheme)")
            XCTAssertEqual(palette.color(at: 0), palette.primary)
            XCTAssertEqual(palette.color(at: 7), palette.octonary)
            // A ninth series never recycles a hue that already means something.
            XCTAssertEqual(palette.color(at: 8), palette.other)
            XCTAssertEqual(palette.color(at: -1), palette.other)
            XCTAssertFalse(palette.slots.contains(palette.other))
        }
    }

    func testSequentialRampClimbsAwayFromTheSurface() throws {
        let light = PluginComponentTheme.DataSeriesPalette.system(colorScheme: .light)
        let dark = PluginComponentTheme.DataSeriesPalette.system(colorScheme: .dark)
        let lightLuminance = try light.sequential.map(Self.luminance)
        let darkLuminance = try dark.sequential.map(Self.luminance)
        XCTAssertEqual(lightLuminance, lightLuminance.sorted(by: >), "Near zero is lightest on a light surface")
        XCTAssertEqual(darkLuminance, darkLuminance.sorted(), "Near zero is darkest on a dark surface")
        XCTAssertEqual(light.sequentialColor(at: 0), light.sequential.first)
        XCTAssertEqual(light.sequentialColor(at: 1), light.sequential.last)
        XCTAssertEqual(light.sequentialColor(at: 2), light.sequential.last)
        XCTAssertEqual(light.sequentialColor(at: .nan), light.sequential.first)
    }

    func testSixSlotPaletteStillProvidesEveryRole() {
        let palette = PluginComponentTheme.DataSeriesPalette(
            primary: .blue, secondary: .orange, tertiary: .green,
            quaternary: .purple, quinary: .teal, senary: .yellow
        )
        XCTAssertEqual(palette.slots.count, 8)
        XCTAssertFalse(palette.sequential.isEmpty)
        XCTAssertEqual(palette.divergingPositive, .blue)
        XCTAssertEqual(palette.color(at: 9), palette.other)
    }

    private static func luminance(_ color: Color) throws -> Double {
        let resolved = try XCTUnwrap(NSColor(color).usingColorSpace(.sRGB))
        func linear(_ component: CGFloat) -> Double {
            let value = Double(component)
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(resolved.redComponent)
            + 0.7152 * linear(resolved.greenComponent)
            + 0.0722 * linear(resolved.blueComponent)
    }
}
