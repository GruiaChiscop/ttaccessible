//
//  AppDelegate+NewInstance.swift
//  ttaccessible
//

import AppKit

@MainActor
extension AppDelegate {
    /// Show the picker that lets the user launch a separate process bound to
    /// another profile. Triggered from the "New Instance…" menu item.
    func openNewInstanceDialog() {
        let registry = ProfileRegistry.shared
        let existing = registry.listAll()
        let currentSlug = ProfileContext.current.slug

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L10n.text("profile.newInstance.title")
        alert.informativeText = L10n.text("profile.newInstance.message")
        alert.addButton(withTitle: L10n.text("profile.newInstance.launch"))
        alert.addButton(withTitle: L10n.text("profile.newInstance.createNew"))
        alert.addButton(withTitle: L10n.text("common.cancel"))

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 320, height: 26), pullsDown: false)
        popup.setAccessibilityLabel(L10n.text("profile.newInstance.picker.accessibilityLabel"))
        for entry in existing {
            let title: String
            if entry.slug == currentSlug {
                title = L10n.format("profile.newInstance.picker.currentSuffix", entry.displayName)
            } else {
                title = entry.displayName
            }
            popup.addItem(withTitle: title)
            popup.lastItem?.representedObject = entry.slug
        }
        if popup.numberOfItems == 0 {
            // Should never happen — the registry always includes the default entry.
            popup.addItem(withTitle: ProfileContext.defaultDisplayName)
            popup.lastItem?.representedObject = ProfileContext.defaultSlug
        }

        // Default the picker to the first non-current profile if any exist.
        if let firstOther = existing.firstIndex(where: { $0.slug != currentSlug }) {
            popup.selectItem(at: firstOther)
        }

        alert.accessoryView = popup

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            guard let slug = popup.selectedItem?.representedObject as? String else { return }
            // Launching the current profile opens a second window that shares
            // its servers/settings — start it disconnected so the user can
            // point it at a different server (mirrors the Qt client).
            let isCurrent = (slug == ProfileContext.current.slug)
            launchInstance(forSlug: slug, suppressAutoConnect: isCurrent)
        case .alertSecondButtonReturn:
            promptCreateAndLaunchProfile()
        default:
            return
        }
    }

    /// Show the picker that lets the user rename or delete an existing custom
    /// profile. Triggered from the "Manage Profiles…" menu item.
    func openManageProfilesDialog() {
        let registry = ProfileRegistry.shared
        let custom = registry.customProfiles()

        guard custom.isEmpty == false else {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = L10n.text("profile.manage.title")
            alert.informativeText = L10n.text("profile.manage.empty.message")
            alert.addButton(withTitle: L10n.text("common.ok"))
            alert.runModal()
            return
        }

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L10n.text("profile.manage.title")
        alert.informativeText = L10n.text("profile.manage.message")
        alert.addButton(withTitle: L10n.text("profile.manage.rename"))
        alert.addButton(withTitle: L10n.text("profile.manage.delete"))
        alert.addButton(withTitle: L10n.text("common.cancel"))

        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 320, height: 26), pullsDown: false)
        popup.setAccessibilityLabel(L10n.text("profile.manage.picker.accessibilityLabel"))
        for entry in custom {
            popup.addItem(withTitle: entry.displayName)
            popup.lastItem?.representedObject = entry.slug
        }
        alert.accessoryView = popup

        let response = alert.runModal()
        guard let slug = popup.selectedItem?.representedObject as? String,
              let entry = custom.first(where: { $0.slug == slug }) else {
            return
        }

        switch response {
        case .alertFirstButtonReturn:
            promptRenameProfile(entry)
        case .alertSecondButtonReturn:
            promptDeleteProfile(entry)
        default:
            return
        }
    }

    private func promptCreateAndLaunchProfile() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L10n.text("profile.create.title")
        alert.informativeText = L10n.text("profile.create.message")
        alert.addButton(withTitle: L10n.text("profile.create.launch"))
        alert.addButton(withTitle: L10n.text("common.cancel"))

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.placeholderString = L10n.text("profile.create.placeholder")
        field.setAccessibilityLabel(L10n.text("profile.create.field.accessibilityLabel"))
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let rawName = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard rawName.isEmpty == false else {
            presentNewInstanceError(message: L10n.text("profile.create.error.empty"))
            return
        }

        let slug = ProfileContext.normalizeSlug(rawName)
        guard slug.isEmpty == false else {
            presentNewInstanceError(message: L10n.text("profile.create.error.invalid"))
            return
        }
        guard slug != ProfileContext.defaultSlug else {
            presentNewInstanceError(message: L10n.text("profile.create.error.reservedDefault"))
            return
        }

        guard let entry = ProfileRegistry.shared.register(displayName: rawName) else {
            presentNewInstanceError(message: L10n.text("profile.create.error.invalid"))
            return
        }
        // A brand-new profile is empty, so there's nothing to auto-connect to.
        launchInstance(forSlug: entry.slug, suppressAutoConnect: false)
    }

    private func promptRenameProfile(_ entry: ProfileRegistry.Entry) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L10n.text("profile.rename.title")
        alert.informativeText = L10n.format("profile.rename.message", entry.displayName)
        alert.addButton(withTitle: L10n.text("profile.rename.confirm"))
        alert.addButton(withTitle: L10n.text("common.cancel"))

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.stringValue = entry.displayName
        field.placeholderString = L10n.text("profile.create.placeholder")
        field.setAccessibilityLabel(L10n.text("profile.create.field.accessibilityLabel"))
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let newName = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard newName.isEmpty == false else {
            presentNewInstanceError(message: L10n.text("profile.create.error.empty"))
            return
        }
        if newName == entry.displayName {
            return
        }
        guard ProfileRegistry.shared.rename(slug: entry.slug, to: newName) != nil else {
            presentNewInstanceError(message: L10n.text("profile.rename.error.failed"))
            return
        }
    }

    private func promptDeleteProfile(_ entry: ProfileRegistry.Entry) {
        if entry.slug == ProfileContext.current.slug {
            presentNewInstanceError(message: L10n.format(
                "profile.delete.error.currentRunning",
                entry.displayName
            ))
            return
        }
        if ProfileInstanceLock.isAnotherInstanceRunning(forSlug: entry.slug) {
            presentNewInstanceError(message: L10n.format(
                "profile.delete.error.otherInstanceRunning",
                entry.displayName
            ))
            return
        }

        let confirm = NSAlert()
        confirm.alertStyle = .warning
        confirm.messageText = L10n.format("profile.delete.confirm.title", entry.displayName)
        confirm.informativeText = L10n.text("profile.delete.confirm.message")
        confirm.addButton(withTitle: L10n.text("profile.delete.confirm.button"))
        confirm.addButton(withTitle: L10n.text("common.cancel"))
        // Make Cancel the default Return action so an accidental Enter doesn't
        // wipe the profile.
        confirm.buttons.first?.keyEquivalent = ""
        confirm.buttons.last?.keyEquivalent = "\r"
        guard confirm.runModal() == .alertFirstButtonReturn else { return }

        ProfileContext.purgeStorage(forSlug: entry.slug)
        ProfileRegistry.shared.remove(slug: entry.slug)
    }

    /// Launch a separate process bound to `rawSlug`. Multiple instances of the
    /// same profile are allowed (like the Qt client): they intentionally share
    /// servers/settings with last-writer-wins. `ProfileInstanceLock` is no
    /// longer used to refuse a launch — only to guard profile deletion against
    /// a live instance. When `suppressAutoConnect` is true (a clone of the
    /// current profile), the new instance starts disconnected via `-noconnect`.
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
                self?.presentNewInstanceError(message: error.localizedDescription)
            }
        }
    }

    private func presentNewInstanceError(message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.text("profile.newInstance.error.title")
        alert.informativeText = message
        alert.runModal()
    }
}
