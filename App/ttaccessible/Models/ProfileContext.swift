//
//  ProfileContext.swift
//  ttaccessible
//

import Foundation
import Security

/// Identifies a single profile (instance) of ttaccessible. Each profile gets
/// its own UserDefaults suite, Application Support subdirectory, and keychain
/// service namespace so two instances of the app can run side-by-side without
/// sharing any state.
///
/// The "default" profile maps to `UserDefaults.standard` and the existing
/// Application Support paths so pre-profile installs keep working with no
/// migration.
final class ProfileContext {
    static let defaultSlug = "default"
    static let defaultDisplayName = "Default"
    /// Dedicated suite for the default profile. The default profile no longer
    /// uses `.standard` directly: its data is migrated into this suite so the
    /// app's bundle domain (which every suite's search list falls through to)
    /// stops leaking the default's data into other profiles. See
    /// `migrateDefaultProfileStorageIfNeeded()`.
    static let defaultSuiteName = "com.math65.ttaccessible.profile.default"
    private static let defaultMigrationFlagKey = "profile.defaultMigration.v1"

    /// The active profile for this process. Resolved lazily on first access
    /// from `-profile <slug>` in `CommandLine.arguments`; stores that take a
    /// `UserDefaults` argument default to `ProfileContext.current.userDefaults`,
    /// which triggers that first access before any store is constructed.
    ///
    /// Bound for the lifetime of the process — switching profiles means
    /// launching a new instance with `NSWorkspace.openApplication`.
    static let current: ProfileContext = ProfileContext.resolveFromLaunchEnvironment()

    /// Look up `-profile <slug>` in `CommandLine.arguments`, fall back to
    /// `TTACCESSIBLE_PROFILE` in the environment for sandbox-friendly
    /// scripted launches. Unknown slugs are registered on the fly so a freshly
    /// chosen profile works on its very first launch.
    private static func resolveFromLaunchEnvironment() -> ProfileContext {
        // Runs once per install (flag-guarded): moves the default profile's
        // data out of the shared bundle domain so other profiles stop seeing it.
        migrateDefaultProfileStorageIfNeeded()

        let args = CommandLine.arguments
        var requestedSlug: String?
        var i = 1
        while i < args.count {
            if args[i] == "-profile" || args[i] == "--profile" {
                if i + 1 < args.count {
                    requestedSlug = args[i + 1]
                }
                break
            }
            i += 1
        }
        if requestedSlug == nil {
            if let envSlug = ProcessInfo.processInfo.environment["TTACCESSIBLE_PROFILE"],
               envSlug.isEmpty == false {
                requestedSlug = envSlug
            }
        }
        // NSWorkspace.openApplication drops arguments AND environment when a
        // sandboxed app launches another instance of itself, and Sparkle
        // relaunches without preserving them either. The reliable channel is the
        // one-shot file token written just before the new instance starts.
        if requestedSlug == nil {
            if let handoff = consumePendingHandoff() {
                requestedSlug = handoff.slug
                startsDisconnectedOnLaunch = handoff.suppressAutoConnect
            }
        }
        guard let rawSlug = requestedSlug else {
            return defaultProfile()
        }
        let slug = normalizeSlug(rawSlug)
        guard slug.isEmpty == false, slug != defaultSlug else {
            return defaultProfile()
        }
        let registry = ProfileRegistry.shared
        let displayName: String
        if let existing = registry.entry(forSlug: slug) {
            displayName = existing.displayName
        } else {
            let registered = registry.register(displayName: rawSlug)
            displayName = registered?.displayName ?? rawSlug
        }
        return make(slug: slug, displayName: displayName)
    }

    let slug: String
    let displayName: String
    let userDefaults: UserDefaults
    let isDefault: Bool

    private init(slug: String, displayName: String, userDefaults: UserDefaults, isDefault: Bool) {
        self.slug = slug
        self.displayName = displayName
        self.userDefaults = userDefaults
        self.isDefault = isDefault
    }

    static func defaultProfile() -> ProfileContext {
        let defaults = UserDefaults(suiteName: defaultSuiteName) ?? .standard
        return ProfileContext(
            slug: defaultSlug,
            displayName: defaultDisplayName,
            userDefaults: defaults,
            isDefault: true
        )
    }

    static func make(slug rawSlug: String, displayName: String) -> ProfileContext {
        let normalized = normalizeSlug(rawSlug)
        guard normalized != defaultSlug, normalized.isEmpty == false else {
            return defaultProfile()
        }
        let suiteName = suiteName(forSlug: normalized)
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        let trimmedDisplay = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return ProfileContext(
            slug: normalized,
            displayName: trimmedDisplay.isEmpty ? normalized : trimmedDisplay,
            userDefaults: defaults,
            isDefault: false
        )
    }

