//
//  UserVolumeStore.swift
//  ttaccessible
//

import Foundation

/// Per-user voice/media volume, stereo balance and pan, persisted in the profile's
/// UserDefaults.
///
/// Entries are keyed by `serverScope` + username, NOT by username alone. TeamTalk
/// `szUsername` is frequently shared/generic on public servers (guest, anonymous,
/// club accounts), so a username-only key let a volume set for one person silently
/// re-apply to a different person with the same username — even across servers
/// (issue #24). Scoping by server (host:port) confines a stored volume to the server
/// it was set on. Same-server collisions on a shared account are an inherent limit:
/// `szUsername` is the only identifier the SDK keeps stable across reconnects.
///
/// Pre-scoping entries (bare-username keys) no longer match a scoped lookup and fall
/// back to the 50% default. That is intentional — those values are exactly the
/// cross-server-polluted data the scoping fixes.
final class UserVolumeStore {
    private let key = "userVoiceVolumeByUsername"
    private let mediaFileKey = "userMediaFileVolumeByUsername"
    private let stereoKey = "userStereoBalanceByUsername"
    private let panKey = "userPanByUsername"
    private let defaults: UserDefaults

    /// Server identity (e.g. "host:port") prepended to every entry key. Empty until a
    /// session is established; reads/writes only happen while connected, so the scope
    /// is always set by then. Guarded because it is set on the TeamTalk queue but read
    /// from both that queue and the main thread (mixer / user-actions UI).
    private var serverScope = ""
    private let scopeLock = NSLock()

    init(defaults: UserDefaults = ProfileContext.current.userDefaults) {
        self.defaults = defaults
    }

    /// Set the current server scope (call on connect), or nil to clear (on disconnect).
    func setServerScope(_ scope: String?) {
        scopeLock.lock()
        serverScope = scope ?? ""
        scopeLock.unlock()
    }

    /// Compose the persisted entry key from the current server scope and the username.
    /// The unit-separator (U+001F) can't appear in a host or a TeamTalk username, so it
    /// is an unambiguous delimiter. With no scope set, falls back to the bare username.
    private func entryKey(_ username: String) -> String {
        scopeLock.lock()
        let scope = serverScope
        scopeLock.unlock()
        return scope.isEmpty ? username : scope + "\u{1F}" + username
    }

    func volume(forUsername username: String) -> Int32? {
        volume(forUsername: username, key: key)
    }

    func setVolume(_ volume: Int32, forUsername username: String) {
        setVolume(volume, forUsername: username, key: key)
    }

    func mediaFileVolume(forUsername username: String) -> Int32? {
        volume(forUsername: username, key: mediaFileKey)
    }

    func setMediaFileVolume(_ volume: Int32, forUsername username: String) {
        setVolume(volume, forUsername: username, key: mediaFileKey)
    }

    private func volume(forUsername username: String, key: String) -> Int32? {
        guard !username.isEmpty,
              let dict = defaults.dictionary(forKey: key),
              let value = dict[entryKey(username)] as? Int else { return nil }
        return Int32(value)
    }

    private func setVolume(_ volume: Int32, forUsername username: String, key: String) {
        guard !username.isEmpty else { return }
        var dict = defaults.dictionary(forKey: key) ?? [:]
        let entry = entryKey(username)
        if volume == SOUND_VOLUME_DEFAULT.rawValue {
            dict.removeValue(forKey: entry)
        } else {
            dict[entry] = Int(volume)
        }
        defaults.set(dict, forKey: key)
    }

    // MARK: - Stereo Balance

    struct StereoBalance: Equatable {
        let left: Bool
        let right: Bool
        static let `default` = StereoBalance(left: true, right: true)
    }

    func stereoBalance(forUsername username: String) -> StereoBalance? {
        guard !username.isEmpty,
              let dict = defaults.dictionary(forKey: stereoKey),
              let entry = dict[entryKey(username)] as? [String: Bool],
              let left = entry["left"],
              let right = entry["right"] else { return nil }
        return StereoBalance(left: left, right: right)
    }

    func setStereoBalance(_ balance: StereoBalance, forUsername username: String) {
        guard !username.isEmpty else { return }
        var dict = defaults.dictionary(forKey: stereoKey) ?? [:]
        let key = entryKey(username)
        if balance == .default {
            dict.removeValue(forKey: key)
        } else {
            dict[key] = ["left": balance.left, "right": balance.right]
        }
        defaults.set(dict, forKey: stereoKey)
    }

    // MARK: - Continuous Pan (Channel Mixer)
    //
    // The mixer's pan slider drives OutputAudioRenderEngine.setUserSettings (our own
    // per-user mix), independent of the SDK's discrete left/right StereoBalance above.
    // Range -1 (full left) .. 0 (center) .. +1 (full right); center is the default and
    // is stored as "no entry" so it never overrides a user who only touches the L/R checks.

    func pan(forUsername username: String) -> Float? {
        guard !username.isEmpty,
              let dict = defaults.dictionary(forKey: panKey),
              let value = dict[entryKey(username)] as? Double else { return nil }
        return Float(value)
    }

    func setPan(_ pan: Float, forUsername username: String) {
        guard !username.isEmpty else { return }
        let clamped = max(-1, min(1, pan))
        var dict = defaults.dictionary(forKey: panKey) ?? [:]
        let key = entryKey(username)
        if abs(clamped) < 0.0001 {
            dict.removeValue(forKey: key)
        } else {
            dict[key] = Double(clamped)
        }
        defaults.set(dict, forKey: panKey)
    }
}
