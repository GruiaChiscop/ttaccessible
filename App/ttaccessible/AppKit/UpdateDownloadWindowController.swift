//
//  UpdateDownloadWindowController.swift
//  ttaccessible
//

import AppKit

protocol UpdateDownloadWindowControllerDelegate: AnyObject {
    func updateDownloadWindowDidRequestCancel(_ controller: UpdateDownloadWindowController)
}

final class UpdateDownloadWindowController: NSWindowController {
    weak var delegate: UpdateDownloadWindowControllerDelegate?

    private let statusLabel = NSTextField(labelWithString: "")
    private let progressIndicator = NSProgressIndicator()
    private let actionButton = NSButton(title: "", target: nil, action: nil)

    private var downloadedFileURL: URL?
    private var isFinished = false

    init(release: UpdateRelease) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 140),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.format("update.download.window.title", release.displayVersion)
        window.isReleasedWhenClosed = false
        window.center()
        super.init(window: window)

        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        window.contentView = contentView

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.stringValue = L10n.format("update.download.status.starting", release.zipAsset.name)
        statusLabel.lineBreakMode = .byTruncatingMiddle
        contentView.addSubview(statusLabel)

        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = true
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 1
        progressIndicator.startAnimation(nil)
        progressIndicator.setAccessibilityLabel(L10n.text("update.download.progress.accessibilityLabel"))
        contentView.addSubview(progressIndicator)

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.bezelStyle = .rounded
        actionButton.title = L10n.text("common.cancel")
        actionButton.keyEquivalent = "\u{1b}" // Escape
        actionButton.target = self
        actionButton.action = #selector(handleAction)
        contentView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            progressIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            progressIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            progressIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            actionButton.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            actionButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func setProgress(_ fraction: Double) {
        if progressIndicator.isIndeterminate {
            progressIndicator.stopAnimation(nil)
            progressIndicator.isIndeterminate = false
        }
        progressIndicator.doubleValue = fraction
        statusLabel.stringValue = L10n.format("update.download.status.progress", Int(fraction * 100))
    }

    func markFinished(fileURL: URL) {
        isFinished = true
        downloadedFileURL = fileURL
        progressIndicator.stopAnimation(nil)
        progressIndicator.isIndeterminate = false
        progressIndicator.doubleValue = 1
        statusLabel.stringValue = L10n.format("update.download.status.finished", fileURL.lastPathComponent)
        actionButton.title = L10n.text("update.download.button.revealInFinder")
        actionButton.keyEquivalent = "\r"
    }

    func markFailed(message: String) {
        isFinished = true
        progressIndicator.stopAnimation(nil)
        statusLabel.stringValue = message
        actionButton.title = L10n.text("common.close")
        actionButton.keyEquivalent = "\r"
    }

    @objc private func handleAction() {
        if let url = downloadedFileURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
            close()
            return
        }
        if isFinished {
            close()
            return
        }
        delegate?.updateDownloadWindowDidRequestCancel(self)
    }
}
