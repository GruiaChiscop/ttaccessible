//
//  DeviceStreamSourceTests.swift
//  ttaccessibleTests
//
//  Live-loopback integration check for AudioDeviceStreamSource (device → channel
//  media streaming): starts the real capture + loopback WAV server, verifies the
//  TeamTalk SDK's FFmpeg probe accepts the stream, and confirms the server paces
//  output to realtime — the guarantee that a silent or stalled device never
//  starves the SDK reader (a starved stream ends the broadcast).
//

import XCTest
@testable import ttaccessible

final class DeviceStreamSourceTests: XCTestCase {

    func testServesSDKCompatiblePacedStream() throws {
        let devices = InputAudioDeviceResolver.availableInputDevices()
        try XCTSkipIf(devices.isEmpty, "No audio input devices on this machine")

        let source = AudioDeviceStreamSource(device: devices[0])
        let url = try source.start()
        defer { source.stop() }

        // 1. The SDK's own probe (TT_GetMediaFileInfo → FFmpeg) must accept the
        //    endless ADTS stream, see 48 kHz audio, and — the reason the stream
        //    is AAC rather than WAV — finish its analysis fast. Everything the
        //    analyzer consumes becomes permanent broadcast latency, so this
        //    bound is a real latency budget (PCM measured ~4.3 s here).
        let controller = TeamTalkConnectionController(preferencesStore: AppPreferencesStore())
        let probeStart = Date()
        let probe = controller.probeMediaFileLocked(path: url.absoluteString)
        let probeSeconds = Date().timeIntervalSince(probeStart)
        XCTAssertTrue(probe.sdkSupported, "SDK/FFmpeg rejected the loopback ADTS stream")
        XCTAssertTrue(probe.hasAudio, "probe found no audio format")
        XCTAssertFalse(probe.hasVideo)
        XCTAssertLessThan(probeSeconds, 2.5,
                          "FFmpeg open consumed \(probeSeconds)s of stream — that much becomes broadcast latency")

        // 2. Realtime pacing: reading for ~3 s must yield roughly 3 s of MEDIA
        //    TIME whether or not the capture device delivers anything (silence
        //    is padded in). Byte counts are useless for AAC — silence encodes
        //    to a few bytes per frame — so count ADTS frames instead: each is
        //    1024 samples ≈ 21.3 ms, so 3 s ≈ 140 frames.
        let counter = ByteCountingDelegate()
        let session = URLSession(configuration: .ephemeral, delegate: counter, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: url)
        task.resume()
        Thread.sleep(forTimeInterval: 3.0)
        task.cancel()

        let frames = counter.adtsFrameCount
        XCTAssertGreaterThan(frames, 70,
                             "stream is starving — silence padding is not keeping it alive (\(frames) ADTS frames in 3 s)")
        XCTAssertLessThan(frames, 400,
                          "stream is not paced to realtime — dumping data (\(frames) ADTS frames in 3 s)")
    }
}

private final class ByteCountingDelegate: NSObject, URLSessionDataDelegate {
    private let lock = NSLock()
    private var bytes = 0
    private var frames = 0
    private var previousByte: UInt8 = 0

    var receivedBytes: Int {
        lock.lock()
        defer { lock.unlock() }
        return bytes
    }

    /// ADTS frames seen so far (0xFFF sync + MPEG-4/no-CRC marker 0xF1).
    var adtsFrameCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return frames
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        bytes += data.count
        for byte in data {
            if previousByte == 0xFF && byte == 0xF1 {
                frames += 1
            }
            previousByte = byte
        }
        lock.unlock()
    }
}
