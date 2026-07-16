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
        //    endless WAV and see 48 kHz stereo audio, no video.
        let controller = TeamTalkConnectionController(preferencesStore: AppPreferencesStore())
        let probe = controller.probeMediaFileLocked(path: url.absoluteString)
        XCTAssertTrue(probe.sdkSupported, "SDK/FFmpeg rejected the loopback WAV stream")
        XCTAssertTrue(probe.hasAudio, "probe found no audio format")
        XCTAssertFalse(probe.hasVideo)

        // 2. Realtime pacing: reading for ~3 s must yield roughly 3 s worth of
        //    48 kHz/16-bit/stereo PCM (192 000 B/s) whether or not the capture
        //    device delivers anything (silence is padded in).
        let counter = ByteCountingDelegate()
        let session = URLSession(configuration: .ephemeral, delegate: counter, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: url)
        task.resume()
        Thread.sleep(forTimeInterval: 3.0)
        task.cancel()

        let bytesPerSecond = 192_000.0
        let received = Double(counter.receivedBytes)
        XCTAssertGreaterThan(received, bytesPerSecond * 1.5,
                             "stream is starving — silence padding is not keeping it alive")
        XCTAssertLessThan(received, bytesPerSecond * 6.0,
                          "stream is not paced to realtime (dumping data)")
    }
}

private final class ByteCountingDelegate: NSObject, URLSessionDataDelegate {
    private let lock = NSLock()
    private var bytes = 0

    var receivedBytes: Int {
        lock.lock()
        defer { lock.unlock() }
        return bytes
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        bytes += data.count
        lock.unlock()
    }
}