    /// Sanitize a user-supplied profile name into a slug usable as a UserDefaults
    /// suite name, directory name, and keychain service suffix.
    static func normalizeSlug(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_")
        let scalars = trimmed.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let collapsed = String(scalars)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return collapsed
    }

    // MARK: - Paths

    /// Application Support directory specific to this profile. Custom profiles
    /// get a per-slug subdirectory; the default profile uses the user's
    /// Application Support root so pre-existing data stays in place.
    ///
    /// Note: under the App Sandbox this resolves inside the container
    /// (`~/Library/Containers/com.math65.ttaccessible/Data/Library/Application Support/`),
    /// not the user's literal `~/Library/Application Support/`. Either way,
    /// every instance of the bundle sees the same root.
    var applicationSupportRoot: URL {
        let base = ProfileContext.applicationSupportBase
        if isDefault {
            return base
        }
        return base
            .appendingPathComponent("ttaccessible", isDirectory: true)
            .appendingPathComponent("profiles", isDirectory: true)
            .appendingPathComponent(slug, isDirectory: true)
    }

    /// Where custom sound packs are stored. The default profile keeps the
    /// historical `~/Library/Application Support/Sound Packs/` location.
    var customSoundPacksDirectory: URL {
        applicationSupportRoot.appendingPathComponent("Sound Packs", isDirectory: true)
    }

    /// Where channel chat history JSON files live. The default profile keeps
    /// the historical `~/Library/Application Support/ttaccessible/history/`
    /// location.
    var channelChatHistoryDirectory: URL {
        if isDefault {
            return applicationSupportRoot
                .appendingPathComponent("ttaccessible", isDirectory: true)
                .appendingPathComponent("history", isDirectory: true)
        }
        return applicationSupportRoot.appendingPathComponent("history", isDirectory: true)
    }

    /// Keychain `kSecAttrService` used by `ServerPasswordStore`. Per-profile so
    /// custom profiles get a fresh keychain namespace and don't collide with
    /// the default profile's items.
    var keychainServiceName: String {
        Self.keychainServiceName(forSlug: slug, isDefault: isDefault)
    }

    /// Decorate a window title with the active profile name when not running
    /// the default profile, so users can tell two running instances apart.
    func decorateWindowTitle(_ base: String) -> String {
        guard isDefault == false else { return base }
        return "\(base) — \(displayName)"
    }

    // MARK: - Shared helpers

