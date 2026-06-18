//
//  AudioDevicePreference.swift
//  ttaccessible
//
//  Created by Mathieu Martin on 17/03/2026.
//

import Foundation

struct AudioDevicePreference: Codable, Equatable {
    /// Sentinel `persistentID` that means "do not initialize an output device
    /// at all" (rather than picking a real device or the system default).
    /// Used by the Audio preferences pane's output picker so streaming
    /// profiles can connect, transmit, and hear nothing — the main profile
    /// carries the audio.
    static let noOutputSentinelID = "__no_output__"

    var persistentID: String?
    var displayName: String?

    static let systemDefault = AudioDevicePreference(persistentID: nil, displayName: nil)
    static let noOutput = AudioDevicePreference(persistentID: noOutputSentinelID, displayName: nil)

    nonisolated var usesSystemDefault: Bool {
        persistentID?.isEmpty != false
    }

    nonisolated var usesNoOutput: Bool {
        persistentID == AudioDevicePreference.noOutputSentinelID
    }
}
