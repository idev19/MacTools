import AppKit
import CoreImage
import Vision
import XCTest
@testable import ScreenshotPlugin

@MainActor
final class AnnotationRendererTests: XCTestCase {
    func testExportKeepsQRCodeRedactedUnderOtherAnnotationsAtBothDisplayScales() throws {
        let payload = "mactools-private-token"
        let filter = try XCTUnwrap(CIFilter(name: "CIQRCodeGenerator"))
        filter.setValue(Data(payload.utf8), forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        let generated = try XCTUnwrap(filter.outputImage)
            .transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        let qr = try XCTUnwrap(CIContext().createCGImage(generated, from: generated.extent))
        let padding = 24
        let width = qr.width + padding * 2
        let height = qr.height + padding * 2
        let context = try XCTUnwrap(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .none
        context.draw(qr, in: CGRect(x: padding, y: padding, width: qr.width, height: qr.height))
        let original = try XCTUnwrap(context.makeImage())
        XCTAssertEqual(try decodedPayloads(original), [payload], "The source fixture must be readable")

        for scale: CGFloat in [1, 2] {
            let size = NSSize(width: CGFloat(width) / scale, height: CGFloat(height) / scale)
            let region = NSRect(x: CGFloat(padding) / scale, y: CGFloat(padding) / scale,
                                width: CGFloat(qr.width) / scale, height: CGFloat(qr.height) / scale)
            let stroke = Stroke(color: .red, width: 2)
            let renderer = AnnotationRenderer(image: original, scale: scale, size: size)
            // These effects sample the unredacted source, so neither may uncover the mask.
            let raster = try XCTUnwrap(renderer.render(
                selection: NSRect(origin: .zero, size: size),
                items: [.qrMask(region), Item(shape: .mosaic(region), stroke: stroke)],
                draft: Item(shape: .blur(region), stroke: stroke),
                radius: 0, shadowSize: 0, shadowColor: .black
            ))
            let bitmap = try XCTUnwrap(NSBitmapImageRep(data: ScreenshotImageEncoder.encodePNG(raster)))
            XCTAssertTrue(try decodedPayloads(XCTUnwrap(bitmap.cgImage)).isEmpty, "Scale: \(scale)")
            let center = try XCTUnwrap(bitmap.colorAt(x: width / 2, y: height / 2)?.usingColorSpace(.deviceRGB))
            XCTAssertEqual(center.alphaComponent, 1)
            XCTAssertEqual(center.redComponent, 0)
            XCTAssertEqual(center.greenComponent, 0)
            XCTAssertEqual(center.blueComponent, 0)
            let outside = try XCTUnwrap(bitmap.colorAt(x: 0, y: 0)?.usingColorSpace(.deviceRGB))
            XCTAssertEqual(outside.redComponent, 1)
        }
    }

    func testSpotlightDimsOnlyOutsideItsRoundedWindowsWithinTheSelection() throws {
        let width = 200, height = 120
        let context = try XCTUnwrap(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let original = try XCTUnwrap(context.makeImage())
        let renderer = AnnotationRenderer(image: original, scale: 1, size: NSSize(width: width, height: height))
        let selection = NSRect(x: 20, y: 10, width: 160, height: 100)
        let window = NSRect(x: 60, y: 40, width: 60, height: 40)
        let stroke = Stroke(color: .white, width: 0)
        // A second, overlapping window drafted mid-drag must not re-dim the shared area.
        let draft = Item(shape: .spotlight(NSRect(x: 100, y: 60, width: 40, height: 30)), stroke: stroke)
        let raster = try XCTUnwrap(renderer.render(
            selection: selection, items: [Item(shape: .spotlight(window), stroke: stroke)], draft: draft,
            radius: 0, shadowSize: 0, shadowColor: .black
        ))
        XCTAssertEqual(raster.image.width, 160)
        XCTAssertEqual(raster.image.height, 100)
        let output = try XCTUnwrap(CGContext(
            data: nil, width: 160, height: 100, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        output.draw(raster.image, in: CGRect(x: 0, y: 0, width: 160, height: 100))
        let data = try XCTUnwrap(output.data)
        // Bitmap rows run top-down from the selection's top edge; view points are bottom-up.
        func brightness(atViewX x: CGFloat, y: CGFloat) -> CGFloat {
            let column = Int(x - selection.minX)
            let row = Int(selection.maxY - y)
            let pixel = data.advanced(by: row * output.bytesPerRow + column * 4).assumingMemoryBound(to: UInt8.self)
            XCTAssertEqual(pixel[3], 255)
            return CGFloat(pixel[0]) / 255
        }
        let dimmed = 1 - AnnotationRenderer.spotlightDimAlpha
        // Inside the window the pixels are untouched, including the overlap of both windows.
        XCTAssertEqual(brightness(atViewX: 90, y: 60), 1, accuracy: 0.02)
        XCTAssertEqual(brightness(atViewX: 110, y: 70), 1, accuracy: 0.02)
        // The rest of the selection is dimmed by the spotlight alpha.
        XCTAssertEqual(brightness(atViewX: 30, y: 20), dimmed, accuracy: 0.05)
        XCTAssertEqual(brightness(atViewX: 170, y: 100), dimmed, accuracy: 0.05)
        // Rounded corners: the window's exact corner pixel is outside the shape, its edge midpoint inside.
        XCTAssertEqual(brightness(atViewX: 60.5, y: 40.5), dimmed, accuracy: 0.05)
        XCTAssertEqual(brightness(atViewX: 90, y: 40.5), 1, accuracy: 0.02)
    }

    private func decodedPayloads(_ image: CGImage) throws -> [String] {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        try VNImageRequestHandler(cgImage: image).perform([request])
        return request.results?.compactMap(\.payloadStringValue) ?? []
    }
}
