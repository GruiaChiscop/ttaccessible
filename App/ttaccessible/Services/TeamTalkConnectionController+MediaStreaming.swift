//
//  TeamTalkConnectionController+MediaStreaming.swift
//  ttaccessible
//

import Foundation

extension TeamTalkConnectionController {

    func startStreamingMediaFile(at url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self,
                  let instance = self.instance,
                  let record = self.connectedRecord else {
                DispatchQueue.main.async {
                    completion(.failure(TeamTalkConnectionError.connectionFailed))
                }
                return
            }

            if self.mediaStreamingActive {
                self.stopStreamingMediaFileLocked(instance: instance)
            }

            let didAccess = url.startAccessingSecurityScopedResource()
            let path = url.path

            var playback = MediaFilePlayback()
            playback.uOffsetMSec = 0
            playback.bPaused = 0
            playback.audioPreprocessor.nPreprocessor = NO_AUDIOPREPROCESSOR

            var videoCodec = VideoCodec()
            videoCodec.nCodec = NO_CODEC

            let started = path.withCString { cPath -> Bool in
                TT_StartStreamingMediaFileToChannelEx(instance, cPath, &playback, &videoCodec) != 0
            }

            guard started else {
                if didAccess { url.stopAccessingSecurityScopedResource() }
                DispatchQueue.main.async {
                    completion(.failure(TeamTalkConnectionError.internalError(L10n.text("mediaStream.error.startFailed"))))
                }
                return
            }

            self.mediaStreamingActive = true
            self.mediaStreamingFileName = url.lastPathComponent
            self.mediaStreamingSecurityScopedURL = didAccess ? url : nil
            self.publishSessionLocked(instance: instance, record: record, invalidation: .audio)
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }

    func stopStreamingMediaFile() {
        queue.async { [weak self] in
            guard let self, let instance = self.instance else { return }
            self.stopStreamingMediaFileLocked(instance: instance)
        }
    }

    func stopStreamingMediaFileLocked(instance: UnsafeMutableRawPointer) {
        guard mediaStreamingActive else { return }
        _ = TT_StopStreamingMediaFileToChannel(instance)
        finalizeMediaStreamingLocked(instance: instance, reason: .userStopped)
    }

    enum MediaStreamingFinalizeReason {
        case userStopped
        case finished
        case error
    }

    func finalizeMediaStreamingLocked(instance: UnsafeMutableRawPointer, reason: MediaStreamingFinalizeReason) {
        mediaStreamingSecurityScopedURL?.stopAccessingSecurityScopedResource()
        mediaStreamingSecurityScopedURL = nil
        mediaStreamingActive = false
        mediaStreamingFileName = nil

        switch reason {
        case .finished:
            appendHistoryLocked(
                kind: .mediaStreamingFinished,
                message: L10n.text("history.mediaStreamingFinished")
            )
        case .error, .userStopped:
            break
        }

        if let record = connectedRecord {
            publishSessionLocked(instance: instance, record: record, invalidation: [.audio, .history])
        }
    }

    func appendMediaStreamingStartedHistoryLocked(fileName: String) {
        appendHistoryLocked(
            kind: .mediaStreamingStarted,
            message: L10n.format("history.mediaStreamingStarted", fileName)
        )
    }
}
