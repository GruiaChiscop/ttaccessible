//
//  UpdateAvailableWindowController.swift
//  ttaccessible
//

import AppKit

protocol UpdateAvailableWindowControllerDelegate: AnyObject {
    func updateAvailableWindowDidRequestDownload(_ controller: UpdateAvailableWindowController, release: UpdateRelease)
    func updateAvailableWindowDidRequestOpenGitHub(_ controller: UpdateAvailableWindowController, release: UpdateRelease)
    func updateAvailableWindowDidDismiss(_ controller: UpdateAvailableWindowController)
}

final class UpdateAvailableWindowController: NSWindowController, NSWindowDelegate {
    weak var delegate: UpdateAvailableWindowControllerDelegate?

    private let latestRelease: UpdateRelease
    private let currentVersion: String

    init(release: UpdateRelease, currentVersion: String) {
        self.latestRelease = release
        self.currentVersion = currentVersion

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 440),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text("update.available.window.title")
        window.isReleasedWhenClosed = false
        window.center()
        window.collectionBehavior = [.moveToActiveSpace]

        super.init(window: window)
        window.delegate = self

        buildLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func showAndRun() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildLayout() {
        guard let contentView = window?.contentView else { return }

        let header = NSTextField(labelWithString: L10n.format("update.available.headline", latestRelease.displayVersion))
        header.font = .systemFont(ofSize: 17, weight: .semibold)
        header.translatesAutoresizingMaskIntoConstraints = false
        header.lineBreakMode = .byWordWrapping
        header.maximumNumberOfLines = 0
        header.setAccessibilityRole(.staticText)
        header.setAccessibilityLabel(L10n.format("update.available.headline.accessibility", latestRelease.displayVersion))
        contentView.addSubview(header)

        let subhead = NSTextField(labelWithString: L10n.format("update.available.subhead", currentVersion, latestRelease.displayVersion))
        subhead.font = .systemFont(ofSize: 13)
        subhead.textColor = .secondaryLabelColor
        subhead.translatesAutoresizingMaskIntoConstraints = false
        subhead.lineBreakMode = .byWordWrapping
        subhead.maximumNumberOfLines = 0
        contentView.addSubview(subhead)

        let notesLabel = NSTextField(labelWithString: L10n.text("update.available.releaseNotesLabel"))
        notesLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        notesLabel.textColor = .secondaryLabelColor
        notesLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(notesLabel)

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        scrollView.drawsBackground = true

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.usesFindBar = true
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.font = .systemFont(ofSize: 13)
        textView.linkTextAttributes = [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.setAccessibilityLabel(L10n.text("update.available.releaseNotes.accessibilityLabel"))

        let attributed = Self.formatReleaseNotes(latestRelease.releaseNotes)
        textView.textStorage?.setAttributedString(attributed)

        scrollView.documentView = textView
        contentView.addSubview(scrollView)

        let laterButton = NSButton(title: L10n.text("update.available.button.later"), target: self, action: #selector(handleLater))
        laterButton.bezelStyle = .rounded
        laterButton.keyEquivalent = "\u{1b}" // Escape
        laterButton.translatesAutoresizingMaskIntoConstraints = false

        let githubButton = NSButton(title: L10n.text("update.available.button.viewOnGitHub"), target: self, action: #selector(handleGitHub))
        githubButton.bezelStyle = .rounded
        githubButton.translatesAutoresizingMaskIntoConstraints = false

        let downloadButton = NSButton(title: L10n.text("update.available.button.download"), target: self, action: #selector(handleDownload))
        downloadButton.bezelStyle = .rounded
        downloadButton.keyEquivalent = "\r"
        downloadButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(laterButton)
        contentView.addSubview(githubButton)
        contentView.addSubview(downloadButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subhead.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 6),
            subhead.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subhead.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            notesLabel.topAnchor.constraint(equalTo: subhead.bottomAnchor, constant: 16),
            notesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            scrollView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            downloadButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            downloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            downloadButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),

            githubButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            githubButton.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -10),

            laterButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            laterButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            scrollView.bottomAnchor.constraint(equalTo: downloadButton.topAnchor, constant: -16)
        ])

        window?.initialFirstResponder = downloadButton
        window?.defaultButtonCell = downloadButton.cell as? NSButtonCell
    }

    private static func formatReleaseNotes(_ raw: String) -> NSAttributedString {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            let empty = NSAttributedString(
                string: L10n.text("update.available.releaseNotes.empty"),
                attributes: [
                    .font: NSFont.systemFont(ofSize: 13),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            )
            return empty
        }

        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: false,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )

        if let parsed = try? NSAttributedString(markdown: trimmed, options: options) {
            let mutable = NSMutableAttributedString(attributedString: parsed)
            let range = NSRange(location: 0, length: mutable.length)
            mutable.addAttributes([
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.labelColor
            ], range: range)
            return mutable
        }

        return NSAttributedString(
            string: trimmed,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13),
                .foregroundColor: NSColor.labelColor
            ]
        )
    }

    @objc private func handleLater() {
        delegate?.updateAvailableWindowDidDismiss(self)
        close()
    }

    @objc private func handleGitHub() {
        delegate?.updateAvailableWindowDidRequestOpenGitHub(self, release: latestRelease)
        close()
    }

    @objc private func handleDownload() {
        delegate?.updateAvailableWindowDidRequestDownload(self, release: latestRelease)
        close()
    }

    func windowWillClose(_ notification: Notification) {
        delegate?.updateAvailableWindowDidDismiss(self)
    }
}