    /// Base Application Support directory visible to every instance of the
    /// bundle regardless of which profile that instance is bound to.
    static var applicationSupportBase: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
    }

    /// Directory used for cross-instance coordination (e.g. running-profile
    /// PID locks). Always under `…/Application Support/ttaccessible/`, never
    /// inside a per-profile subdirectory, so all instances find the same path.
    static var sharedCoordinationDirectory: URL {
        applicationSupportBase
            .appendingPathComponent("ttaccessible", isDirectory: true)
            .appendingPathComponent("instance-locks", isDirectory: true)
    }

    static func suiteName(forSlug slug: String) -> String {
        "com.math65.ttaccessible.profile.\(slug)"
    }

    static func keychainServiceName(forSlug slug: String, isDefault: Bool) -> String {
        if isDefault || slug == defaultSlug {
            return "com.math65.ttaccessible.saved-server-password"
        }
        return "com.math65.ttaccessible.saved-server-password.profile.\(slug)"
    }

    /// One-time migration: move the default profile's UserDefaults from the
    /// app's bundle domain (`.standard`) into a dedicated suite.
    ///
    /// Why: in-process, every `UserDefaults(suiteName:)` search list falls
    /// through to the main bundle's persistent domain. With the default
    /// profile's data living there, a fresh non-default profile would read the
    /// default's servers/preferences for any key it hadn't written yet. Moving
    /// the default's app keys out of the bundle domain makes that fall-through
    /// land on nothing → real isolation.
    ///
    /// Framework keys (Sparkle `SU…`, AppKit `NS…` window-frame autosave, etc.)
    /// are intentionally LEFT in the bundle domain: Sparkle and AppKit read
    /// them from `.standard`, and sharing them across instances is harmless.
    ///
    /// Flag-guarded and idempotent; safe to call on every launch and from any
    /// profile's process (the bundle domain is shared by all instances).
    static func migrateDefaultProfileStorageIfNeeded() {
        guard let suite = UserDefaults(suiteName: defaultSuiteName) else { return }
        if suite.bool(forKey: defaultMigrationFlagKey) { return }

        let standard = UserDefaults.standard
        if let bundleID = Bundle.main.bundleIdentifier,
           let appDomain = standard.persistentDomain(forName: bundleID) {
            let systemPrefixes = ["SU", "NS", "Apple", "com.apple", "WebKit", "Sparkle"]
            for (key, value) in appDomain {
                if systemPrefixes.contains(where: { key.hasPrefix($0) }) { continue }
                suite.set(value, forKey: key)
                standard.removeObject(forKey: key)
            }
        }

        suite.set(true, forKey: defaultMigrationFlagKey)
        suite.synchronize()
        standard.synchronize()
    }

    /// Tear down every storage location owned by a profile. Used by the
    /// Manage Profiles UI when the user deletes a profile. Refuses to touch
    /// the default profile.
    @discardableResult
    static func purgeStorage(forSlug rawSlug: String) -> Bool {
        let slug = normalizeSlug(rawSlug)
        guard slug.isEmpty == false, slug != defaultSlug else {
            return false
        }

        // Application Support subdirectory (sound packs, chat history, …).
        let profileRoot = applicationSupportBase
            .appendingPathComponent("ttaccessible", isDirectory: true)
            .appendingPathComponent("profiles", isDirectory: true)
            .appendingPathComponent(slug, isDirectory: true)
        try? FileManager.default.removeItem(at: profileRoot)

        // UserDefaults suite.
        let suite = suiteName(forSlug: slug)
        UserDefaults.standard.removePersistentDomain(forName: suite)
        UserDefaults.standard.synchronize()
        // Belt-and-braces: also remove the suite-backed plist if it lingers
        // (older macOS bug where removePersistentDomain didn't always delete
        // the file).
        UserDefaults().removePersistentDomain(forName: suite)

        // Keychain items under this profile's service.
        let service = keychainServiceName(forSlug: slug, isDefault: false)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service
        ]
        let status = SecItemDelete(query as CFDictionary)
        // errSecItemNotFound is fine — nothing was ever stored for this slug.
        _ = status

        return true
    }

    // MARK: - Pending profile handoff (NSWorkspace self-launch + Sparkle relaunch)

    /// `NSWorkspace.openApplication` drops BOTH `arguments` and `environment`
    /// when a sandboxed app launches another instance of itself, and Sparkle
    /// relaunches without preserving them either. So the profile a freshly
    /// launched instance should bind to is handed off via a one-shot file token
    /// written just before the new instance starts; the new process consumes it
    /// during launch resolution.
    ///
    /// Single-use: deleted on read and only trusted within a short freshness
    /// window, so a stale token (e.g. after a crash) can't hijack a later launch.
    /// Sequential user-driven launches don't race; the only race
    /// (two launches within the same instant) is astronomically unlikely and
    /// degrades to "the other new instance binds the default profile".
    private static var pendingHandoffTokenURL: URL {
        sharedCoordinationDirectory.appendingPathComponent("pending-handoff", isDirectory: false)
    }

    private static let pendingHandoffMaxAge: TimeInterval = 60

    /// Whether the instance launched this session should start disconnected (a
    /// clone of the current profile, mirroring Qt's `-noconnect`). Set from the
    /// consumed handoff token during launch resolution; read by AppDelegate.
    private(set) static var startsDisconnectedOnLaunch = false

    /// Record the profile a freshly launched instance should bind to, and
    /// whether it should start disconnected. Written by the New Instance menu
    /// before `NSWorkspace.openApplication`, and by `updaterWillRelaunchApplication`.
    static func recordPendingHandoff(slug: String, suppressAutoConnect: Bool) {
        let normalized = normalizeSlug(slug)
        guard normalized.isEmpty == false else { return }
        try? FileManager.default.createDirectory(at: sharedCoordinationDirectory, withIntermediateDirectories: true)
        let payload = "\(Int(Date().timeIntervalSince1970))\n\(normalized)\n\(suppressAutoConnect ? "1" : "0")\n"
        try? payload.write(to: pendingHandoffTokenURL, atomically: true, encoding: .utf8)
    }

    /// Read and delete the handoff token. Returns `(slug, suppressAutoConnect)`
    /// only when the token exists and is fresh; nil otherwise. Consumed once.
    private static func consumePendingHandoff() -> (slug: String, suppressAutoConnect: Bool)? {
        let url = pendingHandoffTokenURL
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        try? FileManager.default.removeItem(at: url)
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: true)
        guard lines.count >= 2,
              let stamp = TimeInterval(lines[0].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }
        let age = Date().timeIntervalSince1970 - stamp
        guard age >= 0, age <= pendingHandoffMaxAge else {
            return nil
        }
        let slug = normalizeSlug(String(lines[1]))
        guard slug.isEmpty == false else { return nil }
        let suppress = lines.count >= 3 && lines[2].trimmingCharacters(in: .whitespaces) == "1"
        return (slug, suppress)
    }
}
