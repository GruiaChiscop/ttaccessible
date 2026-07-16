//
//  AudioDeviceStreamSource.swift
//  ttaccessible
//

import Foundation
import AudioToolbox
import CoreAudio
import Network

enum AudioDeviceStreamSourceError: Error {
    case deviceUnavailable
    case captureStartFailed
    case serverStartFailed
}

/// Captures a CoreAudio input device and serves it as an endless 48 kHz / 16-bit /
/// stereo WAV stream on a loopback HTTP server, so the SDK's media streamer can
/// broadcast it to the channel exactly like a URL stream.
///
/// The server paces its output against the wall clock and substitutes silence
/// whenever the device stops delivering (silent source, unplugged, stalled), so the
/// SDK never sees the stream starve — a starved stream would otherwise be treated
/// as finished and the broadcast would stop.
final class AudioDeviceStreamSource {

    nonisolated static let outputSampleRate = 48_000
    nonisolated static let outputChannels = 2

    private let device: InputAudioDeviceInfo
    private let ring = PCMRing(capacityFrames: outputSampleRate * 2, channels: outputChannels)
    private let serverQueue = DispatchQueue(label: "com.ttaccessible.device-stream-server")

    // Capture state (mutated on start/stop only; callback reads via unmanaged self).
    private var audioUnit: AudioUnit?
    private var captureBufferList: UnsafeMutableRawPointer?
    private var captureBufferCapacity: Int = 0
    private var captureSampleRate: Double = 48_000
    private var captureChannels: Int = 2

