import AVFoundation
import CoreGraphics
import XCTest
@testable import ScreenshotPlugin

final class AutoZoomComposerTests: XCTestCase {
    private enum Hue: Equatable { case red, blue, other }

    func testZoomedFramesFollowTheClickWhileOtherFramesPassThrough() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source.mov")
        let destination = root.appendingPathComponent("zoomed.mov")
        let size = CGSize(width: 160, height: 120)
        // Four seconds of a static frame: red on the left, blue on the right.
        try await Self.writeFixture(to: source, size: size, frames: 40, framesPerSecond: 10)

        // One click on the right half after one second.
        let plan = AutoZoomPlan(clicks: [.init(time: 1, point: CGPoint(x: 0.75, y: 0.5))])
        try await AutoZoomComposer.render(source: source, to: destination, plan: plan, codec: .h264)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path), "The source recording is kept")

        let asset = AVURLAsset(url: destination)
        let track = try XCTUnwrap(try await asset.loadTracks(withMediaType: .video).first)
        let (naturalSize, timeRange) = try await track.load(.naturalSize, .timeRange)
        XCTAssertEqual(naturalSize, size)
        XCTAssertEqual(timeRange.duration.seconds, 4, accuracy: 0.1)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        // Before the click the frame is untouched: both halves are still visible.
        let early = try await generator.image(at: CMTime(seconds: 0.2, preferredTimescale: 600)).image
        XCTAssertEqual(try Self.hue(of: early, atFraction: CGPoint(x: 0.25, y: 0.5)), .red)
        XCTAssertEqual(try Self.hue(of: early, atFraction: CGPoint(x: 0.75, y: 0.5)), .blue)
        // While zoomed toward the right half, the whole viewport shows blue.
        let zoomed = try await generator.image(at: CMTime(seconds: 2, preferredTimescale: 600)).image
        XCTAssertEqual(try Self.hue(of: zoomed, atFraction: CGPoint(x: 0.25, y: 0.5)), .blue)
        XCTAssertEqual(try Self.hue(of: zoomed, atFraction: CGPoint(x: 0.75, y: 0.5)), .blue)
        // After the hold the recording is back at the full frame.
        let late = try await generator.image(at: CMTime(seconds: 3.9, preferredTimescale: 600)).image
        XCTAssertEqual(try Self.hue(of: late, atFraction: CGPoint(x: 0.25, y: 0.5)), .red)
        XCTAssertEqual(try Self.hue(of: late, atFraction: CGPoint(x: 0.75, y: 0.5)), .blue)
    }

    func testCancellationRemovesThePartialOutput() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source.mov")
        let destination = root.appendingPathComponent("zoomed.mov")
        try await Self.writeFixture(to: source, size: CGSize(width: 160, height: 120), frames: 20, framesPerSecond: 10)

        let plan = AutoZoomPlan(clicks: [.init(time: 0.5, point: CGPoint(x: 0.5, y: 0.5))])
        let task = Task {
            try await AutoZoomComposer.render(source: source, to: destination, plan: plan, codec: .h264)
        }
        task.cancel()
        do {
            // A render that finished before the cancellation was observed is also acceptable.
            try await task.value
            XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
        } catch {
            XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
    }

    private static func writeFixture(to url: URL, size: CGSize, frames: Int, framesPerSecond: Int32) async throws {
        let width = Int(size.width), height = Int(size.height)
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
        ])
        writer.add(input)
        XCTAssertTrue(writer.startWriting(), String(describing: writer.error))
        writer.startSession(atSourceTime: .zero)
        let pool = try XCTUnwrap(adaptor.pixelBufferPool)
        for index in 0..<frames {
            var created: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &created)
            let buffer = try XCTUnwrap(created)
            CVPixelBufferLockBaseAddress(buffer, [])
            let base = try XCTUnwrap(CVPixelBufferGetBaseAddress(buffer))
            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            for y in 0..<height {
                for x in 0..<width {
                    let pixel = base.advanced(by: y * bytesPerRow + x * 4).assumingMemoryBound(to: UInt8.self)
                    let isLeft = x < width / 2
                    pixel[0] = isLeft ? 0 : 255   // blue
                    pixel[1] = 0                  // green
                    pixel[2] = isLeft ? 255 : 0   // red
                    pixel[3] = 255
                }
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])
            while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(2)) }
            XCTAssertTrue(adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: framesPerSecond)))
        }
        input.markAsFinished()
        writer.endSession(atSourceTime: CMTime(value: CMTimeValue(frames), timescale: framesPerSecond))
        await writer.finishWriting()
        XCTAssertEqual(writer.status, .completed, String(describing: writer.error))
    }

    private static func hue(of image: CGImage, atFraction point: CGPoint) throws -> Hue {
        let width = image.width, height = image.height
        let context = try XCTUnwrap(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let data = try XCTUnwrap(context.data)
        let x = min(width - 1, Int(CGFloat(width) * point.x))
        let row = min(height - 1, Int(CGFloat(height) * point.y))
        let pixel = data.advanced(by: row * context.bytesPerRow + x * 4).assumingMemoryBound(to: UInt8.self)
        let red = CGFloat(pixel[0]) / 255, blue = CGFloat(pixel[2]) / 255
        if red > 0.6, blue < 0.4 { return .red }
        if blue > 0.6, red < 0.4 { return .blue }
        return .other
    }
}
