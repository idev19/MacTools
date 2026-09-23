import AVFoundation
import CoreImage
import CoreMedia
import CoreVideo

enum AutoZoomError: Error {
    case noVideoTrack
    case invalidDuration
    case readFailed
    case writeFailed
    case renderFailed
}

/// Re-encodes a finished recording with the plan's zoom motion into a separate file.
enum AutoZoomComposer {
    static let framesPerSecond: Int32 = 30

    static func render(source: URL, to destination: URL, plan: AutoZoomPlan, codec: AVVideoCodecType,
                       progress: (@Sendable (Double) -> Void)? = nil) async throws {
        let asset = AVURLAsset(url: source)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw AutoZoomError.noVideoTrack
        }
        let (naturalSize, timeRange) = try await track.load(.naturalSize, .timeRange)
        let size = CGSize(width: naturalSize.width.rounded(), height: naturalSize.height.rounded())
        guard size.width >= 2, size.height >= 2, timeRange.duration.seconds > 0 else {
            throw AutoZoomError.invalidDuration
        }

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ])
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { throw AutoZoomError.readFailed }
        reader.add(output)

        try? FileManager.default.removeItem(at: destination)
        let writer = try AVAssetWriter(outputURL: destination, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
        ])
        guard writer.canAdd(input) else { throw AutoZoomError.writeFailed }
        writer.add(input)
        guard reader.startReading() else { throw reader.error ?? AutoZoomError.readFailed }
        guard writer.startWriting() else {
            reader.cancelReading()
            throw writer.error ?? AutoZoomError.writeFailed
        }
        writer.startSession(atSourceTime: timeRange.start)

        do {
            try await encode(from: output, reader: reader, writer: writer, input: input, adaptor: adaptor,
                             plan: plan, size: size, timeRange: timeRange, progress: progress)
        } catch {
            reader.cancelReading()
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
        input.markAsFinished()
        writer.endSession(atSourceTime: timeRange.end)
        await writer.finishWriting()
        guard writer.status == .completed else {
            try? FileManager.default.removeItem(at: destination)
            throw writer.error ?? AutoZoomError.writeFailed
        }
    }

    /// Moves the processed file into the recording's place; the temporary file is consumed.
    static func replace(_ url: URL, with processed: URL) throws {
        _ = try FileManager.default.replaceItemAt(url, withItemAt: processed)
    }

    /// Frames are emitted on a fixed cadence only while the source or the zoom changes, so static
    /// content stays compact and zoom motion stays smooth even when the recording has sparse samples.
    private static func encode(from output: AVAssetReaderTrackOutput, reader: AVAssetReader, writer: AVAssetWriter,
                               input: AVAssetWriterInput, adaptor: AVAssetWriterInputPixelBufferAdaptor,
                               plan: AutoZoomPlan, size: CGSize, timeRange: CMTimeRange,
                               progress: (@Sendable (Double) -> Void)?) async throws {
        // Geometry only: no color management, so untouched and zoomed frames share one appearance.
        let context = CIContext(options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull(),
                                          .cacheIntermediates: false])
        var simulator = AutoZoomSimulator(plan: plan)
        let end = timeRange.end
        let duration = max(timeRange.duration.seconds, .leastNonzeroMagnitude)
        var pending = output.copyNextSampleBuffer()
        var current: CVPixelBuffer?
        var sourceChanged = false
        var emitted: AutoZoomState?
        var ticks: CMTimeValue = 0

        while true {
            try Task.checkCancellation()
            let tick = min(CMTimeAdd(timeRange.start, CMTime(value: ticks, timescale: framesPerSecond)), end)
            // Present the newest source frame that is due; static content produces no new samples.
            while let sample = pending, CMSampleBufferGetPresentationTimeStamp(sample) <= tick {
                if let buffer = CMSampleBufferGetImageBuffer(sample) {
                    current = buffer
                    sourceChanged = true
                }
                pending = output.copyNextSampleBuffer()
            }
            if pending == nil, reader.status == .failed { throw reader.error ?? AutoZoomError.readFailed }
            let elapsed = CMTimeSubtract(tick, timeRange.start).seconds
            let state = simulator.advance(to: elapsed)
            if let current, sourceChanged || state != emitted {
                let frame: CVPixelBuffer
                if state.isIdentity {
                    frame = current
                } else {
                    frame = try renderFrame(current, state: state, size: size, context: context,
                                            pool: adaptor.pixelBufferPool)
                }
                try await append(frame, at: tick, to: input, adaptor: adaptor, writer: writer)
                emitted = state
                sourceChanged = false
            }
            ticks += 1
            if ticks % 15 == 0 { progress?(min(1, elapsed / duration)) }
            guard tick < end else { break }
        }
    }

    private static func append(_ buffer: CVPixelBuffer, at time: CMTime, to input: AVAssetWriterInput,
                               adaptor: AVAssetWriterInputPixelBufferAdaptor, writer: AVAssetWriter) async throws {
        while !input.isReadyForMoreMediaData {
            guard writer.status == .writing else { throw writer.error ?? AutoZoomError.writeFailed }
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(4))
        }
        guard adaptor.append(buffer, withPresentationTime: time) else {
            throw writer.error ?? AutoZoomError.writeFailed
        }
    }

    private static func renderFrame(_ source: CVPixelBuffer, state: AutoZoomState, size: CGSize,
                                    context: CIContext, pool: CVPixelBufferPool?) throws -> CVPixelBuffer {
        guard let pool else { throw AutoZoomError.renderFailed }
        var created: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &created) == kCVReturnSuccess,
              let target = created else { throw AutoZoomError.renderFailed }
        // Keep the source's color tags so the encoder treats both frame kinds alike.
        CVBufferPropagateAttachments(source, target)
        let crop = state.cropRect(in: size)
        let zoom = size.width / crop.width
        let image = CIImage(cvPixelBuffer: source, options: [.colorSpace: NSNull()])
            .transformed(by: CGAffineTransform(scaleX: zoom, y: zoom).translatedBy(x: -crop.minX, y: -crop.minY))
            .cropped(to: CGRect(origin: .zero, size: size))
        context.render(image, to: target, bounds: CGRect(origin: .zero, size: size), colorSpace: nil)
        return target
    }
}
