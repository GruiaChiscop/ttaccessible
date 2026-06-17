//
//  AppDelegate+NewInstance.swift
//  ttaccessible
//

import AppKit

@MainActor
extension AppDelegate {
    /// Open the dedicated Profiles window (list / launch / create / rename /
    /// delete). Both the "New Instance…" and "Manage Profiles…" menu items route
    /// here — the window covers every profile operation.
    func openProfilesWindow() {
        let vc: ProfilesViewController
        if let existing = profilesViewController {
            vc = existing
        } else {
            vc = ProfilesViewController(appDelegate: self)
            profilesViewController = vc
        }
        if profilesWindowController == nil {
            profilesWindowController = ProfilesWindowController(contentViewController: vc)
        }
        vc.reload()
        profilesWindowController?.showWindow(nil)
        profilesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Launch a separate process bound to `slug`. Launching the current profile
    /// opens a second window that shares its servers/settings, so it starts
    /// disconnected (mirrors the Qt client); other profiles connect normally.
    func launchProfile(slug: String) {
        let isCurrent = (ProfileContext.normalizeSlug(slug) == ProfileContext.current.slug)
        launchInstance(forSlug: slug, suppressAutoConnect: isCurrent)
    }

    /// Launch a separate process bound to `rawSlug`. Multiple instances of the
    /// same profile are allowed (like the Qt client): they intentionally share
    /// servers/settings with last-writer-wins. When `suppressAutoConnect` is true
    /// (a clone of the current profile), the new instance starts disconnected.
    private func launchInstance(forSlug rawSlug: String, suppressAutoConnect: Bool) {
        let slug = ProfileContext.normalizeSlug(rawSlug)

        let bundleURL = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        configuration.activates = true
        // NSWorkspace drops `arguments` when a sandboxed app launches another
        // instance of itself, so the profile is passed via the environment
        // (read by ProfileContext as TTACCESSIBLE_PROFILE). Arguments are kept
        // as a belt-and-braces for contexts where they do come through.
        var arguments = ["-profile", slug]
        var environment = ["TTACCESSIBLE_PROFILE": slug]
        if suppressAutoConnect {
            arguments.append("-noconnect")
            environment["TTACCESSIBLE_NOCONNECT"] = "1"
        }
        configuration.arguments = arguments
        configuration.environment = environment
        // NSWorkspace drops arguments and environment for a sandboxed self-launch,
        // so the reliable channel is the file handoff the child consumes at launch.
        ProfileContext.recordPendingHandoff(slug: slug, suppressAutoConnect: suppressAutoConnect)

        NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { [weak self] _, error in
            guard let error else { return }
            DispatchQueue.main.async {
                self?.presentLaunchError(message: error.localizedDescription)
            }
        }
    }

    private func presentLaunchError(message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.text("profile.newInstance.error.title")
        alert.informativeText = message
        if let window = profilesWindowController?.window, window.isVisible {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
}