    // Server state (guarded by serverQueue).
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: StreamConnection] = [:]
    private var stopped = false

    private let stopLock = NSLock()
    private var didStop = false

    init(device: InputAudioDeviceInfo) {
        self.device = device
    }

    deinit {
        stop()
    }

    /// Start capture and the loopback server. Returns the URL the SDK should stream.
    func start() throws -> URL {
        guard let deviceID = InputAudioDeviceResolver.audioDeviceID(forUID: device.uid) else {
            throw AudioDeviceStreamSourceError.deviceUnavailable
        }
        let port = try startServer()
        do {
            try startCapture(deviceID: deviceID)
        } catch {
            stop()
            throw error
        }
        guard let url = URL(string: "http://127.0.0.1:\(port)/device-stream.wav") else {
            stop()
            throw AudioDeviceStreamSourceError.serverStartFailed
        }
        AudioLogger.log("device stream: source started device=%@ url=%@", device.name, url.absoluteString)
        return url
    }

    func stop() {
        stopLock.lock()
        let alreadyStopped = didStop
        didStop = true
        stopLock.unlock()
        guard alreadyStopped == false else { return }

        // Capture first, so no more ring writes; then the server.
        stopCapture()
        serverQueue.sync {
            stopped = true
            for connection in connections.values {
                connection.cancel()
            }
            connections.removeAll()
            listener?.cancel()
            listener = nil
        }
        AudioLogger.log("device stream: source stopped device=%@", device.name)
    }

    // MARK: - Capture (standalone AUHAL, mirrors AdvancedMicrophoneAudioEngine)

    private func startCapture(deviceID: AudioDeviceID) throws {
        var componentDesc = AudioComponentDescription(
            componentType: kAudioUnitType_Output,
            componentSubType: kAudioUnitSubType_HALOutput,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        guard let component = AudioComponentFindNext(nil, &componentDesc) else {
            throw AudioDeviceStreamSourceError.captureStartFailed
        }
        var unit: AudioUnit?
        guard AudioComponentInstanceNew(component, &unit) == noErr, let au = unit else {
            throw AudioDeviceStreamSourceError.captureStartFailed
        }

        func fail() -> AudioDeviceStreamSourceError {
            AudioComponentInstanceDispose(au)
            return .captureStartFailed
        }

        var enableIO: UInt32 = 1
        guard AudioUnitSetProperty(au, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1,
                                   &enableIO, UInt32(MemoryLayout<UInt32>.size)) == noErr else { throw fail() }
        var disableIO: UInt32 = 0
        guard AudioUnitSetProperty(au, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0,
                                   &disableIO, UInt32(MemoryLayout<UInt32>.size)) == noErr else { throw fail() }
        var devID = deviceID
        guard AudioUnitSetProperty(au, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0,
                                   &devID, UInt32(MemoryLayout<AudioDeviceID>.size)) == noErr else { throw fail() }

        var nativeASBD = AudioStreamBasicDescription()
        var asbdSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        guard AudioUnitGetProperty(au, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1,
                                   &nativeASBD, &asbdSize) == noErr else { throw fail() }

        let channelCount = max(Int(nativeASBD.mChannelsPerFrame), 1)
        let sampleRate = nativeASBD.mSampleRate > 0 ? nativeASBD.mSampleRate : 48_000

        // Int16 interleaved at the device's native rate (AUHAL converts format,
        // never rate — resampling to 48 kHz happens in the input callback).
        var outputASBD = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: UInt32(MemoryLayout<Int16>.size * channelCount),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(MemoryLayout<Int16>.size * channelCount),
            mChannelsPerFrame: UInt32(channelCount),
            mBitsPerChannel: UInt32(MemoryLayout<Int16>.size * 8),
            mReserved: 0
        )
        guard AudioUnitSetProperty(au, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1,
                                   &outputASBD, UInt32(MemoryLayout<AudioStreamBasicDescription>.size)) == noErr else { throw fail() }

        var maxFrames: UInt32 = 4096
        AudioUnitSetProperty(au, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0,
                             &maxFrames, UInt32(MemoryLayout<UInt32>.size))

        // Preallocate the render target (single interleaved buffer).
        let byteCapacity = Int(maxFrames) * channelCount * MemoryLayout<Int16>.size
        let ablSize = MemoryLayout<AudioBufferList>.size
        let ablRawPtr = UnsafeMutableRawPointer.allocate(byteCount: ablSize, alignment: MemoryLayout<AudioBufferList>.alignment)
        ablRawPtr.initializeMemory(as: UInt8.self, repeating: 0, count: ablSize)
        let dataPtr = UnsafeMutableRawPointer.allocate(byteCount: byteCapacity, alignment: MemoryLayout<Int16>.alignment)
        let ablPtr = ablRawPtr.assumingMemoryBound(to: AudioBufferList.self)
        ablPtr.pointee.mNumberBuffers = 1
        ablPtr.pointee.mBuffers.mNumberChannels = UInt32(channelCount)
        ablPtr.pointee.mBuffers.mDataByteSize = UInt32(byteCapacity)
        ablPtr.pointee.mBuffers.mData = dataPtr

        captureBufferList = ablRawPtr
        captureBufferCapacity = byteCapacity
        captureSampleRate = sampleRate
        captureChannels = channelCount

        var callbackStruct = AURenderCallbackStruct(
            inputProc: deviceStreamInputCallback,
            inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
        )
        guard AudioUnitSetProperty(au, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 0,
                                   &callbackStruct, UInt32(MemoryLayout<AURenderCallbackStruct>.size)) == noErr else {
            freeCaptureBuffers()
            throw fail()
        }
        guard AudioUnitInitialize(au) == noErr else {
            freeCaptureBuffers()
            throw fail()
        }
        guard AudioOutputUnitStart(au) == noErr else {
            AudioUnitUninitialize(au)
            freeCaptureBuffers()
            throw fail()
        }
        audioUnit = au
        AudioLogger.log("device stream: capture started device=%@ rate=%d ch=%d",
                        device.name, Int(sampleRate.rounded()), channelCount)
    }

    private func stopCapture() {
        guard let au = audioUnit else { return }
        audioUnit = nil
        AudioOutputUnitStop(au)
        AudioUnitUninitialize(au)
        AudioComponentInstanceDispose(au)
        freeCaptureBuffers()
    }

    private func freeCaptureBuffers() {
        if let ablRawPtr = captureBufferList {
            let ablPtr = ablRawPtr.assumingMemoryBound(to: AudioBufferList.self)
            ablPtr.pointee.mBuffers.mData?.deallocate()
            ablRawPtr.deallocate()
            captureBufferList = nil
        }
        captureBufferCapacity = 0
    }

    /// Called from the AUHAL input callback: render, map to stereo, resample to
    /// 48 kHz and push into the ring.
    fileprivate func handleInput(
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inBusNumber: UInt32,
        inNumberFrames: UInt32
    ) {
        guard let au = audioUnit, let ablRawPtr = captureBufferList else { return }
        let frames = Int(inNumberFrames)
        let channels = captureChannels
        let neededBytes = frames * channels * MemoryLayout<Int16>.size
        guard neededBytes <= captureBufferCapacity else { return }

        let ablPtr = ablRawPtr.assumingMemoryBound(to: AudioBufferList.self)
        ablPtr.pointee.mBuffers.mDataByteSize = UInt32(neededBytes)
        guard AudioUnitRender(au, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ablPtr) == noErr,
              let rawData = ablPtr.pointee.mBuffers.mData else {
            return
        }
        let input = rawData.assumingMemoryBound(to: Int16.self)

        // Map to stereo: mono duplicates, >2 channels keep the first two.
        var stereo = [Int16](repeating: 0, count: frames * 2)
        if channels == 1 {
            for frame in 0..<frames {
                let sample = input[frame]
                stereo[frame * 2] = sample
                stereo[frame * 2 + 1] = sample
            }
        } else {
            for frame in 0..<frames {
                stereo[frame * 2] = input[frame * channels]
                stereo[frame * 2 + 1] = input[frame * channels + 1]
            }
        }

        let resampled = AudioPCMResampler.resampleInterleaved(
            stereo,
            frameCount: frames,
            channels: 2,
            inputRate: captureSampleRate,
            outputRate: Double(Self.outputSampleRate)
        )
        ring.write(resampled.samples, frames: resampled.frameCount)
    }

    // MARK: - Loopback HTTP server

    private func startServer() throws -> UInt16 {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: .any)
        parameters.allowLocalEndpointReuse = true
        let listener: NWListener
        do {
            listener = try NWListener(using: parameters)
        } catch {
            AudioLogger.log("device stream: listener create failed — %@", error.localizedDescription)
            throw AudioDeviceStreamSourceError.serverStartFailed
        }

        let readySemaphore = DispatchSemaphore(value: 0)
        var readyPort: UInt16?
        listener.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                readyPort = listener.port?.rawValue
                readySemaphore.signal()
            case .failed(let error):
                AudioLogger.log("device stream: listener failed — %@", error.localizedDescription)
                readySemaphore.signal()
                self?.serverQueue.async { self?.listener = nil }
            case .cancelled:
                readySemaphore.signal()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.acceptConnection(connection)
        }

        self.listener = listener
        stopped = false
        listener.start(queue: serverQueue)

        _ = readySemaphore.wait(timeout: .now() + 5)
        guard let port = readyPort else {
            listener.cancel()
            self.listener = nil
            throw AudioDeviceStreamSourceError.serverStartFailed
        }
        return port
    }

    private func acceptConnection(_ connection: NWConnection) {
        // Runs on serverQueue (the listener's queue).
        guard stopped == false else {
            connection.cancel()
            return
        }
        let stream = StreamConnection(connection: connection, ring: ring, queue: serverQueue) { [weak self] finished in
            self?.connections.removeValue(forKey: ObjectIdentifier(finished))
        }
        connections[ObjectIdentifier(stream)] = stream
        stream.start()
    }

    // MARK: - Per-connection realtime pump

    /// One accepted HTTP connection: consumes the request head, replies with an
    /// endless WAV body paced to realtime, padding with silence whenever capture
    /// falls behind so the stream never starves.
    private final class StreamConnection {
        private let connection: NWConnection
        private let ring: PCMRing
        private let queue: DispatchQueue
        private let onFinish: (StreamConnection) -> Void

        private var timer: DispatchSourceTimer?
        private var cursor: UInt64 = 0
        private var framesSent: UInt64 = 0
        private var epoch: DispatchTime = .now()
        private var pendingSendBytes = 0
        private var finished = false

        /// Operating buffer: the pump deliberately runs this far behind the
        /// capture live edge, so scheduling jitter on either side is absorbed
        /// by real buffered audio instead of audible silence patches.
        private static let bufferFrames = AudioDeviceStreamSource.outputSampleRate * 3 / 10
        /// Tolerated shortfall beyond the operating buffer before silence is
        /// padded in — only a genuine capture stall gets this far.
        private static let graceFrames = AudioDeviceStreamSource.outputSampleRate / 10
        /// Maximum backlog of captured-but-unsent audio before skipping ahead
        /// (must comfortably exceed bufferFrames, the steady-state backlog).
        private static let maxLagFrames = AudioDeviceStreamSource.outputSampleRate * 3 / 5
        /// Stop enqueueing while this much audio is stuck in the socket (the SDK
        /// reader stalled); the pump then skips ahead instead of buffering.
        private static let maxPendingSendBytes = AudioDeviceStreamSource.outputSampleRate
            * AudioDeviceStreamSource.outputChannels * 2 * 2  // 2 seconds

        private static let tickMSec = 20

        init(connection: NWConnection, ring: PCMRing, queue: DispatchQueue, onFinish: @escaping (StreamConnection) -> Void) {
            self.connection = connection
            self.ring = ring
            self.queue = queue
            self.onFinish = onFinish
        }

        func start() {
            connection.stateUpdateHandler = { [weak self] state in
                switch state {
                case .failed, .cancelled:
                    self?.finish()
                default:
                    break
                }
            }
            connection.start(queue: queue)
            receiveRequestHead(accumulated: Data())
        }

        func cancel() {
            finish()
        }

        private func finish() {
            guard finished == false else { return }
            finished = true
            timer?.cancel()
            timer = nil
            connection.cancel()
            onFinish(self)
        }

        private func receiveRequestHead(accumulated: Data) {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
                guard let self, self.finished == false else { return }
                if error != nil || isComplete {
                    self.finish()
                    return
                }
                var head = accumulated
                if let data { head.append(data) }
                if head.range(of: Data("\r\n\r\n".utf8)) != nil {
                    self.beginStreaming()
                } else if head.count < 16_384 {
                    self.receiveRequestHead(accumulated: head)
                } else {
                    self.finish()
                }
            }
        }

        private func beginStreaming() {
            let headers = "HTTP/1.1 200 OK\r\n"
                + "Content-Type: audio/wav\r\n"
                + "Cache-Control: no-store\r\n"
                + "Connection: close\r\n"
                + "\r\n"
            send(Data(headers.utf8))
            send(Self.wavStreamHeader())

            cursor = ring.liveEdge
            // Crediting the operating buffer as already-sent delays the first
            // send until that much capture has accumulated behind the cursor.
            framesSent = UInt64(Self.bufferFrames)
            epoch = .now()

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + .milliseconds(Self.tickMSec),
                           repeating: .milliseconds(Self.tickMSec),
                           leeway: .milliseconds(5))
            timer.setEventHandler { [weak self] in
                self?.tick()
            }
            self.timer = timer
            timer.resume()
        }

        private func tick() {
            guard finished == false else { return }

            let elapsedSec = Double(DispatchTime.now().uptimeNanoseconds - epoch.uptimeNanoseconds) / 1_000_000_000
            let targetFrames = UInt64(elapsedSec * Double(AudioDeviceStreamSource.outputSampleRate))
            guard targetFrames > framesSent else { return }
            var owed = Int(targetFrames - framesSent)
            // A long scheduler stall (sleep, suspension) would otherwise demand a
            // huge burst; skip the gap and resume live with the buffer restored.
            if owed > AudioDeviceStreamSource.outputSampleRate * 2 {
                framesSent = targetFrames + UInt64(Self.bufferFrames)
                cursor = ring.liveEdge
                return
            }

            // If the reader has stalled (socket backlog), drop this tick's audio
            // and keep the timeline moving so we stay live once it drains.
            if pendingSendBytes > Self.maxPendingSendBytes {
                framesSent = targetFrames + UInt64(Self.bufferFrames)
                cursor = ring.liveEdge
                return
            }

            // Keep the broadcast near-live: if capture ran ahead of what we've
            // sent by more than maxLag, skip forward (drops backlog audio).
            let liveEdge = ring.liveEdge
            if liveEdge > cursor, Int(liveEdge - cursor) > Self.maxLagFrames + owed {
                cursor = liveEdge - UInt64(Self.maxLagFrames)
            }

            let (samples, framesRead, newCursor) = ring.read(from: cursor, maxFrames: owed)
            if framesRead > 0 {
                cursor = newCursor
                framesSent += UInt64(framesRead)
                owed -= framesRead
                send(pcmData(samples))
            }

            // Capture isn't delivering (silent stall, unplug): pad silence so the
            // SDK's reader never starves. Padding the operating buffer on top
            // restores the jitter margin before real audio resumes, so recovery
            // doesn't crackle along with zero headroom.
            if owed > Self.graceFrames {
                let padFrames = owed + Self.bufferFrames
                let silence = [Int16](repeating: 0,
                                      count: padFrames * AudioDeviceStreamSource.outputChannels)
                framesSent += UInt64(padFrames)
                cursor = ring.liveEdge
                send(pcmData(silence))
            }
        }

        private func pcmData(_ samples: [Int16]) -> Data {
            samples.withUnsafeBufferPointer { Data(buffer: $0) }
        }

        private func send(_ data: Data) {
            guard finished == false, data.isEmpty == false else { return }
            pendingSendBytes += data.count
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                guard let self else { return }
                self.pendingSendBytes -= data.count
                if error != nil {
                    self.finish()
                }
            })
        }

        /// 44-byte WAV header with 0xFFFFFFFF chunk sizes — FFmpeg's WAV demuxer
        /// treats that as an unbounded live stream.
        private static func wavStreamHeader() -> Data {
            var data = Data()
            func appendUInt32(_ value: UInt32) {
                withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
            }
            func appendUInt16(_ value: UInt16) {
                withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
            }
            let sampleRate = UInt32(AudioDeviceStreamSource.outputSampleRate)
            let channels = UInt16(AudioDeviceStreamSource.outputChannels)
            let bytesPerFrame = UInt32(channels) * 2

            data.append(contentsOf: Array("RIFF".utf8))
            appendUInt32(0xFFFF_FFFF)
            data.append(contentsOf: Array("WAVE".utf8))
            data.append(contentsOf: Array("fmt ".utf8))
            appendUInt32(16)
            appendUInt16(1)  // PCM
            appendUInt16(channels)
            appendUInt32(sampleRate)
            appendUInt32(sampleRate * bytesPerFrame)
            appendUInt16(UInt16(bytesPerFrame))
            appendUInt16(16)  // bits per sample
            data.append(contentsOf: Array("data".utf8))
            appendUInt32(0xFFFF_FFFF)
            return data
        }
    }

    // MARK: - Ring buffer

    /// Fixed-capacity interleaved Int16 ring with absolute frame counters, so
    /// multiple connections read at independent cursors without consuming.
    private final class PCMRing {
        private let lock = NSLock()
        private var buffer: [Int16]
        private let capacityFrames: Int
        private let channels: Int
        private var writeFrames: UInt64 = 0

        init(capacityFrames: Int, channels: Int) {
            self.capacityFrames = capacityFrames
            self.channels = channels
            self.buffer = [Int16](repeating: 0, count: capacityFrames * channels)
        }

        var liveEdge: UInt64 {
            lock.lock()
            defer { lock.unlock() }
            return writeFrames
        }

        func write(_ samples: [Int16], frames: Int) {
            guard frames > 0 else { return }
            lock.lock()
            defer { lock.unlock() }
            // Writes larger than the ring keep only the newest capacity worth.
            let usableFrames = min(frames, capacityFrames)
            let skippedFrames = frames - usableFrames
            var writeIndex = Int((writeFrames + UInt64(skippedFrames)) % UInt64(capacityFrames))
            samples.withUnsafeBufferPointer { source in
                guard let base = source.baseAddress else { return }
                var sourceFrame = skippedFrames
                var remaining = usableFrames
                while remaining > 0 {
                    let run = min(remaining, capacityFrames - writeIndex)
                    buffer.withUnsafeMutableBufferPointer { dest in
                        dest.baseAddress!
                            .advanced(by: writeIndex * channels)
                            .update(from: base + sourceFrame * channels, count: run * channels)
                    }
                    sourceFrame += run
                    writeIndex = (writeIndex + run) % capacityFrames
                    remaining -= run
                }
            }
            writeFrames += UInt64(frames)
        }

        /// Copy up to `maxFrames` starting at absolute frame `cursor`. A cursor
        /// that has been overwritten is advanced to the oldest retained frame.
        func read(from cursor: UInt64, maxFrames: Int) -> ([Int16], Int, UInt64) {
            guard maxFrames > 0 else { return ([], 0, cursor) }
            lock.lock()
            defer { lock.unlock() }
            guard writeFrames > cursor else { return ([], 0, cursor) }

            let oldestRetained = writeFrames > UInt64(capacityFrames)
                ? writeFrames - UInt64(capacityFrames)
                : 0
            let effectiveCursor = max(cursor, oldestRetained)
            let available = Int(writeFrames - effectiveCursor)
            let framesToRead = min(maxFrames, available)
            guard framesToRead > 0 else { return ([], 0, effectiveCursor) }

            var output = [Int16](repeating: 0, count: framesToRead * channels)
            var readIndex = Int(effectiveCursor % UInt64(capacityFrames))
            output.withUnsafeMutableBufferPointer { dest in
                guard let destBase = dest.baseAddress else { return }
                var destFrame = 0
                var remaining = framesToRead
                buffer.withUnsafeBufferPointer { source in
                    guard let sourceBase = source.baseAddress else { return }
                    while remaining > 0 {
                        let run = min(remaining, capacityFrames - readIndex)
                        destBase
                            .advanced(by: destFrame * channels)
                            .update(from: sourceBase + readIndex * channels, count: run * channels)
                        destFrame += run
                        readIndex = (readIndex + run) % capacityFrames
                        remaining -= run
                    }
                }
            }
            return (output, framesToRead, effectiveCursor + UInt64(framesToRead))
        }
    }
}

private func deviceStreamInputCallback(
    inRefCon: UnsafeMutableRawPointer,
    ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp: UnsafePointer<AudioTimeStamp>,
    inBusNumber: UInt32,
    inNumberFrames: UInt32,
    ioData: UnsafeMutablePointer<AudioBufferList>?
) -> OSStatus {
    let source = Unmanaged<AudioDeviceStreamSource>.fromOpaque(inRefCon).takeUnretainedValue()
    source.handleInput(
        ioActionFlags: ioActionFlags,
        inTimeStamp: inTimeStamp,
        inBusNumber: inBusNumber,
        inNumberFrames: inNumberFrames
    )
    return noErr
}
